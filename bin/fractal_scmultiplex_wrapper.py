#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
"""

"""
import fire
from scmultiplex.fractal.scmultiplex_feature_measurements import scmultiplex_feature_measurements
from fractal_tasks_core.channels import ChannelInputModel
from pathlib import Path
import json


VERSION="0.0.1"
def main(argsjson:str, overwrite:bool, out_table_name:str, output_config:str,
        chs_to_quantify:dict={"DAPI":"PhenoVue Hoechst 33342"}, **args):
    with open(argsjson) as f:
        data = json.load(f)

    channel_in = {k:ChannelInputModel(wavelength_id=v) for k,v in chs_to_quantify.items()}
    
    scmultiplex_feature_measurements(
        zarr_url=data["zarr_url"],
        label_image=data['label_image_folder'],
        output_table_name=out_table_name,
        input_ROI_table = "image_ROI_table",
        input_channels=channel_in,
        level=0,
    )
    data.update({"measurement_table": out_table_name})
    data["waterfall"].append(f"{Path(__file__).name}:{VERSION}")

    with open(output_config, "w") as f:
        json.dump(data, f)
    

if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : VERSION
    }
    fire.Fire(options)