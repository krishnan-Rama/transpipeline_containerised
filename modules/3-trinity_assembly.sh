#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16      #   
#SBATCH --mem=30000     # in megabytes, unless unit explicitly stated

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

IMAGE_NAME=trinity%3A2.15.1--hff880f7_1

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
cat >${log}/trinity_assembly_commands_${SLURM_JOB_ID}.sh <<EOF

cat ${rcordir}/*_1.cor.fq.gz > ${rcordir}/all_1.fastq.gz
cat ${rcordir}/*_2.cor.fq.gz > ${rcordir}/all_2.fastq.gz

Trinity --seqType fq \
        --left "${rcordir}/all_1.fastq.gz" \
        --right "${rcordir}/all_2.fastq.gz" \
        --max_memory ${TOTAL_RAM}G \
        --CPU ${SLURM_CPUS_PER_TASK} \
        --output "${assemblydir}/" \
        --full_cleanup

# remove all temp files created by trinity
# rm -rf ${assemblydir}/*
# rm ${krakendir}/all_1.fastq.gz
# rm ${krakendir}/all_2.fastq.gz

#move assembly and gene trans map into assembly folder
mv "${assemblydir}.Trinity.fasta" "${assemblydir}/${assembly}.fasta"

mv "${assemblydir}.Trinity.fasta.gene_trans_map" "${assemblydir}/${assembly}.gene_trans_map"

#rename contigs by assembly using species identifier
sed -i "s/TRINITY_DN/${SPECIES_IDENTIFIER}_/g" "${assemblydir}/${assembly}.fasta"

#create assembly stats
#TrinityStats.pl on the Trinity.fasta output file
/usr/local/bin/util/TrinityStats.pl "${assemblydir}/${assembly}.fasta" > "${assemblydir}/${assembly}_stats.txt"

mkdir -p "${outdir}/raw_assembly"
cp "${assemblydir}/${assembly}.fasta" "${outdir}/raw_assembly/${assembly}.fasta"
cp "${assemblydir}/${assembly}_stats.txt" "${outdir}/raw_assembly/${assembly}_stats.txt"
cp "${assemblydir}/${assembly}.gene_trans_map" "${outdir}/raw_assembly/${assembly}.gene_trans_map"

echo TOTAL_RAM=${TOTAL_RAM}
echo CPU=${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/trinity_assembly_commands_${SLURM_JOB_ID}.sh
