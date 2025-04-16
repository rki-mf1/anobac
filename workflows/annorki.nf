/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowAnnorki.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { SALTY       } from '../modules/local/salty/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { BAKTA_BAKTA                 } from '../modules/nf-core/bakta/bakta/main'
include { KLEBORATE                   } from '../modules/nf-core/kleborate/main.nf'
include { ECTYPER                     } from '../modules/nf-core/ectyper/main'
include { MENINGOTYPE                 } from '../modules/nf-core/meningotype/main'
include { LISSERO                     } from '../modules/nf-core/lissero/main'
include { NGMASTER                    } from '../modules/nf-core/ngmaster/main'
include { SISTR                       } from '../modules/nf-core/sistr/main'
include { AMRFINDERPLUS_RUN           } from '../modules/nf-core/amrfinderplus/run/main'
include { SPATYPER                    } from '../modules/nf-core/spatyper/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANNORKI {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        file(params.input)
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    input_ch = INPUT_CHECK.out.assembly

    // TODO: OPTIONAL, you can use nf-validation plugin to create an input channel from the samplesheet with Channel.fromSamplesheet("input")
    // See the documentation https://nextflow-io.github.io/nf-validation/samplesheets/fromSamplesheet/
    // ! There is currently no tooling to help you write a sample sheet schema
    // add items passed in from inputCsv samplesheet


    //if ( params.input ) {
    //    csv_ch = Channel.fromPath(params.input)
   //         .splitCsv(header:true)
    //        .map { row ->
    //            def metaMap = row.subMap(["sample", "genus", "species"])
//
//              // naive boolean parsing
//                if (metaMap.doBar.toLowerCase() == "true"){
//                    metaMap.doBar = true
//                } else {
//                   metaMap.doBar = false
//                }
//
//               return [ metaMap, file(row.file) ]
//            }

 //       input_ch = input_ch.mix(csv_ch)
 //   }

    //input_ch = Channel.fromPath((params.input)) \
    //    | splitCsv(header:true) \
    //    | map {row-> tuple(row.sample, file(row.fasta), row.genus, row.species)}

    BAKTA_BAKTA(
        input_ch,
        params.bakta_db,
        [],
        []
    )
    ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)

    // seperate channel for different species to run typing tools
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Neisseria_gonorrhoeae" }.set { ch_neg }
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Neisseria_meningitidis" }.set { ch_nei }
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Listeria_monocytogenes" }.set { ch_lis }
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Klebsiella_pneumoniae" }.set { ch_kp }
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Escherichia_coli" }.set { ch_ec }
    input_ch.filter { meta, fasta -> meta.genus=="Salmonella" }.set { ch_sal }
    input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Staphylococcus_aureus" }.set { ch_mra }

    KLEBORATE(
        ch_kp
    )
    ch_versions = ch_versions.mix(KLEBORATE.out.versions)
    NGMASTER(
        ch_neg
    )

    ch_versions = ch_versions.mix(NGMASTER.out.versions)
    ECTYPER(
        ch_ec
    )
    ch_versions = ch_versions.mix(ECTYPER.out.versions)
    LISSERO(
        ch_lis
    )
    ch_versions = ch_versions.mix(LISSERO.out.versions)
    MENINGOTYPE(
        ch_nei
    )
    ch_versions = ch_versions.mix(MENINGOTYPE.out.versions)
    SISTR(
        ch_sal
    )
    ch_versions = ch_versions.mix(SISTR.out.versions)
    SALTY(
        ch_mra
    )
    ch_versions = ch_versions.mix(SALTY.out.versions)
    //salty_sum = SALTY.out.lineage.collect()
    //SUMMARIZE_REPORTS(
    //    salty_sum,
    //    "salty"
    //)
    SPATYPER(
        ch_mra,
        [],
        []
    )
    ch_versions = ch_versions.mix(SPATYPER.out.versions)
    //spatyper_sum = SPATYPER.out.tsv.collect()
    //SUMMARIZE_REPORTS(
    //    spatyper_sum,
    //    "spatyper"
    //)

    AMRFINDERPLUS_RUN(
        input_ch,
        params.amrfinder_db
    )
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
