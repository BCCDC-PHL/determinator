process bbsplit {

  tag { sample_id }

  publishDir  "${params.outdir}", mode: 'copy', pattern: "*.fq.gz"
  
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
 
  publishDir  "${params.outdir}", mode: 'copy', pattern: "*.gz"
  
  input:
  tuple val(sample_id), path(reads_r1), path(reads_r2)

  output:
  path "*.gz"

  script:
  """

  bwa mem -t ${task.cpus} ${params.composite_ref} ${reads_r1} ${reads_r2} | \
      filter_reads_according_to_ref.py -i - -r1 ${params.ref_1} -r2 ${params.ref_2} -o1 ${sample_id}_${params.ref_1_name}.bam -o2  ${sample_id}_${params.ref_2_name}.bam
    
  samtools sort -@ ${task.cpus} -n ${sample_id}_${params.ref_1_name}.bam| \
      samtools fastq -1 ${sample_id}_${params.ref_1_name}_R1.fastq.gz -2 ${sample_id}_${params.ref_1_name}_R2.fastq.gz -s ${sample_id}_${params.ref_1_name}_singletons.fastq.gz 

  samtools sort -@ ${task.cpus} -n ${sample_id}_${params.ref_2_name}.bam| \
      samtools fastq -1 ${sample_id}_${params.ref_2_name}_R1.fastq.gz -2 ${sample_id}_${params.ref_2_name}_R2.fastq.gz -s ${sample_id}_${params.ref_2_name}_singletons.fastq.gz 



  """
}