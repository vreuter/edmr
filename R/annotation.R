#' generate genebody GRangesList object
#' @export
#' @param file bed file for gene models
#' @importFrom IRanges IRanges
# \dontrun{library(IRanges)}  
# \dontrun{genebody.file=system.file("extdata", "chr22.hg19_refseq_all_types.bed.gz", package = "edmr")}
# \dontrun{genebody=genebody.anno(file=genebody.file)}
genebody.anno=function(file){
  print(paste("load", file))
  genes.obj=readTableFast(file,header=F, sep="\t",stringsAsFactors=F)
  colnames(genes.obj)=c("chr","start","end","id","score","strand","gene.id","gene.symbol")
  subj <- with(genes.obj, GRanges(chr, IRanges(start, end), id=id, gene.symbol=gene.symbol,gene.id=gene.id))
  types=unique(splitn(genes.obj$id,"_",3))
  types=c("up|utr5","utr5","cds","intron","utr3")
  subj.types=lapply(types, function(i){
    print(paste("process:",i))
    with(genes.obj[grep(i, splitn(genes.obj$id,"_",3)),], GRanges(chr, IRanges(start, end), id=id, gene.symbol=gene.symbol,gene.id=gene.id))
  })
  names(subj.types)=c("promoter","utr5","cds","intron","utr3")
  subj.types[["gene"]]=subj
  subj.types
}

#' generate CpG islands GRangesList object
#' @export
#' @param file bed file for CpG islands
#' @param shore.width width for CpG shores
#' @param shelf.width width for CpG shelves
#' @importFrom IRanges IRanges
#' @importFrom IRanges flank
#' @importFrom IRanges reduce
#' @importFrom GenomicRanges GRanges
#' @examples
#' library(GenomicRanges)
#' library(IRanges)
#' cpgi.file=system.file("extdata", "chr22.hg19_cpgisland_all.bed.gz", package = "edmr")
#' cpgi=cpgi.anno(file=cpgi.file)
cpgi.anno=function(file, shore.width=2000, shelf.width=2000){
  ft=readTableFast(file, header=F, sep="\t")
  cpgi.gr= with(ft, GRanges(ft[,1], IRanges(ft[,2], ft[,3])))
  up.shores.gr=flank(cpgi.gr, width=shore.width, start=T,both=F)
  up.shelves.gr=flank(up.shores.gr, width=shelf.width, start=T,both=F)
  dn.shores.gr=flank(cpgi.gr, width=shore.width, start=F,both=F)
  dn.shelves.gr=flank(dn.shores.gr, width=shelf.width, start=F,both=F)
  shores=reduce(sort(c(up.shores.gr, dn.shores.gr)))
  shelves=reduce(sort(c(up.shelves.gr, dn.shelves.gr)))
  return(list(cpgis=cpgi.gr, shores=GenomicRanges::setdiff(shores, cpgi.gr), shelves=GenomicRanges::setdiff(shelves, c(shores, cpgi.gr))))
}


#' plot eDMR distribution over the subject genomic ranges
#' @param myDMR DMRs predicted by \code{edmr}.
#' @param subject GRanges list used to annotate DMRs.
#' @importFrom IRanges findOverlaps
#' @importFrom GenomicRanges GRanges
#' @export
plotdmrdistr=function(myDMR, subject){
  # countOverlapDMRs
  countOverlapDMRs=function(dmr,anno){
    x=findOverlaps(dmr,anno)
    unique(x@from)
  }
  col.list=c("#E41A1C","#377EB8","#984EA3","#4DAF4A","#FF7F00","#FFFF33", "#A65628", "#8DD3C7"  )
  #int=lapply(subject, function(x)intersect(myDMR,x))G
  int=lapply(subject, function(x)countOverlapDMRs(myDMR,x))
  res0=sapply(int, length)
  int.gr=GRanges();for(i in length(int)) {int.gr=append(int.gr,int[[i]])}
  unannotated=length(myDMR)-length(int.gr)
  res0=c(res0, unannotated)
  names(res0)[length(res0)]="un-anno"
  print(res0)
  barplot(res0, col=col.list[1:length(res0)], las=2)  
}


#' get gene list based the genebody granges
#' @export
#' @param myDMR DMRs predicted by \code{edmr}.
#' @param subject GRanges used to annotate DMRs. For example, use promoter in genebody will annotate the DMRs using promoters
#' @param id.type the column names that will be used to annotate the DMR. default: "gene.symbol"
#' @importFrom IRanges findOverlaps
#' @importFrom IRanges values
get.dmr.genes=function(myDMR, subject, id.type="gene.symbol"){
  ind=findOverlaps(subject,myDMR)
  unique(values(subject)[unique(ind@to), id.type])
}

#' get hyper-methylated DMRs
#' @export
#' @param myDMR DMRs predicted by \code{edmr}.
#' @importFrom IRanges values
get.hyper.dmr=function(myDMR){
  myDMR[which(values(myDMR)[,"mean.meth.diff"]>0)]
}
#' get hypo-methylated DMRs
#' @export
#' @param myDMR DMRs predicted by \code{edmr}.
#' @importFrom IRanges values
get.hypo.dmr=function(myDMR){
  myDMR[which(values(myDMR)[,"mean.meth.diff"]<0)]
}
