nextflow.enable.dsl=2

process munge_sumstat {

    cpus 2
    memory 2.GB
    disk 200.GB
    publishDir "$params.outdir"

    input:
      path(sumstat)
      path(ref_fasta)
      val chr_col
      val pos_col
      val ref_col
      val alt_col
      val beta_col
      val se_col
      val switch_alleles_for_id
    output:
      path '*.munged.tsv.gz', emit: tsv
      path '*.munged.tsv.gz.tbi', emit: tbi
    shell:
      template 'munge_dc_pqtl.sh'
}

workflow {

    //sumstats = channel.fromPath(params.sumstats_loc).splitText { it.strip() }.map { it -> file(it) }
    sumstats = channel.fromPath(params.sumstats_loc)
    
    munge_sumstat(
      sumstats,
      channel.value(params.ref_fasta),
      channel.value(params.chr_col),
      channel.value(params.pos_col),
      channel.value(params.ref_col),
      channel.value(params.alt_col),
      channel.value(params.beta_col),
      channel.value(params.se_col),
      channel.value(params.switch_alleles_for_id)
    )
}
