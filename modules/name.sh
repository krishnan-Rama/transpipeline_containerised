#!/bin/bash

# Directory containing the module scripts
moduledir="/mnt/data/GROUP-smbpk/c23048124/gitrepo/transpipeline_containerised/modules"  # Update this path to your actual module directory

# Loop through all .sh files in the specified directory
for script in "${moduledir}"/*.sh; do
    if grep -q "<HPC_partition>" "$script"; then
        sed -i "s/<HPC_partition>/<HPC_partition>/g" "$script"
        echo "Replaced '<HPC_partition>' with '<HPC_partition>' in $script"
    fi
done

