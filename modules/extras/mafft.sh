#!/bin/bash

#SBATCH --job-name=mafft_alignment          # Job name
#SBATCH --partition=jumbo         # Requested queue (replace with actual partition)
#SBATCH --nodes=1                           # Number of nodes to use
#SBATCH --tasks-per-node=1                  # Tasks per node
#SBATCH --cpus-per-task=8                   # Number of CPU cores per task
#SBATCH --mem-per-cpu=6000                 # Memory per CPU in megabytes

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

# Load Singularity module
module load singularity/3.8.7

# Define the Singularity image and input/output paths
IMAGE_NAME=mafft:7.525--h031d066_1
INPUT_FILE=/mnt/scratch15/c23048124/metal/transpipeline_containerised/clipkit/OG0000059.fa
OUTPUT_DIR=/mnt/scratch15/c23048124/metal/transpipeline_containerised/clipkit
OUTPUT_FILE=${OUTPUT_DIR}/OG0000059_aligned.fa

# Set working directory
WORKINGDIR=${OUTPUT_DIR}

# Set folders to bind into container
export BINDS="${WORKINGDIR}:${WORKINGDIR}"

# Check if the Singularity image exists
if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

# Define the Singularity image directory and name
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Create MAFFT command
MAFFT_COMMAND="mafft --auto ${INPUT_FILE} > ${OUTPUT_FILE}"

# Debug: Print the MAFFT command
echo "MAFFT Command:"
echo ${MAFFT_COMMAND}

# Execute the MAFFT command with Singularity
singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${MAFFT_COMMAND}"

# Confirm completion
echo "MAFFT alignment completed. Output file: ${OUTPUT_FILE}"

