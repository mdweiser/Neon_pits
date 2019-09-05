#!/bin/bash

### USEARCH PIPELINE FOR OVERLAPPING PAIRED READS

# Prepare filenames for downstream work
for file in *; do mv "${file}" "${file/_001\.fastq/.fastq}"; done
for file in * ; do mv "${file}" `echo "${file}" | sed 's/_//g'` ; done
for file in * ; do mv "${file}" `echo "${file}" | sed 's/R1/_R1/g'` ; done
for file in * ; do mv "${file}" `echo "${file}" | sed 's/R2/_R2/g'` ; done

# Unzip read files (USEARCH doesn't like zipped files)
gunzip *fastq.gz

# Merge paired reads, this results in substantially higher-quality reads than single read datasets
./usearch -fastq_mergepairs *R1*.fastq -relabel @ -fastq_maxdiffs 10 -fastqout merged.fq

# Remove priming sites from all reads
./usearch -fastx_truncate merged.fq -stripleft 20 -stripright 20 -fastqout stripped.fq

# Size filter reads (for 240 bp exactly)
awk 'BEGIN {OFS = "\n"} {header = $0 ; getline seq ; getline qheader ; getline qseq ; if (length(seq) < 241) {print header, seq, qheader, qseq}}' stripped.fq > lessthan241bp.fq
awk 'BEGIN {OFS = "\n"} {header = $0 ; getline seq ; getline qheader ; getline qseq ; if (length(seq) > 239) {print header, seq, qheader, qseq}}' lessthan241bp.fq > stripped240.fastq

# Quality filter reads
./usearch -fastq_filter stripped240.fastq -fastq_maxee 1.0 -fastaout filtered.fa

# Make abundance matrix for reads
./usearch -fastx_uniques filtered.fa -fastaout uniques.fasta -sizeout -relabel Uniq

# Remove singleton reads from OTU table analysis (they are probably sequencing error, we remap ALL reads below, this is standard approach)
./usearch  -sortbysize uniques.fasta -fastaout dereplicated.fasta -minsize 2

# Cluster non-singleton reads into OTU islands
./usearch  -cluster_otus dereplicated.fasta -otus otus.fa -relabel Otu

# Map all reads to one of the OTU islands, generate matrix by sampleID
./usearch  -otutab stripped240.fastq -otus otus.fa -otutabout otutab.txt -mapout map.txt

# Blast all names on the remote BLAST server
blastn -db nt -query otus.fa -out otu_blastLCO.csv -outfmt "10 qseqid staxids sacc slen length pident evalue"  -max_target_seqs 1 -remote

# extract SeqID from the BLAST output
cat otu_blastLCO.csv | cut -d ',' -f2 > seqID_LCO.txt

# Use TaxonKit 0.4 to lookup names (important that you use v0.4; there is a bug in v0.5)
# note that the OTU name is not in the file, you will need to manually add that later
./taxonkit04 lineage seqID_LCO.txt > OTU_names_LCO.txt

# I normally prefer to see just the DESCRIPTION and the family
./taxonkit04 reformat OTU_names_LCO.txtt -f "{f};{g};{s}" > OTU_names_LCO_short.txt
