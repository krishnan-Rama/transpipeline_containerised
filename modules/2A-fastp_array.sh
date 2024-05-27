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
module load singularity/3.8.7

IMAGE_NAME=fastp:0.23.4--hadf994f_2

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

echo "Singularities directory: ${singularities}"

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Set working directory 
WORKINGDIR=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

# Debug: Print the rawdir variable
echo "Raw directory: ${rawdir}"

# Get list of all unique base names (without _1 or _2 suffix)
bases=$(ls ${rawdir}/*_1.fastq.gz | xargs -n 1 basename | sed 's/_1.fastq.gz//' | sort | uniq)

for base in $bases; do
    export base

    # Debug: Print the base name
    echo "Processing base name: $base"

    ############# SOURCE COMMANDS ##################################
    cat >${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh <<EOF
fastp -i "${rawdir}/${base}_1.fastq.gz" -I "${rawdir}/${base}_2.fastq.gz" \
  -o "${trimdir}/${base}_trim_1.fastq.gz" -O "${trimdir}/${base}_trim_2.fastq.gz" \
  --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 30 \
  --qualified_quality_phred 30 --unqualified_percent_limit 30 \
  --n_base_limit 5 --length_required 60 --detect_adapter_for_pe \
  -h "${qcdir}/${base}_fastp.html" -j "${qcdir}/${base}_fastp.json" \
  -w ${SLURM_CPUS_PER_TASK}
EOF
    ################ END OF SOURCE COMMANDS ######################

    # Debug: Print the command to be executed by singularity
    echo "Singularity Command:"
    cat ${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh

    # Execute the trimming commands with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh
done

