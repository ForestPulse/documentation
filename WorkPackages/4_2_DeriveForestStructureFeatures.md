## Background

For the ForestPulse project, HAWK's contribution in Work Package 4.2 focused on establishing the methodological basis for area-based derivation of forest structure attributes using the preprocessed ALS data from Work Package 4.1. The ALS data were harmonized, reprojected to EPSG:3035, and retiled into 1 km × 1 km subtiles. Each subtile fits perfectly within a FORCE cube tile (30 km × 30 km), requiring exactly 900 subtiles to cover each FORCE cube domain.

Working at the FORCE cube level as a unit base enables precise spatial alignment with Sentinel-2 optical imagery within the FORCE framework. This 30 km × 30 km Sentinel-2 data can be used for modeling alongside LiDAR-derived data. Between LiDAR acquisition dates, Sentinel-2 (with its 2–3-day temporal resolution) can serve as an alternative data source for continuous forest monitoring. Sentinel-2 has a 10 m pixel spatial resolution, giving each FORCE cube 3000 × 3000 pixels. To achieve pixel-level coincidence between LiDAR and Sentinel-2, forest metrics are computed from the LiDAR data at 10 m resolution.

In ForestPulse, the following forest structure metrics are computed nationwide:

| Metric | German Term |
|---|---|
| Canopy cover | Überschirmungsgrad |
| Top height | Bestandesoberhöhe |
| Vertical structure / layering | Bestandesschichtung |
| Growing stock volume | Bestandesvorrat |
| Biomass | Biomasse |

---

## Forest Metrics

## 1. Canopy Cover (Überschirmungsgrad)

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

Where $p_i$ is the proportion of returns in height bin $i$, and $n$ is the total number of height bins (e.g. 1 m layers).

- **VCI = 1**: returns evenly distributed across all layers (multi-layered canopy)
- **VCI = 0**: returns concentrated in a single layer (uniform, single-storey stand)

VCI captures the 3D structural diversity of the forest. High VCI indicates multi-layered canopies with understory, midstory, and overstory all present. It is commonly used alongside metrics such as FHD, VDR, and canopy cover to characterize habitat structural complexity.

---

### 4. Growing Stock Volume (Bestandesvorrat)

Growing stock volume estimates total tree volume in m³/ha.

**Inputs:** ALS-derived metrics (e.g. height percentiles, point density)  
**Reference data:** BWI (Bundeswaldinventur) field plots  
**Modelling approach:** Parametric regression (linear or multiple regression) using BWI plots as calibration data.

---

### 5. Above-Ground Biomass (Biomasse)

The biomass model (`biomass_model`) is an area-based regression model estimating forest above-ground biomass (AGB, Mg/ha) from LiDAR metrics. A general linear form is: (example, not yet determined)

$$AGB = A + B \cdot p95 + C \cdot \text{mean} + D \cdot \text{std}$$

Coefficients A, B, C, D are derived from calibration against field reference data (default: B = 1, others = 0).

This follows the **Area-Based Approach (ABA)** in LiDAR forestry: statistical metrics are derived over an area (plot or raster cell) and regressed against forest inventory variables. This approach is operationally established — for example:

- **Norway**: nationwide ALS data combined with NFI plots; achieves ~10–15% volume error at stand level
- **Canada and Finland**: ALS-based biomass integrated into national inventory updates

LiDAR metrics such as p95, mean height, and canopy density are well-established predictors of AGB, with calibrated models typically achieving R² values of 0.7–0.9.

---

## References

- Jennings, S.B., Brown, N.D., Sheil, D. (1999). Assessing forest canopies and understorey illumination: canopy closure, canopy cover and other measures. *Forestry*, 72(1), 59–74.
- van Laar, A., Akça, A. (2007). *Forest Mensuration*. Springer, Dordrecht.
