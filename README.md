# genetics-results-munge
Workflows to collect and harmonize results from various human genetics resources


These Nextflow workflows are used to collect genetic association and fine-mapping results from:

- eQTL Catalogue (associations and fine-mapping)
- Open Targets (associations)
- FinnGen (associations and fine-mapping)
- deCODE pQTLs (associations)

See [here](https://www.nextflow.io/docs/latest/getstarted.html) for information on getting started with Nextflow.

As inputs the workflows take per-trait tsv association result files or tsv fine-mapped credible set files. For Open Targets, the inputs are association result parquet files instead.

The output of the workflows is a tabixed bgzipped tsv file containing all (or p-value filtered) results from each resource ([nf/merge.nf](nf/merge.nf) and [nf/merge_ot.nf](nf/merge_ot.nf)), or all resources combined ([nf/merge_resources.nf](nf/merge_resources.nf)).

## merge.nf

The workflow [nf/merge.nf](nf/merge.nf) is used for all resources except Open Targets. The workflow reads in tsv summary stat files or tsv variant-level fine-mapped credible set files of a given resource, optionally filters them by p-value, and outputs a bgzipped tabixed file containing the results from the resource. In practice association results are filtered by p-value and credible sets are not filtered. Columns from the original files can be subsetted and renamed. p-values can be converted to -log10(p). The output is sorted by chromosome, position, reference allele, alternative allele and trait name.

Config files:

| resource | associations | credible sets |
| --- | --- | --- |
| eQTL Catalogue R6 | [nf/config/merge.eqtl_r6_sumstats.config](nf/config/merge.eqtl_r6_sumstats.config) | [nf/config/merge.eqtl_r6_credible_sets.config](nf/config/merge.eqtl_r6_credible_sets.config) |
| FinnGen R8 | [nf/config/merge.finngen_r8_sumstats.config](nf/config/merge.finngen_r8_sumstats.config) | [nf/config/merge.finngen_r8_credible_sets.config](nf/config/merge.finngen_r8_credible_sets.config) |
| deCODE pQTL | [nf/config/merge.decode_pqtl_sumstats.config](nf/config/merge.decode_pqtl_sumstats.config) | NA |

Running:

The config files allow the workflows be run locally or in Google Compute Engine using Cloud Life Sciences API. If run locally, input files can be given as bucket uris, or they can be copied on the machine up front. If run in the cloud, input files can be given as bucket uris. Generally fine-mapping result files are small enough to run locally whereas full association result files are bigger and spreading the compute can make sense, though there will be overhead from localization/delocalization of files.

The jobs are by default run with the GCR docker image `eu.gcr.io/finngen-refinery-dev/bioinformatics`. Any other image that has htslib (bgzip and tabix) installed may be speficied in the config files, or `docker.enabled` can be set to false if run locally and htslib is installed.

If run in the cloud, `GOOGLE_WORKDIR`, `GOOGLE_PROJECT` and `GOOGLE_SERVACC` environment variables need to be set, see [nf/nextflow.config](nf/nextflow.config)

### Example run: Merge eQTL Catalogue R6 fine-mapped credible sets locally:

Define input file locations in `params.metadata_loc` in [nf/config/merge.eqtl_r6_credible_sets.config](nf/config/merge.eqtl_r6_credible_sets.config) and run:

```
nextflow run merge.nf -c config/merge.eqtl_r6_cs.config -profile local -resume
```

Output:

```
zcat eQTL_Catalogue_R6_credible_sets.tsv.gz | head -5 | column -t
#resource          dataset    data_type  trait                               chr  pos    ref  alt  mlog10p  beta      se        pip                cs_id                                  cs_size  cs_min_r2
eQTL_Catalogue_R6  QTD000166  eQTL       ENSG00000241860                     1    14677  G    A    6.21444  1.05262   0.204029  0.99222694393951   ENSG00000241860_L1                     1        1
eQTL_Catalogue_R6  QTD000168  eQTL       ENST00000491962                     1    14677  G    A    7.02102  1.17782   0.212414  0.999084805701857  ENST00000491962_L1                     1        1
eQTL_Catalogue_R6  QTD000177  eQTL       ENSG00000228794.11_1_842002_842020  1    17730  C    A    5.748    0.980972  0.197784  0.961950560365049  ENSG00000228794.11_1_842002_842020_L1  1        1
eQTL_Catalogue_R6  QTD000336  eQTL       ENSG00000238009                     1    54490  G    A    4.59374  0.456505  0.106771  0.99999999818183   ENSG00000238009_L2                     1        1
```

## merge_ot.nf

TBA

## merge_resources.nf

The workflow [nf/merge_resources.nf](nf/merge_resources.nf) is used to further merge outputs of [nf/merge.nf](merge.nf) and [nf/merge_ot.nf](merge_ot.nf) into one tabixed file.

*NOTE* All input files to this workflow are assumed to be in the same format with the same columns, and the files must be sorted by chromosome, position, reference allele, alternative allele - otherwise the output is undefined and may be missing rows.

Config files:

- Associations: [nf/config/merge_resources.sumstats.config](nf/config/merge_resources.sumstats.config)
- Credible sets: [nf/config/merge_resources.credible_sets.config](nf/config/merge_resources.credible_sets.config)

BBJ and UKBB fine-mapping results from [Kanai et. al 2021](https://www.medrxiv.org/content/10.1101/2021.09.03.21262975v1) have been manually munged and used with this workflow.

### Example:

```
nextflow run merge_resources.nf -c config/merge_resources.credible_sets.config -profile local -resume
```

Output (one line for each resource):

```
zcat finemapped_resources_public_20230503.tsv.gz | awk '!seen[$1]++' | column -t
#resource          dataset     data_type  trait            chr  pos      ref  alt  mlog10p  beta        se          pip                cs_id                cs_size  cs_min_r2
eQTL_Catalogue_R6  QTD000166   eQTL       ENSG00000241860  1    14677    G    A    6.21444  1.05262     0.204029    0.99222694393951   ENSG00000241860_L1   1        1
FinnGen            FinnGen_R8  GWAS       G6_DEGENOTH      1    727717   G    C    5.49217  -0.345188   0.0741339   0.011555497160868  chr1:0-2313498_1     2        0.762486972025
UKBB_119           UKBB_119    GWAS       eGFRcys          1    922660   C    A    9.79588  1.2812e-02  2.0047e-03  8.6315e-02         1:0-4889757_2        11       0.807848630416
BBJ_79             BBJ_79      GWAS       LOY              1    3155345  C    T    11.0757  3.1295e-02  4.5805e-03  1.7427e-01         1:1597312-4597312_1  4        0.685497890704
```

