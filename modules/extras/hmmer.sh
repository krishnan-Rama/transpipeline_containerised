#!/bin/bash

#SBATCH --job-name=HMMER
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #
#SBATCH --mem-per-cpu=10000    # in megabytes, unless unit explicitly stated

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

# Load HMMER module
module load hmmer/3.1b2

# Set working directory 
WORKINGDIR=${pipedir}

# HMMER-specific variables
ORTHOLOGS_FILE="/mnt/scratch15/c23048124/metal/transpipeline_containerised/modules/OrthoFinder_source/ExampleData_2/OrthoFinder/Results_Jul18/Orthogroup_Sequences/OG0008430.fa"
PFAM_URL="ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz"
PFAM_DAT_URL="ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz"
HMM_DATABASE="${WORKINGDIR}/Pfam-A.hmm"
OUTPUT_FILE="${WORKINGDIR}/hmmer_results.txt"

# Ensure necessary commands are installed
for cmd in wget gunzip awk hmmpress hmmsearch; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd is not installed. Please install it."
        exit 1
    fi
done

# Download and prepare the Pfam database if not already present
if [ ! -f "$HMM_DATABASE" ]; then
    echo "Downloading Pfam database..."
    wget -q "$PFAM_URL" -O ${WORKINGDIR}/Pfam-A.hmm.gz
    wget -q "$PFAM_DAT_URL" -O ${WORKINGDIR}/Pfam-A.hmm.dat.gz
    echo "Extracting Pfam database..."
    gunzip ${WORKINGDIR}/Pfam-A.hmm.gz
    gunzip ${WORKINGDIR}/Pfam-A.hmm.dat.gz
    echo "Preparing Pfam database with hmmpress..."
    hmmpress ${HMM_DATABASE}
fi

# Check if orthologs file exists
if [ ! -f "$ORTHOLOGS_FILE" ]; then
    echo "Orthologs file not found!"
    exit 1
fi

# Extract ortholog sequences
awk '/^>/ {if(seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' "$ORTHOLOGS_FILE" > ${WORKINGDIR}/orthologs.fasta

# Debug: Print the orthologs file path
echo "Orthologs file: ${WORKINGDIR}/orthologs.fasta"

# Get list of all unique headers in the orthologs file
headers=$(grep '^>' ${WORKINGDIR}/orthologs.fasta | sort | uniq)

# Process each sequence
for header in $headers; do
    export header

    # Debug: Print the header being processed
    echo "Processing header: $header"

    # Extract sequence for the current header
    awk -v header="$header" 'BEGIN {print header} {if($0 ~ /^>/) {if(seq) print seq; seq=""; next} {seq=seq $0}} END {print seq}' ${WORKINGDIR}/orthologs.fasta > temp_seq.fasta
    
    # Run hmmsearch on the extracted sequence
    hmmsearch --tblout temp_results.txt "${HMM_DATABASE}" temp_seq.fasta
    
    # Append results to the output file
    cat temp_results.txt >> "${OUTPUT_FILE}"
    
    # Clean up temporary files
    rm -f temp_seq.fasta temp_results.txt
done

# Final clean up
rm -f ${WORKINGDIR}/orthologs.fasta

echo "HMMER search completed. Results are saved in ${OUTPUT_FILE}"

