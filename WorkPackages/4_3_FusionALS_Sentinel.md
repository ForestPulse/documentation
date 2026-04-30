## Background
Work Package 4.3 addresses the temporal gap between ALS acquisition campaigns by fusing ALS-derived forest structure metrics with Sentinel-2 time series data.
Since ALS surveys are conducted infrequently, Sentinel-2 provides dense phenological and spectral observations that can be used to predict and update forest 
structural attributes between acquisitions, ensuring temporal consistency across the monitoring period. 

Machine learning and AI models are trained using ALS metrics as response variables and Sentinel-2 spectral indices (e.g., NDVI, EVI, red-edge bands) as 
predictors, anchored through weighted regression to maintain physical consistency with the LiDAR-derived reference data. Models are validated against 
BWI (Bundeswaldinventur) field plot data to ensure that predicted structural attributes remain accurate and transferable across forest types and conditions.
