process SALTY {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/salty:1.0.6--pyhdfd78af_0' :
        'biocontainers/salty:1.0.6--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*/*_lineage.csv"), emit: lineage
    tuple val(meta), path("*/*.aln"), emit: aln
    tuple val(meta), path("*/*.frag.gz"), emit: frag
    tuple val(meta), path("*/*.fsa"), emit: fsa
    tuple val(meta), path("*/*.res"), emit: res
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    salty \\
        $args \\
        --t $task.cpus \\
        --i . \\
        --o . \\
        -m -c

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salty: \$(echo \$(salty --version 2>&1)  | sed 's/.*salty version://; s/ .*\$//')
    END_VERSIONS
    """
}
