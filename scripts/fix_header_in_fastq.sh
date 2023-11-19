#!/bin/bash

set -e
set -u
set -o pipefail

if [ "$#" -lt 1 ]
then
	echo "First argument must be provided and should be the directory you want to search in"
	echo "Second argument is optional and should be regular expression to filter out unwanted file out of founded all files"
fi


fastq_files=$(find $1 -name "*.fastq.gz" -type f)

if [ "$#" -eq 2 ]
then
	fastq_files=$(echo ${fastq_files} | sed 's/ /\n/g' | grep -v $2)
fi


for file in ${fastq_files}
do
	dir=($(echo ${file} | sed 's/\//\t/g'))
	length=${#dir[@]}
	final_dir=$(echo ${file} | sed 's/\//\t/g' | cut -f1-${length} | sed 's/\t/\//g')
	file_name="${final_dir}/new$(basename ${file})"
	echo "fixing header in $(basename ${file})"
	zcat ${file} | awk '{if(NR % 4 == 1){sub(/ /, "_");print} else {print}}' | gzip > ${file_name}
	echo "fixed file write to ${file_name}"	
done
