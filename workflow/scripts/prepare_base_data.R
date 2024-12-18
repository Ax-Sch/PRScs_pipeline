library(data.table)
library(tidyr)

# debug
sumstat_file="resources/depression_broad_howard/29662059-GCST005902-EFO_0003761-build37.f_MAF_GT_001.tsv.gz"
out_file="output/depression_base/base_data.tsv.gz"

COLS_ALL_REQUIRED=c("CHR", "POS", "SNP", "A2", "A1", "BETA")
COLS_ONE_REQUIRED=c( "P",  "LOG10P")
COLS_TO_KEEP=unique(c(COLS_ALL_REQUIRED, COLS_ONE_REQUIRED))

sumstat_file=snakemake@input[["sumstat_file"]]
column_renaming=snakemake@params[["column_renaming"]]
exclude_regions=snakemake@params[["exclude_regions"]]
select_regions=snakemake@params[["select_regions"]]
col_sep=snakemake@params[["col_sep"]]
out_file=snakemake@output[[1]]

#read in sumstats
base_data<-fread(sumstat_file, sep = col_sep)
print(paste("Starting with", nrow(base_data), "variants."))
print("Data summary:")
print(summary(base_data))

print("Rename columns:")
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

# make sure alleles are in upper case
base_data_uniq <- base_data_uniq[, `:=`(A1=toupper(A1), A2=toupper(A2))]

print(paste("Removed", nrow(base_data) - nrow(base_data_uniq), 
            "duplicate variants,",  nrow(base_data_uniq), "remaining."))


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

print(paste("Removed", nrow(base_data_uniq) - nrow(base_data_uniq_nonAmb_reShape),
            "ambigous variants,",  nrow(base_data_uniq_nonAmb_reShape), "remaining."))

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

# check if regions are given to exclude; if so, go ahead and exclude them
if (!FALSE %in% exclude_regions){
  print("Regions to exclude are given.")
  exclude_regions_df <- 
    do.call(rbind, lapply(names(exclude_regions), function(name) {
      cbind(NAME = name, as.data.frame(exclude_regions[[name]], stringsAsFactors = FALSE))
    }))
  
  for (i in 1:nrow(exclude_regions_df)){
    excl_name=exclude_regions_df$NAME[i]
    excl_chr=exclude_regions_df$CHR[i]
    excl_start=exclude_regions_df$START[i]
    excl_end=exclude_regions_df$END[i]
    
    print(paste("Excluding the following region:", excl_name))
    n_before=nrow(base_data_uniq_nonAmb_reShape)
    
    base_data_uniq_nonAmb_reShape <- base_data_uniq_nonAmb_reShape[
      !((CHR == excl_chr) & (POS >= excl_start) & (POS <= excl_end))
    ]
    print(paste("Excluded", n_before - nrow(base_data_uniq_nonAmb_reShape), "variants," , 
                nrow(base_data_uniq_nonAmb_reShape), "remaining."))
  }
} else {
  print("No regions to exclude are given.")
}

# check if regions are given to be specifically selected; if so, go ahead and select them
if (!FALSE %in% select_regions){
  print("Regions to select are given.")
  select_regions_df <- 
    do.call(rbind, lapply(names(select_regions), function(name) {
      cbind(NAME = name, as.data.frame(select_regions[[name]], stringsAsFactors = FALSE))
    }))
  
  selected_vars<-base_data_uniq_nonAmb_reShape[0,]
  
  for (i in 1:nrow(select_regions_df)){
    incl_name=select_regions_df$NAME[i]
    incl_chr=select_regions_df$CHR[i]
    incl_start=select_regions_df$START[i]
    incl_end=select_regions_df$END[i]
    
    n_before=nrow(selected_vars)
    
    print(paste("Selecting the following region:", incl_name))
    
    selected_vars_tmp <- base_data_uniq_nonAmb_reShape[
      ((CHR == incl_chr) & (POS >= incl_start) & (POS <= incl_end))
    ]
    selected_vars<-selected_vars[ 
      !((CHR == incl_chr) & (POS >= incl_start) & (POS <= incl_end))
    ]
    
    selected_vars<-rbindlist(list(selected_vars, selected_vars_tmp))
    
    print(paste("Selected", nrow(selected_vars) - n_before, "variants," , 
                nrow(selected_vars), "remaining."))
  }
  base_data_uniq_nonAmb_reShape<-selected_vars
} else {
  print("No regions to specifically select are given.")
}


fwrite(x = base_data_uniq_nonAmb_reShape, 
       file=out_file,
       col.names=T, sep="\t")

