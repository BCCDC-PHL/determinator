# In development

```mermaid
flowchart TD
  ref1_bwa[ref_1.fa]
  ref2_bwa[ref_2.fa]
  composite_ref[composite_ref.fa]

  fastq[fastq_dir]
  fastq --> bwa_competitive_mapping(bwa_competitive_mapping)
  ref1_bwa --> bwa_competitive_mapping
  ref2_bwa --> bwa_competitive_mapping
  composite_ref --> bwa_competitive_mapping
  bwa_competitive_mapping --> qc_check(qc_check)
  bwa_competitive_mapping --> bwa_ref_1_fastq
  bwa_competitive_mapping --> bwa_ref_2_fastq
  qc_check --> qc_depth_plot
  qc_check --> qc_depth_summary_csv
  
  ref1_bbsplit[ref_1.fa]
  ref2_bbsplit[ref_2.fa]
  fastq[fastq_dir]
  fastq --> bbsplit(bbsplit)
  ref1_bbsplit --> bbsplit
  ref2_bbsplit --> bbsplit


  bbsplit --> bbsplit_ref_1_fastq
  bbsplit --> bbsplit_ref_2_fastq

```

## Parameters

| Option                           | Default  | Description                                                                                                         |
|:---------------------------------|---------:|--------------------------------------------------------------------------------------------------------------------:|
| `ref_1`       | `NO_FILE`    | path to reference 1                                                         |
| `ref_2`          | `NO_FILE`      | path to reference 2                                                       |
| `ref_1_name`                        | `NO_FILE`     | rame for reference 1 in output file naming                                                                        |
| `ref_2_name`                  | `NO_FILE`     | name for reference 2 in output file                                             |
| `composite_ref`            | `NO_FILE`   | path to bwa indexed composite reference (1 and 2) - for use with bwa_competitive_mapping process only                                                                   |
| `fastq_input`               | `NO_FILE`   | path to directory of fastqs to competitively map and split into reads that map to reference 1 and 2                                                                   |
| `samplesheet_input`                    | `NO_FILE`     | samplesheet containing ID,R1,R2 with sample name and paths to fastq reads      |
| `bwa`                    |  `true`   | default read splitting method using bwa and samtools                                          |
| `bbsplit`                    |    `false`  | use bbsplit for read splitting method |
| `bbsplit_ambigious2`                    |    `toss`  | Set behavior only for reads that map ambiguously to multiple different references default=  toss     options:  best   (use the first best site) toss   (consider unmapped) all   (write a copy to the output for each reference to which it maps) split   (write a copy to the AMBIGUOUS_ output for each reference to which it maps) |
