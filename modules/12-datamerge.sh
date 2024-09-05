#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=16        
#SBATCH --mem-per-cpu=10000    

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

# Load R module
module load R/4.3.1

# Set variables (these will be passed by your pipeline)
workdir=${pipedir}

merged_outdir=${workdir}/outdir/merged_data

# Create the merged data directory if it doesn't exist
mkdir -p ${merged_outdir}

# Run the R script
Rscript ${moduledir}/process_rna_seq.R ${workdir} ${assembly} ${mergedir}

cp ${mergedir}/${assembly}_combined_final.csv ${merged_outdir}/${assembly}_combined_data.csv

