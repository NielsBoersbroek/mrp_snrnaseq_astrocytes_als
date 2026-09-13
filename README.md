# Title

Introduction

## Structure of the repo

The directory structure of this repo is as follows:

```
tree
```

## Running scripts

Scripts locate the project root automatically via the here package (marked by the .here file at the repository root). This resolves automatically when rendering .Rmd/.qmd files via rmarkdown::render() or Quarto's CLI. If running chunks interactively (e.g. in RStudio or VS Code), ensure your R session's working directory is set to somewhere within this project's folder tree first.

One can only run it if the full dataset is stored in the `/data/raw` folder.

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