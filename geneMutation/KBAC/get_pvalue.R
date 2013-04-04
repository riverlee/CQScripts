library("KBAC")
#library("multtest")

getP<-function(infile){
    dat<-read.table(infile,skip=1,sep="\t");
    alpha<-0.01
    num.permutation<-10000
    quiet<-1
    alternative<-1
    maf.upper.bound<-0.5
    pvalue<-KbacTest(dat,alpha,num.permutation,quiet,maf.upper.bound,alternative);
    r<-c(dim(dat)[2]-1,pvalue)
    names(r)<-c("SNPNumber","pvalue")
    return(r)

}

files<-paste("genes/",list.files("genes"),sep="")
genes<-files;
genes<-gsub("genes/","",genes)
genes<-gsub(".txt","",genes)

pvalues<-sapply(files,getP)
colnames(pvalues)<-genes

write.table(t(pvalues),file="gene_snpNumber_maf05_perm10000_pvalue.txt",sep="\t",quote=F)

