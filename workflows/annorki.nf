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
    //INPUT_CHECK (
    //    file(params.input)
    //)
    //ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
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

    input_ch = Channel.fromPath((params.input)) \
        | splitCsv(header:true) \
        | map {row-> tuple(row.sample, file(row.fasta), row.genus, row.species)}

    input_ch.view()
    BAKTA_BAKTA(
        input_ch,
        params.bakta_db
    )
    ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)

    kleb_input = input_ch.collect().view()

    if (params.typing == "kleborate"){
        KLEBORATE(
        input_ch
        )
        ch_versions = ch_versions.mix(KLEBORATE.out.versions)
    }

    if (params.typing == "ngmaster"){
        NGMASTER(
            input_ch
        )
        ch_versions = ch_versions.mix(NGMASTER.out.versions)
    }

    if (params.typing == "ectyper"){
        ECTYPER(
            input_ch
        )
        ch_versions = ch_versions.mix(ECTYPER.out.versions)
    }

    if (params.typing == "lissero"){
        LISSERO(
            input_ch
        )
        ch_versions = ch_versions.mix(LISSERO.out.versions)
    }

    if (params.typing == "meningotype"){
        MENINGOTYPE(
            input_ch
        )
        ch_versions = ch_versions.mix(MENINGOTYPE.out.versions)
    }

    if (params.typing == "sistr"){
        SISTR(
            input_ch
        )
        ch_versions = ch_versions.mix(SISTR.out.versions)
    }
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
