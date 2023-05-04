set -eux

n_cpu=`grep -c ^processor /proc/cpuinfo`

echo `date` merge
cmd="sort -m -T . -k!{chr_col_index},!{chr_col_index}V -k!{pos_col_index},!{pos_col_index}g -k!{ref_col_index},!{alt_col_index} -k!{trait_col_index},!{trait_col_index}"
for input in *.gz; do
    cmd="$cmd <(zcat -f '$input' | tail -n+2)"
done
cat <(ls -1 *.gz | head -1 | xargs zcat | head -1) <(eval "$cmd") | bgzip -@$n_cpu > !{filename}

echo `date` tabix
tabix -s!{chr_col_index} -b!{pos_col_index} -e!{pos_col_index} !{filename}

echo `date` end
