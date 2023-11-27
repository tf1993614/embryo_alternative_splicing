#!/bin/bash

# Date: 22.11.23 
# Author: Feng Tang
# Email: 763615402@qq.com	

set -e
set -u
set -o pipefail

# default setting
dir=""
target_dir=""
element=""

show_help () {
echo "Usage: $0 -d <directory to the file> -fd <target directory>"
echo "A function to convert SRA file to fastq file"
echo "Argument list:"
echo "-d: directory where you want to search file recursively"
echo "-td (optional): target directory where you want to write file. If it is not specified, the fastq file will be written into the same directory where SRA file settles in"
echo "-element (optional): numeric range to determine how many element you want to retrieve from the founded file path when -td is specified"
exit 1
}
	

while [ "$#" -gt 0 ]
do
	case "$1" in
		-d)
			dir="$2"
			shift 2
			;;
		-td)
			target_dir="$2"
			shift 2
			;;
		-element)
			element="$2"
			shift 2
			;;
		--help)
			show_help
			exit 1
			;;
		*)
			echo "Unvalid argument"
			show_help
			exit 1
			;;
	esac
done

# when -d is not specified
if [ -z ${dir} ]
then
	echo "Necessary argument '-d' should be provided"
	show_help
	exit 1
fi


paths=$(find ${dir} -name "*.sra" -type f)

# show the file path and let user to decide whether continue the program
echo "file path is shown below:"
echo ${paths} | sed 's/ /\n/g' | sort -k1n
read -p "Do you want to continue? (y/n) " goon
if [ $goon != "y" ]
then
	exit 1
fi

for path in ${paths}
do 
{
	name=$(basename -s ".sra" ${path})
	echo -e "\033[34m $(date +'%F %X') \033[0m | working on \033[31m${name}\033[0m"
	length=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" "{print NF;exit}")
	# get the directory containing founded file
	odir=$(echo ${path} | sed 's/\//\t/g' | cut -f1-$(($length - 1)) | sed 's/\t/\//g')
	
	# when -td is not specified
	tdir=${odir}

        # when -td is only specified
        if [ ! -z ${target_dir} ] && [ -z ${element} ]
	then
		tdir=${target_dir}
	fi		
	
	# when -td and -element are specified
	if [ ! -z ${target_dir} ] && [ ! -z ${element} ]
	then 

		append=$(echo ${odir} | sed 's/\//\t/g' | cut -f${element} | sed 's/\t/\//g')
		tdir="${target_dir}${append}"
		echo ${tdir}
	
   	fi
	

	echo -e "\033[34m $(date +'%F %X') \033[0m | target dir is \033[31m${tdir}\033[0m"
	echo $path | xargs -P 8 -I{} fastq-dump --split-files --gzip {} --outdir ${tdir} 
	echo "\033[34m $(date +'%F %X') \033[0m | finish sra to fastq conversion for \033[31m${name}\033[0m"

	echo "\033[34m $(date +'%F %X') \033[0m | rename fastq files to suit cell ranger name convention"
	
	# when XXX_1.fastq.gz exists
	if [ -e "${tdir}/${name}_1.fastq.gz" ]
	then
		mv "${tdir}/${name}_1.fastq.gz" "${tdir}/${name}_S1_L001_R1_001.fastq.gz"
	fi

	# when XXX_2.fastq.gz exists
	if [ -e "${tdir}/${name}_2.fastq.gz" ]
        then
                mv "${tdir}/${name}_2.fastq.gz" "${tdir}/${name}_S1_L001_R2_001.fastq.gz"
        fi

  	# when XXX_3.fastq.gz exists
	if [ -e "${tdir}/${name}_3.fastq.gz" ]
        then
                mv "${tdir}/${name}_3.fastq.gz" "${tdir}/${name}_S1_L001_I1_001.fastq.gz"
        fi

	# when XXX_4.fastq.gz exists
        if [ -e "${tdir}/${name}_4.fastq.gz" ]
        then
                mv "${tdir}/${name}_4.fastq.gz" "${tdir}/${name}_S1_L001_I2_001.fastq.gz"
        fi

	echo "\033[34m $(date +'%F %X') \033[0m | finish renaming for \033[31m${name}\033[0m"

}& 
done 
wait
