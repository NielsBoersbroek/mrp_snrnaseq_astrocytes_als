#!/bin/bash
# Worker: renders ONE Quarto document inside a conda env.
# Submitted by run_all.sh, which sets the resources. 
# PROJECT_DIR and CONDA_BASE are passed in via --export.
# Usage: render_one.sh <qmd path relative to project root | SITE> <conda env> [python env | -]

# No -u here: conda's activation scripts reference unset variables
set -eo pipefail

TARGET="$1"
ENV_NAME="$2"
PY_ENV="${3:--}"

echo "Job started: $(date)"
echo "Target: $TARGET | R env: $ENV_NAME | Python env: $PY_ENV"

cd "$PROJECT_DIR"
source "$CONDA_BASE/etc/profile.d/conda.sh"

# If the document uses Python (via reticulate), ask conda where the Python
# env's interpreter lives, so no path is hardcoded. This must happen BEFORE
# activating the main env.
if [[ "$PY_ENV" != "-" ]]; then
  conda activate "$PY_ENV"
  export RETICULATE_PYTHON="$(command -v python)"
  echo "RETICULATE_PYTHON is set to: $RETICULATE_PYTHON"
fi

conda activate "$ENV_NAME"

if [[ "$TARGET" == "SITE" ]]; then
  quarto render            # whole project: stitches the site from _freeze/
else
  quarto render "$TARGET"  # one document: executes the code
fi

echo "Job finished: $(date)"