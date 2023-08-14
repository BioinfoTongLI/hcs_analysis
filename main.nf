#!/usr/bin/env/ nextflow

nextflow.enable.dsl=2

params.masters = [
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_63X_3days__2023-07-28T14_53_45-Measurement 1_max/jm52_20230728_TGlowBencharmking_63X_3days.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3h__2023-07-28T16_16_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3h.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3days__2023-07-28T15_34_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3days.companion.ome', 12],
]
params.out_dir = '.'

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

plates = channel.from(params.masters).map{it->
    [['id': file(it[0]).name], file(it[0]).parent, file(it[0]).name, it[1]]
}

workflow  {
    hcs_plate_analysis(plates)
}