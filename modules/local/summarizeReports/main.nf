process SUMMARIZE_REPORTS {
    label 'process_single'

    conda "conda-forge::pandas:1.5.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.5.2' :
        'biocontainers/pandas:1.5.2' }"

    input:
        file ('*')
        val prefix

    output:
        path '*.csv', emit: summary
        path "versions.yml", emit: versions

    script:
    """
    if [[ $prefix == "salty" ]]; then
        summarizeReports.py \\
            --t . \\
            --o $prefix \\
            --c
    else
        summarizeReports.py \\
            --t . \\
            --o $prefix
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}