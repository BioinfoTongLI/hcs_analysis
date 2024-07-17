RUNNING THE PIPELINE ON SANGER LSF

1. Start an interactive session on the cluster

2. load nextflow module
```bash
module load cellgen/nextflow/24.04.3
```

3. Run the pipeline
```bash
nextflow run BioinfoTongLI/hcs_analysis -r v0.0.1 -entry FRACTAL -profile lsf --trial true -params-file [path_to_params.yaml]
```

Example of a params.yaml file:

```yaml
zarrs:
    - ["id":sample_ID, [path-to-zarr]]
out_dir: "./output"
```