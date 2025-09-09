#!/usr/bin/env bash
set -euo pipefail

# Activate snakemake env
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate snake-hpc

# User-tunable defaults
JOBS="${JOBS:-50}"
LATENCY="${LATENCY:-120}"
RETRY="${RETRY:-2}"
CLUSTER_CONFIG="cluster/cluster.yaml"
LOGDIR="logs/_slurm"
mkdir -p "${LOGDIR}"

# sbatch formatter using cluster-config and per-rule resources
cluster_cmd="sbatch \
  --parsable \
  --job-name={cluster.jobname} \
  --partition={cluster.partition} \
  {cluster.qos:--qos={cluster.qos}} \
  {cluster.account:--account={cluster.account}} \
  --cpus-per-task={threads} \
  --mem={resources.mem_mb} \
  --time={resources.time} \
  {cluster.mail_user:--mail-user={cluster.mail_user}} \
  {cluster.mail_type:--mail-type={cluster.mail_type}} \
  {cluster.extra_sbatch} \
  -o ${LOGDIR}/%x-%j.out -e ${LOGDIR}/%x-%j.err"

# Run snakemake with slurm submission
snakemake \
  --profile "" \
  --use-conda \
  --conda-frontend mamba \
  --jobs "${JOBS}" \
  --latency-wait "${LATENCY}" \
  --rerun-incomplete \
  --restart-times "${RETRY}" \
  --cluster-config "${CLUSTER_CONFIG}" \
  --cluster "${cluster_cmd}" \
  "$@"