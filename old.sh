
for file in *.gz;
do
	sample=$(echo ${file} |sed 's/_L001_R*//')
	cutadapt --interleaved -q 20 -o cd ../Trimmed/${sample}_R1.fastq -p cd ../Trimmed/${sample}_R2.fastq *R1* *R2*
done
