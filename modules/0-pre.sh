#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=jumbo       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=2      #   
#SBATCH --mem-per-cpu=100     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Loop through all R1 files and rename them to _1.fastq.gz if not already in the correct format
for file in "${rawdir}"/*_R1.fastq.gz; 
do 
    # Extract the base name of the file without _R1.fastq.gz
    base_name=$(basename "$file" _R1.fastq.gz)
    
    # Check if the file is already in the correct format
    if [[ ! -f "${rawdir}/${base_name}_1.fastq.gz" ]]; then
        # Rename the file
        mv "$file" "${rawdir}/${base_name}_1.fastq.gz"
    fi
done

# Loop through all R2 files and rename them to _2.fastq.gz if not already in the correct format
for file in "${rawdir}"/*_R2.fastq.gz; 
do 
    # Extract the base name of the file without _R2.fastq.gz
    base_name=$(basename "$file" _R2.fastq.gz)
    
    # Check if the file is already in the correct format
    if [[ ! -f "${rawdir}/${base_name}_2.fastq.gz" ]]; then
        # Rename the file
        mv "$file" "${rawdir}/${base_name}_2.fastq.gz"
    fi
done

echo "Renaming completed."

