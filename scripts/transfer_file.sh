#!/bin/bash

set -e 
set -u
set -o pipefail

if [ "$#" -lt 3 ]
then
	echo "Warning two arguments should be provided"
	echo "First argument should be regular expression matching the file name you want to search"
	echo "Second argument should be directory you want to search in"
	echo "Third argument should be a file containing the target directory path in separate line. The number of line should be equivalent to the number of file "
	echo "Fourth argument is optional and should be extra regular expression to filter out your path"
fi	


expression=$1
bash_array=()
start_num=0

for path in $(find $2 -name ${expression} -type f)
do
	bash_array[start_num]=${path}
	start_num=$((${start_num} + 1))
done

if [ "$#" -eq 3 ]
then
	echo "file path is shown below:"
	echo ${bash_array[@]} | sed 's/ /\n/g' | sort -k1n
	cycle=($(echo ${bash_array[@]} | sed 's/ /\n/g' | sort -k1n))
	exit 1
fi


if [ "$#" -eq 4 ]
then 
	echo "file path is shown below:"
	echo ${bash_array[@]} | sed 's/ /\n/g' | grep $4 | sort -k1n
	cycle=($(echo ${bash_array[@]} | sed 's/ /\n/g' | grep $4 | sort -k1n))
fi

target_path=($(cat $3))

for index in $(seq 0 $((${#cycle[@]} - 1)))
do
	echo "transfering ${cycle[index]}"
	scp ${cycle[index]} "fengtang@192.168.157.40:${target_path[index]}"
	echo "finish transferring the file to ${target_path[index]}"
done
