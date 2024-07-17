#!/usr/bin/env/ nextflow

process hcs_plate_analysis {
    debug true
    cache true

    label "gpu_normal"

    container 'bioinfotongli/hcs_analysis:latest'
    containerOptions "${workflow.containerEngine == 'singularity' ? '-B /lustre,/nfs --nv':'-v /lustre:/lustre -v /nfs:/nfs --gpus all'}"
    publishDir params.out_dir, mode:"copy"

    input:
    tuple val(meta), path(root), val(companion), val(diameter_in_um)

    output:
    tuple val(meta), path("${meta['id']}/*_regionprops.csv"), emit: regionprops 
    tuple val(meta), path("${meta['id']}/*_mask.ome.tif"), emit: masks 

    script:
    def args = task.ext.args ?: ''
    """
    default_analysis.py \
        -root ${root} \
        -plate_name ${companion} \
        -out_dir ${meta['id']} \
        -diameter_in_um ${diameter_in_um} \
        ${args}
    """
}