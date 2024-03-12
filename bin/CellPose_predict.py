#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 Tong LI <tongli.bioinfo@proton.me>
"""

"""
import fire
from aicsimageio import AICSImage
import zarr
from ome_zarr import writer
from ome_zarr.io import parse_url
from skimage import transform
import numpy as np
import shutil
import tifffile as tf

from cellpose import models, core
GPU_READY = core.use_gpu()


def main(field:str, row:str, col:str, C:int, out_dir:str, diameter:int=30, model_name:str="cyto2"):
    model = models.Cellpose(gpu=GPU_READY, model_type=model_name)
    hyperstack = AICSImage(f"./{field}")
    seg_stack = []
    for t in range(hyperstack.dims.T):
        img = hyperstack.get_image_dask_data("CZYX", T=t)
        img = np.max(img, axis=0)
        mask, _, _, _ = model.eval(
            img,
            channels=[0, 0],
            diameter=diameter,
            do_3D=True)
        seg_stack.append(mask)

    stack = np.expand_dims(np.array(seg_stack), axis=0)
    seg_name = f"cellpose_segmentation_diam_{diameter}_model_{model_name}"

    # Create a zarr label image store
    store = parse_url(out_dir, mode="w").store
    root_group = zarr.group(store=store)
    
    # Once ready, we can write directly to the subfolder of input data
    # root_group = zarr.open_group(f"./{field}", mode='a')

    # resize the top resolution layer to get the lower layers of the pyramid
    # shape = np.array(stack.shape)
    # new_shapes = [np.where(shape > 10, shape // 2 ** n, shape) for n in range(5)]
    # layers = [transform.resize(stack, tuple(shape), preserve_range = True).astype(np.uint16) for shape in new_shapes]

    # _ = writer.write_multiscale_labels(
    #     pyramid = layers,
    _ = writer.write_labels(
        labels = stack,
        group = root_group,
        name = seg_name,
        storage_options={'dimension_separator': '/'},
    )

    tf.imwrite(f"{out_dir}/labels/{seg_name}.tif", stack)
    

if __name__ == "__main__":
    fire.Fire(main)
