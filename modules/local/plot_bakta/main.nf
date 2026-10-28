process PLOT_BAKTA {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-base_r-tidyverse_r-optparse_r-ggnewscale_r-ggpubr:0a8a030267d4e59b' :
        'oras://community.wave.seqera.io/library/r-base_r-tidyverse_r-optparse_r-ggnewscale_r-ggpubr:0a8a030267d4e59b' }"

    input:
    file(baktatxt)
    path(sampleSheet)

    output:
    path("*.png"), emit: plots

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    Rscript --vanilla $baseDir/bin/plotting/anobac_plot_bakta.R -i . -s $sampleSheet -o .
    """
}
