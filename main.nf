#!/usr/bin/env/ nextflow


params.masters = [
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_63X_3days__2023-07-28T14_53_45-Measurement 1_max/jm52_20230728_TGlowBencharmking_63X_3days.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3h__2023-07-28T16_16_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3h.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3days__2023-07-28T15_34_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3days.companion.ome', 12],
]

params.zarr = "/nfs/t217_imaging/JM_TCA/playground_Tong/zarrs/jm52_KITTY_20230929_10h__2023-09-30T11_44_13-Measurement 2.zarr"
params.channels = 0..4
params.positions = 0..8

params.out_dir = null

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


process BaSiC_model_fitting {
    debug true

    memory 70.GB

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/hcs_analysis:latest':
        'bioinfotongli/hcs_analysis:latest'}"
    // containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}" // GPU memory is not enough to load all tiles at once
    storeDir params.out_dir + "/BaSiC_models/"

    input:
    path(zarr_root)
    tuple val(C), val(P)

    output:
    tuple val(P), path("BaSiC_model_C${C}_P${P}_T0"), emit: basic_models 

    script:
    def args = task.ext.args ?: ''
    """
    BaSiC_fitting.py \
        -zarr ${zarr_root} \
        -C ${C} \
        -P ${P} \
        ${args}
    """
}


process Illumination_correction {
    debug true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/hcs_analysis:latest':
        'bioinfotongli/hcs_analysis:latest'}"
    storeDir params.out_dir + "/corrected/"

    input:
    tuple val(P), val(row), val(col), path(F), path(models)

    output:
    tuple val(P), val(row), val(col), path("${row}/${col}/${F}"), emit: corrected_images

    script:
    def args = task.ext.args ?: ''
    def models = models.join(',')
    """
    BaSiC_transforming.py \
        -field "${F}" \
        -row ${row} \
        -col ${col} \
        -basic_models ${models} \
        ${args}
    """
}

process CellPose_segmentation {
    debug true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/hcs_analysis:latest':
        'bioinfotongli/hcs_analysis:latest'}"
    containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}"
    storeDir params.out_dir + "/segmentations/"

    input:
    tuple val(P), val(row), val(col), path(F)
    val(diam)
    val(C)

    output:
    tuple val(P), val(row), val(col), path("${cellseg_dir}/labels/cellpose_segmentation_diam_${diam}_model_cyto2"), emit: segmentations
    tuple val(P), val(row), val(col), path("${cellseg_dir}/labels/cellpose_segmentation_diam_${diam}_model_cyto2.tif"), emit: tif_masks

    script:
    def args = task.ext.args ?: ''
    cellseg_dir = "${row}/${col}/${P}"
    """
    CellPose_predict.py \
        -field "${F}" \
        -row ${row} \
        -col ${col} \
        -C ${C} \
        -diameter ${diam} \
        -out_dir ${cellseg_dir} \
        ${args}
    """
}


process Skimage_feature_extract {
    debug true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/hcs_analysis:latest':
        'bioinfotongli/hcs_analysis:latest'}"
    containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}"
    storeDir params.out_dir + "/Features/"

    input:
    tuple val(P), val(row), val(col), path(raw), path(seg)

    output:
    tuple val(P), val(row), val(col), path("${measurement_dir}/measurements.csv"), emit: measurements

    script:
    def args = task.ext.args ?: ''
    measurement_dir = "${row}/${col}/${P}/labels/"
    """
    Feature_extract_skimage.py \
        -row ${row} \
        -col ${col} \
        -raw ${raw} \
        -seg ${seg} \
        -out_dir ${measurement_dir} \
        ${args}
    """
}

plates = channel.from(params.masters).map{it->
    [['id': file(it[0]).name], file(it[0]).parent, file(it[0]).name, it[1]]
}

workflow tif_workflow {
    hcs_plate_analysis(plates)
}

workflow  {
    // The models are fitted for each channel, Z and field in the well.
    // Typically for each channel the models expect an array of shape (xxx, Z, Y, X)
    BaSiC_model_fitting(
        params.zarr,
        channel.from(params.channels).combine(channel.from(params.positions))
    )
    basic_models = BaSiC_model_fitting.out.basic_models.groupTuple().map{ it ->
        [it[0].toInteger(), it[1].sort()] // group basic models by field. e.g. [field_id, [model1, model2, ...]]
    }
    
    fields = channel.fromPath("${params.zarr}/*/*/*", type: 'dir').map{ it ->
        String f = it.baseName
        String col = it.parent.baseName
        String row = it.parent.parent.baseName
        [f.toInteger(), row, col, file(it)] // field_id, field_path
    }
    to_correct = fields.combine(basic_models, by: 0) // join fields channel and basic_model channel models by field_id

    Illumination_correction(to_correct)

    CellPose_segmentation(
        Illumination_correction.out.corrected_images,
        50,
        2 
    )
    for_feature_extract = Illumination_correction.out.corrected_images.combine(
        // CellPose_segmentation.out.segmentations,
        CellPose_segmentation.out.tif_masks,
        by:[0,1,2]
    )
    Skimage_feature_extract(for_feature_extract)
}