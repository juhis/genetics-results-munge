nextflow.enable.dsl=2

process munge_sumstat {

    //maxForks 50
    cpus 1
    memory 2.GB
    disk 200.GB

    input:
      tuple val(dataset), val(data_type), path(sumstat)
      val resource
      val split_variant_to_cpra
      val add_trait_from_filename
      val prefix_remove
      val suffix_remove
      val columns
      val trait_col
      val variant_col
      val chr_col
      val pval_col
      val pval_thres
      val take_log_of_p
      val trait_col_index
      val chr_col_index
      val pos_col_index
      val ref_col_index
      val alt_col_index
      val col_offset
    output:
      path '*.munged.tsv.gz', emit: tsv
    shell:
      template 'munge.sh'
}

process merge_sumstats {

    cpus 4
    memory 8.GB
    disk 2000.GB
    publishDir "$params.outdir"

    input:
      path('*')
      val batch_size
      val first_out_columns
      val out_columns
      val col_offset
      val trait_col_index
      val chr_col_index
      val pos_col_index
      val ref_col_index
      val alt_col_index
      val filename
    output:
      path '*.gz'
      path '*.gz.tbi'
    shell:
      template 'merge_sumstats.sh'
}

workflow {

    munge_input = channel
      .fromPath(params.metadata_loc)
      .splitCsv(sep: "\t")
      .map { row -> [row[0], row[1], file(row[2])] }
  
    munge_sumstat(
      munge_input,
      channel.value(params.resource),
      channel.value(params.split_variant_to_cpra),
      channel.value(params.add_trait_from_filename),
      channel.value(params.prefix_remove),
      channel.value(params.suffix_remove),
      channel.value(params.columns),
      channel.value(params.trait_col),
      channel.value(params.variant_col),
      channel.value(params.chr_col),
      channel.value(params.pval_col),
      channel.value(params.pval_thres),
      channel.value(params.take_log_of_p),
      channel.value(params.trait_col_index),
      channel.value(params.chr_col_index),
      channel.value(params.pos_col_index),
      channel.value(params.ref_col_index),
      channel.value(params.alt_col_index),
      channel.value(params.col_offset)
    )

    merge_sumstats(
      munge_sumstat.out.tsv | collect,
      channel.value(params.batch_size),
      channel.value(params.first_out_columns),
      channel.value(params.out_columns),
      channel.value(params.col_offset),
      channel.value(params.trait_col_index),
      channel.value(params.chr_col_index),
      channel.value(params.pos_col_index),
      channel.value(params.ref_col_index),
      channel.value(params.alt_col_index),
      channel.value(params.filename)
    )
}
