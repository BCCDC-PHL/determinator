#!/usr/bin/env python3

import argparse
import subprocess
import pandas as pd
import matplotlib.pyplot as plt

def read_depth_file(bamfile):

    # get depth
    p = subprocess.Popen(['samtools', 'depth', '-a', '-d', '0', bamfile],stdout=subprocess.PIPE)
    out, _ = p.communicate()

    pos_depth = []
    for ln in out.decode('utf-8').split("\n"):
        if ln:
            pos_depth.append(ln.strip().split("\t"))

    # get reference length 
    p2 = subprocess.Popen(['samtools', 'idxstats', bamfile],stdout=subprocess.PIPE)
    out2, _ = p2.communicate()

    ref_lengths = {}
    for ln in out2.decode('utf-8').strip().split("\n"):
        if ln:
            ref, length, _, _ = ln.split("\t")
            ref_lengths[ref] = int(length)

    return pos_depth, ref_lengths

def plot_depth_per_contig(depth_df, sample_name, min_depth, bam_list,
                          ylim_top=10**5, width_per_plot=6, height=4):

    panels = bam_list
    n_panels = len(panels)

    fig, axs = plt.subplots(
        1,
        n_panels + 1,   # extra column for overlay
        figsize=(width_per_plot * (n_panels + 1), height),
        sharey=True
    )

    colors = plt.cm.tab10.colors

    # -------------------------
    # Individual BAM panels
    # -------------------------
    for i, bam_name in enumerate(panels):

        ax = axs[i]

        df = depth_df[depth_df['bam_name'] == bam_name].copy()
        df['position'] = df['position'].astype(int)
        df['depth'] = df['depth'].astype(int)
        df.sort_values('position', inplace=True)

        df['depth_ma'] = df['depth'].rolling(window=200, min_periods=1).mean()

        ax.plot(
            df['position'],
            df['depth_ma'],
            linewidth=0.8,
            color=colors[i % len(colors)]
        )

        ax.set_title(bam_name.split('/')[-1].replace('.sorted.bam', '').replace(f"{sample_name}_", "") )
        ax.set_yscale("log")
        ax.set_ylim(bottom=1, top=ylim_top)
        ax.axhline(y=min_depth, color='blue', linestyle='dotted', linewidth=0.7)

        ax.set_xlabel("Position")

    # -------------------------
    # Overlay panel (last axis)
    # -------------------------
    ax = axs[-1]

    for i, bam_name in enumerate(panels):

        df = depth_df[depth_df['bam_name'] == bam_name].copy()
        df['position'] = df['position'].astype(int)
        df['depth'] = df['depth'].astype(int)
        df.sort_values('position', inplace=True)

        df['depth_ma'] = df['depth'].rolling(window=200, min_periods=1).mean()

        ax.plot(
            df['position'],
            df['depth_ma'],
            linewidth=0.8,
            label=bam_name.split('/')[-1].replace('.bam', ''),
            color=colors[i % len(colors)]
        )

    ax.set_title("Overlay")
    ax.set_yscale("log")
    ax.set_ylim(bottom=1, top=ylim_top)
    ax.axhline(y=min_depth, color='blue', linestyle='dotted', linewidth=0.7)
    ax.set_xlabel("Position")

    # legend outside
    ax.legend(
        loc='center left',
        bbox_to_anchor=(1.02, 0.5),
        borderaxespad=0
    )

    # -------------------------
    # Global title
    # -------------------------
    fig.suptitle(sample_name, fontsize=14)

    plt.tight_layout(rect=[0, 0, 1, 0.92])

    plt.savefig(
        f"{sample_name}.depth_per_contig.png",
        dpi=300,
        bbox_inches='tight'
    )
    plt.close()

def compute_depth_summary(depth_df, min_depth, sample, bam_list, bam_reference_lengths):

    summary = []

    for bam in bam_list:

        ref = bam.split('/')[-1].replace('.sorted.bam', '').replace(f"{sample}_", "")

        df_bam = depth_df[depth_df['bam_name'] == bam]

        length = bam_reference_lengths[bam].get(ref, None)

        # no reads 
        if df_bam.empty or length is None:

            summary.append({
                'sample_id': sample,
                'reference': ref,
                'total_positions': length if length is not None else 0,
                'covered_positions': 0,
                'percent_covered': 0,
                'average_depth': 0,
                'median_depth': 0
            })

            continue

        df_ref = df_bam[df_bam['contig'] == ref].copy()

        if df_ref.empty:

            summary.append({
                'sample_id': sample,
                'reference': ref,
                'total_positions': length,
                'covered_positions': 0,
                'percent_covered': 0,
                'average_depth': 0,
                'median_depth': 0
            })

            continue

        df_ref['depth'] = df_ref['depth'].astype(int)

        covered = (df_ref['depth'] >= min_depth).sum()

        summary.append({
            'sample_id': sample,
            'reference': ref,
            'total_positions': length,
            'covered_positions': covered,
            'percent_covered': round(covered / length * 100, 2),
            'average_depth': round(df_ref['depth'].mean(), 2),
            'median_depth': round(df_ref['depth'].median(), 2)
        })

    return summary

def write_summary_csv(sample_name, summary):
    df = pd.DataFrame(summary)
    df.to_csv(f"{sample_name}.depth_summary.csv", index=False)

def main(args):

    # collect depths for each bam/reference input
    all_depth_dfs = []
    bam_reference_lengths = {}

    for bam in args.bam:

        pos_depth, ref_lengths = read_depth_file(bam)

        depth_df = pd.DataFrame(
            pos_depth,
            columns=['contig', 'position', 'depth']
        )

        depth_df['bam_name'] = bam

        all_depth_dfs.append(depth_df)

        bam_reference_lengths[bam] = ref_lengths

    merged_depth_df = pd.concat(
        all_depth_dfs,
        ignore_index=True
    )

    plot_depth_per_contig(
        merged_depth_df,
        args.sample,
        args.min_depth,
        args.bam,
        ylim_top=10**args.max_y_axis_exponent,
        width_per_plot=args.width,
        height=args.height
    )

    summary = compute_depth_summary(
        merged_depth_df,
        args.min_depth,
        args.sample,
        args.bam,
        bam_reference_lengths
    )

    write_summary_csv(args.sample, summary)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plot depth per contig side-by-side from BAM and output summary CSV")
    parser.add_argument('--sample', required=True, help='Sample name')
    parser.add_argument('--bam', nargs='+', required=True,help='One or more sorted and indexed BAM files')
    parser.add_argument('--min-depth', type=int, default=1)
    parser.add_argument('--max-y-axis-exponent', type=int, default=5)
    parser.add_argument('--width', type=float, default=8)  # width per subplot
    parser.add_argument('--height', type=float, default=4)
    args = parser.parse_args()
    main(args)
