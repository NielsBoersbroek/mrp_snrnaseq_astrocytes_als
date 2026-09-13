# Title

Introduction

## Structure of the repo

The directory structure of this repo is as follows:

```
tree
```

## Running scripts

Scripts assume the working directory is the project root (marked by the .here file): open the project in VS Code/RStudio from this root folder, or ensure your SLURM wrapper `cd`s here before rendering.

## Environments

This project uses 3 conda environments (see `/environments/`):

| Environment           | Used by                           | Notes                     |
|-----------------------|-----------------------------------|---------------------------|
| `r_scrnaseq_core`     | Scripts 01–03, 05, 07, 08         | General Seurat/tidyverse + slingshot, milo, hdWGCNA |
| `r_monocle3`          | 06_monocle3.R                     | Isolated: requires an older `bioconductor-singlecellexperiment` than other packages (slingshot and milo), which caused a solver conflict |
| `py_scrnaseq`         | 04_sccoda.py                      | Python environment        |

Monocle3 required an older `bioconductor-singlecellexperiment` than other packages (slingshot and milo), which caused a solver conflict when combined and is why it is a seperate environment.

To create an environment, run: 
```
mamba env create -f environments/<name>.yml
```

hdWGCNA is not available via conda; after creating `r_scrnaseq_core`, run:
```
Rscript -e "devtools::install_github('smorabit/hdWGCNA', ref='dev')"
```

`r_monocle3` requires seuratwrappers, which is also not available via conda; after creating `r_monocle3`, run:
```
Rscript -e "devtools::install_github('satijalab/seurat-wrappers')"
```