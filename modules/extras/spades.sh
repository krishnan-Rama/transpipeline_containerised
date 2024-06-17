#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=300GB
#SBATCH --error=spades.err 
#SBATCH --output=spades_%J.out

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

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=spades:3.15.5--h95f258a_1
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

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

WORKINGDIR=$(pwd -P)
ILLUMINA_SE="/mnt/scratch/c23048124/pipeline_all/workdir/rawdir/leaf/SRR11802588.fastq.gz"
NANOPORE_READS="/mnt/scratch/c23048124/pipeline_all/workdir/assembly/flye_assembly_rocket/flye_assembly_rocket_2/assembly.fasta"
#NANOPORE_READS=/mnt/scratch/c23048124/pipeline_all/workdir/assembly/flye_assembly_rocket/flye_assembly_rocket_2/assembly.fasta
OUTPUT_DIR=${moduledir}/spades_assembly_output

# Ensure output directory exists
mkdir -p ${OUTPUT_DIR}

############# SOURCE COMMANDS ##################################
cat >${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh <<EOF

spades.py -s ${ILLUMINA_SE} --nanopore ${NANOPORE_READS} -o ${OUTPUT_DIR} -t ${SLURM_CPUS_PER_TASK} -m 1024

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh
