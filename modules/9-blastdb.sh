#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #   
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated

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

#full swissprot

wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz" -O ${blastdb}/sprot.fasta.gz

#Proteomes
#Human (UP000005640): 
wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz" -O ${blastdb}/Hsap.fasta.gz

#Mouse (UP000000589):
wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000000589/UP000000589_10090.fasta.gz" -O ${blastdb}/Mmus.fasta.gz

#Fly (UP000000803):
wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000000803/UP000000803_7227.fasta.gz" -O ${blastdb}/Dmel.fasta.gz

#C. elegans (UP000001940):
wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000001940/UP000001940_6239.fasta.gz" -O ${blastdb}/Cele.fasta.gz

#Saccharomyces cerevisiae (UP000002311):
wget "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000002311/UP000002311_559292.fasta.gz" -O ${blastdb}/Scer.fasta.gz

gunzip ${blastdb}/sprot.fasta.gz
gunzip ${blastdb}/Hsap.fasta.gz
gunzip ${blastdb}/Mmus.fasta.gz
gunzip ${blastdb}/Dmel.fasta.gz
gunzip ${blastdb}/Cele.fasta.gz
gunzip ${blastdb}/Scer.fasta.gz

# Load singularity module
module load singularity/3.8.7

IMAGE_NAME=blast:2.12.0--hf3cf87c_4

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
cat >${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh <<EOF

makeblastdb -in ${blastdb}/sprot.fasta -dbtype prot -title sprot -out ${blastdb}/sprot
makeblastdb -in ${blastdb}/Hsap.fasta -dbtype prot -title Hsap -out ${blastdb}/Hsap
makeblastdb -in ${blastdb}/Mmus.fasta -dbtype prot -title Mmus -out ${blastdb}/Mmus
makeblastdb -in ${blastdb}/Dmel.fasta -dbtype prot -title Dmel -out ${blastdb}/Dmel
makeblastdb -in ${blastdb}/Cele.fasta -dbtype prot -title Cele -out ${blastdb}/Cele
makeblastdb -in ${blastdb}/Scer.fasta -dbtype prot -title Scer -out ${blastdb}/Scer

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/fastp_trimming_commands_${SLURM_JOB_ID}.sh

