library(data.table)

# debug
sumstat_file="resources/depression_broad_howard/29662059-GCST005902-EFO_0003761-build37.f_MAF_GT_001.tsv.gz"
out_file="output/depression_base/base_data.tsv.gz"
rename_file<-paste(sumstat_file,"rename", sep="_")

COLS_ALL_REQUIRED=c("CHR", "POS", "SNP", "A2", "A1", "BETA")
COLS_ONE_REQUIRED=c( "P",  "LOG10P")
COLS_TO_KEEP=unique(c(COLS_ALL_REQUIRED, COLS_ONE_REQUIRED))

sumstat_file=snakemake@input[["sumstat_file"]]
rename_file=snakemake@input[["rename_file"]]
col_sep=snakemake@params[["col_sep"]]
out_file=snakemake@output[[1]]

#read in sumstats
base_data<-fread(sumstat_file, sep = col_sep)
head(base_data)

# rename columns
rename_scheme<-fread(rename_file, header=TRUE, sep="\t")
head(rename_scheme)

if (nrow(rename_scheme)>0){
for (old_col in rename_scheme$old_name){
  new_col=unlist(rename_scheme[old_name==old_col,new_name])
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


coln=colnames(base_data_uniq_nonAmb_reShape)
if (sum(COLS_ALL_REQUIRED %in% coln)<1 | sum(COLS_ONE_REQUIRED %in% coln)==0){
  print("Not all required columns are present in the file. This is potentially an issue in renaming columns.")
  print("The following column names are all required:")
  print(COLS_ALL_REQUIRED)
  print("One of the following column names is required:")
  print(COLS_ONE_REQUIRED)
  print("Your file has the following column-names after renaming:")
  print(coln)
  quit(status=1)
}

fwrite(x = base_data_uniq_nonAmb_reShape, 
       file=out_file,
       col.names=T, sep="\t")

