process IQTREE {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:3.1.3--h8471819_0' :
        'quay.io/biocontainers/iqtree:3.1.3--h8471819_0' }"

    input:
    path(alignment)

    output:
    path("*.treefile")      , emit: phylogeny     , optional: true
    path("*.iqtree")        , emit: report        , optional: true
    path("*.mldist")        , emit: mldist        , optional: true
    path("*.lmap.svg")      , emit: lmap_svg      , optional: true
    path("*.lmap.eps")      , emit: lmap_eps      , optional: true
    path("*.lmap.quartetlh"), emit: lmap_quartetlh, optional: true
    path("*.sitefreq")      , emit: sitefreq_out  , optional: true
    path("*.ufboot")        , emit: bootstrap     , optional: true
    path("*.state")         , emit: state         , optional: true
    path("*.contree")       , emit: contree       , optional: true
    path("*.nex")           , emit: nex           , optional: true
    path("*.best_scheme")   , emit: best_scheme   , optional: true
    path("*.splits")        , emit: splits        , optional: true
    path("*.suptree")       , emit: suptree       , optional: true
    path("*.alninfo")       , emit: alninfo       , optional: true
    path("*.partlh")        , emit: partlh        , optional: true
    path("*.siteprob")      , emit: siteprob      , optional: true
    path("*.sitelh")        , emit: sitelh        , optional: true
    path("*.treels")        , emit: treels        , optional: true
    path("*.rate")          , emit: rate          , optional: true
    path("*.mlrate")        , emit: mlrate        , optional: true
    path("GTRPMIX.nex")     , emit: exch_matrix   , optional: true
    path("*.log")           , emit: log
    tuple val("${task.process}"), val('iqtree'), eval("iqtree -version 2>&1 | grep -oE '[0-9]+[.][0-9]+[.][0-9]+' | head -n1"), emit: versions_iqtree, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                        = task.ext.args           ?: ''
    def memory                      = task.memory.toString().replaceAll(' ', '')
    // IQ-TREE rejects -mem when a partition model is in use:
    // "-mem option does not work with partition models yet".
    def memory_arg                  = "-mem $memory"
    """
    iqtree \\
        -s $alignment \\
        -pre iqtree \\
        -nt AUTO \\
        -ntmax $task.cpus \\
        $memory_arg
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch "${prefix}.treefile"
    touch "${prefix}.iqtree"
    touch "${prefix}.mldist"
    touch "${prefix}.lmap.svg"
    touch "${prefix}.lmap.eps"
    touch "${prefix}.lmap.quartetlh"
    touch "${prefix}.sitefreq"
    touch "${prefix}.ufboot"
    touch "${prefix}.state"
    touch "${prefix}.contree"
    touch "${prefix}.nex"
    touch "${prefix}.best_scheme"
    touch "${prefix}.splits"
    touch "${prefix}.suptree"
    touch "${prefix}.alninfo"
    touch "${prefix}.partlh"
    touch "${prefix}.siteprob"
    touch "${prefix}.sitelh"
    touch "${prefix}.treels"
    touch "${prefix}.rate"
    touch "${prefix}.mlrate"
    touch "GTRPMIX.nex"
    touch "${prefix}.log"
    """

}
