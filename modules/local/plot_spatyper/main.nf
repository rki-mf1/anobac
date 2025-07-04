process PLOT_SPATYPER {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://bajicv/r/anobac_plot:v0.0.2' :
        'library://bajicv/r/anobac_plot:v0.0.2' }"

    input:
    file(spatyper_csv)

    output:
    path("*.png"), emit: plots

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    Rscript --vanilla $baseDir/bin/plotting/anobac_plot_summary_spatyper.R -i $spatyper_csv -o .

    """
}
