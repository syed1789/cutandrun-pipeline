#!/bin/bash
# Fetches CUT&Tag FASTQ subsets (H3K4me3 + IgG control, 2 reps each,
# downsampled to 10,000 reads) and a chr20 reference from
# nf-core/test-datasets (cutandrun branch), derived from GSE145187
# (Kaya-Okur et al., Nat Protoc 2020).
set -euo pipefail
cd "$(dirname "$0")/.."

FASTQ_BASE="https://raw.githubusercontent.com/nf-core/test-datasets/cutandrun/testdata/GSE145187_10000"
REF_BASE="https://raw.githubusercontent.com/nf-core/test-datasets/cutandrun/reference/genomes"

mkdir -p data/fastq data/reference

for f in h3k4me3_rep1_r1 h3k4me3_rep1_r2 h3k4me3_rep2_r1 h3k4me3_rep2_r2 \
         igg_rep1_r1 igg_rep1_r2 igg_rep2_r1 igg_rep2_r2; do
  out="data/fastq/${f}.fastq.gz"
  [ -f "$out" ] && { echo "Already downloaded: $out"; continue; }
  echo "Downloading $out"
  curl -sL --fail -o "$out" "${FASTQ_BASE}/${f}.fastq.gz"
done

if [ ! -f data/reference/hg38-chr20.fa ]; then
  echo "Downloading chr20 reference"
  curl -sL --fail -o data/reference/hg38-chr20.fa.gz "${REF_BASE}/hg38-chr20.fa.gz"
  gunzip -f data/reference/hg38-chr20.fa.gz
fi

if [ ! -f data/reference/hg38-chr20-genes.bed ]; then
  curl -sL --fail -o data/reference/hg38-chr20-genes.bed.gz "${REF_BASE}/hg38-chr20-genes.bed.gz"
  gunzip -f data/reference/hg38-chr20-genes.bed.gz
fi

if [ ! -f data/reference/hg38-blacklist.bed ]; then
  curl -sL --fail -o data/reference/hg38-blacklist.bed "${REF_BASE}/hg38-blacklist.bed"
fi

echo "Done."
