library("GenomicFeatures")
library("Rsamtools")
library("GenomicRanges")

args<-commandArgs(trailingOnly=TRUE)
print(args)
#load the coding region
#txdb<-loadFeatures("hg19_ucsc_genomicFeatures.sqlite")
#exonRangesList<-exonsBy(txdb,by='gene')
#exonRanges<-unlist(exonRangesList)
#strand(exonRanges)<-"*"
#geneNames<-sub("\\..*$","",names(exonRanges))
#exonRangesListNoStrand<-split(exonRanges,geneNames) #without considered strand
#exonRangesListNoStrand<-split(exonRanges,rep("coding",length(exonRanges))) #without considered strand

dat<-read.table("/data/cqs/guoy1/reference/annotation/hg19/hg19_protein_coding.bed",sep="\t")
gr<-GRanges(seqnames=dat[,1],IRanges(dat[,2],dat[,3]),strand="*")
grlist<-split(gr,rep("kinome",length(gr)))

getCounts<-function(bamfile,tx){
    print(paste("Reading bamfile", bamfile,"at", date()))
    aln<-readBamGappedAlignments(bamfile)
    print(paste("Calculating read counts at", date()))
    counts <- countOverlaps(tx, aln)
    names(counts) <- names(tx)
    return(counts)
}

#bamfile<-paste("/data/cqs/guoy1/pooled/bam/Sample_Pool_",args[1],"_realigned_recalibration_sorted.bam",sep="")
bamfile<-args[1]
count<-getCounts(bamfile,grlist);
write.table(count,file=args[2])

