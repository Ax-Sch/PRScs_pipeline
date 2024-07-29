## Snakemake pipeline for Polygenic Scoring

This is a simple snakemake pipeline for polygenic risk scoring using the software PRScs. It requires quality controlled genotype files of the target dataset as well as GWAS summary statistics of the base dataset. 

### Content of the pipeline:
- Preprocessing of base dataset, including the removal of ambigous SNPs and potentially the conversion of -log10(P) values to P-values
- Annotation with dbSNP IDs of base and target data set, if needed
- Execution of PRScs
- Polygenic scoring of the target data set

The pipeline is configured using the file config/config.yaml.


### Setting up and testing the pipeline:
To run the pipeline the following steps are necessary:
1. Go to a directory where you would like to run the analyses and clone this repository:
```
git clone https://github.com/Ax-Sch/PRScs_pipeline.git
cd PRScs_pipeline
```

2. SKIP if conda is already installed, otherwise install conda, e.g. download miniconda3 (https://docs.conda.io/en/latest/miniconda.html) by running the following commands on a linux system:
```
### run only when you do not have conda installed:
curl -sL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" > "Miniconda3.sh"
bash Miniconda3.sh
rm Miniconda3.sh
```
Potentially restart bash.

3. Install snakemake version 7 via conda:
```
conda env create -f workflow/envs/snakemake7.yaml
```

4. Copy the genotype and phenotype data in the workflow directory (putting them somewhere else is problematic when we use containers). Here is an example - to use your own data, see below. Example data derived from the 1000 genomes project can be found here: https://uni-bonn.sciebo.de/s/3bohPgm1Gt8qhfx

I.e. run the following commands within the directory of the repository and example data will be placed into the folder "prs_example":
```
conda activate snakemake7
curl -J -O "https://uni-bonn.sciebo.de/s/3bohPgm1Gt8qhfx/download"
unzip prs_example.zip
```
The config file (config/config.yaml) is configured to work with these files out of the box.

5. Run the pipeline:
```
conda activate snakemake7
snakemake -np # do a dry run first
snakemake --cores 1 --use-conda
```
In the last command, modify the cores argument to run on multiple cores.

### Analyzing own/real data:



### Acknowledgement:
In particular, I would like to thank the developers of the software that is used within this repository, among others snakemake, plink, R, tidyverse, data.table, PRScs.



Prerequisites:
- Target dataset in Plink binary file format (fam/bim/bed-files)
