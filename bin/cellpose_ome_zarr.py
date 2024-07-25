#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
"""

"""
import fire
from fractal_tasks_core.tasks.cellpose_segmentation import cellpose_segmentation
from fractal_tasks_core.channels import ChannelInputModel
import json
from pathlib import Path


VERSION="0.0.1"
def main(argsjson:str, overwrite:bool, output_config:str,
        target_ch_name="PhenoVue Hoechst 33342", **args):
    with open(argsjson) as f:
        data = json.load(f)

    cellpose_segmentation(
        zarr_url=data['zarr_url'],
        overwrite=overwrite,
        level=0,
        channel=ChannelInputModel(
            wavelength_id=target_ch_name), # one can only either wavelength_id or label
        input_ROI_table ="image_ROI_table",
        model_type="cyto2",
        anisotropy=2, # this has to be set to approxinately to the anisotropy of the image
        **args
    )
    data.update({"label_image_folder": f"label_{target_ch_name}"})
    data["waterfall"].append(f"{Path(__file__).name}:{VERSION}")

    with open(output_config, "w") as f:
        json.dump(data, f)
    

if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : VERSION
    }
    fire.Fire(options)