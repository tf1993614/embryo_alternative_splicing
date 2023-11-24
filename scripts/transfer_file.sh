#!/bin/bash

# Date: 21.11.2023
# Author: Feng Tang
# Email: 763615402@qq.com


# need to install sshpass
# run `conda install -c conda-forge sshpass` to install sshpass

set -e 
set -u
set -o pipefail

show_help () {
	echo "Usage: $0 -r <regular expression> -d <path to the diretcory> -f <file containing target directory in separate line> -p <password to visit the hhost> -host <host IP> -filter <filter out unwanted path>"
	echo "a function to transfer file from one host to another host"
	echo "Argument list:"
	echo "-r: regular expression to match file name you want to search"
	echo "-d: directory where you want to serch wanted file recursively"
	echo "-f: a file containing target directory in separate line. The number of line should be consistent with the number of founded file. If only one target path is provided, all foudned file will be transferred to there."
	echo "-p: password to visit another host"
	echo "-host: the IP address of another host"
	echo "-filter (optional): regular expression to filter out unwanted founded file"
	exit 1

}

# default setting
rexp=""
dir=""
file=""
password=""
host=""
filter=""

while [ "$#" -gt 0 ]
do
	case "$1" in
		-r)
			rexp="$2"
			shift 2
			;;
		-d)
			dir="$2"
			shift 2
			;;
		-f)
			file="$2"
			shift 2
			;;
		-p)
			password="$2"
			shift 2
			;;
		-host)
			host="$2"
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


# check whether necessary arguments are provided
if [ -z "${rexp}" ] || [ -z ${dir} ] || [ -z ${file} ] || [ -z ${host} ] || [ -z ${password} ] 
then
	show_help
	exit 1
fi


bash_array=()
start_num=0

# put file path into bash array
for path in $(find ${dir} -name "${rexp}" -type f)
do
	bash_array[start_num]=${path}
	start_num=$((${start_num} + 1))
done

# when -filter is not specified
if [ -z ${filter} ]
then
	echo "file path is shown below:"
	echo ${bash_array[@]} | sed 's/ /\n/g' | sort -k1n
	cycle=($(echo ${bash_array[@]} | sed 's/ /\n/g' | sort -k1n))
	# let user decide whether continuing the program or not
	read -p "Do you want to continue? (y/n) " goon
	if [ $goon != "y" ]
	then 
		exit 1
	fi
fi

# when -filter is specified
if [ ! -z ${filter} ]
then 
	echo "file path is shown below:"
	echo ${bash_array[@]} | sed 's/ /\n/g' | grep -v ${filter} | sort -k1n
	cycle=($(echo ${bash_array[@]} | sed 's/ /\n/g' | grep -v ${filter} | sort -k1n))
	read -p "Do you want to continue? (y/n) " goon
        if [ $goon != "y" ]
        then
                exit 1
        fi
fi

# get the target path in -f
target_path=($(cat ${file}))


# when the number of target path provided by -f is consistent with the number of founded files
if [ ${#target_path[@]} -eq ${#cycle[@]} ]
then
	for index in $(seq 0 $((${#cycle[@]} - 1)))
	do
		echo -e "\033[34m$(date +'%F %X')\033[0m | transfering \033[31m${cycle[index]}\033[0m"
		sshpass -p ${password} scp ${cycle[index]} "${host}:${target_path[index]}"
		echo -e "\033[34m$(date +'%F %X')\033[0m | finish transferring the file to \033[31m${target_path[index]}\033[0m"
	done
	echo "finish all transferring task"
fi


if [ ${#target_path[@]} -eq 1 ]
then

		index2=0
	        for index in $(seq 0 $((${#cycle[@]} - 1)))
	 	do
			echo -e "\033[34m$(date +'%F %X')\033[0m | transfering \033[31m${cycle[index]}\033[0m"
			sshpass -p ${password} scp ${cycle[index]} "${host}:${target_path[index2]}"
			echo -e "\033[34m$(date +'%F %X')\033[0m | finish transferring the file to \033[31m${target_path[index2]}\033[0m"
		done
fi
