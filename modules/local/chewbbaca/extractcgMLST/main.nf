process CHEWBBACA_EXTRACTCGMLST {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/chewbbaca:3.5.4--pyh106432d_0':
        'quay.io/biocontainers/chewbbaca:3.5.4--pyh106432d_0' }"

    input:
    tuple val(meta), path(allels)

    output:
    tuple val(meta), path("cgMLST*.tsv")  , emit: tsv
    tuple val(meta), path("cgMLST.html") , emit: html
    tuple val(meta), path("cgMLSTschema*.txt") , emit: schema
    tuple val(meta), path("missing_loci_stats.tsv") , emit: missing_loci
    tuple val(meta), path("presence_absence.tsv") , emit: presence_absence
    tuple val("${task.process}"), val("chewbbaca"), eval("chewie --version 2>&1 | sed 's/chewBBACA version: //'"), topic: versions, emit: versions_chewbbaca

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    chewie \\
        ExtractCgMLST \\
        $args \\
        --input-file $allels \\
        --output-directory .
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch cgMLST100.tsv
    touch cgMLST.html
    touch cgMLSTschema100.txt
    touch missing_loci_stats.tsv
    touch presence_absence.tsv

    """
}
