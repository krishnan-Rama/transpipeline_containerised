#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #   
#SBATCH --mem=36000            # in megabytes, unless unit explicitly stated

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

module load singularity/3.8.7

query_seq="/mnt/scratch/c23048124/pipeline_all/workdir/busco_all/busco_Ealbidus/wild/Ealbidus_130923_wild_okay/auto_lineage/run_eukaryota_odb10/busco_sequences/single_copy_busco_sequences"

declare -a blastlib=(\
sprot
)

# Define a function to extract the species name from a SwissProt identifier
extract_species_name() {
  # Split the identifier into two parts: the accession number and the entry name
  accession_number=$(echo $1 | cut -d'_' -f1)
  entry_name=$(echo $1 | cut -d'_' -f2)
 
  # Retrieve the gene name associated with the entry name
  gene_name=$(curl -s "https://www.uniprot.org/uniprot/$entry_name.txt" | grep -oP '^GN\s+Name=\K\S+')
 
  # Extract the species name from the gene name
  genus=$(echo $gene_name | cut -d'_' -f1)
  species=$(echo $gene_name | cut -d'_' -f2)
  echo "$genus $species"
}

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

declare -a blastlib=(\
sprot
)

############# SOURCE COMMANDS ##################################
cat >${log}/blastp_${SLURM_JOB_ID}.sh <<EOF

blastp -db "${blastdb}/${blastlib[${SLURM_ARRAY_TASK_ID}]}" \
-query "${query_seq}/1454155at2759.faa" \
-num_threads ${SLURM_CPUS_PER_TASK} \
-max_target_seqs 10 \
-qcov_hsp_perc 90 \
-out "${busco_blast}/Ealbidus_130923_wild_okay_blast2.tsv" \
-outfmt "6 qseqid sscinames staxids sseq"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/blastp_${SLURM_JOB_ID}.sh

# Process BLAST output to extract species names
blast_output="${busco_blast}/Ealbidus_130923_wild_okay_blast2.tsv"
while read -r line; do
    gene_name=$(echo "$line" | cut -f1)
    species_name=$(extract_species_name "$gene_name")
    echo "$line $species_name"
done < "$blast_output" > "${blast_output}_with_species"
