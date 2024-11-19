# Create a temporary directory for package installation
temp_lib <- tempfile("R_library")
dir.create(temp_lib)

# Set the temporary directory as the default library path
.libPaths(temp_lib)

# Install the 'dplyr' package if it is not already installed
if (!require("dplyr")) {
    install.packages("dplyr", repos = "http://cran.us.r-project.org", lib = temp_lib)
}

# Load the 'dplyr' package
library(dplyr)

# Command line arguments
args <- commandArgs(trailingOnly = TRUE)
workdir <- args[1]
assembly <- args[2]
mergedir <- args[3]

# Set file paths dynamically based on variables
gene_trans_map_file <- paste0(workdir, "/outdir/nonredundant_assembly/", assembly, "_okay.gene_trans_map")
isoform_matrix_file <- paste0(workdir, "/workdir/rsem/", assembly, "_RSEM.isoform.counts.matrix")
gene_matrix_file <- paste0(workdir, "/workdir/rsem/", assembly, "_RSEM.gene.counts.matrix")

# Function to process blp and upimapi files
process_files <- function(blp_file, upimapi_file, gene_trans_map_file, species_name, isoform_matrix_file, gene_matrix_file) {
  # Read the gene-transcript map
  gene_trans_map <- read.table(gene_trans_map_file, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
  colnames(gene_trans_map) <- c("GeneID", "TranscriptID")
  
  # Read the blp file
  blp_data <- read.table(blp_file, sep = "\t", header = FALSE, stringsAsFactors = FALSE, fill = TRUE, quote = "", comment.char = "")
  
  # Extract the Entry from the second column and the e-value from the 11th column
  blp_data <- blp_data %>%
    mutate(Entry = sub(".*\\|(.+?)\\|.*", "\\1", V2)) %>%
    select(TranscriptID = V1, Entry, E_value = V11)
  
  # Read the upimapi file
  upimapi_data <- read.table(upimapi_file, sep = "\t", header = TRUE, stringsAsFactors = FALSE, fill = TRUE, quote = "", comment.char = "")
  
  # Merge blp and upimapi data based on Entry column, remove duplicates
  merged_data <- blp_data %>%
    distinct(Entry, .keep_all = TRUE) %>%
    left_join(upimapi_data, by = "Entry")
  
  # Merge with gene-transcript map
  final_data <- gene_trans_map %>%
    inner_join(merged_data, by = "TranscriptID") %>%
    mutate(Species = species_name)
  
  # Read and integrate the isoform matrix file
  isoform_matrix <- read.table(isoform_matrix_file, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
  colnames(isoform_matrix) <- c("TranscriptID", "Isoform_Count")
  
  # Read and integrate the gene matrix file
  gene_matrix <- read.table(gene_matrix_file, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
  colnames(gene_matrix) <- c("GeneID", "Gene_Count")
  
  # Join isoform matrix data to final data by TranscriptID, placing Isoform_Count next to TranscriptID
  final_data <- final_data %>%
    left_join(isoform_matrix, by = "TranscriptID") %>%
    select(GeneID, TranscriptID, Isoform_Count, everything())
  
  # Join gene matrix data to final data by GeneID, placing Gene_Count next to GeneID
  final_data <- final_data %>%
    left_join(gene_matrix, by = "GeneID") %>%
    select(GeneID, Gene_Count, TranscriptID, everything())
  
  return(final_data)
}

# Process each pair of blp and upimapi files, dynamically building paths from the variables
hsap_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_Hsap_blp.tsv"), 
                           paste0(workdir, "/outdir/annotations/upimapi/Hsap/", assembly, "_Hsap_upimapi.tsv"), 
                           gene_trans_map_file, "Hsap", isoform_matrix_file, gene_matrix_file)
mmus_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_Mmus_blp.tsv"), 
                           paste0(workdir, "/outdir/annotations/upimapi/Mmus/", assembly, "_Mmus_upimapi.tsv"), 
                           gene_trans_map_file, "Mmus", isoform_matrix_file, gene_matrix_file)
cele_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_Cele_blp.tsv"), 
                           paste0(workdir, "/outdir/annotations/upimapi/Cele/", assembly, "_Cele_upimapi.tsv"), 
                           gene_trans_map_file, "Cele", isoform_matrix_file, gene_matrix_file)
dmel_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_Dmel_blp.tsv"), 
                           paste0(workdir, "/outdir/annotations/upimapi/Dmel/", assembly, "_Dmel_upimapi.tsv"), 
                           gene_trans_map_file, "Dmel", isoform_matrix_file, gene_matrix_file)
scer_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_Scer_blp.tsv"), 
                           paste0(workdir, "/outdir/annotations/upimapi/Scer/", assembly, "_Scer_upimapi.tsv"), 
                           gene_trans_map_file, "Scer", isoform_matrix_file, gene_matrix_file)
sprot_data <- process_files(paste0(workdir, "/outdir/blast_results/", assembly, "_sprot_blp.tsv"), 
                            paste0(workdir, "/outdir/annotations/upimapi/sprot/", assembly, "_sprot_upimapi.tsv"), 
                            gene_trans_map_file, "sprot", isoform_matrix_file, gene_matrix_file)

# Combine all data into one data frame
combined_data <- bind_rows(hsap_data, mmus_data, cele_data, dmel_data, scer_data, sprot_data)

# Save the combined data to a single CSV file in the merged data directory
output_file <- paste0(mergedir, "/", assembly, "_combined_final.csv")
write.csv(combined_data, output_file, row.names = FALSE)

# Print a message
print("All data processed and saved into one CSV file successfully.")
