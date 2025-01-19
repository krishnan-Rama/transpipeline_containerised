#!/bin/bash
#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>     
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=4      
#SBATCH --mem=8G     

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

IMAGE_NAME=trinityrnaseq/trinityrnaseq:latest
SINGULARITY_IMAGE_NAME=trinityrnaseq:latest

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

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/trinitystats_commands_${SLURM_JOB_ID}.sh <<EOF

/usr/local/bin/util/TrinityStats.pl "${assemblydir}/${assembly}_okay.fasta" > "${assemblydir}/${assembly}_okay_stats.txt"

/usr/local/bin/util/support_scripts/get_Trinity_gene_to_trans_map.pl "${assemblydir}/${assembly}_okay.fasta" > "${assemblydir}/${assembly}_okay.gene_trans_map"

mkdir -p "${outdir}/nonredundant_assembly"
cp "${assemblydir}/${assembly}_okay.fasta" "${outdir}/nonredundant_assembly/${assembly}_okay.fasta"
cp "${assemblydir}/${assembly}_okay.gene_trans_map" "${outdir}/nonredundant_assembly/${assembly}_okay.gene_trans_map"
cp "${assemblydir}/${assembly}_okay_stats.txt" "${outdir}/nonredundant_assembly/${assembly}_okay_stats.txt"
cp "${evigenedir}/okayset/${assembly}.okay.aa" "${outdir}/nonredundant_assembly/${assembly}_okay.aa.fasta"
cp "${evigenedir}/okayset/${assembly}.okay.cds" "${outdir}/nonredundant_assembly/${assembly}_okay.cds.fasta"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/trinitystats_commands_${SLURM_JOB_ID}.sh
