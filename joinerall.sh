#! /bin/bash


# Run this section first - specify files to be processed (sorts files for join)


# for exptfiles in *_mapped.txt;
# do
# awk -v OFS='\t' '{print $1,$2}' $exptfiles | sort -b -k1 > "$(basename "${exptfiles%_aligned*}" )_tdl.txt"
# done

# Comment out previous codeblock and  uncomment this. Rename input pool file as 1.txt. 
# After running this code, open highest numbered file in Matlab and fill missing values with zero.
# processorder.txt contains order in which files were processed (variable names for readcounts)

# F = fillmissing(A,'constant',v)

i=1 
for exptfilestdl in *_tdl.txt;
do
join -a 1 -1 1 -2 1 $i.txt $exptfilestdl | tr ' ' \\t  > $((i+1)).txt

i=$((i+1))
echo $exptfilestdl >> processorder.txt
done


# use _S[0-9][0-9][0-9]_tdl.txt to trim filenames from processorder.txt

#1-5_Pi_Input1_S1_tdl.txt