#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=300000

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

IMAGE_NAME=flye:2.9.2--py39hd65a603_2
# SINGULARITY_IMAGE_NAME

if [ -f "${pipedir}/singularities/${IMAGE_NAME}" ] && [ -s "${pipedir}/singularities/${IMAGE_NAME}" ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist or is zero size"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# convert mem to GB
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)

# Define input files
read1="${krakendir}/${assembly}.fastq.gz"
#read2="${rcordir}/${assembly}_2.cor.fq.gz"

# Define the output directory and assembly name
output_dir="${workdir}/assembly/flye_assembly_Salmon"
mkdir -p "$output_dir"

WORKINGDIR=${pipedir}
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/trinity_assembly_commands_${SLURM_JOB_ID}.sh <<EOF

# Run Flye with specified parameters
flye --threads ${SLURM_CPUS_PER_TASK} \
     --out-dir "$output_dir" \
     --nano-raw "$read1" \
     --genome-size 0.8g

echo "Assembly complete!"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/trinity_assembly_commands_${SLURM_JOB_ID}.sh

