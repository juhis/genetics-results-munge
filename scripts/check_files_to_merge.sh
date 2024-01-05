#!/bin/bash

cat ../nf/metadata/sumstats_newest_finngen_loc | while read line; do
    gsutil cat $line | zcat | head -2
done | column -t

cat ../nf/metadata/credible_sets_newest_finngen_loc | while read line; do
    gsutil cat $line | zcat | head -2
done | column -t
