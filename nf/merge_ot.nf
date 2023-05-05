nextflow.enable.dsl=2

process convert_parquet_files {

    cpus 2
    memory 4.GB
    disk 20.GB

    input:
      tuple val(idx), path(parquet_files)
      val first_out_columns_content
      val columns
      val study_col
      val pval_col
      val col_offset
      val trait_col_index
      val chr_col_index
      val pos_col_index
      val ref_col_index
      val alt_col_index
      val ignore_study_regex
    output:
      path '*.tsv.gz', emit: tsv
    shell:
      template 'convert_parquet_files.sh'
}

process merge_sumstats {

    cpus 4
    memory 8.GB
    disk 500.GB
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

    def cnt = 1
    parquet_files = channel.fromPath(params.parquet_files_loc)
    convert_parquet_files(parquet_files | toSortedList | flatten | collate(params.chunk_size) | map { tuple(cnt++, it) },
      channel.value(params.first_out_columns_content),
      channel.value(params.columns),
      channel.value(params.study_col),
      channel.value(params.pval_col),
      channel.value(params.col_offset),
      channel.value(params.trait_col_index),
      channel.value(params.chr_col_index),
      channel.value(params.pos_col_index),
      channel.value(params.ref_col_index),
      channel.value(params.alt_col_index),
      channel.value(params.ignore_study_regex)
    )
    // sorting not actually necessary here but included in case something else will be done with the chunks			  
    merge_sumstats(convert_parquet_files.out.tsv | collect(sort: { it.simpleName.toInteger() }),
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
