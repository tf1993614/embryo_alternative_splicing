#！/bin/bash

# Date: 22.11.2023
# Author: Feng Tang
# Email: 763615402@qq.com


set -e
set -u
set -o pipefail

show_help () {
	echo "Usage: $0 -r <regular expression> -d <path to the directory>"
	echo "a function to get the directory path containing your wanted files"
	echo "Argument list:"
 	echo "-r, --regular_expression: regualar expression matching the file name you want to find"
	echo "-d, --directory: directory where you want to search your wanted files recursively"
	echo "-filter (optional): regular expression to filter out unwanted path"
 	exit 1
}

# default setting
rexp=""
dir=""
filter=""

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
			;;
		*)
			echo "unvalid argument"
			show_help
			exit 1
			;;
	esac
done

# chek whether necessary two arguments are provided
if [ -z "${rexp}" ] || [ -z ${dir} ]
then
	        show_help
		exit 1
fi
	

paths=$(find ${dir} -name "${rexp}" -type f)

bash_array=()
index=0
cycle_number=1

for path in ${paths}
do	
	# get the path length
	length=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" "{print NF;exit}")
	# path length minus one to get the directory containing the target file
	length=$(($length - 1))
	# stitch the path
	output=$(echo ${path} | sed 's/\//\t/g' | cut -f1-${length}| sed 's/\t/\//g')
	# put the stitched path into bash array
	bash_array[${index}]=${output}
	# increase the index of bash arrch in each cycle
	index=$(($index + $cycle_number))
done

# when -filter is specified
if [ ! -z ${filter} ]
then
	echo ${bash_array[@]} | sed 's/ /\n/g'| sort | uniq | grep -v ${filter}
fi

# when -filter is not specified
if [ -z ${filter} ]
then
	echo ${bash_array[@]} | sed 's/ /\n/g'| sort | uniq
fi
