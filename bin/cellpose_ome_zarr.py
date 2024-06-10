#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2024 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from fractal_tasks_core.tasks.cellpose_segmentation import cellpose_segmentation
from fractal_tasks_core.channels import ChannelInputModel
import json


def main(argsjson:str, overwrite:bool, output_config:str, stem:str, **args):
    with open(argsjson) as f:
        data = json.load(f)

    print(data) 
    img_list = cellpose_segmentation(
        zarr_url=data['zarr_url'],
        overwrite=overwrite,
        level=0,
        channel=ChannelInputModel(label="PhenoVue Hoechst 33342"),
        input_ROI_table ="image_ROI_table"
    )
    print(img_list)

    with open(output_config, "w") as f:
        json.dump(img_list, f)

    for i, img in enumerate(img_list["image_list_updates"]):
        with open(f"{stem}_{i}.json", "w") as f:
            json.dump({"zarr_url":img["zarr_url"]}, f)
    

if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : "0.0.1"
    }
    fire.Fire(options)