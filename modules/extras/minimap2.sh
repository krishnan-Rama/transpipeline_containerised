#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=gpu       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #
#SBATCH --mem-per-cpu=64000     # in megabytes, unless unit explicitly stated

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

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=minimap2:2.9--1
# SINGULARITY_IMAGE_NAME=fastp-0.20.0.sif

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
 else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

echo ${singularities}

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Set working directory 
WORKINGDIR=${pipedir}
NANOPORE_DRAFT_ASSEMBLY="/mnt/scratch/c23048124/pipeline_all/workdir/assembly/flye_assembly_rocket/flye_assembly_rocket_2/assembly.fasta"
NANOPORE_RAW_READS="/mnt/scratch/c23048124/pipeline_all/workdir/rawdir/leaf/concat.fastq.gz"

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh <<EOF

minimap2 -ax map-ont $NANOPORE_DRAFT_ASSEMBLY $NANOPORE_RAW_READS > mm2_nano.sam

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh

