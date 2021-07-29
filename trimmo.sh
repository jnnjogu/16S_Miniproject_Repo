file=*.gz
for read in *_R1_001.fastq.gz;
do
	read=$(basename ${read} _R1_001.fastq.gz)
	trimmomatic PE -phred33 ${read}_R1_001.fastq.gz ${read}_R2_001.fastq.gz\
	${read}_paired_R1.fastq.gz ${read}_unpaired_R1.fastq.gz\
	${read}_paired_R2.fastq.gz ${read}_unpaired_R2.fastq.gz\
	ILLUMINACLIP:/opt/apps/trimmomatic/0.39/adapters/TruSeq3-PE.fa:2:30:10\
	LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
