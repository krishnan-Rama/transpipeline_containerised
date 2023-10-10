#!/bin/bash
#author: Peter Kille
#SBATCH --job-name=trans-pipe
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1800
#SBATCH --error=%J.err
#SBATCH --output=%J.out


module load fastqc/v0.11.8
module load Trimmomatic/0.36

#call varibles
source variables_transcript_pipeline

#STEP 1A: Transfer files into data directory and rename

for (( i=0 ; i<${#rawdata[@]} ; i++ ));do

#Forward read - transfer, rename and end with /1 or /2
#copy and rename rawdata file into analysis folder
cp "${rawdir}/${rawdata[${i}]}_1.fastq.gz" "${dir}/1-data/${seqname[${i}]}_1.fastq.gz"
#unzip rawdata file
unpigz -p 8 "${dir}/1-data/${seqname[${i}]}_1.fastq.gz"
#edit to add /1
sed -i 's/\ 1\:N\:0.*$/\/1/g' "${dir}/1-data/${seqname[${i}]}_1.fastq"
#compress data
pigz -c -p 8 "${dir}/1-data/${seqname[${i}]}_1.fastq" > "${dir}/1-data/${seqname[${i}]}_1.fastq.gz"
rm "${dir}/1-data/${seqname[${i}]}_1.fastq"

#Repeat for reverse read
#copy and rename rawdata file into analysis folder
cp "${rawdir}/${rawdata[${i}]}_2.fastq.gz" "${dir}/1-data/${seqname[${i}]}_2.fastq.gz"
#unzip rawdata file
unpigz -p 8 "${dir}/1-data/${seqname[${i}]}_2.fastq.gz"
#edit to add /2
sed -i 's/\ 1\:N\:0.*$/\/1/g' "${dir}/1-data/${seqname[${i}]}_2.fastq"
#compress data
pigz -c -p 8 "${dir}/1-data/${seqname[${i}]}_2.fastq" > "${dir}/1-data/${seqname[${i}]}_2.fastq.gz"
rm "${dir}/1-data/${seqname[${i}]}_2.fastq"

#run fastqc
fastqc -t 2 "${dir}/1-data/${seqname[${i}]}_1.fastq.gz" "${dir}/1-data/${seqname[${i}]}_2.fastq.gz"

done

