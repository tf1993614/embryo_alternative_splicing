#！/bin/bash


paths=$(find "$1" -name "*.sra")

for path in ${paths}
do
	dir=$(echo ${path} | sed 's/\//\t/g' | awk -F "\t" '{print $1 "/" $2 "/" $3 "/" $4 "/" $5 "/" $6 "/" $7 "/" $8 "/"}')
	echo ${dir}
done
