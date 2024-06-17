#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=300GB

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

IMAGE_NAME=masurca:4.1.0--pl5321hb5bd705_1 
# SINGULARITY_IMAGE_NAME

if [ -f "${pipedir}/singularities/${IMAGE_NAME}" ] && [ -s "${pipedir}/singularities/${IMAGE_NAME}" ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist or is zero size"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

WORKINGDIR=${pipedir}
BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

# convert mem to GB
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)


# Path to your reads
# READ1="${rcordir}/${assembly}.cor.fq.gz"
# READ2="${rcordir}/${assembly}_2.fastq"

############# SOURCE COMMANDS ##################################
cat >${WORKINGDIR}/masurca_assembly_commands_${SLURM_JOB_ID}.sh <<EOF

# Create a configuration file for MaSuRCA
cat > masurca_config.txt << EOL
DATA
PE= pe 300 20 /mnt/scratch/c23048124/pipeline_all/workdir/kraken_all/Salmon/merged.fastq.gz
END

PARAMETERS
GRAPH_KMER_SIZE = auto
USE_LINKING_MATES = 0
LIMIT_JUMP_COVERAGE = 300
CA_PARAMETERS =  cgwErrorRate=0.25
KMER_COUNT_THRESHOLD = 1
NUM_THREADS = ${SLURM_CPUS_PER_TASK}
JF_SIZE = 1800000000
DO_HOMOPOLYMER_TRIM = 0
SOAP_ASSEMBLY = 1
END
EOL

mv masurca_config.txt masurca_assembly/
cd masurca_assembly

# Run MaSuRCA assembler with the configuration file
masurca masurca_config.txt

# Change into the MaSuRCA assembly directory and build the assembly
./assemble.sh

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${WORKINGDIR}/masurca_assembly_commands_${SLURM_JOB_ID}.sh

mv ${WORKINGDIR}/masurca_assembly_commands_${SLURM_JOB_ID}.sh ${WORKINGDIR}/masurca_assembly
