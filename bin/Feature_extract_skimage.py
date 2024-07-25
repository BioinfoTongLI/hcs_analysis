#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
"""

"""
import fire
from aicsimageio import AICSImage
from skimage.measure import regionprops_table
import numpy as np
import pandas as pd
import tifffile as tf
import os


def main(raw:str, seg:str, row:str, col:str, out_dir:str, diam:int=50, model:str="cyto2"):
    raw_obj = AICSImage(f"./{raw}")
    if seg.endswith(".tif"):
        seg_obj = AICSImage(f"./{seg}")
    else:
        seg_obj = AICSImage(f"./{seg}/cellpose_segmentation_diam_{diam}_model_{model}")
    series_list = []
    for t in range(raw_obj.dims.T):
        img = raw_obj.get_image_dask_data("ZYXC", T=t)
        seg = seg_obj.get_image_dask_data("ZYX", T=t, C=0)
        props = regionprops_table(
            seg.compute(), intensity_image=img.compute(),
            properties=[
                "label",
                "area",
                # "eccentricity", # not for 3d
                # "orientation", # not for 3d
                # "perimeter", # not for 3d

                # "feret_diameter_max", # this one may not been inplemented in cucim
                "equivalent_diameter_area",
                "extent",
                "intensity_max",
                "intensity_mean",
                "intensity_min",
                "solidity"
            ]
        )
        df = pd.DataFrame(props)
        df["T"] = t
        df.set_index("label", inplace=True)
        series_list.append(df)
    series_df = pd.concat(series_list)
    os.makedirs(out_dir)
    series_df.to_csv(f"{out_dir}/measurements.csv")
    

if __name__ == "__main__":
    fire.Fire(main)
