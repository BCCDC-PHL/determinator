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

    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}_fastp.{json,csv}", mode: 'copy'

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
 
  publishDir "${params.outdir}", mode: 'copy', pattern: "**/*.gz"
  publishDir  "${params.outdir}/read_summary", mode: 'copy', pattern: "*_read_summary.csv"
  

  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2), path(composite_ref), path(composite_ref_files), val(reference_names)

  output:
  path "**/*.gz", emit: fastq
  path "*.csv", emit: read_summary_csv
  tuple val(sample_id), path('composite_ref.bam'), emit: composite_ref_bam

  script:
  """

  bwa mem -t ${task.cpus} -T ${params.bwa_T} ${composite_ref} ${reads_r1} ${reads_r2} > composite_ref.bam

  filter_reads_according_to_ref.py \
    -i composite_ref.bam \
    --refs ${reference_names} \
    --sample_id ${sample_id} \
    --min-mapq ${params.min_mapq} \
    --csv-output ${sample_id}_read_summary.csv



  shopt -s nullglob
  for bam in ${sample_id}_*.bam; do

      ref=\${bam#${sample_id}_}
      ref=\${ref%.bam}

      mkdir -p bwa_fastq_\${ref}

      samtools sort -@ ${task.cpus} -n \$bam | \
          samtools fastq \
          -1 bwa_fastq_\${ref}/${sample_id}_\${ref}_minmapQ${params.min_mapq}_R1.fastq.gz \
          -2 bwa_fastq_\${ref}/${sample_id}_\${ref}_minmapQ${params.min_mapq}_R2.fastq.gz \
          -s bwa_fastq_\${ref}/${sample_id}_\${ref}_minmapQ${params.min_mapq}_singletons.fastq.gz

  done

  """
}


process qc_check {

  errorStrategy = 'ignore'

  tag { sample_id }
 
  publishDir  "${params.outdir}/depth_summaries", mode: 'copy', pattern: "*.csv"
  publishDir  "${params.outdir}/qc_plots", mode: 'copy', pattern: "*.png"
  
  input:
  tuple val(sample_id), path(composite_ref_bam)

  output:
  tuple val(sample_id), path('*.png'), emit: depth_plot
  path('*.csv'), emit: depth_csv

  script:
  """

  samtools view -b -F 0x900 ${composite_ref_bam} -q ${params.min_mapq} > composite_ref_clean.bam
  samtools sort -o composite_ref_sorted.bam composite_ref_clean.bam
  samtools index composite_ref_sorted.bam

  plot_summarize_depth.py \
  --sample ${sample_id} \
  --bam composite_ref_sorted.bam \

  """
}
