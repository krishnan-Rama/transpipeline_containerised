#!/bin/bash

# Loop through all .sh files in the current directory
for file in *.sh; do
    # Check if the file exists and is a regular file
    if [ -f "$file" ]; then
        # Use sed to replace the text in the file
        sed -i 's/--job-name=<pipeline>/--job-name=<pipeline>/g' "$file"
        echo "Updated $file"
    else
        echo "No .sh files found in the current directory."
    fi
done

