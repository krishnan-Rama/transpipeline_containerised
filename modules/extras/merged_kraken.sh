#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=70000

# Function to display SLURM environment variables
display_slurm_vars() {
    echo "Some Usable Environment Variables:"
    echo "================================="
    echo "hostname=$(hostname)"
    local vars=("SLURM_JOB_ID" "SLURM_NTASKS" "SLURM_NTASKS_PER_NODE" "SLURM_CPUS_PER_TASK" "SLURM_JOB_CPUS_PER_NODE" "SLURM_MEM_PER_CPU")
    for var in "${vars[@]}"; do
        echo "\$$var=${!var}"
    done
}

display_slurm_vars

# Write jobscript to output file (good for reproducibility)
cat $0

# Check for the existence of the report and output file
output_file="${krakendir}/${assembly}_kraken2_output"
report_file="${krakendir}/${assembly}_kraken2_report"

if [ ! -f $output_file ] || [ ! -f $report_file ]; then
    echo "Starting Kraken2 analysis..."

    # Load necessary modules
    module load kraken2/2.1.1
    module load seqtk/v1.3

    # Run Kraken2
    kraken2 --paired --db /mnt/scratch/nodelete/smbpk/kraken/kraken_db/kraken_standard \
	    --output $output_file \
	    --report $report_file \
	    --classified-out ${krakendir}/${assembly}_#.classified.fastq \
	    --unclassified-out ${krakendir}/${assembly}_#.unclassified.fastq \
	    --threads ${SLURM_CPUS_PER_TASK} \
	    ${trimdir}/${assembly}_1.fastq.gz ${trimdir}/${assembly}_2.fastq.gz

    # Unload modules after use
    module unload kraken2/2.1.1
    module unload seqtk/1.3
fi

# Ensure both the output_file and report_file exist before proceeding
if [ -f $output_file ] && [ -f $report_file ]; then
   
       	# Activate Python virtual environment
    python -m venv python_kraken2
    source ${moduledir}/python_kraken/python_kraken2/bin/activate

    # Run extraction script in sbatch
    sbatch --job-name=pipeline --output=${krakendir}/G_bull.out --error=${krakendir}/G_bull.err \
          --ntasks=1 --cpus-per-task=4 --mem=16G \
          --wrap="${moduledir}/extract_kraken_reads.py \
          -k ${krakendir}/${assembly}_trim_kraken2_output \
          -s1 ${trimdir}/${assembly}_trim_1.fastq.gz \
          -s2 ${trimdir}/${assembly}_trim_2.fastq.gz \
          -r ${krakendir}/${assembly}_trim_kraken2_report \
          --exclude --include-parents --taxid 2 \
          -o ${krakendir}/${assembly}_1.fastq \
          -o2 ${krakendir}/${assembly}_2.fastq"

    # Deactivate virtual environment
    deactivate
else
    echo "The Kraken2 output or report file is missing. Skipping the extraction step."
fi

