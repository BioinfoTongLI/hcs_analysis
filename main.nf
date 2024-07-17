#!/usr/bin/env/ nextflow

include { BaSiC_CellPose_3D } from './workflows/workflow_3D_BaSiC_CellPose'
include { hcs_plate_analysis } from './workflows/workflow_2D_feature_extract'
include { Fractal_run } from './workflows/workflow_fractal'

params.masters = [
    ['ome_zarr', 'cell_size_in_pixel'],
]

params.zarrs = [
    [["id":"ID"], "path-to-ome-zarr"],
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

workflow call_peaks { 
    Spotiflow_run(channel.from(params.zarrs))
}

workflow FRACTAL {
    Fractal_run(channel.from(params.zarrs))
}