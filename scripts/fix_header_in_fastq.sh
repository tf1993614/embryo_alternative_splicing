#!/bin/bash

# Date: 22.11.2023
# Author: Feng Tang
# Email: 763615402@qq.com

set -e
set -u
set -o pipefail

show_help () {
 echo "Usage: $0 -d <path to the directory> -r <regular expression>"
 echo "a function to fix header by replacing the first space with _ in fastq file"
 echo "Argument list:"
 echo "-r,--regular_expression: regular expression to match the fastq file you want to fix"
 echo "-d, --directory: directory where you want to search your wanted files recursively"
 echo "-filter (optional): regular expression to filter out unwanted output"
}

# default setting
rexp=""
dir=""
filter=""

# when no argument, help page is shown
if [ "$#" -eq 0 ]
then
	show_help
fi

while [ "$#" -gt 0 ]
do 
	case "$1" in
		-r|--regular_expression)
			rexp="$2"
			shift 2
			;;
		-d|--directory)
			dir="$2"
			shift 2
			;;
		-filter)
			filter="$2"
			shift 2
			;;
		-h|--help)
			show_help
			shift 2
			;;
		*)
			echo "unvalid argument"
			show_help
			exit 1
			;;
	esac
done

# when -r or -d is not specified, help page is shown
if [ -z ${rexp} ] || [ -z ${dir} ]
then
	        show_help
		exit 1
fi

# when filter is not specified
if [ -z ${filter} ]
then
	fastq_files=$(find ${dir} -name ${rexp} -type f)
fi

# when filter is specified
if [ ! -z ${filter} ]
then
	fastq_files=$(find ${dir} -name ${rexp} -type f | grep -v ${filter})
fi

# show the file path and let user to continue the program or not
echo "file path is shown below:"
echo ${fastq_files} | sed 's/ /\n/g' | sort -k1n
read -p "Do you want to continue? (y/n) " goodn
if [ ${goodn} != "y" ]
then
	exit 1
fi

for file in ${fastq_files}
do
{
	length=$(echo ${file} | sed 's/\//\t/g' | awk -F "\t" "{print NF;exit}")
	length=$(($length - 1))
	final_dir=$(echo ${file} | sed 's/\//\t/g' | cut -f1-${length} | sed 's/\t/\//g')
	file_name="${final_dir}/new$(basename ${file})"
	echo -e "\033[34m$(date +'%F %X')\033[0m | fixing header in \033[31m$(basename ${file})\033[0m"
	zcat ${file} | awk '{if(NR % 4 == 1){sub(/ /, "_");print} else {print}}' | gzip > ${file_name}
	echo -e "\033[34m$(date +'%F %X')\033[0m | fixed file write to \033[31m${file_name}\033[0m"	
}&
done
wait
