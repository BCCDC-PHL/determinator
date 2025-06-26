#!/usr/bin/env python
import pysam
import sys
import argparse

# script adapted from https://github.com/BCCDC-PHL/rsv-a-artic-nf/blob/main/bin/filter_non_human_reads.py

def filter_viral_reads(ref1_contigs, ref2_contigs, input_sam_fp, output1_fp, output2_fp):

    # use streams if args are None
    input_sam = pysam.AlignmentFile(input_sam_fp, 'r') if input_sam_fp else pysam.AlignmentFile('-', 'r')

    output1 = pysam.AlignmentFile(output1_fp, 'wb', template=input_sam)
    output2 = pysam.AlignmentFile(output2_fp, 'wb', template=input_sam)

    # if read isn't mapped or mapped to viral reference contig name
    ref1_reads = 0
    ref2_reads = 0
    other_reads = 0

    # iterate over input from BWA
    for read in input_sam:
        # only look at primary alignments
        if not read.is_supplementary and not read.is_secondary:
            if read.reference_name in ref1_contigs:
                output1.write(read)
                ref1_reads += 1
            elif read.reference_name in ref2_contigs:
                output2.write(read)
                ref2_reads += 1
            else:
                other_reads += 1

    total = ref1_reads + ref2_reads + other_reads

    print(f"ref1 read count = {ref1_reads} ({ref1_reads/total*100:.2f}%)", file=sys.stderr)
    print(f"ref2 read count = {ref2_reads} ({ref2_reads/total*100:.2f}%)", file=sys.stderr)
    print(f"other mapped reads = {other_reads} ({other_reads/total*100:.2f}%)", file=sys.stderr)

    input_sam.close()
    output1.close()
    output2.close()



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Separate reads mapped to two different viral references")

    parser.add_argument('-i', '--input', required=True,
                        help="Input SAM/BAM file (use '-' for stdin)")

    parser.add_argument('-o1', '--output1', required=True,
                        help="Output BAM file for reads mapping to viral ref 1")

    parser.add_argument('-o2', '--output2', required=True,
                        help="Output BAM file for reads mapping to viral ref 2")

    parser.add_argument('-r1', '--ref1', required=True, nargs='+',
                        help="List of contig names for viral ref 1 (e.g., RSV-A)")

    parser.add_argument('-r2', '--ref2', required=True, nargs='+',
                        help="List of contig names for viral ref 2 (e.g., RSV-B)")

    args = parser.parse_args()

    filter_viral_reads(args.ref1, args.ref2, args.input, args.output1, args.output2)
