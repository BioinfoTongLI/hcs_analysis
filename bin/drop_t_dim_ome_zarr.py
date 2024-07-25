#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
"""

"""
import fire
from fractal_helper_tasks.drop_t_dimension import drop_t_dimension
from pathlib import Path
import json
import shutil

VERSION="0.0.1"
def main(argsjson:str, output_config:str, overwrite:bool, **args):
    with open(argsjson) as f:
        data = json.load(f)
        
    img_list = drop_t_dimension(
        zarr_url=data['zarr_url'],
        overwrite_input=overwrite,
        **args
    )
    
    shutil.copytree(
        data['zarr_url'] + '/tables',
        img_list["image_list_updates"][0]["zarr_url"] + '/tables',
        dirs_exist_ok=True)
    
    log = img_list["image_list_updates"][0]
    log["waterfall"] = [f"{Path(__file__).name}:{VERSION}"]

    with open(output_config, "w") as f:
        json.dump(log, f)
    

if __name__ == "__main__":
    options = {
        "run" : main,
        "version" : VERSION
    }
    fire.Fire(options)