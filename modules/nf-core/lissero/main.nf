process LISSERO {
    tag "$meta"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lissero:0.4.9--py_0' :
        'biocontainers/lissero:0.4.9--py_0' }"

    input:
    tuple val(meta), path(fasta), val(genus), val(species)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    lissero \\
        $args \\
        $fasta \\
        > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lissero: \$( echo \$(lissero --version 2>&1) | sed 's/^.*LisSero //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lissero: \$( echo \$(lissero --version 2>&1) | sed 's/^.*LisSero //' )
    END_VERSIONS
    """
}
