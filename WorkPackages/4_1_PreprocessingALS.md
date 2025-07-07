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


### Pulse-based thinning

A horizontal grid of a specific resolution (e.g. 1 m x 1 m) is overlayed on the point cloud. A given maximum target pulse density per area is provided. Each return is assigned to a pulse via its gpstime attribute. In all grid cells with more first returns than the target density, random pulses, i.e. the first returns and all other returns belonging to the same pulses, are removed until the target pulse density is reached.

**Considerations:**  
+ Homogenizes the point cloud horizontally
+ Preserves the vertical frequency distribution of points
+ Has a specific target pulse density (per area)
+ In open areas, single returns are predominant, while in vegetated areas, multiple returns are predominant. By keeping a fixed number of pulses per grid cell with all their returns, this intrinsic structural heterogeneity is preserved.
+ These are desired properties for plant area density estimation using the MacArthur-Horn-method and any quantitative analysis of canopy layering
+ The method relies on a unique gpstime per pulse, which is not given in the case of single-photon-counting-lidar, hence not applicable to such data.









