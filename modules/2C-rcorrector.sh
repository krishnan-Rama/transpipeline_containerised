#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=jumbo       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #
#SBATCH --mem-per-cpu=64000     # in megabytes, unless unit explicitly stated


echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Write jobscript to output file (good for reproducibility)
 cat $0

 cd ${pipedir}/workdir/kraken_all/kraken_output/rcorrector

# load modules
 module load perl/5.34.0
 module load jellyfish/2.2.9

 perl run_rcorrector.pl -1 ${krakendir}/*_1.fastq.gz -2 ${krakendir}/*_2.fastq.gz -od ${rcordir}

# Unload modules
 module unload perl/5.34.0
 module unload jellyfish/2.2.9
