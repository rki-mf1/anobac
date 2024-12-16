process NGMASTER {
    tag "$meta"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ngmaster:0.5.8--pyhdfd78af_1' :
        'biocontainers/ngmaster:0.5.8--pyhdfd78af_1' }"

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
    ngmaster \\
        $args \\
        $fasta \\
        > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ngmaster: \$( echo \$(ngmaster --version 2>&1) | sed 's/^.*ngmaster //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ngmaster: \$( echo \$(ngmaster --version 2>&1) | sed 's/^.*ngmaster //' )
    END_VERSIONS
    """
}
