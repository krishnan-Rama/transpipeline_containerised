#!/bin/bash
#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #   
#SBATCH --mem=36000            # in megabytes, unless unit explicitly stated

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

# Load singularity module
module load singularity/3.8.7

IMAGE_NAME=blast:2.12.0--hf3cf87c_4

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

declare -a blastlib=(\
sprot
Hsap
Mmus
Dmel
Cele
Scer
)

############# SOURCE COMMANDS ##################################
cat >${log}/blastp_trimming_commands_${SLURM_JOB_ID}.sh <<EOF

blastp -query "${evigenedir}/okayset/${assembly}.okay.aa" \
       -db "${blastdb}/${blastlib[${SLURM_ARRAY_TASK_ID}]}" \
       -num_threads ${SLURM_CPUS_PER_TASK} \
       -max_target_seqs 1 \
       -evalue 1E-10 \
       -outfmt 6 \
       -out "${blastout}/${assembly}_${blastlib[${SLURM_ARRAY_TASK_ID}]}_blp.tsv"

mkdir -p "${outdir}/blast_results"
cp "${blastout}"/*.tsv "${outdir}/blast_results" 

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/blastp_trimming_commands_${SLURM_JOB_ID}.sh
