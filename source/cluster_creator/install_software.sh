#!/bin/bash
# used as a "bootstrap" script for an EMR cluster
# installs software - in a version agnostic manner where possible
# ASSUMPTION: only one version of each software package is available locally
set -x
set -o pipefail

sudo yum update -y
mkdir venv
aws s3 cp $2 /home/hadoop/venv --recursive
unzip /home/hadoop/venv/env.zip

source /home/hadoop/env/bin/activate

mkdir /mnt/app
pushd /mnt/app > /dev/null

aws s3 cp $1 . --recursive


# Install STAR and its' dependencies
sudo yum install make -y
sudo yum install gcc-c++ -y
sudo yum install glibc-static -y
sudo yum install zlib-devel -y
sudo yum install ncurses-devel ncurses -y
sudo yum install bzip2-devel -y
sudo yum install xz-devel -y
sudo yum install libpng-devel -y
sudo yum install atlas-sse3-devel lapack-devel -y

# STAR
tar -xzf STAR*.tar.gz
star_path=$( find . -name "STAR"|grep -E "/Linux_x86_64/" )
# symbolic link to the STAR directory (rather than to the executable itself)
ln -s ${star_path%STAR} STAR


# Install subread (featureCount)
tar -xzf subread*.tar.gz
fc=$( find -name "featureCounts"|grep bin )
sr_path=${fc%featureCounts}
ln -s $sr_path subread

# Install HISAT2
unzip hisat2*.zip
hisat_dir=$( find . -maxdepth 1 -type d -name "hisat2*")
ln -s $hisat_dir hisat

#install Stringtie
gunzip stringtie*.tar.gz
tar -xf stringtie*.tar
rm -r stringtie*.tar
stringtie_dir=$( find . -maxdepth 1 -type d -name "stringtie*")
ln -s $stringtie_dir stringtie


# Install samtools
tar -xjf samtools*.tar.bz2
sam_dir=$( find . -maxdepth 1 -type d -name "samtools*" )
pushd $sam_dir > /dev/null
make
sudo make install
popd > /dev/null
ln -s $sam_dir samtools

# Install htslib
hts_dir=$( find $sam_dir -maxdepth 1 -type d -name "htslib-*" )
pushd $hts_dir > /dev/null
make
sudo make install

popd > /dev/null

# Install picard_tools
#unzip picard-tools*.zip
pic_jar=$( find . -name picard.jar )
pic_path=${pic_jar%picard.jar}
ln -s $pic_path picard-tools

# trim galore
tg=trim_galore
unzip trim_galore*.zip
tg_path=$( find . -name $tg )
ln -s $tg_path $tg

# trimmomatic
unzip Trimmomatic*.zip
tm=$( find . -name trimmomatic*.jar )
ln -s $tm ${tm##*/}

# prinseq
ps=prinseq-lite.pl
tar -xzf prinseq-lite*.tar.gz
ps_path=$( find . -name "$ps" )
ln -s $ps_path $ps

# -------------------------------------------------------------
# no longer in /mnt/app
popd > /dev/null

mkdir /mnt/output

deactivate
# Install python dependencies for framework

sudo python3 -m pip install boto3

# Install java8
sudo yum install java-1.8.0-openjdk.x86_64 -y


# install htop
sudo yum install htop -y
