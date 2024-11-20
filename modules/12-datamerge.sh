#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=8        
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

cat $0

module load R/4.3.1

workdir=${pipedir}

merged_outdir=${outdir}/merged_data

mkdir -p ${merged_outdir}

Rscript ${moduledir}/process_rna_seq.R ${workdir} ${assembly} ${mergedir}

cp ${mergedir}/${assembly}_combined_final.csv ${merged_outdir}
