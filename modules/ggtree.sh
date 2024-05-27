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

# Define the path to your Newick file
newick_file="/mnt/scratch/c23048124/pipeline_all/workdir/busco_blast/bl_tree.raxml.support"

# Define the output image file name
output_image="/mnt/scratch/c23048124/pipeline_all/workdir/busco_blast/tree_visualization.png"

IMAGE_NAME=bioconductor-ggtree:3.8.0--r43hdfd78af_0
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

############# SOURCE COMMANDS ##################################
cat >${log}/ggtree_${SLURM_JOB_ID}.sh <<EOF
#!/bin/bash

# Load R module
module load R/4.3.1

# Run R script to create and save the plot
Rscript -e "library(ggtree); tree <- read.tree('$newick_file'); p <- ggtree(tree) + geom_tiplab(); ggsave('$output_image', plot = p)"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/ggtree_${SLURM_JOB_ID}.sh

