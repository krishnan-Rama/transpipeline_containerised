#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8      #
#SBATCH --mem-per-cpu=30000     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Write jobscript to output file (good for reproducibility)
cat $0

# Load necessary modules and activate virtual environment
cd ${moduledir}

python -m venv kraken_bio
source kraken_bio/bin/activate
pip install biopython

echo ${trimdir}

# Get list of all unique base names (without _1 or _2 suffix)
bases=$(ls ${trimdir}/*_trim_1.fastq.gz | xargs -n 1 basename | sed 's/_trim_1.fastq.gz//' | sort | uniq)

for base in $bases; do
    export base

    echo "Processing base name: $base"

    python ${moduledir}/extract_kraken_reads.py \
        -k ${krakendir}/${base}_kraken2_output \
        -s1 ${trimdir}/${base}_trim_1.fastq.gz \
        -s2 ${trimdir}/${base}_trim_2.fastq.gz \
        -r ${krakendir}/${base}_kraken2_report \
        --exclude --include-parents --taxid 2 \
        -o ${krakendir}/${base}_1.fastq \
        -o2 ${krakendir}/${base}_2.fastq
done

# Deactivate virtual environment and unload modules
deactivate

