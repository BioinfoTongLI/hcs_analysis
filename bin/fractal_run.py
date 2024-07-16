import fire
from fractal_tasks_core.tasks.cellpose_segmentation import cellpose_segmentation
from fractal_tasks_core.tasks.import_ome_zarr import import_ome_zarr

def main(zarr):
    fractal_url = import_ome_zarr(input_paths=["./"], zarr_name="jm52_KITTY_20230929_10h__2023-09-30T11_44_13-Measurement 2", output_path="", metadata="", overwrite=True, add_image_ROI_table=True)
    c = fractal_url[0] 
    cellpose_segmentation(input_paths=["./"], output_path="", component=c, metadata="", level=0, channel={"wavelength_id":"PhenoVue Fluor 488"}, input_ROI_table='image_ROI_table')
