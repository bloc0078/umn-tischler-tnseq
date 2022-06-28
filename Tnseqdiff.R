library(Tnseq)
library(readr)

myco_input <- read_delim("tnseqdiff_readcount_table.txt",
                         "\t", escape_double = FALSE, col_names = FALSE,
trim_ws = TRUE)
xx<-list()
# Specify columns to be used for each comparison.
xx[[1]]<-c(2,3,4,5,6,7)
xx[[2]]<-c(2,3,4,8,9,10)
xx[[3]]<-c(2,3,4,11,12,13)
xx[[4]]<-c(5,6,7,8,9,10)
xx[[5]]<-c(5,6,7,11,12,13)

#filenames for output
yy<-c("input_ctrl.txt","input_CI.txt","input_RI.txt","ctrl_CI.txt","ctrl_RI.txt")
yypval<-c("input_ctrl_pval.txt","input_CI_pval.txt","input_RI_pval.txt","ctrl_CI_Pval.txt","ctrl_RI_pval.txt")
yyres<-c("input_ctrl_res.txt","input_CI_res.txt","input_RI_res.txt","ctrl_CI_res.txt","ctrl_RI_res.txt")

dedup_data<-myco_input[!duplicated(myco_input), ]
condition=c(rep("Input",3),rep("Output",3))
pool=c(1,1,1,1,1,1)
geneID=as.character(dedup_data$X1)
location=dedup_data$X1
ff=length(xx)
for (i in 1:ff) {
  countData=dedup_data[,xx[[i]]]
  
  #Running TnSeqDiff
  funcresult<-TnseqDiff(countData, geneID, location, pool, condition)
  
  # output table for TnSeqDiff
  res=funcresult$resTable
  
  res$padj=p.adjust(res$pvalue, method = "BH")
  
  #filtering res table for signficant hits
  filter_significant=res[abs(log2(res$FC))>=2 & res$padj<0.025,]
  filter_significantpval=res[abs(log2(res$FC))>=2 & res$pvalue<0.05,]
  
  #Write output tables
  write.table(res,yyres[[i]],row.names=TRUE)
  write.table(filter_significant,yy[[i]],row.names=FALSE)
  write.table(filter_significantpval,yypval[[i]],row.names=FALSE)
}
