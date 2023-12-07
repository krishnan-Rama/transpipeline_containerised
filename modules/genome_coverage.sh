#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem=128000

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
 module load bowtie2/v2.4.1
 module load samtools/1.17

# Set file paths
OUTPUT_DIR="${workdir}/assembly/assembly_coverage"
INDEX_DIR="${workdir}/assembly/assembly_coverage"

# Create output and index directories if they don't exist
mkdir -p ${OUTPUT_DIR}
mkdir -p ${INDEX_DIR}

# Build Bowtie2 index
bowtie2-build ${assemblydir}/${assembly}.fasta ${INDEX_DIR}/assembly_index

# Align reads to the assembly
bowtie2 -x ${INDEX_DIR}/assembly_index -1 ${rcordir}/${assembly}_1.cor.fq.gz -2 ${rcordir}/${assembly}_2.cor.fq.gz -S ${OUTPUT_DIR}/aligned_reads.sam

# Convert SAM to BAM and sort
samtools view -Sb ${OUTPUT_DIR}/aligned_reads.sam | samtools sort -o ${OUTPUT_DIR}/sorted_aligned_reads.bam

# Index the BAM file
samtools index ${OUTPUT_DIR}/sorted_aligned_reads.bam

# Calculate coverage
samtools depth ${OUTPUT_DIR}/sorted_aligned_reads.bam > ${OUTPUT_DIR}/coverage.txt

# Print completion message
echo "Coverage assessment completed. Results are in ${OUTPUT_DIR}/coverage.txt"
