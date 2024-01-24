#!/bin/bash

module load blast/2.12.0
module load singularity/3.8.7

# Define paths to your files
blastdb="/mnt/scratch/c23048124/pipeline_all/blastdb"
query_seq="/mnt/scratch/c23048124/pipeline_all/workdir/busco_all/busco_Ealbidus/wild/Ealbidus_130923_wild_okay/auto_lineage/run_eukaryota_odb10/busco_sequences/single_copy_busco_sequences/1454155at2759.faa"
blastlib="sprot"
SLURM_CPUS_PER_TASK=8
busco_blast="/mnt/scratch/c23048124/pipeline_all/workdir/busco_blast"
blast_output="${busco_blast}/blastout.tsv"
modified_blast_output="${busco_blast}/modified_blastout.fasta"

# Run blastp
blastp -db "${blastdb}/${blastlib}" \
  -query "${query_seq}" \
  -num_threads "${SLURM_CPUS_PER_TASK}" \
  -max_target_seqs 100 \
  -qcov_hsp_perc 90 \
  -out "${blast_output}" \
  -outfmt "6 sseqid sscinames staxids sseq"

# Clear the contents of the modified blast output file before starting
> "$modified_blast_output"

# Read the blast output and replace sequence identifiers with shortened headers
while IFS=$'\t' read -r sseqid sscinames staxids sseq
do
  # Extract the UniProt ID
  uniprot_id=$(echo $sseqid | sed 's/sp|\([A-Z0-9_]*\)|.*/\1/')
  
  # Retrieve the scientific name using UniProt API
  full_scientific_name=$(curl -s "https://rest.uniprot.org/uniprotkb/${uniprot_id}.txt" | grep "OS   " | head -1 | sed 's/OS   \(.*\)/\1/' | sed 's/.$//')
  
  # Extract only the genus and species from the full scientific name
  short_scientific_name=$(echo $full_scientific_name | awk '{print $1 "_" $2}')

  # Use UniProt ID and short scientific name for the header
  header="${uniprot_id}_${short_scientific_name}"

  # Write the header and sequence to the modified blast output in FASTA format
  # Remove any dashes which represent gaps in sequences
  echo -e ">${header}\n$(echo $sseq | tr -d ' \t\n\r-' | fold -w 60)" >> "$modified_blast_output"
done < "$blast_output"

# Append the query sequence to the end of the modified blast output in FASTA format
cat "$query_seq" >> "$modified_blast_output"

# Replace spaces with underscores in sequence identifiers
sed '/^>/s/ /_/g' "${busco_blast}/modified_blastout.fasta" > "${busco_blast}/cleaned_blastout.fasta"

# Remove empty lines
grep -vP '^\s*$' "${busco_blast}/cleaned_blastout.fasta" > "${busco_blast}/cleaned_blastout_2.fasta"

# Clean up the headers in the cleaned_blastout_2.fasta
# This sed command replaces commas, parentheses, apostrophes, slashes, and other undesired symbols with underscores
sed -i '/^>/s/[(),;:\/'\''\t]/_/g' "${busco_blast}/cleaned_blastout_2.fasta"


# Load MAFFT module and align sequences
module load mafft-7.481-gcc-8.5.0-b6srufn
mafft "${busco_blast}/cleaned_blastout_2.fasta" > "${busco_blast}/blast_aln.fasta"
module unload mafft-7.481-gcc-8.5.0-b6srufn

# Load RAxML-NG module and construct the phylogenetic tree for protein sequences
module load RAxML-NG/v1.2.0
raxml-ng --all --msa "${busco_blast}/blast_aln.fasta" --model LG+G --bs-tree 100 --prefix "${busco_blast}/bl_tree" --threads 8
module unload RAxML-NG/v1.2.0

#module load iq-tree-2.1.3-gcc-8.4.1-5btx3gt
#iqtree -s "${busco_blast}/blast_aln.fasta" -m TEST -bb 1000 -nt 8 -prefix "${busco_blast}/iq_tree"
#module unload iq-tree-2.1.3-gcc-8.4.1-5btx3gt


#rm bl_tree*

