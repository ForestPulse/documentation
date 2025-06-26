# Documentation
This repository is currently meant to store guides and relevant information for the ForestPulse project. It should store guides on how the project architecture was set up(along with guides for recurrent processes and issues); and descriptions on its various work packages/services, describing the relevant definitions that were taken into consideration, steps taken on their processes, and how are they meant to be executed.

Guides and Files found here will be used as the base for external documentation in a later step.

### Proposed Document Structure

1. Introduction (this page)
2. [Usage Policy](UsagePolicy.md)
3. [Architecture Description](Architecture/SetupNotes.md)
    1. [Working with VM Volumes](Architecture/VolumeCheatsheet.md)
    2. [Installing Nextflow on Nodes](Architecture/InstallingNextflow.md)
4. Work Packages
    1. Passive Earth Observation Data
        1. [Data Cube](WorkPackages/3_1_DataCube.md)
        2. [Forest Areas](WorkPackages/3_2_ForestAreas.md)
        3. [Tree Species](WorkPackages/3_3_TreeSpecies.md)
        4. [Disturbances](WorkPackages/3_4_Disturbances.md)
        5. [Vitality](WorkPackages/3_5_Vitality.md)
    2. Active Aerial Survey Data
        1. [Preprocessing of ALS](WorkPackages/4_1_PreprocessingALS.md)
        2. [Area based derivation of Forest Structure Features](WorkPackages/4_2_DeriveForestStructureFeatures.md)
        3. [Fusion of ALS + Sentinel 2](WorkPackages/4_3_FusionALS_Sentinel.md)
        4. [ALS Data Analysis](WorkPackages/4_4_ALSDataAnalysis.md)




Here is a link to the tree species unmixing GitHub Page: 
https://github.com/davidklehr/tree-species-unmixing
