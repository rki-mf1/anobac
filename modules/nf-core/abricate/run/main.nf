process ABRICATE_RUN {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate:1.4.0--h05cac1d_0':
        'biocontainers/abricate:1.4.0--h05cac1d_0' }"


    input:
    tuple val(meta), path(assembly)
    path databasedir

    output:
    tuple val(meta), path("*.txt"), emit: report
    tuple val("${task.process}"), val('abricate'), eval("abricate --version | sed 's/^.* //' "), emit: versions_abricate, topic: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def datadir = databasedir ? "--datadir ${databasedir}" : ''
    """
    ## Symlink when necessary to rename the file to allow specifying the prefix variable inside report
    ## As the variable is what is used as the sample ID in the report file
    if [[ "${assembly}" != "${prefix}.fasta" ]]; then
        ln -s ${assembly} ${prefix}.fasta
    fi

    abricate \\
        ${prefix}.fasta \\
        ${args} \\
        ${datadir} \\
        --threads ${task.cpus} \\
        > ${prefix}.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt
    """
}
