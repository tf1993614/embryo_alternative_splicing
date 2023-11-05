# Embryo alternative splicing project


## SRA to fastq conversion

All single cell raw sequencing files (SRA) were downloaded by lanxiang Li using SRAtoolKit (version: 3.0.6). Metadata files are in the **embryo_data.xlsx**.

All raw SRA files are in `/mnt/disk2/disk_new2/`

SRA to fastq conversion was done by the script (**sra2fastq.sh**) written by Feng Tang. Code is shown below. 

	#!/bin/bash

	set -e
	set -u
	set -o pipefail


	if [ "$#" -eq 0 ]
	then
        	echo "Warning: fist argument showing the top directory containing SRA files for each oragnism must be supplied. E.g. 'bash $0 /mnt/disk2/disk_new2/Human_data/'"
        	echo "Warning: second argument is optional and should be the directory you want to output your results. Otherwise the default directory of SRA files will be used to output results"
        	exit 1
	fi

	paths=$(find "$1" -name "*.sra")

	for path in ${paths}
	do
        	name=$(basename -s ".sra" ${path})
        	echo "wokring on ${name}"

        	dir=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" '{print $1 "/" $2 "/" $3 "/" $4 "/" $5 "/" $6 "/" $7 "/" $8 "/"}')

        	if [ "$#" -eq 2 ]
        	then

                	echo "Warning: second argument is optional and should be the path to your output.Otherwise the default directory of SRA file will be used to output results"
                	append=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" -v OFS="/" '{print $5,$6,$7,$8}')
                	dir="$2/${append}"
        	fi


        	echo "target dir is ${dir}"
        	echo $path | xargs -I{} fastq-dump --split-files --gzip {} --outdir ${dir}
        	echo "finish sra to fastq conversion for ${mame}"

		
		echo "rename fastq files to suit cell ranger name convention"
        	mv "${dir}/${name}_1.fastq.gz" "${dir}/${name}_S1_L001_R1_001.fastq.gz"
        	mv "${dir}/${name}_2.fastq.gz" "${dir}/${name}_S1_L001_R2_001.fastq.gz"
        	echo "finish renaming for ${name}"

	done


To parallelly run `sra2fastq.sh`, we can run `getfiles.sh` to get the directories containing SRA files, for example:
	
	bash getfiles.sh  /mnt/disk2/disk_new2/Human_data > samples.txt     #The result of `getfiles.sh` is shown in the samples.txt. 

Then，run following code:
	
	parallel -a samples.txt bash sra2fastq.sh

If want to change the output directory in the parallel run:
	
	parallel -a samples.txt -a samples2.txt bash sra2fastq.sh    # samples2.txt contains output directory


## Cellranger pipeline

The following reference transcriptomes were downloaded from [10x Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads#reference-downloads) website. 

md5sum check values provied by the 10x genomics:
1. refdata-gex-GRCh38-2020-A.tar.gz      **md5sum**: dfd654de39bff23917471e7fcc7a00cd
2. refdata-gex-mm10-2020-A.tar.gz        **md5sum**: 886eeddde8731ffb58552d0bb81f533d 		

Our own md5sum check values:
- dfd654de39bff23917471e7fcc7a00cd       refdata-gex-GRCh38-2020-A.tar.gz
- 886eeddde8731ffb58552d0bb81f533d       refdata-gex-mm10-2020-A.tar.gz

