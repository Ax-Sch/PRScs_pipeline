library(tidyverse)
dbsnp_path<-"/home/aschmidt/Arbeit_Gen/annotate_bim_w_dbsnp/results/dbsnp_index/dbnsp_index.tsv.gz"
bim_path<-"/mnt/int1/PRS_long_covid_clean/results/plink_target/allchr.prefiltered.bim"

dbsnp_path=snakemake@input[[1]]
bim_path=snakemake@input[[2]]
bim_out_path=snakemake@output[[1]]

dbsnp<-read_tsv(file = dbsnp_path)
dbsnp_dst<-dbsnp %>% distinct(CHROM, POS, REF, ALT, .keep_all = TRUE)

bim<-read_tsv(file = bim_path,
              col_names=c("CHR","SNP","cM","BP","A1","A2"))
bim<-bim %>%
  mutate(CHR=as.character(CHR))%>%
  mutate(CHR=str_replace(string=CHR,pattern=fixed("23"), replacement = "X"))%>%
  mutate(CHR = str_replace(CHR, pattern = fixed("chr"), replacement = ""))

bim_rs<-bim%>%
  left_join(dbsnp_dst, by=c("CHR"="CHROM","BP"="POS","A1"="REF","A2"="ALT"))

bim_rs<-bim_rs %>%
  mutate(SNP=ifelse(is.na(RSID), SNP, RSID))%>%
  select(-RSID)

bim_rs_second<-bim_rs%>%
  left_join(dbsnp_dst, by=c("CHR"="CHROM","BP"="POS","A2"="REF","A1"="ALT"))

bim_rs_second<-bim_rs_second %>% 
  mutate(SNP=ifelse(is.na(RSID), SNP, RSID))%>%
  select(-RSID)%>%
  mutate(A1=toupper(A1),
         A2=toupper(A2))

write_tsv(x = bim_rs_second,
          file = bim_out_path,
          col_names = FALSE)
