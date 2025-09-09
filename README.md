# Metagenome Taxonomic + Functional Profiling on HPC (Slurm)

This pipeline performs:
- Read trimming (fastp)
- Host read removal (human, using KneadData/Bowtie2)
- Taxonomic profiling (MetaPhlAn 4)
- Functional profiling (HUMAnN 3)

It is designed for HPC (Slurm) and Snakemake with per-rule Conda environments.

## 1) Requirements

- A working conda/mamba on the HPC login node
- Slurm (sbatch/squeue available)
- Internet access to download databases on first run

Recommended: mamba >= 1.5, conda >= 23

## 2) Setup the Snakemake runner env

Create a small environment to run Snakemake itself:

```bash
mamba env create -f envs/snakemake.yaml
conda activate snake-hpc
```

## 3) Prepare inputs

- Edit `config/config.yaml` to check thread counts and DB locations (defaults should be fine).
- Prepare your sample sheet at `config/samples.tsv`:

Columns:
- sample_id: unique sample name (no spaces or dots)
- fq1: absolute path to R1 fastq.gz
- fq2: absolute path to R2 fastq.gz

Example is provided in file.

## 4) Database bootstrap (automatic)

DBs will be downloaded automatically as needed by Snakemake rules:
- MetaPhlAn 4 DB (latest default via `metaphlan --install`)
- HUMAnN databases (ChocoPhlAn pangenomes + UniRef90 DIAMOND + utility mapping)
- Human bowtie2 DB via KneadData

You can also pre-run the DB download step (optional):
```bash
snakemake -n  # dry-run to see plan
snakemake --use-conda --cores 4 db_done
```

## 5) Submit to Slurm

Use the provided wrapper which submits each Snakemake job to Slurm:

```bash
bash submit_snakemake_slurm.sh
```

This will:
- use `--use-conda`
- map per-rule threads/memory/time to sbatch
- write logs under `logs/`

You can customize partitions/QOS in `cluster/cluster.yaml` or via env vars in the submit script.

## 6) Outputs

Key outputs:
- Trimmed reads: `results/01.trimmed/{sample}/*.fastq.gz`
- Host-removed reads: `results/02.host_removed/{sample}/*.fastq.gz`
- MetaPhlAn 4 per-sample: `results/03.metaphlan4/profile/{sample}.metaphlan4.profile.tsv`
- MetaPhlAn merged: `results/03.metaphlan4/report/metaphlan4_merged_abundance.tsv`
- HUMAnN per-sample tables:
  - `results/04.humann3/profile/{sample}/{sample}_genefamilies.tsv`
  - `results/04.humann3/profile/{sample}/{sample}_pathabundance.tsv`
  - `results/04.humann3/profile/{sample}/{sample}_pathcoverage.tsv`
- HUMAnN joined tables (across samples):
  - `results/04.humann3/report/humann3_{genefamilies,pathabundance,pathcoverage}_joined.tsv`
  - And CPM-normalized versions: `_cpm_joined.tsv`

## 7) Reproducibility notes

- MetaPhlAn DB: the pipeline calls `metaphlan --install` without `--index` so it fetches the current default v4 DB. If you want a fixed version, set `databases.metaphlan.index` in `config/config.yaml` and the workflow will pass it.
- HUMAnN DBs: also use "latest" of the configured flavors. You can pin versions by setting specific URLs or mirroring.

## 8) Clean / rerun

- Dry-run: `snakemake -n`
- Force rerun target: `snakemake -R step_metaphlan4_profile`
- Clean intermediates: `snakemake --delete-temp-output`

## 9) Support

Contact: your HPC admins for Slurm quotas/partitions, or open an issue in your repo.
