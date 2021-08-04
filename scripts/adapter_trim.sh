#Authored by John Njogu & Brenda kamau
# Written on 30-07-2021
# This script takes in fastq files and trims the adapter sequences provided in the path

module load trimmomatic

for read in *_R1_001.fastq;
do
        read=$(basename ${read} _R1_001.fastq)
        trimmomatic PE -phred33 ${read}_R1_001.fastq ${read}_R2_001.fastq\
        ${read}_paired_trim_R1.fastq ${read}_unpaired_trim_R1.fastq\
        ${read}_paired_trim_R2.fastq ${read}_unpaired_trim_R2.fastq\
        ILLUMINACLIP:/opt/apps/trimmomatic/0.39/adapters/TruSeq3-PE.fa:2:30:10\
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

