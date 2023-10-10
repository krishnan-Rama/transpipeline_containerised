#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=gpu       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=1      #
#SBATCH --mem-per-cpu=70000     # in megabytes, unless unit explicitly stated

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

IMAGE_NAME=kraken2:2.1.3--pl5321hdcf5f25_0
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

# wget -O ${pipedir}/kraken_standard/kraken_standard.tar.gz https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20230605.tar.gz
# tar -xzvf ${pipedir}/kraken_standard/kraken_standard.tar.gz -C ${pipedir}/kraken_standard/

# Check if both "all_1.fastq.gz" and "all_2.fastq.gz" files exist
if [ ! -f "${trimdir}/all_1.fastq.gz" ] || [ ! -f "${trimdir}/all_2.fastq.gz" ]; then
    # Concatenate the individual files if either or both don't exist
    cat ${trimdir}/*_1.fastq.gz > "${trimdir}/all_1.fastq.gz"
    cat ${trimdir}/*_2.fastq.gz > "${trimdir}/all_2.fastq.gz"
    echo "Concatenation complete."
else
    echo "Input files already exist. Skipping concatenation."
fi

echo "Starting Kraken2 analysis..."

echo ${trimdir}

############# SOURCE COMMANDS ##################################
cat >${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh <<EOF

kraken2 --paired --db ${pipedir}/kraken_standard \
  --output ${krakendir}/${assembly}_kraken2_output \
  --report ${krakendir}/${assembly}_kraken2_report \
  --classified-out ${krakendir}/${assembly}_#.classified.fastq \
  --unclassified-out ${krakendir}/${assembly}_#.unclassified.fastq \
  --threads ${SLURM_CPUS_PER_TASK} \
  ${trimdir}/all_1.fastq.gz ${trimdir}/all_2.fastq.gz

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh
