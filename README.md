# Transcriptional Heterogeneity of Astrocytes in the ALS Spinal Cord

This repository contains the analysis code of my master's internship in the [Kenna-lab](https://translationalneuroscience.nl/kevin_kenna/) at the Translational Neuroscience department of the UMC Utrecht.
 
The overarching project studies post-mortem spinal cord tissue of ALS patients and controls with single-nucleus RNA sequencing. Each library was split: half was sequenced with short reads (Illumina), whose depth identifies cell types, and half with long reads (PacBio), whose length can span multiple exons and therefore identifies RNA isoforms (splice variants). My part of the project focuses on the astrocytes: I subset and cluster them, infer trajectories, test differential abundance, find co-expression modules, and examine differential junction usage in the long-read data.

## Rendered analysis
 
Every script is a Quarto document, so you can read the full analysis (code, figures and the reasoning behind each step) without running anything: **[link to the Quarto site]**
 
The site has one page per script, in the order they were run, with a sidebar to jump between pages and a table of contents for each page. The first page provides an overview, summarizing what each script does. This README also covers everything you need to run the scripts yourself.

## Respository structure

```
.
├── .gitignore
├── .here                       # marks the project root for the R package `here`
├── README.md
├── _quarto.yml                 # Quarto website configuration
├── index.qmd                   # landing page of the Quarto site
├── data/                       # untracked (sensitive patient data); empty folders kept with .gitkeep
│   ├── metainformation/        # small metadata tables, e.g. sex_genes.txt (is tracked, as non-sensitive)
│   ├── raw/                    # input data: the short-read Seurat object
│   │   └── longread/           # long-read input, in a separate folder for Read10X()
│   ├── processed/              # objects saved by the scripts
│   └── temporary/              # large intermediate files (hdWGCNA TOM, AnnotationHub cache)
├── environments/               # conda environment .yml files
├── logs/                       # .out and .err files of the SLURM jobs (untracked)
├── results/                    # untracked
│   ├── figures/                # one subfolder per script
│   │   └── manuscript/         # figure objects (.rds) that script 11 assembles for written report
│   └── tables/                 # one subfolder per script
├── scripts/                    # the Quarto documents, one per analysis step
│   ├── 00_template.qmd
│   ├── 01_subsetting_astros.qmd
│   ├── 02_clustering.qmd
│   ├── 03_trajectory_slingshot.qmd
│   ├── 04_trajectory_tradeseq.qmd
│   ├── 05_trajectory_monocle3.qmd
│   ├── 06_milo.qmd
│   ├── 07_hdwgcna.qmd
│   ├── 08_astrocyte_junction_seurat.qmd
│   ├── 09_junction_de-cluster.qmd
│   ├── 10_junction_de-pseudobulk.qmd
│   └── 11_assemble_manuscript_figures.qmd
└── slurm/                      # system to run all scripts as SLURM jobs
    ├── config.example.sh       # template for user-specific settings
    ├── config.sh               # your own settings (untracked)
    ├── render_one.sh           # renders one document inside its conda environment(s)
    ├── resources.txt           # per script: environments, memory, time and CPUs
    └── run_all.sh              # submits all scripts as chained SLURM jobs
```


Rendering of Quarto also creates `_site/` (the website), `_freeze/` (stored results, so the site can be rebuilt without re-running any code) and `.quarto/`. All three are untracked.

## Reproducing the analysis

You need a SLURM cluster, a conda installation (for example [miniforge](https://github.com/conda-forge/miniforge)) and the input data. Quarto, R and Python are all installed inside the conda environments, so nothing else has to be installed separately. Without SLURM, you can still render each document manually (see [Rendering a single document](#rendering-a-single-document)).

### Data

No data are included in this repository, because they are sensitive patient data. The scripts expect:
 
- the short-read Seurat object containing all cell types I derived from Charlotte, saved as `seu_shortread_allcelltypes_postQC.rds` in `data/raw/`
- the long-read output in `data/raw/longread/`, which are the files `barcodes.tsv.gz`, `cell_metadata.tsv.gz`, `features.tsv.gz`, `junction_features.tsv.gz` and `matrix.mtx.gz` I derived from Tom.

### Environments
 
The project uses three conda environments, defined in `environments/`. Each script names its environment in its introduction.
 
| Environment       | Used by                                    | Notes |
|-------------------|--------------------------------------------|-------|
| `r_scrnaseq_core` | Scripts 01–04 and 06–11                    | General Seurat/tidyverse/Quarto, plus slingshot, tradeSeq, milo, hdWGCNA and DESeq2 |
| `r_monocle3`      | Script 05                                  | Separate because monocle3 needs an older `bioconductor-singlecellexperiment` than slingshot and milo, which caused a solver conflict when combined |
| `py_scrnaseq`     | Python part of script 02 (scCODA)          | Python only; script 02 reaches it through `reticulate` |
 
Create an environment with:
 
```bash
mamba env create -f environments/<name>.yml
```
 
Two packages are not available through conda and need a manual step after creating the environment:
 
```bash
# hdWGCNA, in r_scrnaseq_core
conda activate r_scrnaseq_core
Rscript -e "devtools::install_github('smorabit/hdWGCNA', ref='dev')"
 
# seurat-wrappers, in r_monocle3
conda activate r_monocle3
Rscript -e "devtools::install_github('satijalab/seurat-wrappers')"
```

### Running all scripts
 
Scripts depend on the output of earlier scripts, so they must run in numbered order. The SLURM system takes care of this.
 
1. Copy the settings template and edit it. `CONDA_BASE` should be the folder of your conda installation that contains `etc/profile.d/conda.sh`.
```bash
   cp slurm/config.example.sh slurm/config.sh
```
 
2. Run the driver from the repository root (directly, not with `sbatch`):
```bash
   bash slurm/run_all.sh
```
 
`run_all.sh` reads `slurm/resources.txt`, which has one row per script with its R environment, Python environment (or `-`), memory, time and number of CPUs. It submits every script as its own job, so each gets its own resources, and chains the jobs: each starts only after the previous one succeeded, and a failure cancels the rest. Quarto cannot render several documents of one project in parallel, so the jobs run sequentially. A final job builds the website in `_site/`. SLURM output is written to `logs/`.
 
To run a subset, or to skip building the site:
 
```bash
ONLY=02_clustering SKIP_SITE=1 bash slurm/run_all.sh   # one script
ONLY='0[2-3]*' bash slurm/run_all.sh                    # a range of scripts
```
 
Scripts read the outputs of earlier scripts from `data/processed/`, so a single script only works if the files it needs already exist.
 
### Rendering a single document
 
Activate the right environment and render from the repository root:
 
```bash
conda activate r_scrnaseq_core
quarto render scripts/01_subsetting_astros.qmd
```
 
Script 02 also uses Python, so tell R where the Python environment lives *before* activating the R environment:
 
```bash
conda activate py_scrnaseq
export RETICULATE_PYTHON="$(command -v python)"
conda activate r_scrnaseq_core
quarto render scripts/02_clustering.qmd
```
 
Because of `freeze: true` in `_quarto.yml`, rendering a document executes its code, whereas a project-wide `quarto render` only assembles the site from the stored results.
 
### Working directory
 
The scripts find the project root with the `here` package, using the `.here` file at the root. This works automatically when rendering. When running chunks interactively (for example in RStudio), make sure your working directory is somewhere inside this repository.

## Declaration of AI use
 
I come from a biomedical sciences background with little coding experience and chose a bioinformatics internship: the point of this internship literally was to learn how to code. Therefore, I steered clear of having LLMs write the code for me. However, I occasionally used Claude (Anthropic) as a tutor and code reviewer throughout the internship: to explain errors I could not solve on my own, to review drafts for bugs, structure and reproducibility, and to set exercises that led me towards the code - I always instructed it not to give me code directly, unless specified otherwise. Suggestions occasionally came with a short illustrative snippet or a pointer to a technique (for example, converting plots to static grobs before saving them for the manuscript figures), which I then implemented in my own code. However, my priority was to learn how to code myself, and I can confidently say I did so during this internship: I can always lean on LLMs for speed later; I wanted to learn the fundamentals first.
