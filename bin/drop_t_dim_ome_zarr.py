#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2024 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from fractal_helper_tasks.drop_t_dimension import drop_t_dimension
from pathlib import Path
import json


def main(argsjson:str, overwrite:bool, output_config:str, json_stem:str, suffix:str, **args):
    with open(argsjson) as f:
        data = json.load(f)
        
    img_list = drop_t_dimension(zarr_url=data['zarr_url'], overwrite_input=overwrite, suffix=suffix)
    # print(img_list)

    with open(output_config, "w") as f:
        json.dump(img_list, f)

    with open(f"{json_stem}.json", "w") as f:
        json.dump({"zarr_url":img_list["image_list_updates"][0]["zarr_url"]}, f)
    

if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : "0.0.1"
    }
    fire.Fire(options)