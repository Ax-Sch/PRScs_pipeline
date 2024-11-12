library(data.table)

# debug
sumstat_file="resources/depression_broad_howard/29662059-GCST005902-EFO_0003761-build37.f_MAF_GT_001.tsv.gz"
out_file="output/depression_base/base_data.tsv.gz"
rename_file<-paste(sumstat_file,"rename", sep="_")

COLS_ALL_REQUIRED=c("CHR", "POS", "SNP", "A2", "A1", "BETA")
COLS_ONE_REQUIRED=c( "P",  "LOG10P")
COLS_TO_KEEP=unique(c(COLS_ALL_REQUIRED, COLS_ONE_REQUIRED))

sumstat_file=snakemake@input[["sumstat_file"]]
column_renaming=snakemake@params[["column_renaming"]]
col_sep=snakemake@params[["col_sep"]]
out_file=snakemake@output[[1]]

#read in sumstats
base_data<-fread(sumstat_file, sep = col_sep)
print("first few columns of the base data:")
head(base_data)

print("rename columns:")
if (length(column_renaming)>0){
for (i in 1:length(column_renaming)){
  new_col=names(column_renaming)[i]
  old_col=as.character(column_renaming[i])
  print(paste0("renaming ", old_col, " to ", new_col))
  setnames(x = base_data, old = old_col, new=new_col)
}
}

# Check if the column 'SNP' exists, and if not, create it
if (!"SNP" %in% names(base_data)) {
  base_data[, SNP := paste(CHR, POS, A1, A2, sep = ":")]
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

