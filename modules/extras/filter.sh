#!/bin/bash

module load seqtk/v1.3

# Step 1: Extract Sequence IDs (clean only the first column)
awk '/^Apisum_/' Contamination.txt | awk '{print $1}' > contamination_ids1.txt
awk '/^Apisum_/' RemainingContamination.txt | awk '{print $1}' > contamination_ids2.txt
cat contamination_ids1.txt contamination_ids2.txt > all_contamination_ids.txt

# Step 2: Create list of sequences to keep by excluding the contaminated ones
grep -v -Ff all_contamination_ids.txt Apisum_220724_okay.fasta | grep '>' | sed 's/>//' > keep_ids.txt

# Step 3: Filter the FASTA file by keeping only the sequences not listed in the contamination files
seqtk subseq Apisum_220724_okay.fasta keep_ids.txt > Apisum_220724_filtered.fasta

# Step 4: Clean up
rm contamination_ids1.txt contamination_ids2.txt keep_ids.txt

# Optional: Uncomment the next line if you want to keep all_contamination_ids.txt
# rm all_contamination_ids.txt

echo "Pipeline complete. Filtered FASTA file: Apisum_220724_filtered.fasta"

