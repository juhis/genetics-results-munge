#!/usr/bin/env bash

set -euxo pipefail

# input:  a (gzipped) tab-delimited sumstat uri
# output: a headerless p-value filtered bgzipped sumstat file
#
# adds as first three columns
# 1) a given resource name
# 2) a given dataset name
# 3) data type (e.g. pQTL or GWAS)
#
# subsets the sumstat to given columns
# filters the sumstat to p-values below the given threshold (threshold can be 1 for no filtering)
# possibly convert p-value to -log10(p-value)
# if p-value == 0, -log10(p-value) will be 324 # TODO compute from beta and se
# outputs only unique rows (in the input data variants with several rsids might be duplicated for example)
# sort order in the output will be chromosome, position, alleles and trait
# 
# possible chr prefix will be removed, possible 23 will be changed to X

chr_col_out=$((!{chr_col_index} + !{col_offset}))
pos_col_out=$((!{pos_col_index} + !{col_offset}))
ref_col_out=$((!{ref_col_index} + !{col_offset}))
alt_col_out=$((!{alt_col_index} + !{col_offset}))
trait_col_out=$((!{trait_col_index} + !{col_offset}))

catcmd() {
    zcat -f !{sumstat}
}
if [[ "!{add_trait_from_filename}" == "true" ]]; then
    trait=`basename !{sumstat} | sed 's/^!{prefix_remove}//' | sed 's/!{suffix_remove}$//'`
    catcmd() {
	zcat -f !{sumstat} | awk -v trait=$trait 'BEGIN {FS=OFS="\t"} NR==1 {print "!{trait_col}",$0} NR>1 {print trait,$0}'
    }
fi

catcmd | awk '
BEGIN {FS=OFS="\t"}
NR==1 {
  for(i=1;i<=NF;i++) {
    h[$i]=i;
  }
  if ("!{split_variant_to_cpra}" == "true") {
    h["chr"]=NF+1;
    h["pos"]=NF+2;
    h["ref"]=NF+3;
    h["alt"]=NF+4;
  }
  split("!{columns}", col_arr, " ");
  for(i=1;i<=length(col_arr);i++) {
    if(!(col_arr[i] in h)) {
      print "column "col_arr[i]" not in the sumstat file , quitting" > "/dev/stderr";
      exit 1;
    }
  }
}
NR>1 && $h["!{pval_col}"] <= !{pval_thres} {
  # split variant id to chr,pos,ref,alt and insert them as last columns
  if ("!{split_variant_to_cpra}" == "true") {
    split($h["!{variant_col}"], cpra, "_");
    for (i=1; i<=4; i++) {
      $(NF+1) = cpra[i];
    }
  }

  # in chromosome name remove chr prefix and replace 23 with X
  chr=$h["!{chr_col}"];
  sub("^chr", "", chr);
  if(chr==23) chr="X";
  $h["!{chr_col}"]=chr;

  if ("!{take_log_of_p}" == "true") {
    # replace p-value with -log10(p-value), or 324 if p-value is 0
    pval=$h["!{pval_col}"];
    if (pval == 0) mlog10p=324;
    else mlog10p=-log(pval)/log(10);
    $h["!{pval_col}"]=mlog10p;
  }

  printf "!{resource}\t!{dataset}\t!{data_type}";
  for(i=1;i<=length(col_arr);i++) {
    printf "\t"$h[col_arr[i]];
  }

  printf "\n";
}' | \
sort \
-k${chr_col_out},${chr_col_out}V \
-k${pos_col_out},${pos_col_out}g \
-k${ref_col_out},${alt_col_out} \
-k${trait_col_out},${trait_col_out} | \
uniq | \
bgzip > !{sumstat}.munged.tsv.gz
