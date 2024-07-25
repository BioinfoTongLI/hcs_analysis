#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
"""

"""
from typing import List, Tuple
import fire
from aicsimageio import AICSImage
from aicsimageio.writers import OmeTiffWriter
from ome_types import from_xml
from dask.distributed import Client
import dask
import pandas as pd
import numpy as np
import gc
import os

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
def process_one_well(img_path: str, name:str, model: models.CellposeModel, diameter_in_um: float,
                     out_dir: str, nuclei_channel_name: str = "PhenoVue Hoechst 33342", nuc_only: bool = False,
                     channels: List[List[int]] = [[0, 0]]) -> pd.DataFrame:
    """
    Processes a single well image using a given model.

    :param img_path: Path to the well image.
    :type img_path: str
    :param name: Well name.
    :type name: str
    :param model: Trained CellPose model to use for prediction.
    :type model: models.CellposeModel
    :param nuclei_channel_name: Name of the channel containing nuclei. Default is "PhenoVue Hoechst 33342".
    :type nuclei_channel_name: str
    :param out_dir: Path to the output folder of the mask.
    :type out_dir: str
    :param diameter_in_um: Diameter of the nuclei in micrometers.
    :type diameter_in_um: float
    :param channels: List of channel indices to use for prediction. Default is [[0, 0]].
    :type channels: List[List[int]]
    :param nuc_only: Whether to use only the nuclei channel for prediction. Default is False.
    :type nuc_only: bool

    :return: A pandas DataFrame containing the predicted mask and the original image.
    :rtype: pd.DataFrame
    """
    img = AICSImage(f"{img_path}/{name}")
    stem = name.split("_")[0]
    spacing = float(img.get_xarray_dask_stack().coords["X"][1])
    diameter_in_px = int(diameter_in_um / spacing)
    # print(f"Processing {name} with diameter {diameter_in_px} px and spacing {spacing} um")

    stack = img.get_xarray_dask_stack().squeeze()
    print(stack.shape)
    if nuc_only:
        img_for_seg = stack.sel(C=nuclei_channel_name).compute()
    else:
        img_for_seg = np.max(np.array(stack), axis=0)
    mask, _, _, _ = model.eval(img_for_seg,
                                channels=channels,
                                diameter=diameter_in_px)

    OmeTiffWriter.save(mask, f"{out_dir}/{stem}_mask.ome.tif", dim_order="YX")

    props_dict = skimage.measure.regionprops_table(
        xp.array(mask),
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
    pd.DataFrame({k: props_dict[k].get() for k in props_dict}).to_csv(f"{out_dir}/{stem}_regionprops.csv", index=False)


def main(
    root: str,
    plate_name: str,
    out_dir: str,
    diameter_in_um: float,
    channels: List[Tuple[int, int]] = [(0, 0)]
) -> None:
    """
    Process a plate of images using Cellpose and save the results to a CSV file.

    :param root: Path to the root directory containing the plate directory.
    :type root: str
    :param plate_name: Name of the plate directory containing well directories.
    :type plate_name: str
    :param out_dir: Path to the output folder.
    :type out_dir: str
    :param diameter_in_um: Estimated diameter of cells in micron.
    :type diameter: float
    :param channels: List of channel indices to use for each image. Default is [(0, 0)].
    :type channels: List[Tuple[int, int]]]
    :return: None
    :rtype: None
    """

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    model = models.Cellpose(gpu=GPU_READY, model_type='cyto2')
    md = from_xml(f"{root}/{plate_name}")

    with Client(processes=True, threads_per_worker=1, n_workers=9, memory_limit='20GB'):
        dfs_jobs = {i.name : process_one_well(root, i.name, model=model, out_dir=out_dir, channels=channels, diameter_in_um=diameter_in_um)
                    for i in md.images}
        for j in dfs_jobs:
            dfs_jobs[j].compute()

        xp.get_default_memory_pool().free_all_blocks()
        gc.collect()


if __name__ == "__main__":
    fire.Fire(main)
