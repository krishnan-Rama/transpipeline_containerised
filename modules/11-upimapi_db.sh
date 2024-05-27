#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=<HPC_partition>
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G

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

# create a single output folder instead of one for each organism
mkdir -p ${upimapi}/output/

# run upimapi --blast once for all organisms
for i in sprot Dmel Cele Mmus Scer Hsap; do
    upimapi --blast -i "${blastout}/${assembly}_\${i}_blp.tsv" -t ${SLURM_CPUS_PER_TASK} -o ${upimapi}/output/ -ot "${upimapi}/output/${assembly}_\${i}_upimapi.tsv" --columns "Gene Names&Gene ontology (biological process)"
done

# concatenate all the output files into a single CSV dataframe vertically with their headers
output_file="${upimapi}/output/${assembly}_all_upimapi.csv"
: > \$output_file  # empty the file if it exists

header_written=false
for i in sprot Dmel Cele Mmus Scer Hsap; do
    if [ "\$header_written" = "false" ]; then
        # Convert TSV to CSV and append to the final file
        awk 'BEGIN { OFS=","; FS="\t" } { $1=$1; print }' "${upimapi}/output/${assembly}_\${i}_upimapi.tsv" >> \$output_file
        header_written=true
    else
        # Skip the header, convert TSV to CSV, and append the rest
        awk 'BEGIN { OFS=","; FS="\t" } NR > 1 { $1=$1; print }' "${upimapi}/output/${assembly}_\${i}_upimapi.tsv" >> \$output_file
    fi
done

EOF

################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGFOLDER} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/upimapi_source_commands_${SLURM_JOB_ID}.sh
