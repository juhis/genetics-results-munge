# download and munge GTEx RNA editing QTL significant results

set -euxo pipefail

wget https://storage.googleapis.com/gtex_analysis_v8/single_tissue_cisRNA_editing_QTL_data/GTEx_Analysis_v8_edQTL.tar
tar xvf GTEx_Analysis_v8_edQTL.tar

cat <(echo -e "#resource\tdataset\tdata_type\ttrait\tchr\tpos\tref\talt\tmlog10p\tbeta\tse") \
<(for file in *.signif_variant_site_pairs.txt.gz; do
    dataset=`basename $file .signif_variant_site_pairs.txt.gz`
    zcat $file | awk -vdataset=$dataset '
    BEGIN {OFS="\t"}
    NR==1 {
     for(i=1;i<=NF;i++) h[$i]=i;
    }
    NR >1 {
     split($h["variant_id"],cpra,"_");
     sub("^chr", "", cpra[1]);
     print "GTEx_v8_edQTL",dataset,"edQTL",$h["gene_id"],cpra[1],cpra[2],cpra[3],cpra[4],-log($h["pval_nominal"])/log(10),$h["slope"],$h["slope_se"]
    }'
  done | sort -k5,5V -k6,6g -k7,8 -k4,4) \
    | bgzip -@4 > GTEx_v8_edQTL.tsv.gz
