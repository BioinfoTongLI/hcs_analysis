#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from aicsimageio import AICSImage
from ome_zarr.writer import write_image
from ome_zarr.io import parse_url
from ome_zarr.scale import Scaler
import zarr
from aicsimageio import types
from basicpy import BaSiC
import numpy as np
from glob import glob
from typing import List
import shutil
import json


def parse_md_for_omezarr_writer(config:dict):
    md = {
        "channel_names": [],
        "channel_colors": [],
        "physical_pixel_sizes": None,
        "image_name": config["multiscales"][0]["name"],
        "scale_num_levels": len(config["multiscales"][0]["datasets"]),
        "scale_factor": 2.0, 
        "dimension_order": "".join([d["name"].upper() for d in config['multiscales'][0]['axes']])
    }
    for c in config["omero"]["channels"]:
        md["channel_names"].append(c["label"])
        md["channel_colors"].append(c["color"])

    # print(config)
    # print(md["dimension_order"].find("Z"))

    md["physical_pixel_sizes"] = types.PhysicalPixelSizes(
        config["multiscales"][0]["datasets"][0]["coordinateTransformations"][0]['scale'][md["dimension_order"].find("Z")],
        config["multiscales"][0]["datasets"][0]["coordinateTransformations"][0]['scale'][md["dimension_order"].find("Y")],
        config["multiscales"][0]["datasets"][0]["coordinateTransformations"][0]['scale'][md["dimension_order"].find("X")],
    )
    ### omezarr writer doesn't take list of physical_pixel_sizes. Sending one the bottem level for now.
    ### https://github.com/AllenCellModeling/aicsimageio/blob/main/aicsimageio/writers/ome_zarr_writer.py#L263
    # for d in config["multiscales"][0]["datasets"]:
    #     md["physical_pixel_sizes"].append(
    #         types.PhysicalPixelSizes(
    #             Z=d["coordinateTransformations"][0]['scale'][md["dimension_order"].find("Z")],
    #             Y=d["coordinateTransformations"][0]['scale'][md["dimension_order"].find("Y")],
    #             X=d["coordinateTransformations"][0]['scale'][md["dimension_order"].find("X")])
    #     )
    print(md)
    return md



def main(field:str, basic_models:List[str], row:str, col:str):
    original_zattrs = f"{field}/.zattrs"
    with open(original_zattrs) as f:
        config = json.load(f)

    hyperstack = AICSImage(f"./{field}")
    corrected_stack = []
    for t in range(hyperstack.dims.T):
        for c in range(hyperstack.dims.C):
            img = hyperstack.get_image_dask_data("ZYX", T=t, C=c)
            basic = BaSiC.load_model(basic_models[c])
            transformed = basic.transform(img)
            corrected_stack.append(transformed)

    store = parse_url(f"./{row}/{col}/{field}", mode="w").store
    root_group = zarr.group(store=store)
    # root_group.attrs["omero"] = config["omero"]
    write_image(
        image=np.expand_dims(np.vstack(corrected_stack), 0),
        group=root_group,
        scaler=Scaler(),
        axes=[d["name"] for d in config['multiscales'][0]['axes']],
        # coordinate_transformations=config["multiscales"][0]["datasets"],
        # storage_options=chunks,
    )
    shutil.copy(original_zattrs, f"./{row}/{col}/{field}/.zattrs")


if __name__ == "__main__":
    fire.Fire(main)
