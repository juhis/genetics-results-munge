#!/bin/bash

gsutil ls gs://finngen-public-data-r9/summary_stats/*.gz | \
awk 'BEGIN{OFS="\t"} {print "FinnGen_R9","GWAS",$0}' \
> ../nf/metadata/fg_r9_gwas_sumstats_munge_input.tsv
