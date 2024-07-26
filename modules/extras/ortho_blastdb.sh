#!/bin/bash

#SBATCH --job-name=ortho_blast
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8      #   
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
cat >${log}/ortho_blast_commands_${SLURM_JOB_ID}.sh <<EOF

makeblastdb -in ${blastdb}/A_vulgaris_GCA_020796225_pep.fasta -dbtype prot -title sprot -out ${blastdb}/Avul
makeblastdb -in ${blastdb}/ApCa_Genome_070519_omicsbox_pep.fasta -dbtype prot -title Hsap -out ${blastdb}/ApCa
makeblastdb -in ${blastdb}/C_elegans_170624_proteome.fasta -dbtype prot -title Mmus -out ${blastdb}/Cele
makeblastdb -in ${blastdb}/Casp_20240627_Tall_okay.aa.fasta -dbtype prot -title Dmel -out ${blastdb}/Casp
makeblastdb -in ${blastdb}/Dret_20240624_Twb-cns_okay.aa.fasta -dbtype prot -title Cele -out ${blastdb}/Dret
makeblastdb -in ${blastdb}/Lumbricus_rubellus-GCA_945859605.1-2023_03-pep.fasta -dbtype prot -title Scer -out ${blastdb}/Lrub
makeblastdb -in ${blastdb}/Lumbricus_terrestris-GCA_949752735.1-2023_11-pep.fasta -dbtype prot -title Scer -out ${blastdb}/Lter
makeblastdb -in ${blastdb}/Ocincta_170724_pep.fasta -dbtype prot -title Scer -out ${blastdb}/Ocin
makeblastdb -in ${blastdb}/Ppac_170724_proteome.fasta -dbtype prot -title Scer -out ${blastdb}/Ppac
makeblastdb -in ${blastdb}/PscaXX_20240624_Ttiss_okay.aa.fasta -dbtype prot -title Scer -out ${blastdb}/Psca

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/ortho_blast_commands_${SLURM_JOB_ID}.sh

