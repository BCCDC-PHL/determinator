#!/usr/bin/env python3
import argparse
import pysam
import sys
import csv

# script adapted from https://github.com/BCCDC-PHL/rsv-a-artic-nf/blob/main/bin/filter_non_human_reads.py


def filter_reads_by_reference(reference_names, input_sam_fp, output_fps, sample_id, min_mapq, csv_output):

    input_sam = pysam.AlignmentFile(input_sam_fp, 'r') if input_sam_fp else pysam.AlignmentFile('-', 'r')

    outputs = {}

    for ref, fp in output_fps.items():
        bam_handle = pysam.AlignmentFile(fp, "wb", template=input_sam)
        outputs[ref] = bam_handle

    # Initialize per-reference read counters
    counts = {}

    for ref_name in reference_names:
        counts[ref_name] = 0

    # Reads that do not map to any reference
    unassigned = 0

    for read in input_sam:

        if read.is_supplementary or read.is_secondary:
            continue

        if read.mapping_quality < min_mapq:
            continue

        ref = read.reference_name

        if ref in outputs:
            outputs[ref].write(read)
            counts[ref] += 1
        else:
            unassigned += 1

    total = sum(counts.values()) + unassigned

    def pct(count):
        return count / total * 100 if total > 0 else 0.0

    for ref, count in counts.items():
        print(f"{ref} = {count} ({pct(count):.2f}%)", file=sys.stderr)

    print(f"unassigned = {unassigned} ({pct(unassigned):.2f}%)", file=sys.stderr)


    with open(csv_output, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["sample_id", "reference", "read_count", "pct_total"])

        for ref, count in counts.items():
            w.writerow([sample_id, ref, count, f"{pct(count):.2f}"])

        w.writerow([sample_id, "unassigned", unassigned, f"{pct(unassigned):.2f}"])

    input_sam.close()
    for o in outputs.values():
        o.close()


def main(args):

    # build output mapping
    output_fps = {
        ref: f"{args.sample_id}_{ref}.bam"
        for ref in args.refs
    }

    filter_reads_by_reference(
        reference_names=args.refs,
        input_sam_fp=args.input,
        output_fps=output_fps,
        sample_id=args.sample_id,
        min_mapq=args.min_mapq,
        csv_output=args.csv_output
    )

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("-i", "--input", required=True, 
                        help="Input SAM/BAM file (use '-' for stdin)")
    parser.add_argument("--refs", nargs="+", required=True,
                        help="List of reference names exactly matching BAM contig names")
    parser.add_argument('--csv-output', required=True, type=str, default="read_summary.csv",
                    help="CSV file to write read counts and percentages")
    parser.add_argument('--sample_id', type=str, default= "sample_X",
                        help="Sample id used for output csv")
    parser.add_argument('--min-mapq', type=int, default=0,
                        help="Minimum MAPQ required to include a read (default: 0)")
    args = parser.parse_args()

    main(args)
    