#!/bin/env bash

mkdir -p fg_rnaseq
cd fg_rnaseq
gsutil ls gs://finngen-production-library-red/EA5/multiome/batch1_3/gex_results/susie/*.SUSIE.snp.bgz > rnaseq_snpfiles
# filter for snps in non-low-purity credsets
while read file; do
    echo $file
    gsutil cat $file | zcat | awk '
    BEGIN {FS="\t"}
    NR==1 {for(i=1;i<=NF;i++) h[$i]=i; print $0}
    NR>1 && $h["cs"] != -1 && $h["low_purity"] == 0
    ' > `basename $file .bgz`.filter.tsv
done < rnaseq_snpfiles

# get unique cell types
ls -1 *.SUSIE.snp.filter.tsv | \
xargs -I{} basename {} .SUSIE.snp.filter.tsv | \
sed 's/predicted\.celltype\.//; s/\.chr[0-9|X]*//' \
| sort -u > traits

gsutil -mq cp gs://finngen-production-library-red/EA5/multiome/batch1_3/gex_results/susie/*.SUSIE.cred.bgz .
# combine chromosomes and join snp files with credible set files
while read trait; do
    echo $trait
    join -t $'\t' -1 17 -2 3 \
	 <(ls *.${trait}.chr*.SUSIE.snp.filter.tsv | sort -V | xargs cat | awk '
BEGIN {FS=OFS="\t"}
NR==1 {$16="#cs_id"; print $0,"cs_id"}
NR>1 && $1 != "trait" {$16=$2"_"$16; print $0,$16}
' | nl -nln | sort -b -k17,17) \
	 <(ls *.${trait}.chr*.SUSIE.cred.bgz | sort -V | xargs zcat | awk '
BEGIN {FS=OFS="\t"}
NR==1 {$3="#cs_id"; print $0,"cs_id"}
NR>1 && $1 != "trait" {$3=$2"_"$3; print $0,$3}
' | sort -k3,3) | \
	sort -b -k2,2g | cut -f1,3- > ${trait}.SUSIE.munged.tsv
done < traits

# create credible sets munge input
while read trait; do
    echo -e "FinnGen_${trait}_2023-10-05\teQTL\t`ls -d $PWD/${trait}.SUSIE.munged.tsv`"
done < traits > ../../nf/metadata/fg_rnaseq_credible_sets_munge_input.tsv

# create sumstats munge input
gsutil ls gs://r12-data/tmp_rnaseq/*.gz | while read line; do
    dataset=`basename $line .inv.cis_qtl_egenes.tsv.gz | \
    sed 's/integrated_gex_batches_filtered\.fgid\.predicted\.celltype\.//'`
    echo $line | awk -vdataset=$dataset '
    BEGIN{OFS="\t"}
    {print "FinnGen_"dataset"_2023-10-05","eQTL",$1}
    '
done > ../../nf/metadata/fg_rnaseq_sumstats_munge_input.tsv
