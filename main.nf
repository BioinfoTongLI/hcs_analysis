#!/usr/bin/env/ nextflow

import groovy.json.JsonSlurper
import groovy.xml.XmlParser

include { BaSiC_CellPose_3D } from './workflows/workflow_3D_BaSiC_CellPose'
include { hcs_plate_analysis } from './workflows/workflow_2D_feature_extract'

params.masters = [
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_63X_3days__2023-07-28T14_53_45-Measurement 1_max/jm52_20230728_TGlowBencharmking_63X_3days.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3h__2023-07-28T16_16_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3h.companion.ome', 12],
    ['/nfs/team283_imaging/0HarmonyStitched/JM_TCA/jm52_20230728_TGlowBencharmking_40X_3days__2023-07-28T15_34_04-Measurement 1_max/jm52_20230728_TGlowBencharmking_40X_3days.companion.ome', 12],
]

params.zarrs = [
    [[:], "/nfs/t217_imaging/JM_TCA/playground_Tong/zarrs/jm52_KITTY_20230929_10h__2023-09-30T11_44_13-Measurement 2.zarr"],
    // "/lustre/scratch126/cellgen/team283/tl10/demo_datasets/minimal_HCS.zarr/",
    // "/lustre/scratch126/cellgen/team283/tl10/demo_datasets/minimal_WSI.zarr/",
    [[:], "/nfs/t233_imaging/NT_FAK/playground_Tong/fk7_3xHpSci_22-01-24_24srID__2024-01-30T10_21_49-Measurement 25_no_hcs.zarr"]
    // "/lustre/scratch126/cellgen/team283/tl10/demo_datasets//20200812-CardiomyocyteDifferentiation14-Cycle1.zarr"
    // "s3://idr/zarr/v0.4/idr0128E/9701.zarr"
]
params.out_dir = null


workflow tif_workflow {
    plates = channel.from(params.masters).map{it->
        [['id': file(it[0]).name], file(it[0]).parent, file(it[0]).name, it[1]]
    }
    hcs_plate_analysis(plates)
}


workflow {
    BaSiC_CellPose_3D(channel.from(params.zarrs))
}