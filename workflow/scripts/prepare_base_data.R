library(data.table)

# debug
sumstat_file="resources/depression_broad_howard/29662059-GCST005902-EFO_0003761-build37.f_MAF_GT_001.tsv.gz"
out_file="output/depression_base/base_data.tsv.gz"
rename_file<-paste(sumstat_file,"rename", sep="_")

COLS_TO_KEEP=c( "CHR", "POS", "SNP", "A2", "A1", "BETA", "P",  "LOG10P")

sumstat_file=snakemake@input[["sumstat_file"]]
rename_file=snakemake@input[["rename_file"]]
col_sep=snakemake@params[["col_sep"]]
out_file=snakemake@output[[1]]

#read in sumstats
base_data<-fread(sumstat_file, sep = col_sep)
head(base_data)

# rename columns
rename_scheme<-fread(rename_file, header=FALSE, col.names = c("old","new"))
head(rename_scheme)

if (nrow(rename_scheme)>0){
for (old_col in rename_scheme$old){
  new_col=unlist(rename_scheme[old==old_col,new])
  setnames(x = base_data, old = old_col, new=new_col)
}
}
  
# remove duplicate SNPs
base_data_uniq<-unique(base_data, by = "SNP")
base_data_uniq<-base_data_uniq[!(is.na(SNP) | SNP=="" |  SNP==" ")]

base_data_uniq <- base_data_uniq[, `:=`(A1=toupper(A1), A2=toupper(A2))]

# remove ambigous SNPs
base_data_uniq_nonAmb<-
  base_data_uniq[!(
    (A1=="A" & A2=="T") |
    (A1=="T" & A2=="A") |
    (A1=="G" & A2=="C") |
    (A1=="C" & A2=="G")
  ) ]

coln=colnames(base_data_uniq_nonAmb)
coln_keep=COLS_TO_KEEP[COLS_TO_KEEP %in% coln]
base_data_uniq_nonAmb_reShape<-
  base_data_uniq_nonAmb[, coln_keep, with = FALSE]
setcolorder(base_data_uniq_nonAmb_reShape, coln_keep)


fwrite(x = base_data_uniq_nonAmb_reShape, 
       file=out_file,
       col.names=T, sep="\t")

