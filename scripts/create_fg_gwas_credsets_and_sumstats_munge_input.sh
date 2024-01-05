#!/bin/env bash

mkdir -p fg
cd fg
gsutil -mq cp gs://finngen-production-library-green/finngen_R12/finngen_R12_analysis_data/finemap/summary/* .
ls -1 *.SUSIE.snp.filter.tsv | xargs -I{} basename {} .SUSIE.snp.filter.tsv > traits

# join snp files with credible set files
while read trait; do
    echo $trait
    join -t $'\t' -1 5 -2 3 \
	 <(cat $trait.SUSIE.snp.filter.tsv | awk '
BEGIN {FS=OFS="\t"}
NR==1 {$4="#cs_id"; print $0}
NR>1 && $4!=-1 {$4=$2"_"$4; print $0}
' | nl -nln | sort -b -k5,5) \
	 <(cat $trait.SUSIE.cred.summary.tsv | awk '
BEGIN{FS=OFS="\t"}
NR==1{$3="#cs_id"; print $0}
NR>1 {$3=$2"_"$3; print $0}
' | sort -k3,3) | \
	sort -b -k2,2g | cut -f1,3-25 > ${trait}.SUSIE.munged.tsv
done < traits

# create credible sets munge input
while read line; do
    echo -e "FinnGen_R12\tGWAS\t$line"
done < <(ls -d "$PWD/"*.SUSIE.munged.tsv) > ../../nf/metadata/fg_r12_gwas_credible_sets_munge_input.tsv

# create sumstats munge input
gsutil ls gs://finngen-production-library-green/finngen_R12/finngen_R12_analysis_data/summary_stats/release/*.gz | awk '
BEGIN{OFS="\t"}
{print "FinnGen_R12","GWAS",$1}
' > ../../nf/metadata/fg_r12_gwas_sumstats_munge_input.tsv
