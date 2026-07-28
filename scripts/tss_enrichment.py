#!/usr/bin/env python3
"""Snakemake script: fraction of MACS3 peak summits within 2kb of a chr20
gene TSS -- the expected enrichment pattern for a promoter mark (H3K4me3),
used here as a biological sanity check rather than a formal QC metric."""
import bisect
import csv

genes = []
with open(snakemake.input.genes) as f:
    for line in f:
        p = line.strip().split("\t")
        start, end, strand = int(p[1]), int(p[2]), p[5]
        tss = start if strand == "+" else end
        genes.append(tss)
genes.sort()


def nearest_dist(pos):
    i = bisect.bisect_left(genes, pos)
    best = 10**9
    for j in (i - 1, i):
        if 0 <= j < len(genes):
            best = min(best, abs(genes[j] - pos))
    return best


rows = []
for peak_file in snakemake.input.peaks:
    rep = peak_file.split("h3k4me3_")[1].split("_peaks")[0]
    summit_file = peak_file.replace("_peaks.narrowPeak", "_summits.bed")
    dists = []
    with open(summit_file) as f:
        for line in f:
            p = line.strip().split("\t")
            dists.append(nearest_dist(int(p[1])))
    n_within_2kb = sum(1 for d in dists if d <= 2000)
    rows.append({
        "replicate": rep,
        "n_summits": len(dists),
        "n_within_2kb_of_tss": n_within_2kb,
        "pct_within_2kb_of_tss": round(100 * n_within_2kb / len(dists), 1) if dists else 0,
        "median_dist_to_tss": sorted(dists)[len(dists) // 2] if dists else None,
    })

with open(snakemake.output[0], "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()), delimiter="\t")
    writer.writeheader()
    writer.writerows(rows)

for r in rows:
    print(f"{r['replicate']}: {r['n_summits']} summits, "
          f"{r['pct_within_2kb_of_tss']}% within 2kb of a TSS, "
          f"median dist {r['median_dist_to_tss']}bp")
