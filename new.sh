#!/bin/bash
#Written on 23rd July 2021
#Authored by John Njogu and Brenda Kamau

#this script takes in paired end files of format *.fastq.gz and trims the first 20 bases at both reads denoting the primer
for file in *R1_001.fastq.gz; 
do
	readpre=$(basename ${file} _R1_001.fastq.gz)
	echo $readpre
	sample=$(echo ${file} | sed -e 's/_L001_//' | sed -e 's/.fastq.gz//')
	#echo $sample
	cutadapt --interleaved -q 20 \
		-o ${readpre}_R1_trimmed.fastq \
		-p ${readpre}_R2_trimmed.fastq ${readpre}_R1_001.fastq.gz ${readpre}_R2_001.fastq.gz
done
