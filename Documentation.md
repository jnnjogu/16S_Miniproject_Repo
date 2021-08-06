 # Code documentation
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
for file in *.gz
do
	fastqc
done
```
* load multiqc
 module load multiqc
 multiqc *.html
 
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
 ## Usearch tool
 
- Is a sequence analysis and clustering tool.

 ## merging the paired reads
 
 - Combined the forward and the reverse reads into one using the _-fastq_mergepairs_
 - The relabel option gets the sample identifier from the FASTQ file name by truncating at the first underscore
 
```
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
 
 ```usearch -fastx_uniques filtered_from_orient.fastq  -fastaout uniques.fasta -sizeout -relabel Uniq
 ```
 
  ## Clustering OTUS
  
- Sequences are clustered based on percentage similarity which is 97% and the chimeras within the sequences are removed.
``` 
 usearch -cluster_otus uniques.fasta -otus otus.fasta -uparseout uparse.txt -relabel Otu
 
```
  ## Denoising
 - The process of removing errors from reads, identifying the correct biological sequences in the reads.
```
usearch -unoise3 uniques.fasta -zotus zotus.fasta

```
  ## Creating OTUS tables
  
 - The otutab command generates an OTU table by mapping reads to OTUs.
 - An OTU table aids in checking the sampling depth.
```
 usearch -otutab mergedreads.fastq -otus otus.fasta -otutabout otutab.txt -mapout map.txt
 ```
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
```
- Shannon_Vector
```   
    qiime diversity alpha-group-significance  --i-alpha-diversity core-metrics-results/shannon_vector.qza   --m-metadata-file data.tsv   --o-visualization core-metrics-results/shannon_group-significance.qzv
```
- Beta Diversity
- Bray_Curtis
    
```   
    qiime emperor plot --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza   --m-metadata-file data.tsv  --o-visualization core-metrics-bray_curtis_pcoa_results.qzv
```
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
- Rarefied the data and generated the rarefaction curve.
```
qiime diversity alpha-rarefaction --i-table ../otu_tab_map.qza --i-phylogeny ../rooted-tree.qza --p-max-depth 4000 --m-metadata-file ../data.tsv --o-visualization rarefaction_4000.qzv
```
