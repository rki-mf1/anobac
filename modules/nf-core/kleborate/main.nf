process KLEBORATE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kleborate:3.2.0--pyhdfd78af_0' :
        'biocontainers/kleborate:3.2.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastas)
    val preset

    output:
    tuple val(meta), path("*_kleborate_results.txt"), emit: txt
    //tuple val(meta), path("*_hAMRonization_output.txt"), emit: amr
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    kleborate \\
        $args \\
        --outdir . \\
        --assemblies $fastas \\
        --preset $preset

    mv *_output.txt ${prefix}_kleborate_results.txt
    #mv *_hAMRonization_output.txt ${prefix}_hAMRonization_output.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kleborate: \$( echo \$(kleborate --version | sed 's/Kleborate v//;'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.results.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kleborate: \$( echo \$(kleborate --version | sed 's/Kleborate v//;'))
    END_VERSIONS
    """
}
