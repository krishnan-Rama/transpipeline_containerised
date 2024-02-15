#!/bin/bash

#SBATCH --job-name=Hypo
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=100GB

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

IMAGE_NAME=hypo:1.0.3--he513fc3_0 
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

ASSEMBLY="/mnt/scratch/c23048124/pipeline_all/modules/polish/racon_polished_assembly.fasta"
ILLUMINA_R1="/mnt/scratch/c23048124/pipeline_all/workdir/rawdir/leaf/SRR11802588.fastq.gz"
OUTPUT_DIR="${moduledir}/hypo"
SAM="/mnt/scratch/c23048124/pipeline_all/modules/polish"

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/hypo_polishing_commands_${SLURM_JOB_ID}.sh <<EOF

hypo -r $ILLUMINA_R1 -d $ASSEMBLY -c 43 -b $SAM/illumina_reads.bam -s 180m -o $SAM/hypo_polished_genome.fasta -t ${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/hypo_polishing_commands_${SLURM_JOB_ID}.sh

