process ROARY {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/roary:3.13.0--pl526h516909a_0' :
        'quay.io/biocontainers/roary:3.13.0--pl526h516909a_0' }"

    input:
    path(gffs)

    output:
    path("${prefix}/*"), emit: results
    path("${prefix}/*.aln"),  emit: aln, optional: true
    tuple val("${task.process}"), val('roary'), eval('roary --version'), emit: versions_roary, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = "roary"
    """
    roary \\
        ${args} \\
        -p ${task.cpus} \\
        -f ${prefix} \\
        *.gff3
    """

    stub:
    prefix = "roary"
    """
    mkdir -p ${prefix}
    touch ${prefix}/core_gene_alignment.aln
    touch ${prefix}/gene_presence_absence.csv
    touch ${prefix}/gene_presence_absence.Rtab
    touch ${prefix}/accessory_binary_genes.fa
    touch ${prefix}/pan_genome_reference.fa
    touch ${prefix}/summary_statistics.txt
    """
}
