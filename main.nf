#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// include modules
// include {printHelp} from './modules/help.nf'

// import subworkflows

if (params.help){
    printHelp()
    exit 0
}

if (params.profile){
    println("Profile should have a single dash: -profile")
    System.exit(1)
}


include { bbsplit }          from './modules/determinate.nf'
include { bwa_competitive_mapping }          from './modules/determinate.nf'

// main workflow

workflow {
  //ch_ref = Channel.fromPath( "${params.ref}", type: 'file')

  if (params.samplesheet_input != 'NO_FILE') {
    ch_fastq = Channel.fromPath(params.samplesheet_input).splitCsv(header: true).map{ it -> [it['ID'], it['R1'], it['R2']] }
  } else {
    ch_fastq = Channel.fromFilePairs( params.fastqSearchPath, flat: true ).map{ it -> [it[0].split('_')[0], it[1], it[2]] }.unique{ it -> it[0] }
  }

  main:
    bbsplit(ch_fastq)
    bwa_competitive_mapping(ch_fastq)

}

