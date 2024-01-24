#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=300000

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Write jobscript to output file (good for reproducability)
cat $0

# Load modules
 module load bwa/v0.7.17
 module load samtools/1.17

OUTPUT_DIR="${workdir}/assembly/assembly_coverage/${assembly}"
mkdir -p ${OUTPUT_DIR}

# index the assembly
bwa index ${assemblydir}/${assembly}.fasta

# align reads to the assembly
bwa mem -x ont2d -t ${SLURM_CPUS_PER_TASK} ${assemblydir}/${assembly}.fasta ${krakendir}/${assembly}.fastq.gz > ${OUTPUT_DIR}/aligned_reads.sam

# convert SAM to BAM and sort
samtools view -Sb ${OUTPUT_DIR}/aligned_reads.sam | samtools sort -o ${OUTPUT_DIR}/sorted_aligned_reads.bam

# Index the BAM file
samtools index ${OUTPUT_DIR}/sorted_aligned_reads.bam

# Calculate coverage
samtools depth ${OUTPUT_DIR}/sorted_aligned_reads.bam > ${OUTPUT_DIR}/coverage.txt

echo "Coverage assessment completed. Results are in ${OUTPUT_DIR}/coverage.txt"

