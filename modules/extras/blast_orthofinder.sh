#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16      #
#SBATCH --mem-per-cpu=30000   # in megabytes, unless unit explicitly stated

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

# Load singularity module
module load singularity/3.8.7

# Define the OrthoFinder Singularity image name and path
IMAGE_NAME=orthofinder:2.5.5--hdfd78af_1
IMAGE_URL=https://depot.galaxyproject.org/singularity/$IMAGE_NAME
IMAGE_PATH=${pipedir}/singularities/${IMAGE_NAME}

# Check if the Singularity image exists and download it if it does not
if [ -f ${IMAGE_PATH} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${IMAGE_PATH} ${IMAGE_URL}
fi

echo ${singularities}

# Define directories
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}
WORKINGDIR=${pipedir}
OUTPUT_DIR=${WORKINGDIR}/orthofinder_out

# Set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/orthofinder_${SLURM_JOB_ID}.sh <<EOF

orthofinder -f ${OUTPUT_DIR}/genomes -M msa -T iqtree -t ${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/orthofinder_${SLURM_JOB_ID}.sh

