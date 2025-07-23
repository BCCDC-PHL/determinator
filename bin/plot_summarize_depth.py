#!/usr/bin/env python3

import argparse
import subprocess
import pandas as pd
import matplotlib.pyplot as plt

def read_depth_file(bamfile):
    p = subprocess.Popen(['samtools', 'depth', '-a', '-d', '0', bamfile],
                         stdout=subprocess.PIPE)
    out, _ = p.communicate()
    pos_depth = []
    for ln in out.decode('utf-8').split("\n"):
        if ln:
            pos_depth.append(ln.strip().split("\t"))  # contig, pos, depth
    return pos_depth

def plot_depth_per_contig(depth_df, sample_name, min_depth, ylim_top=10**5, width_per_plot=8, height=4):
    contigs = depth_df['contig'].unique()
    n_contigs = len(contigs)

    if n_contigs == 0:
        print(f"No contigs found in {sample_name}, skipping plot.")
        return
    
    fig, axs = plt.subplots(1, n_contigs, figsize=(width_per_plot * n_contigs, height), squeeze=False)
    
    for i, contig in enumerate(contigs):
        df_contig = depth_df[depth_df['contig'] == contig].copy()
        df_contig['position'] = df_contig['position'].astype(int)
        df_contig['depth'] = df_contig['depth'].astype(int)
        df_contig.sort_values('position', inplace=True)
        df_contig['depth_moving_average'] = df_contig['depth'].rolling(window=200, min_periods=1).mean()
        
        ax = axs[0, i]
        ax.set_title(contig)
        ax.set_xlabel('Position')
        ax.set_ylabel('Depth (log scale)')
        ax.set_yscale('log')
        ax.set_ylim(bottom=1, top=ylim_top)
        ax.axhline(y=min_depth, color='blue', linestyle='dotted', linewidth=0.7)
        ax.plot(df_contig['position'], df_contig['depth_moving_average'], color='green', linewidth=0.6)
    
    plt.suptitle(sample_name)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(f"{sample_name}.depth_per_contig.png", dpi=300)
    plt.close()

def compute_depth_summary(depth_df, min_depth, sample):
    summary = []
    for contig in depth_df['contig'].unique():
        df = depth_df[depth_df['contig'] == contig].copy()
        df['depth'] = df['depth'].astype(int)
        total_positions = len(df)
        covered_positions = (df['depth'] >= min_depth).sum()
        avg_depth = df['depth'].mean() if total_positions > 0 else 0
        median_depth = df['depth'].median() if total_positions > 0 else 0
        summary.append({
            'sample_id' : sample, 
            'reference': contig,
            'total_positions': total_positions,
            'covered_positions': covered_positions,
            'percent_covered': round(covered_positions / total_positions * 100, 2) if total_positions > 0 else 0,
            'average_depth': round(avg_depth, 2),
            'median_depth': round(median_depth, 2)
        })
    return summary

def write_summary_csv(sample_name, summary):
    df = pd.DataFrame(summary)
    df.to_csv(f"{sample_name}.depth_summary.csv", index=False)

def main(args):
    pos_depth = read_depth_file(args.bam)
    depth_df = pd.DataFrame(pos_depth, columns=['contig', 'position', 'depth'])

    plot_depth_per_contig(depth_df, args.sample, args.min_depth, 
                         ylim_top=10**args.max_y_axis_exponent,
                         width_per_plot=args.width,
                         height=args.height)

    summary = compute_depth_summary(depth_df, args.min_depth, args.sample)
    write_summary_csv(args.sample, summary)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Plot depth per contig side-by-side from BAM and output summary CSV")
    parser.add_argument('--sample', required=True, help='Sample name')
    parser.add_argument('--bam', required=True, help='Sorted and indexed BAM file')
    parser.add_argument('--min-depth', type=int, default=10)
    parser.add_argument('--max-y-axis-exponent', type=int, default=5)
    parser.add_argument('--width', type=float, default=8)  # width per subplot
    parser.add_argument('--height', type=float, default=4)
    args = parser.parse_args()
    main(args)
