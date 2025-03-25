process SUMMARIZE_REPORTS {
    label 'process_single'

    conda "conda-forge::pandas:1.5.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.5.2' :
        'biocontainers/pandas:1.5.2' }"

    input:
        file ('*')
        path prefix

    output:
        path '*.csv'
        path "versions.yml", emit: versions

    script:
    """
    summarizeReports.py \\
        --t . \\
        --p $outdir

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}