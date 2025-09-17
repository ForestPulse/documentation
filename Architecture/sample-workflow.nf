#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Can be placed in a config file
params.datacube = 'path/to/datacube'
params.training_points = 'path/to/trainingpoints'
params.year = 2020

workflow {
    files = Channel.of('path/to/files')
    results = tree_species_unmixing(input_files: files)
    results.final_output.view() //a list of files
}

workflow tree_species_unmixing {
    take:
    input_files

    main:
    models = extract_samples(input_files)
    | synth_library
    | train_ANN

    species_predictions = mapping(models.out, params.datacube)

    emit:
    final_output = species_predictions.out
}

process extract_samples {
    label 'tree-species'
    
    input:
    path files

    output:
    path "${working_dir}/*"

    script:
    """
    1_extract_pure.py \
        --dc_folder ${params.datacube} \
        --training_points ${params.training_points} \
        --year ${params.year} \
        --working_directory ${files}
    """
}