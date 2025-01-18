#!/bin/bash

#SBATCH --job-name=Mamestra_b_160124
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=2000     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

cat $0

##################SINGULARITY SETUP##############################

# load singularity module
module load singularity/3.8.7

WORKINGDIR=${pipedir}

IMAGE_NAME=blobtoolkit.sif
taxdb="${WORKINGDIR}/taxdb"
mkdir -p ${taxdb}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

mkdir -p $WORKINGDIR/blobtools
export blob="$WORKINGDIR/blobtools"

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
 else
    echo "Singularity image does not exist"
        singularity pull -F ${pipedir}/singularities/${IMAGE_NAME} docker://genomehubs/blobtoolkit:4.3.2
fi

if [ -f ${taxdb}/taxdump.tar.gz ]; then
    echo "Taxdump db exists"
 else
    echo "Taxdump db does not exist"
    wget -O ${taxdb}/taxdump.tar.gz https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz
    tar -xzvf ${taxdb}/taxdump.tar.gz -C ${taxdb}
fi

echo "Creating blobtools dataset..."

############# SOURCE COMMANDS ##################################
cat >${log}/blobtools_commands_${SLURM_JOB_ID}.sh <<EOF


# Define BUSCO directories
eukaryota_dir="${buscodir}/${assembly}_okay/run_eukaryota_odb10"
lepidoptera_dir="${buscodir}/${assembly}_okay/run_lepidoptera_odb10"

# Process BUSCO directories
for busco_dir in "\$eukaryota_dir" "\$lepidoptera_dir"; do
    outname=\$(basename "\$busco_dir")
    mkdir -p "${blob}/datasets/\${outname}"

    # Ensure the full_table.tsv exists
    full_table="\${busco_dir}/full_table.tsv"
    if [ ! -f "\$full_table" ]; then
        echo "Error: full_table.tsv missing in \${busco_dir}!"
        continue
    fi

    # Run blobtools create
    blobtools create \
        --fasta "${assemblydir}/${assembly}_okay.fasta" \
        --taxid "${taxa}" \
        --taxdump "${taxdb}" \
        --busco "\$full_table" \
        "${blob}/datasets/\${outname}"
done

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/blobtools_commands_${SLURM_JOB_ID}.sh
