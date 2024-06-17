#!/bin/bash

#SBATCH --job-name=pipeline
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

find $buscodir/PscaXX_260723_okay/* -maxdepth 0 -type d | while read x
do
	outname=$(basename $x)
	mkdir -p ${blob}/datasets/${outname}
	blobtools create \
	    --fasta ${assemblydir}/PscaXX_260723.fasta \
	    --taxid 83198 \
	    --taxdump ${taxdb} \
	    --busco ${x}/run_eukaryota_odb10/full_table.tsv \
	    --busco ${x}/run_metazoa_odb10/full_table.tsv \
	    ${blob}/datasets/${outname}
done

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/blobtools_commands_${SLURM_JOB_ID}.sh
