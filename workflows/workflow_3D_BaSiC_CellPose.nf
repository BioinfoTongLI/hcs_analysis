#!/usr/bin/env/ nextflow

include { BASIC_CORRECTION_ZARR } from '../subworkflows/sanger/basic_correction_zarr/main'                                                                


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


workflow BaSiC_CellPose_3D {

    take:
    omezarrs

    main:
    BASIC_CORRECTION_ZARR(omezarrs)
    BASIC_CORRECTION_ZARR.out.corrected_ome_zarr.view()
    // CellPose_segmentation(
    //     BASIC_CORRECTION_ZARR.out.corrected_images,
    //     50,
    //     2 
    // )
    // for_feature_extract = Illumination_correction.out.corrected_images.combine(
    //     // CellPose_segmentation.out.segmentations,
    //     CellPose_segmentation.out.tif_masks,
    //     by:[0,1,2]
    // )
    // Skimage_feature_extract(for_feature_extract)
}