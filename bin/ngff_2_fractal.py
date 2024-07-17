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
from pathlib import Path


def main(zarr:str, output_config: str, stem:str, overwrite:bool=True, **args):
    img_list = import_ome_zarr(
        zarr_urls=[],
        zarr_dir="./",
        zarr_name=zarr,
        overwrite=overwrite,
        add_image_ROI_table=True,
        **args
    )
    with open(output_config, "w") as f:
        json.dump(img_list, f)

    for i, img_md in enumerate(img_list["image_list_updates"]):
        field = Path(img_md["zarr_url"]).stem
        col = Path(img_md["zarr_url"]).parent.stem
        row = Path(img_md["zarr_url"]).parent.parent.stem
        img_md["attributes"]["field"] = field
        with open(f"{stem}-{str(row)}-{str(col)}-{str(field)}.json", "w") as f:
            json.dump(img_md, f)


if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : "0.0.1"
    }
    fire.Fire(options)