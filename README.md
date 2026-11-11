# Chromatin Profiling Peak Calling: bowtie2 + MACS3, as a Snakemake DAG

[![CI](https://github.com/syed1789/cutandrun-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/syed1789/cutandrun-pipeline/actions/workflows/ci.yml)

**Author:** Syed Nurul Hasan, Ph.D.
**Contact:** nayanchoton1789@gmail.com | [ORCID: 0000-0002-4564-872X](https://orcid.org/0000-0002-4564-872X)

---

## Why this project

CUT&RUN was named specifically in several role-tailored CVs, with no public
repo behind it. This one is a real bowtie2 → peak-calling pipeline on real
public data, run as a Snakemake DAG with a SLURM profile — the same
infrastructure pattern as my `bulk-rnaseq-star-deseq2` repo.

**Important disclosure, up front:** the public dataset used here
([GSE145187](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE145187),
Kaya-Okur et al., *Nat Protoc* 2020) is **CUT&Tag**, not CUT&RUN. I'm naming
that plainly rather than letting the similarity paper over it. CUT&Tag and
CUT&RUN are both Henikoff-lab in-situ chromatin profiling methods (antibody
targeting → controlled cleavage → sequencing) with **the same downstream
bioinformatics**: paired-end alignment with permissive/local settings, IgG-
control peak calling, TSS-proximity QC. nf-core's own `cutandrun` pipeline
uses this exact GSE145187 dataset as its CI test fixture for that reason.
This repo demonstrates that shared analysis pipeline; it is not a substitute
for having actually run CUT&RUN-specific wet-lab or library-prep work.

## Pipeline

```
Paired-end FASTQ (H3K4me3 x2 reps, IgG control x2 reps, 10,000 reads each)
        │
        ▼
1. bowtie2_index / bowtie2_align  (Docker: biocontainers/bowtie2)
   --local --very-sensitive-local --no-mixed --no-discordant -I 10 -X 700
   (standard CUT&RUN/CUT&Tag alignment settings -- short local alignments,
   permissive fragment size range)
        │
        ▼
2. sort_index_bam  (samtools)
        │
        ▼
3. macs3_callpeak  (Docker: biocontainers/macs3)
   H3K4me3 vs. matched IgG control, per replicate, BAMPE mode
        │
        ▼
4. tss_enrichment  (scripts/tss_enrichment.py)
   fraction of peak summits within 2kb of a chr20 gene TSS
```

## Dataset

FASTQ subsets (downsampled to 10,000 reads/sample) + a chr20 reference from
[nf-core/test-datasets](https://github.com/nf-core/test-datasets)
(`cutandrun` branch), derived from **GSE145187** — Kaya-Okur HS, Janssens DH,
Henikoff JG, et al. "Efficient low-cost chromatin profiling with CUT&Tag."
*Nat Protoc*. 2020;15(10):3264-3283. H3K4me3 marks active promoters; IgG is
the isotype-control background for peak calling.

**Why this alignment rate is low, and that's expected:** these FASTQs are
reads subsampled *genome-wide* (not restricted to chr20), so only ~2–3% of
the 10,000 reads per sample land on chr20 (~250-300 fragments after
alignment/dedup). That's exactly what nf-core's own CI test fixture expects
for this pairing — it verifies pipeline mechanics on a fast, tiny dataset,
not statistical power. See "Results" below for why the signal is still real
despite the small numbers.

**MACS2 → MACS3 substitution, also disclosed:** the biocontainers MACS2
image has a binary-compatibility bug under x86_64 emulation on this Apple
Silicon Mac (`undefined symbol: __log_finite` — a glibc/libm mismatch in the
compiled Cython extension). MACS3 is the actively maintained successor with
the same `callpeak` interface and algorithm; switching to it was a same-day
fix, not a workaround of anything algorithmic.

## Results (this run)

- Alignment: 2.51–3.08% overall rate across all 4 samples (expected — see above).
- MACS3 (`-q 0.1`, BAMPE): **82 peaks** (rep1), **93 peaks** (rep2).
- TSS enrichment sanity check: **90.2%** of rep1 summits and **65.6%** of
  rep2 summits fall within 2kb of a chr20 gene TSS (median distance 434bp
  and 583bp) — the expected promoter-proximal enrichment pattern for
  H3K4me3, recovered cleanly even from a 10,000-read subsample. Full table:
  [`results/tss_enrichment.tsv`](results/tss_enrichment.tsv).

## Running it

```bash
bash scripts/download_data.sh

python3 -m venv .venv && source .venv/bin/activate
pip install snakemake

snakemake -s workflow/Snakefile --cores 4 -p

# SLURM cluster execution
snakemake -s workflow/Snakefile --workflow-profile workflow/profiles/slurm
```

## Key Features

- Real bowtie2 alignment + MACS3 peak calling, containerized
- IgG-controlled peak calling per replicate, matching the standard
  CUT&RUN/CUT&Tag analysis convention
- An actual Snakemake DAG with a SLURM executor profile
- A quantitative biological sanity check (TSS enrichment), not just "it ran"
- Both real limitations in this run (low alignment %, MACS2→3 swap, CUT&Tag
  vs. CUT&RUN) disclosed rather than smoothed over

## References

1. Kaya-Okur HS, Janssens DH, Henikoff JG, et al. Efficient low-cost
   chromatin profiling with CUT&Tag. *Nat Protoc*. 2020;15(10):3264-3283.
2. Skene PJ, Henikoff S. An efficient targeted nuclease strategy for
   high-resolution mapping of DNA binding sites. *eLife*. 2017;6:e21856.
   (CUT&RUN)
3. Zhang Y, Liu T, Meyer CA, et al. Model-based Analysis of ChIP-Seq
   (MACS). *Genome Biology*. 2008;9:R137.

## License

MIT — see [LICENSE](LICENSE).

## Running on HPC (SLURM) and AWS

Includes `CONTAINER_RUNTIME=apptainer` switch for the Snakefile, a SLURM head-job script, and a one-shot EC2 launcher. See [HPC_AWS.md](HPC_AWS.md) for steps and what was verified.
