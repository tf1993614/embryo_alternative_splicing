# Embryo alternative splicing project


## SRA to fastq conversion

All single cell raw sequencing files (SRA) were downloaded by lanxiang Li using SRAtoolKit (version: 3.0.6). Original source description files are in the **embryo_data.xlsx**. Its clean version is `embryo_data(tidy up by Feng).csv`

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
	
	bash getfiles.sh "*.sra" /mnt/disk2/disk_new2/Human_data > samples.txt     #The result of `getfiles.sh` is shown in the samples.txt. 

Then，run following code:
	
	parallel -a samples.txt bash sra2fastq.sh

If want to change the output directory in the parallel run:
	
	parallel -a samples.txt -a samples2.txt bash sra2fastq.sh    # samples2.txt contains output directory


For raw sequencing files downloaded from GEO database, the sample attributes of each SRA file was obtained by running `GEO_crawl.R`

	R GEO_crawl.R

For raw sequencing files downloaded from arrayexpress database, the sample attributes of each sample was gained by visting the ArrayExpress website, for example:

- go to the webiste e.g. https://www.ebi.ac.uk/biostudies/arrayexpress/studies/E-MTAB-9388
- click `Download` icon to download  MAGE-TAB Files 


## Cellranger pipeline

The following reference transcriptomes were downloaded from [10x Genomics](https://www.10xgenomics.com/support/software/cell-ranger/downloads#reference-downloads) website. 

md5sum check values provied by the 10x genomics:
1. refdata-gex-GRCh38-2020-A.tar.gz      **md5sum**: dfd654de39bff23917471e7fcc7a00cd
2. refdata-gex-mm10-2020-A.tar.gz        **md5sum**: 886eeddde8731ffb58552d0bb81f533d 		

Our own md5sum check values:
- dfd654de39bff23917471e7fcc7a00cd       refdata-gex-GRCh38-2020-A.tar.gz
- 886eeddde8731ffb58552d0bb81f533d       refdata-gex-mm10-2020-A.tar.gz

We only run cellranger pipeline on 10x Genomics datasets including GSE229578, GSE134571, GSE185643, GSE218314 and GSE226794.

	parallel -a cellranger_all.txt bash cellranger.sh

**Warning:** The BAM file produced by cellranger lost flow cell information in read group tag. One possible reason for this may be one extra space in header in some fastq file, for example:

        # problem example (extra space after @xxx ID)
        @SRR9719056.1 K00135:362:H2JNGBBXY:5:1101:1184:1261 length=8

        # good example (can get tidy BAM file with flow cell info in read group tag after running cellranger)
        @HF2_27192:5:1101:1144:1297 1:N:0:NCTTAAAN

The standard format of header in fastq file can be found [here](https://zhuanlan.zhihu.com/p/158694643).

Since downstream **SCAPE** software used to detect alternative polyadenlation (APA) needs the flow cell information in the read group tag of BAM file, we have to fix the header inthose 'problem' fastq files by replcaing extra space with `_`. For this, run `fix_header_in_fastq.sh`:

	bash fix_header_in_fastq.sh {top directory you want to search fastq files in}  
	
	# Fresh fastq.gz file with fixed header will write to same directory where 'problem' fastq file settles in. 
	# Those fresh fastq.gz file will be named in this tradition: `new{followed by origin file name}`.  

## Alternative polyadenylation (APA) pipeline

Several softwares for detecting APA sites including, [scAPA](https://pubmed.ncbi.nlm.nih.gov/31501864/), [scAPAtrap](https://pubmed.ncbi.nlm.nih.gov/33142319/), [Sierra](https://pubmed.ncbi.nlm.nih.gov/32641141/), [scDaPars](https://pubmed.ncbi.nlm.nih.gov/34035046/), [SCAPTURE](https://pubmed.ncbi.nlm.nih.gov/34376223/), [MAAPER](https://pubmed.ncbi.nlm.nih.gov/34376236/) and [SCAPE](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9226526/). **SCAPE** is our first trial since its higher performance and accuracy, friendly tutorial as well as supporting different single cell sequencing technology. The detailed user guide can be found [here](https://github.com/LuChenLab/SCAPE/tree/main).

To run **SCAPE** on 10x Genomics samples, we need:

1. BAM file provided by cellranger workflow.
2. GTF annotation file (can be downloaded from [ensembl](https://www.ensembl.org/info/data/ftp/index.html?redirect=no) and [genecode](https://www.gencodegenes.org/) (for human or mouse) databases)


We downloaded human and mouse GTF files from genecode databases. md5 check values are shown below:

- cd64f4e6b373084baa96f5d9ebdcc082  ./human/gencode.v34.primary_assembly.annotation.gtf.gz
- c5125258a0a2c5250ddb4c192abbf4e8  ./mouse/gencode.vM25.primary_assembly.annotation.gtf.gz

**Note**: *we didn't download the latest release for those GTF files since reference transcriptomes we downloaded from 10x Genomics website were built under older GTF files*.  
	
The loadData function in the [tutorial](https://github.com/LuChenLab/SCAPE/wiki/Differential-APA-analysis-(Mouse-brain-vs-bone-marrow,-R)) didn't run successfully, to fix this problem, create a new function named `my_loadData` by change 30th line of source code in the following way:

	return(map(Layers(objs), ~ Seurat::GetAssayData(objs, layer = .x)))
	 
Then, create a new function called `add_row_for_consistance`, the code is shown below:

	add_row_for_consistance = function(matrix_ls,
                                   target_data,
                                   collapse = F){
	row_count = map_int(matrix_ls, ~ nrow(.x))
	nrow = max(row_count)
  	row_selector = unique(unlist(map(matrix_ls, ~ rownames(.x)))) 
  
  	if(is.null(names(matrix_ls))){
    		stop("matrix_ls should be named list")
  	}
  
  	res = map(
    		names(matrix_ls),
    		\(x){
      			data = matrix_ls[[x]]
      			column_selector = colnames(target_data)[str_detect(colnames(target_data), x)]
      			data = data[, column_selector]
      			fill_na = row_selector[! row_selector %in% rownames(data)]
      			na_matrix = Matrix::Matrix(0, nrow = length(fill_na), ncol = ncol(data))
      			rownames(na_matrix) = fill_na
      			output = rbind(data, na_matrix)
      			output = output %>% as.data.frame() %>% rownames_to_column("id")
    		}
 	)
  
  	if(collapse){
    		res = reduce(res, left_join, by = "id")
    		res = res %>% column_to_rownames("id")
    		return(Matrix::Matrix(as.matrix(res)))
 	}
  	else{
    		return(res)
  		}
	} 

Then, run the following code:

	pa_mtx = my_loadData(exp_file, collapse_pa, matrix = True)
	pa_mtx = add_row_for_consistance(pa_mtx, collapse = True)
	binary_filter = Matrix::rowSums(+pa_mtx)
	pa_mtx = pa_mtx[binary_filter > 50, ]

	gene_obj[['apa']] =  CreateAssayObject(pa_mtx)
	gene_obj =  NormalizeData(gene_obj, assay = 'apa')
	gene_obj = ScaleData(gene_obj, assay = 'apa')
	
After that, follow up the [tutorial](https://github.com/LuChenLab/SCAPE/wiki/Differential-APA-analysis-(Mouse-brain-vs-bone-marrow,-R)).



