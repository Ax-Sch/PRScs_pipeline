library(tidyverse)

bim_path<-"/home/aschmidt/Arbeit_Gen/annotate_bim_w_dbsnp/results/bim_w_rsid/bim_w_rsid.bim"
gwas_path<-"../../results/depression/base_data.tsv.gz"
p_cutoff<-1
bim_out_path<-"../../results/overlapping_vars/general.bim"
gwas_out_path<-"../../results/overlapping_vars/gwas.sst"

bim_path<-snakemake@input[[1]]
gwas_path<-snakemake@input[[2]]
p_cutoff<-snakemake@params[[1]]
bim_out_path<-snakemake@output[[1]]
gwas_out_path<-snakemake@output[[2]]

bim_header<-c("CHROM",
              "SNP",
              "cM",
              "POS",
              "A1",
              "A2")

bim<-read_tsv(file=bim_path, col_names=bim_header)
gwas<-read_tsv(file=gwas_path, col_names=TRUE)

gwas_filtered<-gwas %>%
  filter(P<p_cutoff)%>%
  filter(CHR!="chrX", CHR!="chrY")%>%
  mutate(CHR=str_replace(string=CHR, pattern="chr", replacement=""))%>%
  mutate(CHR=as.integer(CHR))%>%
  filter(CHR<23)

bim_CHR<-bim %>%
  filter(CHROM!="chrX", CHROM!="chrY")%>%
  mutate(CHROM=str_replace(string=CHROM, pattern="chr", replacement=""))%>%
  mutate(CHROM=as.integer(CHROM))%>%
  filter(CHROM<23)

bim_CHR_filtered <- bim_CHR %>%
  filter(SNP %in% gwas_filtered$SNP)%>%
  arrange(CHROM, POS)

gwas_out<-gwas_filtered %>% 
  filter(SNP %in% bim_CHR_filtered$SNP)%>%
  arrange(CHR, POS)%>%
  select(SNP,A1,A2,BETA,P)%>%
  relocate(SNP,A1,A2,BETA,P)

write_tsv(x=gwas_out, file=gwas_out_path, col_names=TRUE)
write_tsv(x=bim_CHR_filtered, file=bim_out_path, col_names=FALSE)
