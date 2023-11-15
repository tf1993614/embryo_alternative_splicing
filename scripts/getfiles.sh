#！/bin/bash

set -e
set -u
set -o pipefail

paths=$(find "$2" -name "$1")
paths=$(echo ${paths} | sort | uniq)

bash_array=()
index=0
for_number=1

for path in ${paths}
do

	dir=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" -v OFS="/" 'NF==3{print $1,$2};NF==4{print $1,$2,$3};NF==5{print $1,$2,$3,$4};NF==6{print $1,$2,$3,$4,$5};NF==7{print $1,$2,$3,$4,$5,$6};NF==8{print $1,$2,$3,$4,$5,$6,$7}')
	bash_array[${index}]=${dir}
	index=$(($index + $for_number))
done

echo ${bash_array[@]} | sed 's/ /\n/g'| sort | uniq
