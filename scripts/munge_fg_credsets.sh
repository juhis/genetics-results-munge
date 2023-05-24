#!/bin/env bash

mkdir -p fg
cd fg
gsutil -mq cp gs://finngen-public-data-r9/finemapping/summary/* .
ls -1 *.SUSIE.snp.filter.tsv | xargs -I{} basename {} .SUSIE.snp.filter.tsv > traits

while read trait; do
    echo $trait
    join -t $'\t' -1 5 -2 3 \
	 <(cat $trait.SUSIE.snp.filter.tsv | awk '
BEGIN{FS=OFS="\t"} NR==1 {$4="#cs_id"; print $0} NR>1&&$4!=-1 {$4=$2"_"$4; print $0}
' | nl -nln | sort -b -k5,5) \
	 <(cat $trait.SUSIE.cred.summary.tsv | awk '
BEGIN{FS=OFS="\t"} NR==1{$3="#cs_id"; print $0} NR>1{$3=$2"_"$3; print $0}
' | sort -k3,3) | \
	sort -b -k2,2g | cut -f1,3-25 > ${trait}.SUSIE.munged.tsv
done < traits

while read line; do
    echo -e "FinnGen_R9\tGWAS\t$line"
done < <(ls -d "$PWD/"*.SUSIE.munged.tsv) > ../../nf/metadata/fg_r9_gwas_credible_sets_munge_input.tsv
