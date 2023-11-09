#!/bin/bash

set -e
set -u
set -o pipefail

trans="/home/fengtang/project/embryo_splicing_site/data/reference_genome/refdata-gex-GRCh38-2020-A"
file=$1

name=$(basename ${file})
id="run_count_${name}"
cellranger count --noexit --id=${id} --fastqs=${file} --sample=${name} --transcriptome=${trans}
