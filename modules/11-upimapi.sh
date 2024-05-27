#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8      #   
#SBATCH --mem=16G     # in megabytes, unless unit explicitly stated

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

#IMAGE_NAME=downloaded from http://datacache.g2.bx.psu.edu/singularity/u/p/ guide UPIMAPI : https://github.com/iquasere/UPIMAPI
SINGULARITY_IMAGE_NAME=upimapi_1.9.0.sif

if [ -f ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    cp /mnt/scratch/nodelete/singularity_images/upimapi_1.9.0.sif ${pipedir}/singularities/upimapi_1.9.0.sif
fi

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}

# Set working directory 
WORKINGFOLDER=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGFOLDER}:${WORKINGFOLDER}"

############# SOURCE COMMANDS ##################################
cat >${log}/upimapi_source_commands_${SLURM_JOB_ID}.sh <<EOF

for i in sprot Dmel Cele Mmus Scer Hsap; do

mkdir ${upimapi}/\${i}/

upimapi --blast -i "${blastout}/${assembly}_\${i}_blp.tsv" -t ${SLURM_CPUS_PER_TASK} -o ${upimapi}/\${i}/ -ot "${upimapi}/\${i}/${assembly}_\${i}_upimapi.tsv" --columns "Gene Names&InterPro&PANTHER"

done

#Entry&Pfam&Reactome&InterPro -cols "Entry Name&Gene Names&Organism&Protein names&Length&Geane Ontology (biological process)&Gene Ontology (cellular component)&Gene Ontology (GO)&Gene Ontology (molecular function)&Gene Ontology IDs&Pfam&InterPro&Reactome"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGFOLDER} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/upimapi_source_commands_${SLURM_JOB_ID}.sh
