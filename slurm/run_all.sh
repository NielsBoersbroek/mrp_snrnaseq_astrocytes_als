#!/bin/bash
# Driver: submits one SLURM job per row of the resource table, chained so that
# each job starts only after the previous one succeeded (Quarto can't render
# several documents in parallel, and each script reads the previous outputs).
# Then submits a final job that assembles the site.
# Run it directly (NOT via sbatch):  bash slurm/run_all.sh [table_file]
# Set SKIP_SITE=1 to skip the final site job (useful for partial test runs).

set -eo pipefail

# Project root = parent of the folder this script lives in
SLURM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SLURM_DIR")" # dirname returns everything except last component
TABLE="${1:-$SLURM_DIR/resources.txt}"

if [[ ! -f "$SLURM_DIR/config.sh" ]]; then
  echo "Missing slurm/config.sh: copy config.example.sh and edit it" >&2
  exit 1
fi
source "$SLURM_DIR/config.sh"

mkdir -p "$PROJECT_DIR/logs"
: > "$PROJECT_DIR/logs/last_run_jobids.txt"   # reset the job-ID list for this run

prev_id=""   # job ID of the previously submitted job (empty for the first row)

while read -r script env pyenv mem time cpus; do
  [[ -z "$script" || "$script" == \#* ]] && continue   # skip blanks and comments

  name="$(basename "$script" .qmd)"
  # Optional filter: ONLY=02_clustering, or a glob such as ONLY='0[1-3]*'
  [[ -n "${ONLY:-}" && "$name" != $ONLY ]] && continue

  # Every job except the first waits for the previous one to succeed
  dep_flag=()
  if [[ -n "$prev_id" ]]; then
    dep_flag=(--dependency="afterok:${prev_id}" --kill-on-invalid-dep=yes)
  fi

  # $SBATCH_EXTRA is deliberately unquoted so several flags split into words
  jobid=$(sbatch --parsable \
    --job-name="$name" \
    --output="$PROJECT_DIR/logs/${name}_%j.out" \
    --error="$PROJECT_DIR/logs/${name}_%j.err" \
    --mem="$mem" --time="$time" --cpus-per-task="$cpus" \
    --export=ALL,PROJECT_DIR="$PROJECT_DIR",CONDA_BASE="$CONDA_BASE" \
    "${dep_flag[@]}" \
    $SBATCH_EXTRA \
    "$SLURM_DIR/render_one.sh" "$script" "$env" "$pyenv" < /dev/null)

  echo "$jobid" >> "$PROJECT_DIR/logs/last_run_jobids.txt"
  echo "Submitted $name -> job $jobid (mem $mem, time $time, after: ${prev_id:-nothing})"
  prev_id="$jobid"
done < "$TABLE"

# Final job: assemble the site once the last document has been rendered
if [[ "${SKIP_SITE:-0}" != "1" ]]; then
  site_dep=()
  if [[ -n "$prev_id" ]]; then
    site_dep=(--dependency="afterok:${prev_id}" --kill-on-invalid-dep=yes)
  fi
  site_id=$(sbatch --parsable \
    --job-name="render_site" \
    --output="$PROJECT_DIR/logs/render_site_%j.out" \
    --error="$PROJECT_DIR/logs/render_site_%j.err" \
    --mem=4G --time=00:10:00 --cpus-per-task=1 \
    --export=ALL,PROJECT_DIR="$PROJECT_DIR",CONDA_BASE="$CONDA_BASE" \
    "${site_dep[@]}" \
    $SBATCH_EXTRA \
    "$SLURM_DIR/render_one.sh" SITE r_scrnaseq_core -)
  echo "$site_id" >> "$PROJECT_DIR/logs/last_run_jobids.txt"
  echo "Submitted site assembly -> job $site_id (after: $prev_id)"
fi