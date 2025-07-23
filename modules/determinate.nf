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
	--cut_tail -g -x \
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

  publishDir  "${params.outdir}/bbsplit_${params.ref_1_name}_fastq", mode: 'copy', pattern: "*${params.ref_1_name}*.fq.gz"
  publishDir  "${params.outdir}/bbsplit_${params.ref_2_name}_fastq", mode: 'copy', pattern: "*${params.ref_2_name}*.fq.gz"
  
  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2)

  output:
  path "*.gz"

  script:
  """

  bbsplit.sh ambiguous2=${params.bbsplit_ambiguous2} ref=${params.ref_1},${params.ref_2} in=${reads_r1} in2=${reads_r2}  basename=${sample_id}_%_R#.fq
  gzip *.fq

  """
}


process bwa_competitive_mapping {

  tag { sample_id }
 
  publishDir  "${params.outdir}/bwa_${params.ref_1_name}_fastq", mode: 'copy', pattern: "*${params.ref_1_name}*_R*.gz"
  publishDir  "${params.outdir}/bwa_${params.ref_2_name}_fastq", mode: 'copy', pattern: "*${params.ref_2_name}*_R*.gz"
  publishDir  "${params.outdir}/read_summary", mode: 'copy', pattern: "*_read_summary.csv"
  
  
  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2)

  output:
  path "*.gz"
  path "*.csv"
  tuple val(sample_id), path('composite_ref.bam'), emit: composite_ref_bam

  script:
  """

  bwa mem -t ${task.cpus} -T ${params.bwa_T} ${params.composite_ref} ${reads_r1} ${reads_r2} > composite_ref.bam
    filter_reads_according_to_ref.py -i composite_ref.bam -r1 ${params.ref_1_name} -r2 ${params.ref_2_name} -o1 ${sample_id}_${params.ref_1_name}.bam -o2  ${sample_id}_${params.ref_2_name}.bam --min-mapq ${params.min_mapq} --csv-output ${sample_id}_read_summary.csv --sample_id ${sample_id}
    
  samtools sort -@ ${task.cpus} -n ${sample_id}_${params.ref_1_name}.bam | \
      samtools fastq -1 ${sample_id}_${params.ref_1_name}_R1.fastq.gz -2 ${sample_id}_${params.ref_1_name}_R2.fastq.gz -s ${sample_id}_${params.ref_1_name}_singletons.fastq.gz 

  samtools sort -@ ${task.cpus} -n ${sample_id}_${params.ref_2_name}.bam | \
      samtools fastq -1 ${sample_id}_${params.ref_2_name}_R1.fastq.gz -2 ${sample_id}_${params.ref_2_name}_R2.fastq.gz -s ${sample_id}_${params.ref_2_name}_singletons.fastq.gz 

  """
}

process qc_check {

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

  samtools sort -o composite_ref_sorted.bam ${composite_ref_bam} 
  samtools index composite_ref_sorted.bam

  plot_summarize_depth.py \
  --sample ${sample_id} \
  --bam composite_ref_sorted.bam \

  """
}
