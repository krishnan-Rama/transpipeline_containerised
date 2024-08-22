#!/bin/bash

# Step 1: Extract Sequence IDs
awk '/^Apisum_/' Contamination.txt > contamination_ids1.txt
awk '/^Apisum_/' RemainingContamination.txt > contamination_ids2.txt
cat contamination_ids1.txt contamination_ids2.txt > all_contamination_ids.txt

# Step 2: Create list of sequences to keep
grep -v -Ff all_contamination_ids.txt Apisum_220724_okay.fasta | grep '>' | sed 's/>//' > keep_ids.txt

# Step 3: Filter the FASTA file
seqtk subseq Apisum_220724_okay.fasta keep_ids.txt > Apisum_220724_filtered.fasta

# Step 4: Clean up
#rm contamination_ids1.txt contamination_ids2.txt all_contamination_ids.txt keep_ids.txt

echo "Pipeline complete. Filtered FASTA file: Apisum_220724_filtered.fasta"

