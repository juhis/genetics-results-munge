nextflow.enable.dsl=2

process merge_resources {

    cpus 4
    memory 4.GB
    disk 1000.GB
    publishDir "$params.outdir"

    input:
      path('*')
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
      template 'merge_resources.sh'
}

workflow {

    input_files = channel
      .fromPath(params.resource_files_loc)
      .splitText { it.strip() }
      .map { it -> file(it) }
      | collect
    
    merge_resources(
      input_files,
      channel.value(params.trait_col_index),
      channel.value(params.chr_col_index),
      channel.value(params.pos_col_index),
      channel.value(params.ref_col_index),
      channel.value(params.alt_col_index),
      channel.value(params.filename)
    )
}
