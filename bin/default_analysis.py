#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 Tong LI <tongli.bioinfo@proton.me>
"""

"""
from typing import List, Tuple
import fire
from aicsimageio import AICSImage
from ome_types import from_xml
from dask.distributed import Client
import dask
import pandas as pd
import numpy as np
import gc

from cellpose import models, core
GPU_READY = core.use_gpu()

try:
    import cupy as xp
    if xp.cuda.is_available():
        import cucim.skimage as skimage
        print("Using skimage in cucim")
except ImportError:
    print("Using skimage")
    import skimage
    import numpy as xp


@dask.delayed
def process_one_well(img_path: str, model: models.CellposeModel,
                     nuclei_channel_name: str = "PhenoVue Hoechst 33342",
                     channels: List[List[int]] = [[0, 0]], diameter: int = 40
                     ) -> pd.DataFrame:
    """
    Processes a single well image using a given model.

    Args:
        img_path (str): Path to the well image.
        model (keras.Model): Trained Keras model to use for prediction.
        nuclei_channel_name (str): Name of the channel containing nuclei. Default is "PhenoVue Hoechst 33342".
        channels (list): List of channel indices to use for prediction. Default is [[0, 0]].
        diameter (int): Diameter of the nuclei in pixels. Default is 40.

    Returns:
        tuple: A tuple containing the predicted mask and the original image.
    """
    img = AICSImage(img_path)
    # spacing = float(img.get_xarray_dask_stack().coords["Y"][1])
    stack = img.get_xarray_dask_stack().squeeze()
    nuc_img = stack.sel(C=nuclei_channel_name)
    masks, _, _, _ = model.eval(np.array(nuc_img),
                                channels=channels,
                                diameter=diameter)

    props_dict = skimage.measure.regionprops_table(
        xp.array(masks),
        intensity_image=xp.transpose(xp.array(stack), (1, 2, 0)),
        properties=[
            "label",
            "area",
            "eccentricity",
            "equivalent_diameter_area",
            "extent",
            "feret_diameter_max", # this one may not been inplemented in cucim 
            "intensity_max",
            "intensity_mean",
            "intensity_min",
            "orientation",
            "perimeter",
            "solidity"
        ],
        # spacing = cp.array([spacing, spacing, 1])
    )
    return pd.DataFrame({k: props_dict[k].get() for k in props_dict})


def main(
    root: str, 
    plate_name: str, 
    out: str, 
    channels: List[Tuple[int, int]] = [(0, 0)], 
    diameter: int = 40
) -> None:
    """
    Process a plate of images using Cellpose and save the results to a CSV file.

    Args:
        root (str): Path to the root directory containing the plate directory.
        plate_name (str): Name of the plate directory containing well directories.
        out (str): Path to the output CSV file.
        channels (List[Tuple[int, int]], optional): List of channel indices to use for each image. Defaults to [(0, 0)].
        diameter (int, optional): Estimated diameter of cells in pixels. Defaults to 40.

    Returns:
        None
    """

    model = models.Cellpose(gpu=GPU_READY, model_type='cyto2')
    md = from_xml(f"{root}/{plate_name}")

    with Client(processes=True, threads_per_worker=1, n_workers=9, memory_limit='20GB'):
        dfs_jobs = {i.name : process_one_well(f"{root}/{i.name}", model=model, channels=channels, diameter=diameter)
                    for i in md.images}
        dfs = {j:dfs_jobs[j].compute() for j in dfs_jobs}
        all_dfs = pd.concat(dfs)
        all_dfs.to_csv(out)

        del dfs_jobs
        del dfs
        xp.get_default_memory_pool().free_all_blocks()
        gc.collect()


if __name__ == "__main__":
    fire.Fire(main)
