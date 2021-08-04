#Authors John Njogu & Brenda Kamau
# Written on 30-07-2021
# this script takes in files and runs fastqc and writes the output to another directory

for file in *.fastq;
do
	fastqc $file
done
