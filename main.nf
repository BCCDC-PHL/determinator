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

def measles_header() {
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
    \\\\               . -==- .-|      Hasta la vista, measles ambiguity. I'll be back ... with genotypes!
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

def sarsCoV2_header() {
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
    \\\\               . -==- .-|      Hasta la vista, SARS-CoV-2 ambiguity. I'll be back ... with Cicada squashed!
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

if (params.rsv) {
    log.info rsv_header()

} else if (params.measles) {
    log.info measles_header()

} else if (params.sarsCoV2) {
    log.info sarsCoV2_header()

} else {
    log.info header()
}




include { bbsplit }                          from './modules/determinate.nf'
include { bwa_competitive_mapping }          from './modules/determinate.nf'
include { fastp }                            from './modules/determinate.nf'
include { index_reference }                  from './modules/determinate.nf'
include { plot_depth }                       from './modules/determinate.nf'
include { sort_fastq }                       from './modules/determinate.nf'
include { split_fastq }                      from './modules/determinate.nf'

include { pipeline_provenance }              from './modules/provenance.nf'
include { collect_provenance }               from './modules/provenance.nf'
include { hash_files }                       from './modules/hash_files.nf'

// main workflow

workflow {

  //prepare bwa index files as channels
  ch_composite_ref_file = Channel.fromPath(params.composite_ref)

  if (params.index) {
      ch_composite_bwaAuxFiles = index_reference(ch_composite_ref_file).map { it[1] }.collect().toList()
  } else {
    composite_bwaAuxFiles = []
    composite_refPath = new File(params.composite_ref).getAbsolutePath()
    new File(composite_refPath).getParentFile().eachFileMatch( ~/.*.bwt|.*.pac|.*.ann|.*.amb|.*.sa/) { composite_bwaAuxFiles << it }
    ch_composite_bwaAuxFiles = Channel.fromPath( composite_bwaAuxFiles ).collect().toList()
  }

  //prepare list of references used in composite reference
  ch_ref_names = Channel.fromPath(params.composite_ref).map { fasta ->
            def names = []
            fasta.withReader { r ->
                r.eachLine { line ->
                    if (line.startsWith('>')) {
                        names << line.substring(1).tokenize(' ')[0]
                    }
                }
            }
            names.join(' ')
        }

  // prepare bbsplit ref files as channels 
  ch_ref1_file = Channel.fromPath(params.ref_1)
  ch_ref2_file = Channel.fromPath(params.ref_2)

  if (params.samplesheet_input != 'NO_FILE') {
    ch_fastq = Channel.fromPath(params.samplesheet_input).splitCsv(header: true).map{ it -> [it['ID'], it['R1'], it['R2']] }
  } else {
    ch_fastq = Channel.fromFilePairs( params.fastqSearchPath, flat: true ).map{ it -> [it[0].split('_')[0], it[1], it[2]] }.unique{ it -> it[0] }
  }

  main:

    def ch_reads

    if (!params.skip_fastp) {
        fastp(ch_fastq)
        ch_reads = fastp.out.reads
    } else {
        ch_reads = ch_fastq
    }

    if (params.bbsplit){
        bbsplit(ch_reads.combine(ch_ref1_file).combine(ch_ref2_file))
    }
    
    if (params.bwa){

        bwa_competitive_mapping(ch_reads.combine(ch_composite_ref_file).combine(ch_composite_bwaAuxFiles).combine(ch_ref_names))
         
        plot_depth(bwa_competitive_mapping.out.split_bams)

        if (params.fastq_mode == "split") {
            split_fastq(bwa_competitive_mapping.out.split_bams)

        }
        if (params.fastq_mode == "sort") {
            sort_fastq(ch_reads.join(bwa_competitive_mapping.out.top_ref))
        }
        
        depth_summary_csv = plot_depth.out.depth_summary_csv.collectFile(name: 'combined_depth_summary.csv', keepHeader: true, storeDir: params.outdir)

        reads_summary_csv = bwa_competitive_mapping.out.read_summary_csv.collectFile(name: 'combined_read_summary.csv', keepHeader: true, storeDir: params.outdir)
                    
        reference_summary_csv = bwa_competitive_mapping.out.reference_summary_csv.collectFile(name: 'combined_reference_summary.csv', keepHeader: true, storeDir: params.outdir)

     }

    // Provenance collection processes
      // [sample_id, [provenance_file_1.yml, provenance_file_2.yml, provenance_file_3.yml...]]
      // ...and then concatenate them all together in the 'collect_provenance' process.
      ch_start_time = Channel.of(workflow.start)
      ch_pipeline_name = Channel.of(workflow.manifest.name)
      ch_pipeline_version = Channel.of(workflow.manifest.version)
      ch_pipeline_provenance = pipeline_provenance(ch_pipeline_name.combine(ch_pipeline_version).combine(ch_start_time))
      // FASTQ provenance
      hash_files(ch_fastq.map{ it -> [it[0], [it[1], it[2]]] }.combine(Channel.of("fastq-input")))
      // determinator.nf provenance

    if (!params.skip_fastp) {
        ch_provenance = fastp.out.provenance
        ch_provenance = ch_provenance
            .join(bwa_competitive_mapping.out.provenance)
            .map { it -> [it[0], [it[1]] << it[2]] }

    } else {
        ch_provenance = bwa_competitive_mapping.out.provenance.map { it -> [it[0], [it[1]]] }

    }
    ch_provenance = ch_provenance.join(plot_depth.out.provenance).map { it -> [it[0], it[1] << it[2]] }
    if (params.fastq_mode == "split") {
        ch_provenance = ch_provenance.join(split_fastq.out.provenance).map { it -> [it[0], it[1] << it[2]] }
    }

      collect_provenance(ch_provenance)

}

