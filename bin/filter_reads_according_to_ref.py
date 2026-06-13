#!/usr/bin/env python3
import argparse
import pysam
import sys
import csv
import json

# script adapted from https://github.com/BCCDC-PHL/rsv-a-artic-nf/blob/main/bin/filter_non_human_reads.py



def process_reads(input_sam, outputs, counts, min_mapq):
    """
    Parses reads from bam files, get per reference read counts, and separates into individual bams
    """

    unassigned = 0

    for read in input_sam:

        if read.is_supplementary or read.is_secondary:
            continue

        if read.mapping_quality < min_mapq:
            continue

        ref = read.reference_name

        if ref in outputs:
            counts[ref] += 1
            outputs[ref].write(read)

        else:
            unassigned += 1

    return unassigned


def compute_reference_metrics(counts, unassigned):
    """
    Dermines top and second best fractions and delta.
    """

    total = sum(counts.values()) + unassigned

    if total == 0:
        return {
            "top_ref": "NA",
            "second_ref": "NA",
            "top_frac": 0.0,
            "second_frac": 0.0,
            "delta": 0.0,
            "total": 0
        }

    sorted_refs = sorted(counts.items(), key=lambda x: x[1], reverse=True)

    # rank each ref - used for json output
    ranked = []
    for ref, count in sorted_refs:
        fraction = count / total
        ranked.append({
            "name": ref,
            "read_count": count,
            "fraction": round(fraction, 4),
            "percent": round(fraction * 100, 2)
        })

    top = ranked[0] if len(ranked) > 0 else None
    second = ranked[1] if len(ranked) > 1 else None
    third = ranked[2] if len(ranked) > 2 else None 

    top_frac = top["fraction"] if top else 0.0
    second_frac = second["fraction"] if second else 0.0
    third_frac = third["fraction"] if third else 0.0

    delta = top_frac - second_frac



    return {
        "total": total,
        "references": ranked,

        "top": top,
        "second": second,
        "third": third,

        "top_ref": top["name"] if top else "NA",
        "second_ref": second["name"] if second else "NA",
        "third_ref": third["name"] if third else "NA",

        "top_frac": top_frac,
        "second_frac": second_frac,
        "third_frac": third_frac,
        "top_vs_second_delta": delta

    }



def classify_sample(metrics, args):

    if metrics["total"] == 0:
        return "empty"

    top_frac = metrics["top_frac"]
    delta = metrics["top_vs_second_delta"]

    if top_frac >= args.min_top_fraction and delta >= args.min_delta:
        return "assigned"
    elif top_frac >= args.min_top_fraction:
        return "mixed_close"
    else:
        return "mixed"


def write_outputs(sample_id, counts, unassigned, metrics, csv_output):

    def pct(count, total):
        return count / total * 100 if total else 0.0

    total = metrics["total"]

    # Output read summary only
    with open(csv_output, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["sample_id", "reference", "read_count", "pct_total"])

        for ref, count in counts.items():
            w.writerow([sample_id, ref, count, f"{pct(count, total):.2f}"])

        w.writerow([sample_id, "unassigned", unassigned, f"{pct(unassigned, total):.2f}"])


    summary_fp =  f"{sample_id}_reference_summary.csv"

    with open(summary_fp, "w", newline="") as f:
        w = csv.writer(f)

        w.writerow([
            "sample_id",
            "top_reference",
            "top_fraction",
            "second_reference",
            "second_fraction",
            "top_vs_second_delta",
            "third_reference",
            "third_fraction",
            "status"
        ])

        w.writerow([
            sample_id,
            metrics["top_ref"],
            f"{metrics['top_frac']:.4f}",
            metrics["second_ref"],
            f"{metrics['second_frac']:.4f}",
            f"{metrics['top_vs_second_delta']:.4f}",
            metrics["third_ref"],
            f"{metrics['third_frac']:.4f}",
            metrics.get("status", "NA")
        ])

    json_fp = f"{sample_id}_reference_summary.json"

    json_data = {
        "sample_id": sample_id,
        "status": metrics.get("status", "NA"),
        "total_reads": metrics["total"],

        "references": metrics["references"],

        "top": metrics["top"],
        "second": metrics["second"],

        "top_vs_second_delta": metrics["top_vs_second_delta"]
    }

    with open(json_fp, "w") as f:
        json.dump(json_data, f, indent=2)



def filter_reads_by_reference(reference_names, input_sam_fp, output_fps, sample_id, min_mapq, csv_output, args):

    input_sam = pysam.AlignmentFile(input_sam_fp, 'r') \
        if input_sam_fp else pysam.AlignmentFile('-', 'r')

    # BAM outputs 
    outputs = {}


    for ref, fp in output_fps.items():
        outputs[ref] = pysam.AlignmentFile(fp, "wb", template=input_sam)

    # initialize read counts per reference
    counts = {ref: 0 for ref in reference_names}

    # core processing
    unassigned = process_reads(input_sam, outputs, counts, min_mapq)

    # compute metrics
    metrics = compute_reference_metrics(counts, unassigned)

    # classify sample
    status = classify_sample(metrics, args)

    # add metadata
    metrics["status"] = status

    # write outputs
    write_outputs(sample_id, counts, unassigned, metrics, csv_output)

    input_sam.close()

    for o in outputs.values():
        o.close()


def main(args):

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
        csv_output=args.csv_output,
        args=args  
    )


if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("-i", "--input", required=True,
                        help="Input SAM/BAM file (use '-' for stdin)")

    parser.add_argument("--refs", nargs="+", required=True,
                        help="List of reference names exactly matching BAM contig names")

    parser.add_argument('--csv-output', required=True, type=str, default="read_summary.csv",
                        help="CSV file to write read counts and percentages")

    parser.add_argument('--sample_id', type=str, default="sample_X",
                        help="Sample id used for output csv")

    parser.add_argument('--min-mapq', type=int, default=0,
                        help="Minimum MAPQ required to include a read")
    
    parser.add_argument('--min-top-fraction', type=float, default=0.70,
                        help="Threshold for dominant reference")

    parser.add_argument('--min-delta', type=float, default=0.15,
                        help="Threshold difference between top and second")

    args = parser.parse_args()

    main(args)