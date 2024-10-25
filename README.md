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
1. Go to a directory where you would like to run the analyses and clone this repository as well as PRScs:
```
git clone https://github.com/Ax-Sch/PRScs_pipeline.git
cd PRScs_pipeline
git clone https://github.com/getian107/PRScs.git
```
2. Download the appropriate LD reference panel from the links provided in the github of PRScs: https://github.com/getian107/PRScs ; un-tar the file. 

For the example data, the LD reference panel constructed using the UK Biobank data for Europeans was used. 
If you would like to run the example data, download ldblk_ukbb_eur.tar.gz to the folder "example_data", then run the following:
```
# manually download ldblk_ukbb_eur.tar.gz to ./example_data
cd example_data
tar -zxvf ldblk_ukbb_eur.tar.gz
cd ..
```

2. SKIP if conda is already installed, otherwise install conda, e.g. download miniconda3 (https://docs.conda.io/en/latest/miniconda.html) by running the following commands on a linux system:
```
### run only when you do not have conda installed:
curl -sL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" > "Miniconda3.sh"
bash Miniconda3.sh
rm Miniconda3.sh
```
Potentially restart bash to make sure conda is running.

3. Install snakemake version 7 via conda:
```
conda env create -f workflow/envs/snakemake7.yaml
```

4. Test the pipeline using example data (folder example_data is used):
```
conda activate snakemake7
snakemake -np # do a dry run first
snakemake --cores 4 --use-conda --conda-frontend conda
```
In the last command, modify the cores argument to run on more cores.


### Analyzing own/real data:
For analyzing own data, the file config/config.yaml has to be modified - please have a look at the file, you can see the structure and find additional comments.
Target data:
 - Please make sure your target data set underwent throurough quality control steps. It should be in the plink 1 binary format (fam/bim/bed files). The location of the files need to be given in the config file. 
 - Additionally, specify if rsids are present in the bim file or if they should be added.

Base data:
- The base data set should have a first line containing the header. Give a arbitrary name to the phenotype in the config file and spedify the location of the GWAS sum stats file.
- The header can be renamed according to a renaming-file containing two columns old_name, new_name (tab separated file with header; see example data). The following column names are expected: CHR, POS, SNP, A1, A2, BETA, P. 
- Indicate the separator of the columns (e.g. "\t" for tab)
- Specify if rsids should be added, if so, specify the reference genome that is used in your file.
- Specify if a column named LOG10P (after renaming) with -log10(P) values should be converted to P-values
- Specify a cutoff of p-values for prefiltering if this is wanted
- Specify the number of individuals that were analyzed in the GWAS (this is directly handed over to PRScs n_gwas)

Output:
Output will be written to the folder "results". In particular, the scores of the individuals from the target data set can be found in "results/PRS_values/". These can be loaded e.g. with R for further analyses.
 

### Contact
If you encounter issues - please open an issue in this repository.

### Acknowledgement:
In particular, I would like to thank the developers of the software that is used within this repository, among others snakemake, plink, R, tidyverse, data.table, PRScs.
