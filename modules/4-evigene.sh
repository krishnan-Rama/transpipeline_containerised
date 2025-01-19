#!/bin/bash
#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>     
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=16      
#SBATCH --mem=32G     

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

cat $0

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=ramakrishnan2005/evigene:01jan18
SINGULARITY_IMAGE_NAME=evigene:01jan18

if [ -f ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    singularity pull ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} docker://$IMAGE_NAME
fi

echo ${singularities}

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}

# Set working directory
WORKINGDIR=${pipedir}

export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/evigene_commands_${SLURM_JOB_ID}.sh <<EOF

/opt/evigene/scripts/prot/tr2aacds.pl -mrnaseq "${assemblydir}/${assembly}.fasta" -MINCDS=60 -NCPU=16 -MAXMEM=128000 -logfile -tidyup

mv dropset ${evigenedir}
mv okayset ${evigenedir}
cp "${evigenedir}/okayset/${assembly}.okay.fasta" "${assemblydir}/${assembly}_okay.fasta"

rm -r inputset
rm -r tmpfiles
rm -r ${assemblydir}/${assembly}nrcd1*
rm "${assemblydir}/${assembly}.tr2aacds.log"
rm "${assemblydir}/${assembly}.trclass"
rm "${assemblydir}/${assembly}.trclass.sum.txt"
rm "${assemblydir}/${assembly}nr.cds."*
rm -r "${assemblydir}/chrysalis"
rm -r "${assemblydir}/insilico_read_normalization"
rm -r "${assemblydir}/${assembly}_split"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/evigene_commands_${SLURM_JOB_ID}.sh
