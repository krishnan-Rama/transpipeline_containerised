#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #   
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file
##SBATCH --mail-user=[insert email address]@Cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=end                                   # email on job end
##SBATCH --mail-type=fail                                  # email on job failure

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

workdir="/mnt/scratch/c23048124/new_Psca"

# Define and export fastq_files variable
fastq_files="${workdir}/fastq_files"
fastq_test="${workdir}/fastq_test"

module load seqtk/v1.3

echo "Starting subsequence..."

for file in ${fastq_files}/*_1.fastq.gz
do
  R1=$(basename $file | cut -f1 -d.)
  base=$(echo $R1 | sed 's/_1//')

  seqtk sample -s100 ${fastq_files}/${base}_1.fastq.gz 100000 > ${fastq_test}/${base}_100K_1.fastq.gz
  seqtk sample -s100 ${fastq_files}/${base}_2.fastq.gz 100000 > ${fastq_test}/${base}_100K_2.fastq.gz

done
