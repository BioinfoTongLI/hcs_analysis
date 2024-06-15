#!/usr/bin/env/ nextflow

process OMENGFF_TO_FRACTAL {
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
    ngff_2_fractal.py run \
        ${zarr} \
        -output_config ${original_fractal_cfg} \
        -stem ${meta.id} \
        ${args}
    """
}

process DROP_T_DIMENSION {
    cache true
    debug true

    container 'fractal_core_tasks:2.0'
    storeDir params.out_dir + "/t_dropped"

    cpus 1
    memory 2.GB

    input:
    tuple val(meta), path(argsjson), val(row), val(col), val(fov), path(zarr)

    output:
    tuple val(meta), path(out_cfg), val(row), val(col), val(fov), emit: fractal_config

    script:
    def args = task.ext.args ?: ''
    out_cfg = "${meta.id}_${row}_${col}_${fov}_t_dropped.json"
    """
    drop_t_dim_ome_zarr.py run \
        -argsjson ${argsjson} \
        -output_config ${out_cfg} \
        -overwrite False \
        ${args}
    """
}


process FRACTAL_CELLPOSE {
    cache true
    debug true

    maxForks 20

    container 'fractal_core_tasks:2.0'
    containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}"
    storeDir params.out_dir + "/cellpose_segmentation"

    input:
    tuple val(meta), path(argsjson), val(row), val(col), val(fov), path(zarr)

    output:
    tuple val(meta), path(out_cfg), val(row), val(col), val(fov), emit: fractal_config

    script:
    def args = task.ext.args ?: ''
    out_cfg = "${meta.id}_${row}_${col}_${fov}_cellpose_seg.json"
    """
    cellpose_ome_zarr.py run \
        -argsjson ${argsjson} \
        -output_config ${out_cfg} \
        -overwrite True \
        ${args}
    """
}


process FRACTAL_SCMULTIPLEX {
    cache true
    debug true

    container 'fractal_core_tasks:2.0'
    containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}"
    storeDir params.out_dir + "/feature_measurement"

    input:
    tuple val(meta), path(argsjson), val(row), val(col), val(fov), path(zarr)

    output:
    tuple val(meta), path(out_cfg), val(row), val(col), val(fov), emit: original_fractal_config

    script:
    def args = task.ext.args ?: ''
    out_cfg = "${meta.id}_${row}_${col}_${fov}_scMultipleX_meas.json"
    """
    fractal_scmultiplex_wrapper.py run \
        -argsjson ${argsjson} \
        -out_table_name scMultipleX_meas \
        -output_config ${out_cfg} \
        -overwrite True \
        ${args}
    """
}

workflow Fractal_run {
    take:
    zarrs

    main:
    OMENGFF_TO_FRACTAL(zarrs)
    to_remove_t = OMENGFF_TO_FRACTAL.out.for_downsteam_fractal_config
        .flatMap{ meta, list -> list.collect{
            values = it.baseName.split("-")
            row = values[1]
            col = values[2]
            fov = values[3]
            [meta, it, row, col, fov] }
        }
        .combine(zarrs, by:0)
    DROP_T_DIMENSION(to_remove_t) 
    FRACTAL_CELLPOSE(DROP_T_DIMENSION.out.fractal_config.combine(zarrs, by: 0))
    FRACTAL_SCMULTIPLEX(FRACTAL_CELLPOSE.out.fractal_config.combine(zarrs, by: 0))
}