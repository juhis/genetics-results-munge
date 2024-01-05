set -euxo pipefail                 

echo "`date` converting sumstat to vcf"
                                   
python3 <<EOF | bgzip > vcf.gz

from datetime import date
import gzip
from collections import defaultdict

sumstat = "!{sumstat}"
chr_col = "!{chr_col}"
pos_col = "!{pos_col}"
ref_col = "!{ref_col}"
alt_col = "!{alt_col}"

print('##fileformat=VCFv4.0')

today = date.today()
print('##filedate=' + today.strftime('%Y%m%d'))

header_line = ['#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER', 'INFO']
print('\t'.join(header_line))

with gzip.open(sumstat, 'rt') as f:
    h_idx = {h:i for i,h in enumerate(f.readline().strip().split("\t"))}
    h_idx = defaultdict(lambda: 1e9, h_idx)

    for line in f:
        s = line.strip().split("\t")
        s = {i:v for i,v in enumerate(s)}
        s = defaultdict(lambda: '.', s)

        chr = str(s[h_idx[chr_col]])
        if chr == '23':
            chr = 'X'
        if chr == '24':
            chr = 'Y'
        if chr == '25':
            chr = 'M'
        if chr[:3] != 'chr':
            chr = 'chr' + chr

        pos = s[h_idx[pos_col]]
        ref = s[h_idx[ref_col]]
        alt = s[h_idx[alt_col]]
        id = ':'.join([chr, pos, alt, ref]) if "!{switch_alleles_for_id}" == "true" else ':'.join([chr, pos, ref, alt])
        qual = '.'
        filter = '.'
        info = '.'

        print('\t'.join([chr, pos, id, ref, alt, qual, filter, info]))

EOF

echo "`date` tabixing vcf"
tabix -s 1 -b 2 -e 2 vcf.gz

echo "`date` left aligning, removing 'invariants', joining original stats, computing mlog10p"
join -1 4 -2 3 -t$'\t' \
<(bcftools norm -f !{ref_fasta} vcf.gz -c ws -Ov | grep -Ev "^##" | awk '$5!="."' | nl -nln | sort -T . -b -k4,4) \
<(zcat !{sumstat} | awk 'BEGIN{OFS="\t"} NR==1{$3="ID"} 1' | sort -T . -k3,3) | \
sort -T . -k2,2g | cut -f1,3- | python3 <(cat <<EOF
import math
import scipy as sp
import fileinput
inp = fileinput.input()
line = inp.readline().strip().replace("#CHROM", "CHROM")
print("#ORIGINAL_" + line + "\tmlog10p")
h = {h: i for i, h in enumerate(line.strip().split("\t"))}
for line in inp:
  line = line.strip()
  s = line.split("\t")
  mlog10p = round(-sp.stats.norm.logsf(abs(float(s[h["!{beta_col}"]]))/float(s[h["!{se_col}"]]))/math.log(10) - math.log10(2), 4)
  print(line + "\t" + str(mlog10p))
EOF) | cut -f 1-5,11-15,17-20 | bgzip > `basename !{sumstat} .gz`.munged.tsv.gz

echo "`date` tabixing result"
tabix -s2 -b3 -e3 `basename !{sumstat} .gz`.munged.tsv.gz

echo "`date` done"
