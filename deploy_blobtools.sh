#!/bin/bash

# Source config script
source config.parameters_all

# Prompt the user for the HPC partition name
read -p "Enter your preferred HPC partition name: " HPC_partition

# Function to replace <HPC_partition> in a given file
replace_partition() {
    sed -i "s/<HPC_partition>/${HPC_partition}/g" "$1"
}

# Replace <HPC_partition> only in the two specific scripts
for script in "${moduledir}/blobtools.sh" "${moduledir}/blobviewer.sh"; do
    if grep -q "<HPC_partition>" "$script"; then
        replace_partition "$script"
    fi
done

#---------------------------SPECIES IDENTIFIER---------------------------------------------

# Prompt the user for the species identifier name
read -p "Please enter the species/project identifier name (e.g., Hsap_120624, Hsap for humans): " species_identifier

# Function to replace <pipeline> in a given file
replace_pipeline() {
    sed -i "s/<pipeline>/${species_identifier}/g" "$1"
}

# Replace <pipeline> only in the two specific scripts
for script in "${moduledir}/blobtools.sh" "${moduledir}/blobviewer.sh"; do
    if grep -q "<pipeline>" "$script"; then
        replace_pipeline "$script"
    fi
done

# Export the species identifier
export SPECIES_IDENTIFIER="$species_identifier"

assembly="${SPECIES_IDENTIFIER}"
export assembly

#-------------------------------TAXON ID---------------------------------------------------

# Prompt the user for the species taxonomic Id
read -p "Please enter the species taxonomic Id (e.g., 9606 for Homo sapiens): " taxon_identifier

# Function to replace <pipeline> in a given file
replace_pipeline() {
    sed -i "s/<pipeline>/${taxon_identifier}/g" "$1"
}

# Replace <pipeline> only in the two specific scripts
for script in "${moduledir}/blobtools.sh" "${moduledir}/blobviewer.sh"; do
    if grep -q "<pipeline>" "$script"; then
        replace_pipeline "$script"
    fi
done

# Export the species identifier
export TAXON_IDENTIFIER="$taxon_identifier"

taxa="${TAXON_IDENTIFIER}"
export taxa

#---------------------------RUN TASKS---------------------------------------------

# Step 1: Run Blobtools
sbatch -d singleton --error="${log}/blobtools%J.err" --output="${log}/blobtools_%J.out" "${moduledir}/blobtools.sh"

sbatch -d singleton --error="${log}/blobviewer%J.err" --output="${log}/blobviewer_%J.out" "${moduledir}/blobviewer.sh"
