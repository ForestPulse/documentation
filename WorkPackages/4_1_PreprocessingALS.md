# Point cloud thinning
### Goals
There are several goals of point cloud thinning:
+ Removal of point density heterogeneities, which are a result of the data collection (swath overlaps, scanning patterns)
+ Reduction of the data amount for more efficient processing, while keeping all the required structural information
+ Reduction of the point density for the public dataset with 10 points per m² (BKG)

### Random thinning
Points are subsetted randomly.

**Considerations:** 
+ Very simple
+ Preserves the vertical frequency distribution of points
+ No horizontal homogenization of point density
+ No target point density
+ Information loss in areas with low sampling density


### Grid-based thinning (xy)
A horizontal grid of a specific resolution (e.g. 1 m x 1 m) is overlayed on the point cloud. A given maximum target point density per area is provided. In all grid cells with more points than the target density, random points are removed until the target point density is reached.

**Considerations:** 
+ Homogenizes the point cloud horizontally
+ Has a specific target point density (per area)
+ Slightly alters the vertical frequency distribution of points
+ In open areas, single returns are predominant, while in vegetated areas, multiple returns are predominant. By keeping a fixed number of points per grid cell, more returns are being removed from the vegetated areas.

**Implementations:** 

Grid-based thinning is available in R via [slidartools::thin_point_cloud_xyz](https://github.com/nikoknapp/slidaRtools/blob/master/R/thin_point_cloud_xyz_function.R) with dim="xy".

### Voxel-based thinning (xyz)
A 3D grid of a specific resolution (e.g. 1 m x 1 m x 1 m) is overlayed on the point cloud. A given maximum target point density per volume is provided. In all voxels with more points than the target density, random points are removed until the target point density is reached.

**Considerations:**  
+ Homogenizes the point cloud horizontally
+ Homogenizes the point cloud vertically
+ Has a specific target point density (per volume)
+ Strongly alters the vertical frequency distribution of points
+ In upper canopy layers the point density is higher than in lower layers due to the occlusion of laser beams. By keeping a fixed number of points per voxel, more of the maybe redundant points in the upper layers are being removed, while the rarer points in the understory are kept.
+ These are desired properties for single tree detection, by making the overstory more efficient to process, due to less points, while not losing the understory
+ These are undesired properties for plant area density estimation using the MacArthur-Horn-method and any quantitative analysis of canopy layering

**Implementations:** 

Voxel-based thinning is available in R via [slidartools::thin_point_cloud_xyz](https://github.com/nikoknapp/slidaRtools/blob/master/R/thin_point_cloud_xyz_function.R) with dim="xyz".

### Pulse-based thinning

A horizontal grid of a specific resolution (e.g. 1 m x 1 m) is overlayed on the point cloud. A given maximum target pulse density per area is provided. Each return is assigned to a pulse via its gpstime attribute. In all grid cells with more first returns than the target density, random pulses, i.e. the first returns and all other returns belonging to the same pulses, are removed until the target pulse density is reached.

**Considerations:**  
+ Homogenizes the point cloud horizontally
+ Preserves the vertical frequency distribution of points
+ Has a specific target pulse density (per area)
+ In open areas, single returns are predominant, while in vegetated areas, multiple returns are predominant. By keeping a fixed number of pulses per grid cell with all their returns, this intrinsic structural heterogeneity is preserved.
+ These are desired properties for plant area density estimation using the MacArthur-Horn-method and any quantitative analysis of canopy layering
+ The method relies on a unique gpstime per pulse, which is not given in the case of single-photon-counting-lidar, hence not applicable to such data.

**Implementations:** 

Pulse-based thinning is available in R via the following function, which makes use of several lidR functions:
```R
# Function for thinning by pulse, i.e., it will assign each pulse 
# to a grid cell based on the xy-position of its first return and then
# it will randomly discard pulses (i.e., all returns of a pulse) until 
# a desired pulse density is reached
homogenize_pc_by_pulse <- function(las, density = 4, res= 1){
  require(lidR)
  # Package required for the pipe operator %>%
  require(magrittr)
  # If the input is not a LAS object, convert it to LAS
  if(!("LAS" %in% class(las))){
    las <- LAS(las)
  }
  # Give each pulse an ID
  las_pulse <- lidR::retrieve_pulses(las)
  # Thin out the first returns to the desired target density
  las_homogenized_pulses <- las_pulse %>%
    lidR::filter_first(.) %>%
    lidR::decimate_points(.,lidR::homogenize(density, res = res))
  # Subset only the points that belong to the selected pulses, based on pulse ID
  las_homogenized_points <- las_pulse %>%
    lidR::filter_poi(., pulseID %in% las_homogenized_pulses@data$pulseID)
  return(las_homogenized_points)
}
```


