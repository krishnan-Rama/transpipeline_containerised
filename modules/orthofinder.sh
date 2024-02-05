#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=64      #
#SBATCH --mem-per-cpu=5000   # in megabytes, unless unit explicitly stated

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

# load modules
#module load python/3.10.5

#cd ${moduledir}/OrthoFinder_source

#python orthofinder.py -f ExampleData_2

#mkdir -p  ${workdir}/Orthologtree

#module unload python/3.10.5

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=orthofinder:2.5.5--hdfd78af_1 
#SINGULARITY_IMAGE_NAME=trinityrnaseq_2.15.1.sif

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

echo ${singularities}

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Trinity requires max memory in GB not MB, script to convert mem to GB
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)

# Set working directory
WORKINGDIR=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/orthofinder_${SLURM_JOB_ID}.sh <<EOF

orthofinder -f ${moduledir}/OrthoFinder_source/ExampleData_2 -M msa -T iqtree

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/orthofinder_${SLURM_JOB_ID}.sh
