#!/bin/bash
# an example of a user-provided pre-processing script
# preprocessing done with Trimmomatic
# expects either 1 or 2 input arguments - being the fastq file names (pathless)
# The user is required to replace the supplied file with the pre-processing
# output (i.e. the fastq that has been through pre-processing)
# NOTE that this file is used by the Falco framework (in particular, this file is executed as a Hadoop streaming job)
# such that the input data (the list of file names) is streamed into this file

# this file includes example code that could be used for paired-end data

# function to deal with terminal errors
exit_msg() {
    printf "$0 program terminated.  %s\n" "$1"
    exit 1
}

# check that there are 2 arguments to this program - paired end
if [ $# -eq 3 ] ; then
    paired=true
    fq_1="$1"
    fq_2="$2"
    min_trim ="$3"
    [ -f $fq_1 ] || exit_msg "Unable to locate read 1 file: $fq_1"
    [ -f $fq_2 ] || exit_msg "Unable to locate read 1 file: $fq_2"
else
    paired=False
    fq_1="$1"
    min_trim ="$2"
    [ -f $fq_1 ] || exit_msg "Unable to locate read 1 file: $fq_1"
fi


trimmomatic="/mnt/app/trimmomatic-0.36.jar"
if [$paired] ; then
    fa="NexteraPE-PE.fa"
    [ -f $trimmomatic ] || exit_msg "Couldn't find trimmomatic: $trimmomatic"
    [ -f $fa ] || exit_msg "Couldn't find fa file: $fa"
    java -jar $trimmomatic PE -phred33 \
         $fq_1 $fq_2 r1_paired.fastq r1_unpaired.fastq r2_paired.fastq \
         r2_unpaired.fastq ILLUMINACLIP:$fa:2:30:10 LEADING:3 \
         TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:$min_trim
else
    fa='TruSeq3-SE.fa'
    [ -f $trimmomatic ] || exit_msg "Couldn't find trimmomatic: $trimmomatic"
    [ -f $fa ] || exit_msg "Couldn't find fa file: $fa"
    java -jar $trimmomatic SE -phred33 \
         $fq_1 r1_paired.fastq r1_unpaired.fastq ILLUMINACLIP:$fa:2:30:10 \
         LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:$min_trim
fi
[ $? -eq 0 ] || exit_msg "trimmomatic command failed"

# IMPORTANT: replace existing working fastq
if [$paired] ; then
    mv r1_paired.fastq $fq_1
    mv r2_paired.fastq $fq_2
else
    mv r1_paired.fastq $fq_1
fi
