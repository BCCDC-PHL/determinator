process index_reference {

    publishDir "${params.outdir}/indexed_composite_reference", mode: 'copy'

    tag { composite_ref_fasta }

    input:
    path composite_ref_fasta

    output:
    tuple path(composite_ref_fasta), path("*")

    script:
    """
    bwa index ${composite_ref_fasta}

    """
}

process fastp {

    tag { sample_id }

    publishDir "${params.outdir}/fastp/${sample_id}", pattern: "${sample_id}_fastp.{json,csv}", mode: 'copy'

    input:
    tuple val(sample_id), path(reads_1), path(reads_2)

    output:
    tuple val(sample_id), path("${sample_id}_fastp.json"), emit: json
    tuple val(sample_id), path("${sample_id}_fastp.csv"), emit: csv
    tuple val(sample_id), path("${sample_id}_trimmed_R1.fastq.gz"), path("${sample_id}_trimmed_R2.fastq.gz"), emit: reads
    tuple val(sample_id), path("${sample_id}_fastp_provenance.yml"), emit: provenance

    script:
    """
    printf -- "- process_name: fastp\\n"  >> ${sample_id}_fastp_provenance.yml
    printf -- "  tools:\\n"               >> ${sample_id}_fastp_provenance.yml
    printf -- "    - tool_name: fastp\\n" >> ${sample_id}_fastp_provenance.yml
    printf -- "      tool_version: \$(fastp --version 2>&1 | cut -d ' ' -f 2)\\n" >> ${sample_id}_fastp_provenance.yml
    printf -- "      parameters:\\n"               >> ${sample_id}_fastp_provenance.yml
    printf -- "        - parameter: --cut_tail\\n" >> ${sample_id}_fastp_provenance.yml
    printf -- "          value: null\\n"           >> ${sample_id}_fastp_provenance.yml

    fastp \
	--cut_tail --trim_poly_g \
	-i ${reads_1} \
	-I ${reads_2} \
	-o ${sample_id}_trimmed_R1.fastq.gz \
	-O ${sample_id}_trimmed_R2.fastq.gz

    mv fastp.json ${sample_id}_fastp.json
    fastp_json_to_csv.py -s ${sample_id} ${sample_id}_fastp.json > ${sample_id}_fastp.csv
    """
}


process bbsplit {

  tag { sample_id }

  publishDir  "${params.outdir}/bbsplit_${params.ref_1_ID}_fastq", mode: 'copy', pattern: "*${params.ref_1_ID}*.fq.gz"
  publishDir  "${params.outdir}/bbsplit_${params.ref_2_ID}_fastq", mode: 'copy', pattern: "*${params.ref_2_ID}*.fq.gz"
  
  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2), path(ref_1), path(ref_2)

  output:
  path "*.gz"

  script:
  """

  bbsplit.sh ambiguous2=${params.bbsplit_ambiguous2} ref=${ref_1},${ref_2} in=${reads_r1} in2=${reads_r2}  basename=${sample_id}_%_R#.fq
  gzip *.fq

  """
}


process bwa_competitive_mapping {

  tag { sample_id }
 
  publishDir  "${params.outdir}/read_summary", mode: 'copy', pattern: "*_read_summary.csv"
  publishDir  "${params.outdir}/reference_summary", mode: 'copy', pattern: "*_reference_summary*"

  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2), path(composite_ref), path(composite_ref_files), val(reference_names)

  output:
  path("*_read_summary.csv"), emit: read_summary_csv
  path("*_reference_summary.json"), emit: reference_summary_json
  path("*_reference_summary.csv"), emit: reference_summary_csv
  tuple val(sample_id), path('composite_ref.bam'), emit: composite_ref_bam
  tuple val(sample_id), path("${sample_id}*.bam"), emit: split_bams
  tuple val(sample_id), env(TOP_REF), emit: top_ref


  script:
  """

  bwa mem -t ${task.cpus} -T ${params.bwa_T} ${composite_ref} ${reads_r1} ${reads_r2} > composite_ref.bam

  filter_reads_according_to_ref.py \
    -i composite_ref.bam \
    --refs ${reference_names} \
    --sample_id ${sample_id} \
    --min-mapq ${params.min_mapq} \
    --csv-output ${sample_id}_read_summary.csv

    export TOP_REF=\$(cut -d',' -f2 ${sample_id}_reference_summary.csv | tail -n 1)

  """

}

process plot_depth {

    tag { sample_id }

    publishDir  "${params.outdir}/individual_depth_summary", mode: 'copy', pattern: "*depth_summary.csv"
    publishDir  "${params.outdir}/individual_qc_plots", mode: 'copy', pattern: "*.png"
    publishDir  "${params.outdir}/bams", mode: 'copy', pattern: "*.bam"

    input:
    tuple val(sample_id), path(bams)

    output:
    tuple val(sample_id), path("*.png"), emit: plots
    path("*depth_summary.csv"), emit: depth_summary_csv
    tuple val(sample_id), path("*.bam"), emit: split_sorted_bams


    script:
    """
    for bam in ${bams}; do
        sorted_bam=\${bam%.bam}.sorted.bam

        samtools sort \
            -@ ${task.cpus} \
            -o \$sorted_bam \
            \$bam

        samtools index \$sorted_bam
    done

    shopt -s nullglob

    plot_summarize_depth_individual_bams.py \
        --sample ${sample_id} \
        --bam *.sorted.bam
    """
}


process split_fastq {

    tag { sample_id }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(bams)

    output:
    path("split_fastq/**")

    script:
    """
    mkdir -p split_fastq/bwa_fastq_singletons
    
    for bam in ${bams}; do

        ref=\$(basename \$bam .bam)
        ref=\${ref#${sample_id}_}

        mkdir -p split_fastq/bwa_fastq_\${ref}

        samtools sort -@ ${task.cpus} -n \$bam | \
        samtools fastq \
          -1 split_fastq/bwa_fastq_\${ref}/${sample_id}_\${ref}_minmapQ${params.min_mapq}_R1.fastq.gz \
          -2 split_fastq/bwa_fastq_\${ref}/${sample_id}_\${ref}_minmapQ${params.min_mapq}_R2.fastq.gz \
          -s split_fastq/bwa_fastq_singletons/${sample_id}_\${ref}_minmapQ${params.min_mapq}_singletons.fastq.gz

    done
    """
}


process sort_fastq {

    tag { sample_id }

    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(sample_id), path(reads_r1), path(reads_r2), val(top_ref)

    output:
    path("sorted_fastq/**")

    script:
    """
    mkdir -p sorted_fastq/${top_ref}

    cp ${reads_r1} \
        sorted_fastq/${top_ref}/${reads_r1}

    cp ${reads_r2} \
        sorted_fastq/${top_ref}/${reads_r2}
    """
}

