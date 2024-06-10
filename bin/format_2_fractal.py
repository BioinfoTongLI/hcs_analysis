#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2024 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from fractal_tasks_core.tasks.import_ome_zarr import import_ome_zarr
import json


def main(zarr:str, output_config: str, stem:str):
    img_list = import_ome_zarr(
        zarr_urls=[],
        zarr_dir="./",
        zarr_name=zarr,
        overwrite=True,
        add_image_ROI_table=True,
    )
    with open(output_config, "w") as f:
        json.dump(img_list, f)

    for i, img in enumerate(img_list["image_list_updates"]):
        with open(f"{stem}-{i}.json", "w") as f:
            json.dump({"zarr_url":img["zarr_url"]}, f)


if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : "0.0.1"
    }
    fire.Fire(options)