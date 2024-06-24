#!/bin/bash

#SBATCH --job-name=trans
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #   
#SBATCH --mem=16G     # in megabytes, unless unit explicitly stated
#SBATCH --error="logs/trans_%J.err" 
#SBATCH --output="logs/trans_%J.out"

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

module load singularity/3.8.7

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <GTF_FILE> <PEP_FILE> <GENOME_FA>"
    exit 1
fi

GTF_FILE=$1
PEP_FILE=$2
GENOME_FA=$3

if [[ $GTF_FILE == *.gz ]]; then
    if [ ! -f ${GTF_FILE%.gz} ]; then
        echo "Decompressing $GTF_FILE..."
        gunzip -k $GTF_FILE
        GTF_FILE=${GTF_FILE%.gz}
    else
        GTF_FILE=${GTF_FILE%.gz}
    fi
fi

if [[ $GENOME_FA == *.gz ]]; then
    if [ ! -f ${GENOME_FA%.gz} ]; then
        echo "Decompressing $GENOME_FA..."
        gunzip -k $GENOME_FA
        GENOME_FA=${GENOME_FA%.gz}
    else
        GENOME_FA=${GENOME_FA%.gz}
    fi
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Full paths to files
FULL_GTF_FILE=$(realpath $GTF_FILE)
FULL_GENOME_FA=$(realpath $GENOME_FA)
WORK_DIR=$(pwd)

# Extract exon entries from the GTF file
echo "Extracting exons from GTF file..."
awk '$3 == "exon" {print $0}' $FULL_GTF_FILE > exons.gtf

# Convert GTF to BED format using bedtools
echo "Converting GTF to BED format..."
singularity exec --bind $WORK_DIR:/mnt bedtools%3A2.29.2--hc088bd4_0 bash -c "bedtools sort -i /mnt/exons.gtf > /mnt/exons_sorted.gtf"

# Extract exon sequences from the genome
echo "Extracting exon sequences from the genome..."
singularity exec --bind $WORK_DIR:/mnt bedtools%3A2.29.2--hc088bd4_0 bedtools getfasta -fi /mnt/$(basename $FULL_GENOME_FA) -bed /mnt/exons_sorted.gtf -fo /mnt/exons.fa

# Concatenate exons to form transcripts
echo "Concatenating exons to form transcripts..."
singularity exec --bind $WORK_DIR:/mnt gffread%3A0.12.7--hdcf5f25_4 gffread -w /mnt/transcripts.fa -g /mnt/$(basename $FULL_GENOME_FA) /mnt/$(basename $FULL_GTF_FILE)

echo "Transcriptome extraction complete. Output saved to transcripts.fa"

# Clean up intermediate files
rm exons.gtf exons_sorted.gtf exons.fa

