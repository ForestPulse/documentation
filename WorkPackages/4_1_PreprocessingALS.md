## Background

Airborne Laser Scanning (ALS) data in ForestPulse come from multiple sources,
including state surveying authorities and the Federal Agency for Cartography
and Geodesy (BKG) via the Digital Twin Germany (DigiZ-DE) initiative.
These datasets vary in sensor type, acquisition date, flight parameters, and
strip configuration. This leads to heterogeneous point clouds, irregular overlap
areas, and strong variation in point density within and across flight paths.

Such inconsistencies make it difficult to build robust, standardized large-scale
processing workflows. Preprocessing is therefore a mandatory first step to
harmonize inputs and ensure comparability of derived forest structure products
across regions and data providers.

### Data Source and Pilot Region

The original project plan expected nationwide ALS data from BKG DigiZ-DE, with
deliveries starting in late 2024. Due to delays, we used openly available ALS
data from Thüringia as the pilot dataset. These data were downloaded from the
official Thüringia state geoportal and stored on the GWDG HPC infrastructure.

The Thüringia dataset comprised **16,945 tiles** of 1 km² each, with an average
point density of ~33 pts/m². It served as the primary testbed for developing,
validating, and benchmarking the full preprocessing workflow. 
https://github.com/ForestPulse/ForestStructure

The validated workflow is designed to be transferable to other German federal
states once DigiZ-DE data become available.

---

## Preprocessing

Preprocessing transforms raw, heterogeneous ALS tiles into a consistent,
analysis-ready point cloud dataset. It reduces data volume, removes noise,
standardizes point density and height reference, and ensures spatial alignment
with the FORCE (https://force-eo.readthedocs.io) Datacube grid used across all ForestPulse layers.

The full preprocessing chain runs on the **GWDG HPC** using SLURM batch jobs,
with tools including PDAL, R (`lasR`, `lidR`), and Bash.

### Preprocessing Steps

#### 1. Denoising and Outlier Removal

Raw ALS data often contain isolated noise points from atmosphere, water
surfaces, or sensor artifacts. These outliers are removed before any further
processing to prevent contamination of classification and normalization results.

**Tool:** PDAL (`filters.outlier`)

---
#### 2. Reprojection

The Thüringia ALS tiles are delivered in **UTM Zone 32N (EPSG:25832)**. The
FORCE Datacube used for ForestPulse is defined in **ETRS89 / LAEA Europe
(EPSG:3035)**. Reprojection is required to align the point cloud data with
the FORCE grid before metric extraction and raster generation.

No vertical datum transformation is needed. Both CRS are based on the ETRS89
reference framework, so a horizontal coordinate transformation is sufficient.

**Tool:** PDAL (`filters.reprojection`)

```bash
# Example PDAL reprojection stage
{
  "type": "filters.reprojection",
  "in_srs": "EPSG:25832",
  "out_srs": "EPSG:3035"
}
```

---
#### 3. Retiling

Because UTM and LAEA use different grid orientations, a point-level reprojection
alone produces tile boundaries that are oblique to the FORCE Datacube grid.
Retiling reorganizes reprojected points into new output tiles strictly aligned
with FORCE cube extents.

Reprojection and retiling are performed together in a single python script with PDAL pipeline to
avoid redundant read/write cycles.

> See `scripts/reproject_retile.sh` for the batch SLURM implementation.

---
#### 4. Ground Classification

Ground classification separates ground returns from vegetation, buildings, and
other above-ground objects. An accurate ground model is required for height
normalization in the next step.

We use the **Progressive Morphological Filter (PMF)** or **Cloth Simulation
Filter (CSF)** depending on terrain complexity.

**Tool:** PDAL (`filters.pmf`, `filters.csf`) or R `lidR::classify_ground()`

```r
# Example in lidR
las <- classify_ground(las, algorithm = csf())
```
#### 5. Point Thinning (Density Standardization)

ALS data from different acquisition campaigns often have varying point
densities. Thinning standardizes the density across the dataset to a target
value (e.g., 10 pts/m²), reducing processing load and ensuring that derived
metrics are comparable between tiles and regions.

**Tool:** PDAL (`filters.relaxationdartthrowing`, `filters.sample`) or

R `slidartools::thin_point_cloud_xyz` (https://github.com/nikoknapp/slidaRtools/blob/master/R/thin_point_cloud_xyz_function.R)

R `lidR::decimate_points()`

```r
# Homogeneous thinning to 10 pts/m²
las <- decimate_points(las, homogenize(10, res = 1))
```

---

#### 6. Height Normalization

Height normalization subtracts the ground surface elevation from each point,
converting ellipsoidal or orthometric heights to **height above ground (HAG)**.
This is a prerequisite for computing canopy height, crown metrics, and
vertical structure attributes.

**Tool:** PDAL (`filters.hag_delaunay`, `filters.hag_nn`, `filters.hag_dem`)

**Tool:** R `lidR::normalize_height()` or `lasR` pipelines

```r
las <- normalize_height(las, algorithm = tin())
```

---

#### 7. COPC Conversion

Final preprocessed tiles are written in **Cloud Optimized Point Cloud (COPC)**
format. COPC enables efficient spatial querying and streaming, which is
essential for large-scale catalog-based processing on the HPC.

**Tool:** PDAL (`writers.copc`)

---

### Preprocessing Workflow Summary

Raw ALS tiles (LAZ, EPSG:25832)
│
▼
Denoising / Outlier Removal
│
▼
Reprojection + Retiling (EPSG:25832 → EPSG:3035, FORCE grid)
│
▼
Ground Classification
│
▼
Point Thinning (density standardization)
│
▼
Height Normalization (HAG)
│
▼
COPC Conversion
│
▼
Analysis-ready tiles (COPC, EPSG:3035)


---

## Infrastructure

All preprocessing runs on the **GWDG HPC** cluster using the SLURM scheduler.
Tiles are processed in parallel using array jobs. Scripts are organized under
`scripts/preprocessing/`.

| Resource | Details |
|---|---|
| HPC system | GWDG (`medium96s` / `standard96` partitions) |
| Storage | Project account on `/scratch` |
| Parallelization | SLURM array jobs, one tile per task |
| Primary tools | PDAL, R (`lidR`, `lasR`), Bash |
| Input format | LAZ (EPSG:25832) |
| Output format | COPC (EPSG:3035) |

---
