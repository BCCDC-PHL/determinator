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

  //prepare bwa index files as channels

  ch_composite_ref_file = Channel.fromPath(params.composite_ref)
  composite_bwaAuxFiles = []
  composite_refPath = new File(params.composite_ref).getAbsolutePath()
  new File(composite_refPath).getParentFile().eachFileMatch( ~/.*.bwt|.*.pac|.*.ann|.*.amb|.*.sa/) { composite_bwaAuxFiles << it }
  ch_composite_bwaAuxFiles = Channel.fromPath( composite_bwaAuxFiles ).collect().toList()

  // prepare bbsplit ref files as channels 
  ch_ref1_file = Channel.fromPath(params.ref_1)
  ch_ref2_file = Channel.fromPath(params.ref_2)

  if (params.samplesheet_input != 'NO_FILE') {
    ch_fastq = Channel.fromPath(params.samplesheet_input).splitCsv(header: true).map{ it -> [it['ID'], it['R1'], it['R2']] }
  } else {
    ch_fastq = Channel.fromFilePairs( params.fastqSearchPath, flat: true ).map{ it -> [it[0].split('_')[0], it[1], it[2]] }.unique{ it -> it[0] }
  }

  main:

    fastp(ch_fastq)

    if (params.bbsplit){
        bbsplit(fastp.out.reads.combine(ch_ref1_file).combine(ch_ref2_file))
    }
    
    if (params.bwa){

         bwa_competitive_mapping(fastp.out.reads.combine(ch_composite_ref_file).combine(ch_composite_bwaAuxFiles))
         qc_check(bwa_competitive_mapping.out.composite_ref_bam)
         depth_summary_csv = qc_check.out.depth_csv.collectFile(name: 'combined_depth_summary.csv', keepHeader: true, storeDir:  params.outdir)
         reads_summary_csv = bwa_competitive_mapping.out.read_summary_csv.collectFile(name: 'combined_read_summary.csv', keepHeader: true, storeDir:  params.outdir)
    }

    
   

}

