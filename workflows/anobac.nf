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
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS1 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS2 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS3 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS4 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS5 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS6 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS7 } from '../modules/local/summarizeReports/main'
include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS8 } from '../modules/local/summarizeReports/main'
//include { SUMMARIZE_REPORTS as SUMMARIZE_REPORTS9 } from '../modules/local/summarizeReports/main'
include { PLOT_AMRFINDER } from '../modules/local/plot_amrfinder/main'
include { PLOT_BAKTA } from '../modules/local/plot_bakta/main'
include { PLOT_ECTYPER } from '../modules/local/plot_ectyper/main'
include { PLOT_SALTY } from '../modules/local/plot_salty/main'
include { PLOT_KLEBORATE } from '../modules/local/plot_kleborate/main'
include { PLOT_LISSERO } from '../modules/local/plot_lissero/main'
include { PLOT_MENINGOTYPE } from '../modules/local/plot_meningotype/main'
include { PLOT_NGMASTER } from '../modules/local/plot_ngmaster/main'
include { PLOT_SISTR } from '../modules/local/plot_sistr/main'
include { PLOT_SPATYPER } from '../modules/local/plot_spatyper/main'

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
//include { KLEBORATE as KLEBORATE_EC   } from '../modules/nf-core/kleborate/main.nf'
include { ECTYPER                     } from '../modules/nf-core/ectyper/main'
include { MENINGOTYPE                 } from '../modules/nf-core/meningotype/main'
include { LISSERO                     } from '../modules/nf-core/lissero/main'
include { NGMASTER                    } from '../modules/nf-core/ngmaster/main'
include { SISTR                       } from '../modules/nf-core/sistr/main'
include { AMRFINDERPLUS_RUN           } from '../modules/nf-core/amrfinderplus/run/main'
include { SPATYPER                    } from '../modules/nf-core/spatyper/main'
include { BAKTA_BAKTADBDOWNLOAD       } from '../modules/nf-core/bakta/baktadbdownload/main'
include { AMRFINDERPLUS_UPDATE        } from '../modules/nf-core/amrfinderplus/update/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANOBAC {

    ch_versions = Channel.empty()


    // if run in setup up mode just download dbs for AMRFINDERPLUS and BAKTA
    if (params.setup_dbs==true){

        BAKTA_BAKTADBDOWNLOAD()
        ch_versions = ch_versions.mix(BAKTA_BAKTADBDOWNLOAD.out.versions)

        AMRFINDERPLUS_UPDATE()
        ch_versions = ch_versions.mix(AMRFINDERPLUS_UPDATE.out.versions)


    }else{

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

        BAKTA_BAKTA(
            input_ch,
            params.bakta_db,
            [],
            []
        )
        ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)

        PLOT_BAKTA(
            BAKTA_BAKTA.out.txt.collect(),
            file(params.input)
        )

        // seperate channel for different species to run typing tools
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Neisseria_gonorrhoeae" }.set { ch_neg }
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Neisseria_meningitidis" }.set { ch_nei }
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Listeria_monocytogenes" }.set { ch_lis }
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Klebsiella_pneumoniae" }.set { ch_kp }
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Escherichia_coli" }.set { ch_ec }
        input_ch.filter { meta, fasta -> meta.genus=="Salmonella" }.set { ch_sal }
        input_ch.filter { meta, fasta -> meta.genus+"_"+meta.species=="Staphylococcus_aureus" }.set { ch_mra }

        // KLEBORATE
        KLEBORATE(
            ch_kp,
            "kpsc"
        )
        ch_versions = ch_versions.mix(KLEBORATE.out.versions)
        kleborate_sum = KLEBORATE.out.txt.collect()
        SUMMARIZE_REPORTS1(
            kleborate_sum,
            "kleborate_kpsc"
        )
        PLOT_KLEBORATE(
            SUMMARIZE_REPORTS1.out.summary
        )

        // NGMASTER
        NGMASTER(
            ch_neg,
            params.ngmaster_db
        )
        ch_versions = ch_versions.mix(NGMASTER.out.versions)
        ngmaster_sum = NGMASTER.out.tsv.collect()
        SUMMARIZE_REPORTS2(
            ngmaster_sum,
            "ngmaster"
        )
        PLOT_NGMASTER(
            SUMMARIZE_REPORTS2.out.summary
        )

        // ECTYPER
        ECTYPER(
            ch_ec
        )
        ch_versions = ch_versions.mix(ECTYPER.out.versions)
        ectyper_sum = ECTYPER.out.tsv.collect()
        SUMMARIZE_REPORTS3(
            ectyper_sum,
            "ectyper"
        )
        PLOT_ECTYPER(
            SUMMARIZE_REPORTS3.out.summary
        )
        //KLEBORATE_EC(
        //    ch_ec,
        //    "escherichia"
        //)
        //kleborate_ec_sum = KLEBORATE_EC.out.txt.collect()
        //SUMMARIZE_REPORTS9(
        //    kleborate_ec_sum,
        //    "kleborate_escherichia"
        //)

        // LISSERO
        LISSERO(
            ch_lis
        )
        ch_versions = ch_versions.mix(LISSERO.out.versions)
        lissero_sum = LISSERO.out.tsv.collect()
        SUMMARIZE_REPORTS4(
            lissero_sum,
            "lissero"
        )
        PLOT_LISSERO(
            SUMMARIZE_REPORTS4.out.summary
        )

        // MENINGOTYPE
        MENINGOTYPE(
            ch_nei
        )
        ch_versions = ch_versions.mix(MENINGOTYPE.out.versions)
        meningo_sum = MENINGOTYPE.out.tsv.collect()
        SUMMARIZE_REPORTS5(
            meningo_sum,
            "meningotype"
        )
        PLOT_MENINGOTYPE(
            SUMMARIZE_REPORTS5.out.summary
        )

        // SISTR
        SISTR(
            ch_sal
        )
        ch_versions = ch_versions.mix(SISTR.out.versions)
        sistr_sum = SISTR.out.tsv.collect()
        SUMMARIZE_REPORTS6(
            sistr_sum,
            "sistr"
        )
        PLOT_SISTR(
            SUMMARIZE_REPORTS6.out.summary
        )

        // SALTY
        SALTY(
            ch_mra
        )
        ch_versions = ch_versions.mix(SALTY.out.versions)
        salty_sum = SALTY.out.lineage.collect()
        SUMMARIZE_REPORTS7(
            salty_sum,
            "salty"
        )
        PLOT_SALTY(
            SUMMARIZE_REPORTS7.out.summary
        )

        // SPATYPER
        SPATYPER(
            ch_mra,
            [],
            []
        )
        ch_versions = ch_versions.mix(SPATYPER.out.versions)
        spatyper_sum = SPATYPER.out.tsv.collect()
        SUMMARIZE_REPORTS8(
            spatyper_sum,
            "spatyper"
        )
        PLOT_SPATYPER(
            SUMMARIZE_REPORTS8.out.summary
        )


        //AMRFINDER + METAL + STRESS + STRESSFACTORS
        AMRFINDERPLUS_RUN(
            input_ch,
            params.amrfinder_db
        )
        ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions)
        PLOT_AMRFINDER(
            AMRFINDERPLUS_RUN.out.report.collect(),
            file(params.input)
        )
    }


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
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
