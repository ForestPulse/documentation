## Background

For the ForestPulse project, Work Package 4.2 focused on establishing the methodological basis for area-based derivation of forest structure attributes using the preprocessed ALS data from Work Package 4.1. The ALS data were harmonized, reprojected to EPSG:3035, and retiled into 1 km × 1 km subtiles. Each subtile fits perfectly within a FORCE cube tile (30 km × 30 km), requiring exactly 900 subtiles to cover each FORCE cube domain.

Working at the FORCE cube level as a unit base enables precise spatial alignment with Sentinel-2 optical imagery within the FORCE framework. This 30 km × 30 km Sentinel-2 data can be used for modeling alongside LiDAR-derived data. Between LiDAR acquisition dates, Sentinel-2 (with its 2–3-day temporal resolution) can serve as an alternative data source for continuous forest monitoring. Sentinel-2 has a 10 m pixel spatial resolution, giving each FORCE cube 3000 × 3000 pixels. To achieve pixel-level coincidence between LiDAR and Sentinel-2, forest metrics are computed from the LiDAR data at 10 m resolution.

In ForestPulse, the following forest structure metrics are computed nationwide:

| Metric | German Term | Unit |
|---|---|---|
| Canopy cover | Überschirmungsgrad | $\%$ |
| Top height | Bestandesoberhöhe | $m$ |
| Vertical structure / layering | Bestandesschichtung | (no unit) |
| Growing stock volume | Bestandesvorrat | $m^3$ / $ha$ |
| Biomass | Biomasse | $t$ / $ha$ |
| Basal Area | Grundfläche | $m^2$ / $ha$ |

---

## Forest Metrics

### 1. Canopy Cover (Überschirmungsgrad)

Canopy cover (CC, also crown closure) is defined as the percentage of ground
covered by individual tree crowns, measured as the vertical projection onto a
horizontal plane (van Laar and Akça, 2007).

CC derived from LiDAR is the fraction of returns that intersect the canopy.
In the [processing script](https://github.com/ForestPulse/ForestStructure/blob/main/metrics_R/forestMetrics_subtile.R),
CC is implemented as the proportion of points with height ≥ 2.0 m, a threshold
that distinguishes tree vegetation from ground returns or low shrubs (Jennings et al., 1999).

CC is formally expressed as:

$$CC = \frac{1}{N} \sum_{i=1}^{N} \mathbf{1}(h_i \geq 2.0)$$

Where:
- $N$ = total number of LiDAR returns within the pixel (10 m × 10 m cell)
- $h_i$ = height of the $i$-th return above ground
- $\mathbf{1}(h_i \geq 2.0)$ = indicator function equal to 1 if return height meets the canopy threshold, 0 otherwise

| CC value | Interpretation |
|----------|---------------|
| Close to 1.0 | Closed canopy, little open ground |
| Close to 0.0 | Open forest or canopy gaps |

This ratio method is an accepted proxy for the Beer–Lambert law approach to
canopy transmittance: it measures the probability that a LiDAR pulse is
intercepted by vegetation above 2 m. CC is a key structural attribute
influencing understory light availability, microclimate, wildlife habitat,
and the stocking density.

---

### 2. Top Height (Bestandesoberhöhe)

In operational forestry, top height is defined as the mean height of the tallest trees, typically the 100 largest-diameter trees per hectare.

The **95th-percentile height (p95)** is a robust, reproducible estimator of upper canopy height from LiDAR data. Using a high percentile rather than the absolute maximum captures the general top-of-canopy level while filtering out outlier points (e.g. bird strikes or noise spikes).

LiDAR-derived p95 correlates strongly with stand height, timber volume, and above-ground biomass. Research has shown that LiDAR-based top height can predict field-measured dominant height with only a few percent error.

---

### 3. Vertical Structure / Layering (Bestandesschichtung)

The **Vertical Complexity Index (VCI)** quantifies the evenness of LiDAR point distribution across vertical canopy layers. It is computed as the normalized Shannon–Wiener entropy of the height distribution:

$$VCI = \frac{-\sum_{i=1}^{n} p_i \ln(p_i)}{\ln(n)}$$

Where $p_i$ is the proportion of returns in height bin $i$, and $n$ is the total number of height bins. In this case, 60 height bins of size 1 m were used. 

- **VCI = 1**: returns evenly distributed across all layers (multi-layered canopy)
- **VCI = 0**: returns concentrated in a single layer (uniform, single-storey stand)

VCI captures the 3D structural diversity of the forest. High VCI indicates multi-layered canopies with understory, midstory, and overstory all present. It is commonly used alongside metrics such as FHD, VDR, and canopy cover to characterize habitat structural complexity.

---

### 4. Growing Stock Volume (Bestandesvorrat)

Growing stock volume (GSV) is defined as the total above-ground stem volume of living trees per unit land area (m³/ha). 

At tree level, stem volume is estimated from DBH and height using allometric taper equations. 

**LiDAR-based estimation:** GSV is estimated using the Area-Based Approach (ABA).  ALS-derived height metrics, as well as a wood density value which is derived from the species composition, serve as predictors in a parametric regression:

$$GSV = a \cdot \bar{h} ^b \cdot \rho^c$$

where:
- $\bar{h}$ = mean height of Canopy height Model (m)
- $\rho$ = dry wood density of tree species
- $a, b, c$ = regression coefficients 

Using data of the German National Forest Inventory (BWI, Bundeswaldinventur), the model coefficients were calibrated to these values:

$$a = 3.4838, \ \ b = 1.3921, \ \ c = -0.76431$$

---

### 5. Above-Ground Biomass (Biomasse)

Above-Ground Biomass was calculated similarly to GSV, fitting a power law model from LiDAR metrics to BWI data. This formula:

$$AGB = a \cdot \bar{h} ^b \cdot \rho^c$$

where:
- $\bar{h}$ = mean height of Canopy height Model (m)
- $\rho$ = dry wood density of tree species
- $a, b, c$ = regression coefficients 

was fitted to the following parameter values:

$$ a = 4.988, \ \ b = 1.343, \ \ c = 0.3047$$

---

### 5. Basal Area (Grundfläche)

Basal area (BA) is defined as the cross-sectional area of a tree stem at breast height (1.3 m above ground). At stand level, it is expressed as the sum of all stem cross-sectional areas per unit land area (m²/ha). It is a widely used measure of stand density and stocking, closely related to timber volume and productivity.

BA for a single tree is calculated from its diameter at breast height (DBH):

$$BA_{tree} = \pi \times \left(\frac{DBH}{2}\right)^2$$

Stand-level basal area is then:

$$BA_{stand} = \frac{\sum_{i=1}^{n} BA_{i}}{A}$$

Where:
- $DBH$ = diameter at breast height (m)
- $n$ = number of trees in the sampled area
- $BA_{i} = BA_{tree} for the i-th tree
- $A$ = plot or pixel area (ha)

**LiDAR-based estimation:** BA is estimated using the Area-Based Approach (ABA). A parametric regression model links ALS-derived height and density metrics to field-measured BA from BWI reference plots:

$$BA = a \cdot \bar{h}^b \cdot \rho^c$$

where:
- $\bar{h}$ = mean height of Canopy height Model (m)
- $\rho$ = dry wood density of tree species
- $a, b, c$ = regression coefficients 

The coefficients were fitted to the following values:

$$a = 2.1713, / / b = 0.75521, / / c = -0.71128$$

---

## References

- Jennings, S.B., Brown, N.D., Sheil, D. (1999). Assessing forest canopies and understorey illumination: canopy closure, canopy cover and other measures. *Forestry*, 72(1), 59–74.
- van Laar, A., Akça, A. (2007). *Forest Mensuration*. Springer, Dordrecht.
