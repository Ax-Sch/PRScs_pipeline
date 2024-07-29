library(tidyverse)
# debug
dbsnp_path<-"/home/aschmidt/Arbeit_Gen/annotate_bim_w_dbsnp/results/dbsnp_index/dbnsp_index.tsv.gz"
in_path<-"/mnt/int1/COVID_HGI_GWAS/japanische_gwas/COVID_vs_Control_LT65_Rsq0.5_MAF0.001.txt"
out_path<-"/mnt/int1/PRS_long_covid_clean/results/plink_target/allchr.prefiltered.bim"


in_path=snakemake@input[[1]]
out_path=snakemake@output[[1]]

add_rsid=as.logical(snakemake@params[["add_rsid"]])
LOG10P_to_P=as.logical(snakemake@params[["LOG10P_to_P"]])

delim_par<-"\t"

if (add_rsid){
  dbsnp_path=snakemake@input[[2]]
  dbsnp<-read_tsv(file = dbsnp_path)
  dbsnp_dst<-dbsnp %>% distinct(CHROM, POS, REF, ALT, .keep_all = TRUE)
}

in_dat<-read_delim(file = in_path, delim=delim_par)

if (LOG10P_to_P){
  in_dat<-in_dat %>%
    mutate(P=10^(-LOG10P))
}

if (add_rsid){
  in_dat<-in_dat %>%
    mutate(CHR=as.character(CHR))%>%
    mutate(CHR=str_replace(string=CHR,pattern=fixed("23"), replacement = "X"))
  
  join_vec<-c("CHROM","POS","ALT","REF")
  names(join_vec)<-c("CHR", "POS", "A2", "A1")
  
  in_dat_rs<-in_dat%>%
    left_join(dbsnp_dst, by=join_vec)
  
  in_dat_rs<-in_dat_rs %>%
    mutate(SNP=ifelse(is.na(RSID), SNP, RSID))%>%
    select(-RSID)
  
  names(join_vec)<-c("CHR", "POS", "A1", "A2")
    
  in_dat_rs_second<-in_dat_rs%>%
    left_join(dbsnp_dst, by=join_vec)
  
  in_dat_rs_second<-in_dat_rs_second %>% 
    mutate(SNP=ifelse(is.na(RSID), SNP, RSID))%>%
    select(-RSID)

} else {
  in_dat_rs_second<-in_dat
}

write_tsv(x = in_dat_rs_second,
          file = out_path,
          col_names = TRUE)
