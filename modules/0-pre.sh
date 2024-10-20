#!/bin/bash
#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=2      
#SBATCH --mem-per-cpu=100    

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Loop through all possible file formats and rename to _1.fastq.gz or _2.fastq.gz as needed
for file in "${rawdir}"/*_R1.fastq.gz "${rawdir}"/*_R1.fq.gz "${rawdir}"/*_1.fastq.gz "${rawdir}"/*_1.fq.gz; 
do 
    # Extract the base name of the file without the specific suffix
    base_name=$(basename "$file" | sed -E 's/(_R1|_1)\.(fastq|fq)\.gz$//')
    
    # Check if the file is already in the correct format
    if [[ ! -f "${rawdir}/${base_name}_1.fastq.gz" ]]; then
        # Rename the file
        mv "$file" "${rawdir}/${base_name}_1.fastq.gz"
    fi
done

# Loop through all possible file formats for R2 and rename to _2.fastq.gz as needed
for file in "${rawdir}"/*_R2.fastq.gz "${rawdir}"/*_R2.fq.gz "${rawdir}"/*_2.fastq.gz "${rawdir}"/*_2.fq.gz; 
do 
    # Extract the base name of the file without the specific suffix
    base_name=$(basename "$file" | sed -E 's/(_R2|_2)\.(fastq|fq)\.gz$//')
    
    # Check if the file is already in the correct format
    if [[ ! -f "${rawdir}/${base_name}_2.fastq.gz" ]]; then
        # Rename the file
        mv "$file" "${rawdir}/${base_name}_2.fastq.gz"
    fi
done

echo "Renaming completed."
