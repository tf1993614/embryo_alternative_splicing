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
		dir=$2
   	fi
	

	echo "target dir is ${dir}"
	echo $path | xargs -P 8 -I{} fastq-dump --split-files {} --outdir ${dir} 
	echo "finish sra to fastq conversion for ${mame}"

done
