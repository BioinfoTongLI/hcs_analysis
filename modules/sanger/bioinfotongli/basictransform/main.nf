process BIOINFOTONGLI_BASICTRANSFORM {
    tag "ID: $meta.id Field:$field"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/basic_zarr:latest':
        'bioinfotongli/basic_zarr:latest' }"
    storeDir params.out_dir

    input:
    tuple val(meta), val(fov), path(zarr_root), val(field), path(models), val(new_zarr_root)

    output:
    tuple val(meta), path(expected_dir), emit: corrected_images
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    fov_to_correct = fov == "-1" ? field: "${field}/${fov}"
    new_zarr_root_name = file(new_zarr_root).name
    expected_dir = "${new_zarr_root_name}/${fov_to_correct}"
    """
    /opt/scripts/basic/BaSiC_transforming.py run \
        -field ${zarr_root}/${fov_to_correct} \
        -out_dir "${expected_dir}" \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_transforming.py version) 
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    expected_dir = row == -1 ? "corrected/${F}":"corrected/${row}/${col}/${F}"
    """
    mkdir ${expected_dir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_transforming.py version)
    END_VERSIONS
    """
}
