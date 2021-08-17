 # Code documentation
 
 ## Dependancies
- fastqc/0.11.9 
- multiqc/1.4
- qiime2/2020.6
- usearch/11.0
- R/4.0.3
- trimmomatic/0.39


 ## Downloading data
- The first thing is downloading the data from the online Zenodo repository. This is a repository that helps scientists upload their resarch outcomes and also facilitate sharing and discovery of information
```
wget https://zenodo.org/record/4559793/files/honey_bees_samples.zip?download=1
gunzip evz166_supplementary_data(1).zip
```

 ## Quality checking of reads
- FastQc checks the quality of reads from high throughput sequencing platforms and generates a a html report with the quality of reads.
- MultiQc combines the fastqc output into one report.
* load fastqc

 module load fastqc
```
for file in *.gz;
do
	fastqc $file
done
```
* load multiqc

 module load multiqc

 multiqc *.html
 
![](https://i.imgur.com/Bqd4CgE.png)
![](https://i.imgur.com/jW334t6.png)

 ## Trimming
 
- Trimmomatic tool is used to trim and filter reads thus removing poor quality reads and adapters.

* module load trimmomatics
```
# this is a bash script that trims PE reads 

for read in *_R1_001.fastq.gz;
do
        read=$(basename ${read} _R1_001.fastq.gz)
        trimmomatic PE -phred33 ${read}_R1_001.fastq.gz ${read}_R2_001.fastq.gz\
        ${read}_paired_R1.fastq.gz ${read}_unpaired_R1.fastq.gz\
        ${read}_paired_R2.fastq.gz ${read}_unpaired_R2.fastq.gz\
        ILLUMINACLIP:/opt/apps/trimmomatic/0.39/adapters/TruSeq3-PE.fa:2:30:10\
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
```
![](https://i.imgur.com/4bSKVBR.png)
![](https://i.imgur.com/QKifgAl.png)

 ## Usearch tool
 
- Is a sequence analysis and clustering tool.

 ## merging the paired reads
 
 - Combined the forward and the reverse reads into one using the _-fastq_mergepairs_
 - The relabel option gets the sample identifier from the FASTQ file name by truncating at the first underscore
 
```
Module load Usearch

usearch -fastq_mergepairs *_R1.fastq -reverse *_R2.fastq mergedreads.fastq -relable @
```

 ## creating a subsample
 
 - The fastx_subsample command generates a random subset of sequences in a FASTA or FASTQ file.
 
 ```
usearch -fastx_subsample mergedreads -samplesize 10000 -fastqout subsample.fastq 
```

 ## copying the primers to the primer.fa file
 

    nano primer.fa #created a primer.fa file and copied the primers stated in the paper


 ## primer search within the reads
 
 - Search for matches of nucleotide sequences to a database containing short nucleotide sequences (oligonucleotides)
 - The specified userfields are defined in the link provided [click here](https://www.drive5.com/usearch/manual/userfields.html)

 ```
usearch -search_oligodb subsample.fastq -db primer.fa -strand both -userout hits.txt -userfields query+target+qstrand+diffs+tlo+thi+trowdots \
```

 ## Filtered the reads to remove the primers
 - Performed quality filtering of the reads and converted the reads from fastq to fasta format
```
usearch -fastq_filter mergedreads.fastq --fastq_stripleft 19 --fastq_stripright 20 -fastaout filtered_reads.fasta
```
 ## Did another search to confirm the removal of the primers we got .1% hits
 
 

```
    usearch -search_oligodb filtered_reads.fasta -db primer.fa -strand both -userout filtered-primerhits.txt -userfields query+target+qstrand+diffs+tlo+thi+trowdots \
```
_Before filtering_
    
    Sample ID                Primer                phits     indices
    Nairobi-9.1726518       forward_primer  -       1       1       19      G..................
    Nairobi-9.1728912       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1728912       reverse_primer  -       1       1       20      .................A..
    Nairobi-9.1730451       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1731920       reverse_primer  -       0       1       20      ....................
    Nairobi-9.1733886       forward_primer  +       1       1       19      .............C.....
    Nairobi-9.1734698       forward_primer  -       1       1       19      ..G................
    Nairobi-9.1735286       forward_primer  +       2       1       19      .....A............A
    

_After filtering_

    Sample ID                Primer                phits     indices
    Nairobi-9.1739466       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1739497       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1739533       forward_primer  -       0       1       19      ...................
    Nairobi-9.1739533       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1739295       reverse_primer  -       0       1       20      ....................
    Nairobi-9.1739295       forward_primer  +       2       1       19      .................AA
    Nairobi-9.1739411       reverse_primer  +       0       1       20      ....................
    Nairobi-9.1739402       forward_primer  -       0       1       19      ...................
    

# Chimera detection

- QIIME2 tool is used to remove chimeras which are artifacts formed after sequences are incorrectly joined together during PCR reactions.This tool also does Alpha and Beta diversity
- Usearch tool is used to find representative sequences or sequence Variants for the samples. Its important when assigning taxonomy.


```
usearch -uchime_ref mergedreads.fasta -db ../../silver_bacteria/silva.bacteria.fasta -uchimeout chimera_out.txt -strand plus -mode sensitive
```
  ## Orient the reads
  
- For each input sequence, the orient command attempts to determine whether it is on the same strand as the database sequences (which are assumed to all be on the same strand), or reverse-complemented. If the latter, the sequence is reverse complemented so that the output sequences are all on the same strand.
```
usearch -orient mergedreads.fastq -db ../../silver_bacteria/silva.bacteria.fasta -fastqout orient.fastq
```
 ## Filtering the oriented reads
 
- Maxee represents the maximum number of expected errors
 ```
 usearch -fastq_filter orient.fastq -fastq_maxee 1.0 -fastqout filtered_from_orient.fastq
 ```
  ## Dereplicating the reads
  
 - Dereplication is the process where quality filtered sequences are collapsed into unique reads
 
 ```
 	usearch -fastx_uniques filtered_from_orient.fastq  -fastaout uniques.fasta -sizeout -relabel Uniq
 ```
 
  ## Clustering OTUS
  
- Sequences are clustered based on percentage similarity which is 97% and the chimeras within the sequences are removed.
``` 
 usearch -cluster_otus uniques.fasta -otus otus.fasta -uparseout uparse.txt -relabel Otu
 
```
Uniq9;size=5242;        match   dqt=1;top=Otu1(99.7%); \
Uniq10;size=5038;       match   dqt=1;top=Otu2(99.7%); \
Uniq11;size=4627;       match   dqt=1;top=Otu2(99.7%); \
Uniq12;size=4423;       match   dqt=2;top=Otu1(99.3%); \
Uniq13;size=4119;       match   dqt=1;top=Otu2(99.7%); \
Uniq14;size=4118;       match   dqt=2;top=Otu1(99.3%); \
Uniq15;size=4078;       perfect top=Otu1(100.0%); \
Uniq16;size=3945;       match   dqt=2;top=Otu1(99.3%); \
Uniq17;size=3886;       match   dqt=1;top=Otu1(99.6%); 


  ## Denoising
 - The process of removing errors from reads (i.e. Reads with sequencing and PCR point error are identified and removed), identifying the correct biological sequences in the reads.
```
usearch -unoise3 uniques.fasta -zotus zotus.fasta

```
  ## Creating OTUS tables
  
 - The otutab command generates an OTU table by mapping reads to OTUs.
 - An OTU table aids in checking the sampling depth.
```
 usearch -otutab mergedreads.fastq -otus otus.fasta -otutabout otutab.txt -mapout map.txt
 ```
 Kakamega-101.10 Otu3 \
Kakamega-101.6  Otu9 \
Kakamega-101.9  Otu3 \
Kakamega-101.8  Otu3 \
Kakamega-101.2  Otu3 \
Kakamega-101.15 Otu4 \
Kakamega-101.18 Otu3 \
Kakamega-101.19 Otu3 \
Kakamega-101.22 Otu3 \
Kakamega-101.20 Otu2 \
Kakamega-101.5  Otu2 \
Kakamega-101.25 Otu11 

 ### Converted the sample-names format
 
 ```
 sed 's/-/_/g' mergedreads.fastq > mreads.fastq
 
 usearch -otutab mreads.fastq -otus otus.fasta -otutabout otu_new.txt -mapout map2.txt
 ```
 
  ## Creating ZOTUS tables
  
 - Zotus are denoised sequences.
 ``` 
 usearch -otutab mreads.fastq -zotus zotus.fasta -otutabout zotutab.txt -mapout zmap.txt
``` 
Kakamega-101.6  Zotu298 \
Kakamega-101.15 Zotu291 \
Kakamega-101.13 Zotu4 \
Kakamega-101.11 Zotu37 \
Kakamega-101.14 Zotu54 \
Kakamega-101.9  Zotu75 \
Kakamega-101.17 Zotu97 \
Kakamega-101.18 Zotu122 \
Kakamega-101.10 Zotu92 \
Kakamega-101.8  Zotu24 \
Kakamega-101.7  Zotu7 

 # Convert Otu reads into qiime2 artifact
 
 - Converts the input to a .qza format.
 ```
    qiime tools import --input-path ./otus.fastq --output-path ./otus.qza --type 'FeatureData[Sequence]'
```
 # Perform Alignment using Mafft
 
 - Maftt is a tool used for multiple sequence alignment.
```    
    qiime alignment mafft --i-sequences otus.qza --o-alignment aligned_otus.qza
```
 # Masking sites
 - Masking is a way of telling the program to ignore parts of the sequence that are repetitive or conserved regions.
 - This is done because in the alignment some sites are not phylogenetically informative.
 ```
    qiime alignment mask --i-alignment aligned_otus.qza --o-masked-alignment masked_aligned_otus.qza
```
 # Create Phylogeny tree using FastTree
 - Construct a phylogenetic tree with FastTree.
```
    qiime phylogeny fasttree --i-alignment masked_aligned_otus.qza --o-tree unrooted_tree.qza
```
 # Midpoint-rooting of the Phylogeny tree
 - Attempts to root the tree on its midpoint between the two longest branches.
```
 qiime tools export unrooted-tree.qza --output-dir exported-tree
 ```
 # Convert Otu table into a qiime2 Artifact
 
 - Converts the OTU table to a hdf5 format
```    
biom convert -i otu_new.txt -o otu_table.from_txt_hdf5.biom --table-type="OTU table" --to-hdf5
```
- Convert the biom file into a qiime artifact
```
 qiime tools import --input-path otu_table.from_txt_hdf5.biom --type 'FeatureTable[Frequency]' --output-path otu_tab_map.qza
 
```
# Beta and Alpha Diversity Analyses

### converting the metadata format

- Converted the metadata from csv to tsv
```
sed 's/,/\t/g' Sample-metadata.csv >sam-metadata.tsv
```
- Converted the file name format to match the Sample id's in the Otu table.
```
sed 's/-/_/g' sam-metadata.tsv > data.tsv
```   
### Core metrics analysis
- Applies a collection of diversity metrics.
```
qiime diversity core-metrics --i-table otu_tab_map.qza --p-sampling-depth 4000 --m-metadata-file data.tsv --output-dir core-metrics-results
```

### qiime2_visualization of the analysis

function qiime2_visualization() 
- Data Visualization
- Alpha Diversity
- Evenness
```
    qiime diversity alpha-group-significance  --i-alpha-diversity core-metrics-results/evenness_vector.qza   --m-metadata-file data.tsv   --o-visualization core-metrics-results/evenness-group-significance.qzv
    
    
  ![](https://i.imgur.com/AlBaYwt.png)
    
```
- Shannon_Vector
```   
    qiime diversity alpha-group-significance  --i-alpha-diversity core-metrics-results/shannon_vector.qza   --m-metadata-file data.tsv   --o-visualization core-metrics-results/shannon_group-significance.qzv
```
![Screenshot 2021-08-17 at 10-06-57 shannon-diversity qzv QIIME 2 View](https://user-images.githubusercontent.com/76898485/129679960-c17f4bed-af21-48ce-bfb4-7e7cebe0e2c0.png)

- Beta Diversity
- Bray_Curtis
    
```   
    qiime emperor plot --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza   --m-metadata-file data.tsv  --o-visualization core-metrics-bray_curtis_pcoa_results.qzv
```
![emperor(1)](https://user-images.githubusercontent.com/76898485/129679670-0f96fcb8-e9ef-49d2-8887-5784a9af29ad.png)

-----
# Taxonomic classification

### Downloading Greengenes classifier
```
 wget   -O "greengenes-classifier.qza"  "https://data.qiime2.org/2021.2/common/gg-13-8-99-515-806-nb-classifier.qza"
```

- Classify reads by taxon using a fitted classifier.

```
qiime feature-classifier classify-sklearn --i-reads ../otus.qza --i-classifier greengenes-classifier.qza --o-classification taxonomy.qza

```

- Used the metadata tabulate to visualize the feature table

```
qiime metadata tabulate --m-input-file taxonomy.qza --o-visualization taxabarplot.qzv

```
- Generated the taxa bar plots.
```
qiime taxa barplot --i-table ../otu_tab_map.qza --i-taxonomy taxonomy.qza --m-metadata-file ../data.tsv  --o-visualization taxbar.qzv
```
![Screenshot 2021-08-17 at 09-59-00 taxa-barplot qzv QIIME 2 View](https://user-images.githubusercontent.com/76898485/129678808-5d1afcb2-fc0a-44eb-a58a-8f2c4a7f5392.png)
![Screenshot 2021-08-17 at 10-01-25 taxa-barplot qzv QIIME 2 View](https://user-images.githubusercontent.com/76898485/129679119-4f0d8694-495b-4974-897b-4fe67e739018.png)


- Rarefied the data and generated the rarefaction curve.
```
qiime diversity alpha-rarefaction --i-table ../otu_tab_map.qza --i-phylogeny ../rooted-tree.qza --p-max-depth 4000 --m-metadata-file ../data.tsv --o-visualization rarefaction_4000.qzv
```
![Screenshot 2021-08-17 at 10-03-46 alpha-rarefaction qzv QIIME 2 View](https://user-images.githubusercontent.com/76898485/129679411-b6adfe09-6dd3-4295-af58-29979162a8ff.png)
