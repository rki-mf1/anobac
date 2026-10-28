process ABRICATE_UPDATE {

    conda "bioconda::abricate=1.4.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate:1.4.0--h05cac1d_0':
        'biocontainers/abricate:1.4.0--h05cac1d_0' }"

    input:
    val dbsource

    output:
    path "abricate"

    script:
    """
        mkdir -p abricate/$dbsource
        abricate-get_db --db $dbsource --force --dbdir abricate
    """
}