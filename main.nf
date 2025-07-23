#!/usr/bin/env nextflow

nextflow.enable.dsl = 2


def header() {
    return """
                                                                              
██████╗░███████╗████████╗███████╗██████╗░███╗░░░███╗██╗███╗░░██╗░█████╗░████████╗░█████╗░██████╗░
██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗░████║██║████╗░██║██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗
██║░░██║█████╗░░░░░██║░░░█████╗░░██████╔╝██╔████╔██║██║██╔██╗██║███████║░░░██║░░░██║░░██║██████╔╝
██║░░██║██╔══╝░░░░░██║░░░██╔══╝░░██╔══██╗██║╚██╔╝██║██║██║╚████║██╔══██║░░░██║░░░██║░░██║██╔══██╗░
██████╔╝███████╗░░░██║░░░███████╗██║░░██║██║░╚═╝░██║██║██║░╚███║██║░░██║░░░██║░░░╚█████╔╝██║░░██║
╚═════╝░╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝
                       ______
                     <((((((\\\\\\\\
                     /      . }\\\\
                     ;--..--._|}
  (\\\\               '--/\\\\--'  )
   \\\\                | '-'  :'|
    \\\\               . -==- .-|      Hasta la vista, sample ambiguity. I'll be back ... with sorted fastqs!
     \\\\               \\\\.__.'   \\\\--._
     [\\\\          __.--|       //  _/'--.
     \\ \\\\       .'-._ ('-----'/ __/      \\\\
      \\ \\\\     /   __>|      | '--.       |
       \\ \\\\   |   \\\\   |     /    /       /
        \\ '\\ /     \\\\  |     |  _/       /
         \\\\  \\\\       \\ |     | /        /
          \\\\  \\\\      \\\\        /

===================================================================================================================
output directory: ${params.outdir}

"""
}

def rsv_header() {
    return """
                                                                              
██████╗░███████╗████████╗███████╗██████╗░███╗░░░███╗██╗███╗░░██╗░█████╗░████████╗░█████╗░██████╗░░██████╗██╗░░░██╗
██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗░████║██║████╗░██║██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║░░░██║
██║░░██║█████╗░░░░░██║░░░█████╗░░██████╔╝██╔████╔██║██║██╔██╗██║███████║░░░██║░░░██║░░██║██████╔╝╚█████╗░╚██╗░██╔╝
██║░░██║██╔══╝░░░░░██║░░░██╔══╝░░██╔══██╗██║╚██╔╝██║██║██║╚████║██╔══██║░░░██║░░░██║░░██║██╔══██╗░╚═══██╗░╚████╔╝░
██████╔╝███████╗░░░██║░░░███████╗██║░░██║██║░╚═╝░██║██║██║░╚███║██║░░██║░░░██║░░░╚█████╔╝██║░░██║██████╔╝░░╚██╔╝░░
╚═════╝░╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░
                       ______
                     <((((((\\\\\\\\
                     /      . }\\\\
                     ;--..--._|}
  (\\\\               '--/\\\\--'  )
   \\\\                | '-'  :'|
    \\\\               . -==- .-|      Hasta la vista, RSV ambiguity. I'll be back ... with subtypes!
     \\\\               \\\\.__.'   \\\\--._
     [\\\\          __.--|       //  _/'--.
     \\ \\\\       .'-._ ('-----'/ __/      \\\\
      \\ \\\\     /   __>|      | '--.       |
       \\ \\\\   |   \\\\   |     /    /       /
        \\ '\\ /     \\\\  |     |  _/       /
         \\\\  \\\\       \\ |     | /        /
          \\\\  \\\\      \\\\        /

===================================================================================================================
output directory: ${params.outdir}

"""
}

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


if (params.rsv){
    log.info rsv_header()
} else{
    log.info header()

}


include { bbsplit }                          from './modules/determinate.nf'
include { bwa_competitive_mapping }          from './modules/determinate.nf'
include { qc_check }                         from './modules/determinate.nf'
include { fastp }                            from './modules/determinate.nf'

// main workflow

workflow {
  //ch_ref = Channel.fromPath( "${params.ref}", type: 'file')

  if (params.samplesheet_input != 'NO_FILE') {
    ch_fastq = Channel.fromPath(params.samplesheet_input).splitCsv(header: true).map{ it -> [it['ID'], it['R1'], it['R2']] }
  } else {
    ch_fastq = Channel.fromFilePairs( params.fastqSearchPath, flat: true ).map{ it -> [it[0].split('_')[0], it[1], it[2]] }.unique{ it -> it[0] }
  }

  main:

    fastp(ch_fastq)

    if (params.bbsplit){
        bbsplit(fastp.out.reads)
    }
    
    if (params.bwa){
         bwa_competitive_mapping(fastp.out.reads)
         qc_check(bwa_competitive_mapping.out.composite_ref_bam)
         summary_csv = qc_check.out.depth_csv.collectFile(name: 'combined_depth_summary.csv', keepHeader: true, storeDir:  params.outdir)
    }

    
   

}

