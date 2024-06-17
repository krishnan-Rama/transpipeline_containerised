#!/bin/bash

#SBATCH --job-name=Medaka
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=200GB
#SBATCH --error=medaka.err 
#SBATCH --output=medaka_%J.out

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

IMAGE_NAME=medaka:1.8.0--py39h771796b_0
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
ILLUMINA_BASECALL="/mnt/scratch/c23048124/pipeline_all/workdir/rawdir/leaf/SRR11802588.fastq.gz"
NANOPORE_DRAFT_ASSEMBLY="${moduledir}/polish/racon_polished_assembly.fasta"
#NANOPORE_DRAFT_ASSEMBLY="/mnt/scratch/c23048124/pipeline_all/workdir/assembly/flye_assembly_rocket/flye_assembly_rocket_2/assembly.fasta"
#NANOPORE_READS=/mnt/scratch/c23048124/pipeline_all/workdir/assembly/flye_assembly_rocket/flye_assembly_rocket_2/assembly.fasta
OUTPUT_DIR="${moduledir}/polish/medaka_assembly_output"

############# SOURCE COMMANDS ##################################
cat >${log}/medaka_commands_${SLURM_JOB_ID}.sh <<EOF

medaka_consensus -i $ILLUMINA_BASECALL -d $NANOPORE_DRAFT_ASSEMBLY -o $OUTPUT_DIR -m r941_min_high_g303

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/medaka_commands_${SLURM_JOB_ID}.sh
