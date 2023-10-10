#!/bin/bash

# Load necessary modules and activate virtual environment
python -m venv python_kraken2
source ${moduledir}/python_kraken/python_kraken2/bin/activate

echo ${trimdir}

# file=$(ls ${trimdir}/*_1.fastq.gz | sed -n ${SLURM_ARRAY_TASK_ID}p)

# R1=$(basename $file | cut -f1 -d.)
# base=$(echo $R1 | sed 's/_1$//')

# cat ${trimdir}/*_1.fastq.gz > ${trimdir}/all_1.fastq.gz
# cat ${trimdir}/*_2.fastq.gz > ${trimdir}/all_2.fastq.gz

sbatch --job-name=pipeline --output=${krakendir}/Ealbidus.out --error=${krakendir}/Ealbidus.err \
		--ntasks=1 --cpus-per-task=4 --mem=16G --partition=jumbo \
		--wrap="${moduledir}/extract_kraken_reads.py \
		-k ${krakendir}/${assembly}_kraken2_output \
		-s1 ${trimdir}/all_1.fastq.gz \
		-s2 ${trimdir}/all_2.fastq.gz \
		-r ${krakendir}/${assembly}_kraken2_report \
		--exclude --include-parents --taxid 2 \
		-o ${krakendir}/${assembly}_1.fastq \
		-o2 ${krakendir}/${assembly}_2.fastq"

# rm ${trimdir}/all_1.fastq.gz
# rm ${trimdir}/all_2.fastq.gz

# Deactivate virtual environment and unload modules
deactivate
