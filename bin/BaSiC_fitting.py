#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from aicsimageio import AICSImage
from basicpy import BaSiC
import numpy as np
from glob import glob
import logging

logger = logging.getLogger(__name__)

def main(zarr:str, C:int, P:int, T:int=0, is_hcs=True):
    """
    Perform BaSiC fitting on a stack of images.

    Parameters:
    ----------
    zarr : str
        Path to the directory containing the zarr files.
    C : int
        Channel index to extract from the images.
    P : int
        Position index to select from the images.
    T : int, optional
        Time index to select from the images. Default is 0.
    is_hcs : bool, optional
        Flag indicating whether the images are from high-content screening (HCS). Default is True.

    Returns:
    -------
    None

    Raises:
    ------
    NotImplementedError
        If `is_hcs` is False.
    """
    
    stack = []
    if is_hcs:
        # Populate stack across all wells for the given position P
        for f in glob(f"{zarr}/*/*/{P}"):
            img = AICSImage(f).get_image_dask_data("ZYX", S=0, T=T, C=C)
            stack.append(img)
    else:
        logger.info("Not implemented yet")
        raise NotImplementedError("Non-HCS mode is not implemented yet")
    
    stack_np = np.array(stack)
    basic = BaSiC(get_darkfield=True, resize_mode="skimage_dask")
    basic.fit(stack_np.astype(np.int16))
    basic.save_model(f"BaSiC_model_C{C}_P{P}_T{T}")


if __name__ == "__main__":
    fire.Fire(main)
