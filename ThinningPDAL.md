# Point Cloud Thinning/Subsampling in PDAL

Thinning or subsampling reduces the number of points in a point cloud to:

- Accelerate processing (less data to handle)
- Normalize point density
- Ease visualization

In reality, points in a LAZ/LAS file are often **not uniformly distributed**. When thinning or sampling, we should attempt to:
- Preserve the overall shape and structure
- Use randomized methods to avoid bias
- Optionally normalize point density for better consistency

PDAL provides three main approaches:

## 1. Radius (Poisson) Based — `filters.sample`
`filters.sample` performs **Poisson disk sampling** (radius sampling) to reduce density while keeping points evenly spaced. Once a point is maintained, no other point within the specified minimum distance (`radius`) is accepted. This prevents clustering and maintains a uniform spatial distribution.

How it works:
- Space is divided into voxels (3D cubes).
- The first point in a voxel is kept if it satisfies the radius rule.
- Points too close to kept points in the same or neighboring voxels are discarded.
- Operates in streaming mode (memory-efficient) and avoids expensive KD-tree searches.

Control parameters:
- `radius`: minimum distance between kept points.
- `cell`: voxel size; PDAL calculates radius so the voxel fits inside a sphere of that radius.

Notes:
- Larger `radius` → fewer points (more aggressive thinning).
- Smaller `radius` → more points retained.
- Order matters in streaming mode — keep scan order (e.g., by GPS time) to avoid artifacts.
- Works in 3D space, not just XY.

      Example:
      ```json
      {
        "pipeline": [
          "input.las",
          {
            "type": "filters.sample",
            "radius": 0.5
          },
          "output.las"
        ]
      }
Pros:
* Produces evenly spaced points.
* Preserves spatial structure well.
* Works in 3D.

Cons:
* Sensitive to point order in streaming mode.
* Radius choice affects density significantly.

[https://pdal.io/en/stable/stages/filters.sample.html#filters-sample]

## 2. Systematic Random Based Thinning in PDAL
Systematic random thinning reduces point cloud size by ignoring spatial arrangement and operating on point order. This approach is often used for quick, uniform thinning when spatial structure preservation is not critical.

## a. `filters.decimation`
Retains every *N*-th point from the input point sequence.

Parameter:
- `step`: number of points to skip between retained points.
  - `step = 1` → keep all points.
  - `step = 2` → keep every other point (~50% retained).
  - `step = 100` → keep ~1% of points.
  - Fractional steps allowed: e.g., `step = 1.6` keeps `100 / 1.6 = 62.5%`.

## b. `filters.randomize`
Randomly shuffles the order of points without removing or altering them.

Purpose:
- Reduces bias caused by ordered input (e.g., scan lines or GPS-time sequence).
- Ensures that `filters.decimation` samples points more uniformly.

      Example
      ```json
      {
        "pipeline": [
          "input.las",
          { "type": "filters.randomize" },
          {
            "type": "filters.decimation",
            "step": 10
          },
          "output.las"
        ]
      }

Pros:
* Extremely fast and simple to apply.
* Easy to control percentage of retained points.
* Randomization reduces sampling bias.

Cons:
* No spatial awareness — can leave gaps or clusters.
* Not suitable for preserving fine-scale spatial features.

[https://pdal.io/en/stable/stages/filters.randomize.html#filters-randomize]

[https://pdal.io/en/stable/stages/filters.decimation.html#filters-decimation]

## 3. Voxel-Based Thinning in PDAL
Voxel-based thinning reduces point density by dividing space into a **3D grid of cubes** (*voxels*) and selecting **one representative point per voxel**.  
This method produces a **uniform density** pattern that is easy to control through voxel size. The most common PDAL implementation is `filters.voxelcenternearestneighbor`.

This filter:
1. Divides the input point cloud into voxels of fixed size (`cell`).
2. Calculates the center coordinate of each voxel.
3. Finds the **nearest point** to the voxel center.
4. Keeps that point (with all its attributes) and discards the rest from that voxel.

      Example
      ```json
      {
        "pipeline": [
          "input.las",
          {
            "type": "filters.voxelcenternearestneighbor",
            "cell": 1.0
          },
          "output.las"
        ]
      }

Pros:
* Produces uniform density across the cloud.
* Simple, predictable control through voxel size.
* Works consistently regardless of point ordering.

Cons:
* Can create an artificial “grid” pattern.
* Loses fine spatial detail if voxel size is too large.
* Not adaptive; same cell size used everywhere.

[https://pdal.io/en/stable/stages/filters.voxelcenternearestneighbor.html]

## Summary Table

| Method            | PDAL Filter(s)                             | Spatial? | Output Pattern     | Key Parameter   | Pros                                       | Cons                                      |
| ----------------- | ------------------------------------------ | -------- | ------------------ | --------------- | ------------------------------------------ | ----------------------------------------- |
| Poisson / Radius  | `filters.sample`                           | Yes      | Evenly spaced      | `radius`/`cell` | Preserves shape, good spatial distribution | Sensitive to point order in streaming     |
| Systematic Random | `filters.randomize` + `filters.decimation` | No       | Random in order    | `step`          | Fast, reduces bias                         | Can leave clusters/gaps                   |
| Voxel Grid        | `filters.voxelcenternearestneighbor`       | Yes      | Grid-based spacing | `cell`          | Uniform density, simple control            | Grid-like artifacts, detail loss in areas |



# Statistics of Point Cloud Thinning

This note summarizes the main statistical tools used to evaluate thinning of point cloud data.
We consider two aspects: **Vertical structure preservation** and **Horizontal spatial uniformity**.

---

## 1. Vertical Structure Preservation

Thinning should not distort the vertical distribution of points (canopy and understory).  
We evaluate this using:

### 1.1 Kernel Density Estimate (KDE)

**Definition:** KDE is a smooth estimate of a probability density function (PDF) from sampled data.  
Instead of just showing histograms of z-values, KDE gives a smooth curve of how points are distributed vertically.

**Formula (1D KDE):**

$$\[
\hat{f}(z) \=\ \frac{1}{nh} \sum_{i=1}^{n} K\left(\frac{z - z_i}{h}\right)
\]$$

- \(n\): number of points  
- \(h\): bandwidth (controls smoothness)  
- \(K\): kernel function (Gaussian)  
- $\(z_i\)$: observed heights  

**Application in thinning:**  
Take all point cloud heights (z) from original and thinned files, compute KDE curves, and plot them over z.  
This allows us to observe whether thinning preserved canopy and understory structure, or distorted the vertical distribution.

---

### 1.2 Empirical Cumulative Distribution Function (CDF)

**Definition:** CDF is the probability that a variable is less than or equal to some value.  
It shows the entire vertical distribution, not just density at each height.

**Formula:**

$$\[
\hat{F}(z) \=\ \frac{1}{n} \sum_{i=1}^n I(z_i \leq z)
\]$$

- $\(I\)$: indicator function (1 if true, 0 if false)  
- Steps up by \(1/n\) at each observation  

**Application in thinning:**  
Compute CDF for z-values in original and thinned point clouds. Overlay them.  
If curves overlap closely, the vertical distribution is preserved.

---

### 1.3 Kolmogorov–Smirnov (KS) Test

**Definition:** A test comparing two cumulative distributions.

**Statistic:**

<img width="159" height="61" alt="image" src="https://github.com/user-attachments/assets/a2b7b804-9a01-4474-b061-45a460c0bf20" />

- where supx is the supremum of the set of distances. Intuitively, the statistic takes the largest absolute difference between the two distribution functions across all x values
- $\(D\)$: maximum vertical gap between the two CDFs 
- **p-value:** probability of observing such a large difference under $\(H_0\)$

**Hypotheses:** 
- Null hypothesis (H₀): Original and thinned z-values come from the same vertical distribution.  
- Alternative (H₁): They differ.

**Interpretation:**  
- Small p-value (e.g. <0.05): reject H₀ → thinning altered vertical structure.  
- Large p-value: fail to reject H₀ → thinning preserved structure.

<img width="2979" height="780" alt="output" src="https://github.com/user-attachments/assets/449e03de-12eb-4a8a-a267-4df3f3988d39" />

---

## 2. Horizontal Spatial Uniformity

Thinning should not introduce excessive clumping or regularity in the XY plane.  
We evaluate this using voxel statistics.

### 2.1 Index of Dispersion (ID)

**Definition:** Ratio of variance to mean of voxel counts.

**Formula:**

$$\[
ID \=\ \frac{s^2}{\bar{c}}
\]$$

- \($s^2$\): variance of voxel counts  
- \($\bar{c}$\): mean voxel count  

**Interpretation:**  
- \$(ID \approx 1\)$: random uniform (Poisson-like)  
- \$(ID > 1\)$: clumping (over-dispersed)  
- \$(ID < 1\)$: regular spacing (under-dispersed)  

---

### 2.2 Chi-Square (χ²) Test

**Definition:** Statistical test on dispersion index.

**Formula:**

$$\[
\chi^2 \=\ (k-1) \cdot ID
\]$$

- \(k\): number of voxels  
- Degrees of freedom: \(k-1\)  

**Interpretation:**  
- High p-value: consistent with Poisson (uniform)  
- Low p-value: not Poisson-like  

---

### 2.3 XY Heatmaps

**Definition:** Visualize voxel counts collapsed onto XY plane.  
**Use:** Detect clustering, grid patterns, or empty regions that statistics alone may miss.

<img width="2710" height="780" alt="horizontal_sample" src="https://github.com/user-attachments/assets/fb2ae011-b739-4873-9811-24f98131431e" />

---

## Summary

- **Vertical preservation:** KDE, CDF, KS test → quantify and visualize changes in canopy/understory profiles.  
- **Horizontal uniformity:** ID, χ², XY heatmaps → quantify and visualize spatial randomness vs. regularity.  

Together, these methods provide a robust statistical and visual framework for comparing thinning strategies in point cloud analysis.

Example of plot:

<img width="1200" height="500" alt="ThreeMethods" src="https://github.com/user-attachments/assets/6d4104ae-acda-458a-80ef-150e723843b0" />

<img width="700" height="700" alt="KDE_CDF" src="https://github.com/user-attachments/assets/60913380-3a10-4110-bfa9-79346b704373" />

<img width="700" height="700" alt="ComparisionKS_ID" src="https://github.com/user-attachments/assets/60e26cac-ecf0-4c6c-8ec5-63b7fd343f7a" />

---

## References

- SciPy Gaussian KDE: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.gaussian_kde.html  
- SciPy KS test: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.ks_2samp.html  
- Variance-to-mean ratio (Index of Dispersion): https://en.wikipedia.org/wiki/Variance-to-mean_ratio  

































