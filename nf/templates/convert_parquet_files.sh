#!/usr/bin/env bash

set -euxo pipefail

# input: all sumstat parquet files in the current directory (*.parquet)
# output: a headerless bgzipped tsv file
# 
# adds as first three columns
# 1) a given resource name
# 2) a given dataset name
# 3) a given data type (e.g. pQTL or GWAS)
#
# subsets the sumstats to given columns
# filters out studies whose study_id matches the given regex
# filters out consecutive identical rows
# 
# output is sorted by chromosome, position, alleles and trait

chr_col_out=$((!{chr_col_index} + !{col_offset}))
pos_col_out=$((!{pos_col_index} + !{col_offset}))
ref_col_out=$((!{ref_col_index} + !{col_offset}))
alt_col_out=$((!{alt_col_index} + !{col_offset}))
trait_col_out=$((!{trait_col_index} + !{col_offset}))

python-cat() {
python3 <<EOF
import pyarrow.parquet as pq
import glob
import math
import sys
import re

IGNORE_REGEX = re.compile("!{ignore_study_regex}", re.IGNORECASE)

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

for fpath in sorted(glob.glob("*.parquet")):
    tbl = pq.ParquetFile(fpath)
    if tbl.num_row_groups > 1:
        eprint(f"unexpectedly, there are multiple row groups, quitting. {fpath}")
        quit(1)
    row_group = tbl.read_row_group(0, !{columns})
    study_col_idx = row_group.column_names.index("!{study_col}")
    pval_col_idx = row_group.column_names.index("!{pval_col}")
    for batch in row_group.to_batches():
        for row in zip(*batch.columns):
            if IGNORE_REGEX.match(str(row[study_col_idx])) is None:
                mlog10p = round(-math.log10(row[pval_col_idx].as_py()), 3)
                print("\t".join(!{first_out_columns_content} + [str(col) if i != pval_col_idx else str(mlog10p) for i,col in enumerate(row)]))
EOF
}

echo `date` start chunk !{idx}
ls -1 *.parquet
python-cat | \
sort \
-k${chr_col_out},${chr_col_out}V \
-k${pos_col_out},${pos_col_out}g \
-k${ref_col_out},${alt_col_out} \
-k${trait_col_out},${trait_col_out} | \
uniq | bgzip > !{idx}.tsv.gz
echo `date` end chunk !{idx}
