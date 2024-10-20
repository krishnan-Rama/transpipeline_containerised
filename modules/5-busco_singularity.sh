#!/bin/bash
#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16      #   
#SBATCH --mem=32G     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Write jobscript to output file (good for reproducability)
cat $0

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=ezlabgva/busco:v5.4.7_cv1
SINGULARITY_IMAGE_NAME=busco_v5.4.7_cv1

if [ -f ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    singularity pull ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} docker://$IMAGE_NAME
fi

# set singularity image
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}

# Set working directory
WORKINGFOLDER=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGFOLDER}:${WORKINGFOLDER}"

############# SOURCE COMMANDS ##################################
cat >${log}/busco_source_commands_${SLURM_JOB_ID}.sh <<EOF

busco -f -i ${assemblydir}/${assembly}.fasta -m trans -o ${assembly} --out_path ${buscodir} --auto-lineage-euk -c ${SLURM_CPUS_PER_TASK}

busco -f -i ${assemblydir}/${assembly}_okay.fasta -m trans -o ${assembly}_okay --out_path ${buscodir} --auto-lineage-euk -c ${SLURM_CPUS_PER_TASK}


cp "${buscodir}/${assembly}"/*.txt "${outdir}/raw_assembly"
cp "${buscodir}/${assembly}_okay/"*.txt "${outdir}/nonredundant_assembly"

echo CPU=\${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGFOLDER} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/busco_source_commands_${SLURM_JOB_ID}.sh
