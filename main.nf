#!/usr/bin/env/ nextflow

nextflow.enable.dsl=2

params.masters = [
    '/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_63X_3days__2023-07-28T14_53_45-Measurement 1_max/jm52_20230728_TGlowBencharmking_63X_3days.companion.ome',
    '/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3h__2023-07-28T16_16_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3h.companion.ome',
    '/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3days__2023-07-28T15_34_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3days.companion.ome',
]
params.out_dir = '.'

process hcs_plate_analysis {
    debug true
    cache true

    maxForks 1

    container 'bioinfotongli/hcs_analysis:latest'
    containerOptions "${workflow.containerEngine == 'singularity' ? '-B /lustre,/nfs --nv':'-v /lustre:/lustre -v /nfs:/nfs --gpus all'}"
    publishDir params.out_dir, mode:"copy"

    input:
    tuple val(meta), path(root), val(companion)

    output:
    tuple val(meta), path(out), emit: quantifications 

    script:
    out = "${meta['id']}_quantifications.csv"
    def args = task.ext.args ?: ''
    """
    default_analysis.py \
        -root ${root} \
        -plate_name ${companion} \
        -out ${out} \
        ${args}
    """
}

plates = channel.from(params.masters).map{it->
    [['id': file(it).name], file(it).parent, file(it).name]
}

workflow  {
    hcs_plate_analysis(plates)
}