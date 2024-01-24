#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=defq       # the requested queue
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
python -m venv python_kraken2
source ${moduledir}/python_kraken/python_kraken2/bin/activate

echo ${trimdir}

# file=$(ls ${trimdir}/*_1.fastq.gz | sed -n ${SLURM_ARRAY_TASK_ID}p)

# R1=$(basename $file | cut -f1 -d.)
# base=$(echo $R1 | sed 's/_1$//')

# cat ${trimdir}/*_1.fastq.gz > ${trimdir}/all_1.fastq.gz
# cat ${trimdir}/*_2.fastq.gz > ${trimdir}/all_2.fastq.gz

python ${moduledir}/extract_kraken_reads.py \
		-k ${krakendir}/${assembly}_kraken2_output \
		-s1 ${trimdir}/${assembly}_trim_1.fastq.gz \
		-s2 ${trimdir}/${assembly}_trim_2.fastq.gz \
		-r ${krakendir}/${assembly}_kraken2_report \
		--exclude --include-parents --taxid 2 \
		-o ${krakendir}/${assembly}_1.fastq \
		-o2 ${krakendir}/${assembly}_2.fastq

# rm ${trimdir}/all_1.fastq.gz
# rm ${trimdir}/all_2.fastq.gz

# Deactivate virtual environment and unload modules
deactivate
