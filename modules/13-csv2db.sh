#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=8        
#SBATCH --mem-per-cpu=10000 

echo "Environment Variables:"
echo "======================"
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

module load python/3.10.5

pip install tabulate

workdir=${pipedir}

database_outdir=${outdir}/database

mkdir -p ${merged_outdir}

merged_outdir=${workdir}/workdir/mergedir

python ${moduledir}/query_gene_data.py --csv ${merged_outdir}/${assembly}_combined_final.csv --db ${merged_outdir}/final_data.db 
