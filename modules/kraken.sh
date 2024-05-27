#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=<HPC_partition>       # the requested queue
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
# load singularity module
module load singularity/3.8.7

IMAGE_NAME=kraken2:2.1.3--pl5321hdcf5f25_0

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

# Create directory for Kraken standard database
mkdir -p "${pipedir}/kraken_standard/"

# Download kraken database (standard) if not provided
if [ ! -f ${pipedir}/kraken_standard/k2_standard_20230605 ]; then
    wget -O ${pipedir}/kraken_standard/kraken_standard.tar.gz https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20230605.tar.gz
    tar -xzvf ${pipedir}/kraken_standard/kraken_standard.tar.gz -C ${pipedir}/kraken_standard/
fi

echo "Starting Kraken2 analysis..."

# Get list of all unique base names (without _1 or _2 suffix)
bases=$(ls ${trimdir}/*_trim_1.fastq.gz | xargs -n 1 basename | sed 's/_trim_1.fastq.gz//' | sort | uniq)

for base in $bases; do
    export base

    echo "Processing base name: $base"

    ############# SOURCE COMMANDS ##################################
    cat >${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh <<EOF

kraken2 --paired --db ${pipedir}/kraken_standard \
  --output ${krakendir}/${base}_kraken2_output \
  --report ${krakendir}/${base}_kraken2_report \
  --classified-out ${krakendir}/${base}_#.classified.fastq \
  --unclassified-out ${krakendir}/${base}_#.unclassified.fastq \
  --threads ${SLURM_CPUS_PER_TASK} \
  ${trimdir}/${base}_trim_1.fastq.gz ${trimdir}/${base}_trim_2.fastq.gz

EOF
    ################ END OF SOURCE COMMANDS ######################

    # Debug: Print the command to be executed by singularity
    echo "Singularity Command:"
    cat ${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh

    # Execute the Kraken2 commands with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/kraken_taxa_commands_${SLURM_JOB_ID}.sh
done

