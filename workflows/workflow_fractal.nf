#!/usr/bin/env/ nextflow

process reformat_to_fractal {
    cache true

    container 'fractal_core_tasks:2.0'
    storeDir params.out_dir + "/reforamtted"

    input:
    tuple val(meta), path(zarr)

    output:
    tuple val(meta), path("${meta.id}-*.json"), emit: for_downsteam_fractal_config
    tuple val(meta), path(original_fractal_cfg), emit: original_fractal_config

    script:
    def args = task.ext.args ?: ''
    original_fractal_cfg = "${meta.id}_original_fractal.json"
    downsteam_stem = ""
    """
    format_2_fractal.py run \
        ${zarr} \
        -output_config ${original_fractal_cfg} \
        -stem ${meta.id} \
        ${args}
    """
}

process Remove_t_dimension {
    cache true
    debug true

    container 'fractal_core_tasks:2.0'
    storeDir params.out_dir + "/t_dropped"

    cpus 1

    input:
    tuple val(meta), path(argsjson), path(zarr)

    output:
    tuple val(meta), path("${stem}.json"), emit: fractal_config
    tuple val(meta), path(origianl_cfg), emit: original_fractal_config

    script:
    def args = task.ext.args ?: ''
    suffix = "_t_dropped"
    stem = file(argsjson).baseName + suffix
    origianl_cfg = "${meta.id}_original_${suffix}.json"
    """
    drop_t_dim_ome_zarr.py run \
        -zarr_url ${zarr} \
        -argsjson ${argsjson} \
        -overwrite False \
        -output_config ${origianl_cfg} \
        -json_stem ${stem} \
        -suffix ${suffix} \
        ${args}
    """
}


process FRACTAL_CELLPOSE {
    cache true
    debug true

    container 'fractal_core_tasks:2.0'
    storeDir params.out_dir + "/cellpose_segmentation"

    input:
    tuple val(meta), path(argsjson), path(zarr)

    output:
    tuple val(meta), path("${stem}*.json"), emit: fractal_config

    script:
    def args = task.ext.args ?: ''
    stem = "${meta.id}_t_dropped"
    for_downsteam_cfg = "${meta.id}_for_downstream_img_list.json"
    """
    cellpose_ome_zarr.py run \
        -zarr_url ${zarr} \
        -argsjson ${argsjson} \
        -overwrite True \
        -output_config ${stem}_original.json \
        -stem ${stem} \
        ${args}
    """
}


workflow Fractal_run {
    take:
    zarrs

    main:
    reformat_to_fractal(zarrs)
    to_remove_t = reformat_to_fractal.out.for_downsteam_fractal_config
        .flatMap{ meta, list -> list.collect{ [meta, it] } }
        .combine(zarrs, by:0)
    Remove_t_dimension(to_remove_t.first()) 
    FRACTAL_CELLPOSE(
        Remove_t_dimension.out.fractal_config.combine(zarrs, by: 0)
    )
}