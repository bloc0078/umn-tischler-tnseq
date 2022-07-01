#! /bin/bash

# Nagendra Palani - University of Minnesota Genomics Center - 08/2017 - MN, USA

# Revision - 03/2018 - Changed software access to Conda environment
#Pipeline for TnSeq data preprocessing. 
#Input - demultiplexed Fastq; Output - mapped TA positions with raw readcounts

#Tool Dependencies - bbtools, Hisat2, GNU Parallel, Bioawk.
#Tools used are inherently multi-threaded or use GNU Parallel for multi-core execution.

#File dependencies - ReferenceOrganism.fasta, TAgenemap.txt (from Matlab script tnseqpreprocess.m)
 

#Load modules and activate environment for BBTools & bioawk
module load python2
source activate tnseqenv
module load parallel
module load hisat2
# module load fastqc

#base folder containing sequencing data
basedr=~/Downloads/Basespace_downloads/Dunny_041

#Other variables

#Place fasta & TAposition files from matlab output in reffiles folder within base directory
reffasta=efaecalisOG1RF_fasta.fasta
alignidxname="$(basename "${reffasta%.fasta*}")_idx"

#TAgenemap=Mycotuberc_TA_genemap.txt
TAgenemap_sort=efaecalis_TAposition.txt

#hisat2 threads - set threadnum equal to number of processor cores available.
threadnum=3

#sub-directories to be created for outputs

mkdir $basedr/RefIndex
mkdir $basedr/0_filter
mkdir $basedr/1_cutadapt
mkdir $basedr/2_sizecut
mkdir $basedr/3_TAonly
mkdir $basedr/4_alignfiles
mkdir $basedr/5_readfreqs
mkdir $basedr/6_mappedinserts
#mkdir $basedr/stats

#--------------------------------------------------------------------------
# Build required files

#Build Hisat2 aligner index

hisat2-build -f $basedr/reffiles/$reffasta $basedr/RefIndex/$alignidxname

# Sort TA_map file for join

#sort -b -k1 $basedr/reffiles/$TAgenemap > $basedr/reffiles/$TAgenemap_sort

#--------------------------------------------------------------------------

#filter sequences for valid transposons - bbduk (bbtools package) - specify filtering seq in literal

for seqfile in $basedr/*R1_001.fastq.gz;
do
bbduk.sh -Xmx4g in="$seqfile" outm=$basedr/0_filter/"$(basename "${seqfile%L001_R1_001*}" )_filtered.fastq" literal=GGACTTATCAGCCAACCTGT k=20 hdist=3 rcomp=f maskmiddle=f

done
#--------------------------------------------------------------------------

#trim 5' adapters - bbduk (bbtools package) - specify adapter seq in literal

for seqfilefilt in $basedr/0_filter/*.fastq*;
do
bbduk.sh -Xmx4g in="$seqfilefilt" out=$basedr/1_cutadapt/"$(basename "${seqfilefilt%_filter*}" )_cutadapt.fastq" literal=GGACTTATCAGCCAACCTGT ktrim=l k=20 mink=11 hdist=3 rcomp=f

done

#--------------------------------------------------------------------------

#cut sequences to length X bp -bioawk - change startposition & length in substr($seq,start,length)

bawk_sizecut='{ print "@"$name" "$comment; print substr($seq,1,25); print "+"; print substr($qual,1,25);}'

parallel "bioawk -c fastx '$bawk_sizecut' {} > $basedr/2_sizecut/{/.}_sizecut.fastq" ::: $basedr/1_cutadapt/*.fastq

#--------------------------------------------------------------------------

#keep only sequences that start with TA - bioawk

bawk_keepta='{ if ($seq ~ /^TA/) { print "@"$name" "$comment; print $seq; print "+"; print $qual;}}'

parallel "bioawk -c fastx '$bawk_keepta' {} > $basedr/3_TAonly/{/.}_TAonly.fastq" ::: $basedr/2_sizecut/*.fastq

#--------------------------------------------------------------------------

#run aligner to generate SAM files - build index in RefIndex directory and fill-in index name here.

for alreffile in $basedr/3_TAonly/*.fastq;
do
hisat2 -q -x $basedr/RefIndex/$alignidxname -U "$alreffile" -S $basedr/4_alignfiles/"$(basename "${alreffile%_cutadapt*}" )_aligned.sam" --no-unal -p $threadnum

done

#--------------------------------------------------------------------------
# Find read frequencies for each insertion

bawk_samposition='{ if($flag==0) print $pos+1; if($flag==16)  print $pos+length($seq)-1; }'

parallel "bioawk -c sam '$bawk_samposition' {} | cut -f 1 | sort -g -k1 | uniq -c | sed 's/^ *//' | sort -b -k2 > $basedr/5_readfreqs/{/.}_readfreq.txt" ::: $basedr/4_alignfiles/*.sam
#--------------------------------------------------------------------------
# Map reads to TA positions

parallel "join -1 2 -2 1 {} $basedr/reffiles/$TAgenemap_sort | sort -n -r -k2 | tr ' ' '\t' > $basedr/6_mappedinserts/{/.}_mapped.txt" ::: $basedr/5_readfreqs/*_readfreq.txt

#--------------------------------------------------------------------------

#basic stats

#parallel "wc -l {} > $basedr/stats/UniqueInsertionsCount.txt" ::: $basedr/6_mappedinserts/*_mapped.txt
# used to work but not now - 09/14/2017

#parallel "wc -l {}" ::: $basedr/6_mappedinserts/*_mapped.txt  > $basedr/stats/UniqueInsertionsCount.txt

#--------------------------------------------------------------------------

#cd $basedr/3_TAonly

#parallel "fastqc {}" ::: *.fastq



