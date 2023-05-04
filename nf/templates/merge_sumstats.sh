set -euxo pipefail

n_cpu=`grep -c ^processor /proc/cpuinfo`
chr_col=$((!{chr_col_index} + !{col_offset}))
pos_col=$((!{pos_col_index} + !{col_offset}))
ref_col=$((!{ref_col_index} + !{col_offset}))
alt_col=$((!{alt_col_index} + !{col_offset}))
trait_col=$((!{trait_col_index} + !{col_offset}))

echo `date` decompress
ls -1 *.tsv.gz | xargs -P $n_cpu -I{} gzip -d --force {}
ls -1 *.tsv | tr '\n' '\0' > merge_these

echo `date` merge
time \
cat \
<(echo "!{first_out_columns} !{out_columns}" | tr ' ' '\t') \
<(sort \
-m \
-T . \
--parallel=$n_cpu \
--compress-program=gzip \
--files0-from=merge_these \
--batch-size=!{batch_size} \
-k${chr_col},${chr_col}V \
-k${pos_col},${pos_col}g \
-k${ref_col},${alt_col} \
-k${trait_col},${trait_col}) \
| bgzip -@$n_cpu > !{filename}

echo `date` tabix
tabix -s${chr_col} -b${pos_col} -e${pos_col} !{filename}

echo `date` end
