#!/bin/bash

set -e
set -u
set -o pipefail

trans="/data/embryo_alternative_splicing/human_data/human_transcriptome_index/refdata-gex-GRCh38-2020-A"
file=$1
 
name=$(basename -s ".fastq.gz" ${file})
id="run_count_${name}"
cellranger count --noexit --id=${id} --fastqs=${file} --sample=${name} --transcriptome=${trans}
