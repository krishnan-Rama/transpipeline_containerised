# temporary directory for package installation
temp_lib <- tempfile("R_library")
dir.create(temp_lib)

# Set the temp directory as the default library path
.libPaths(temp_lib)

if (!require("dplyr")) {
    install.packages("dplyr", repos = "http://cran.us.r-project.org", lib = temp_lib)
}
if (!require("tidyr")) {
    install.packages("tidyr", repos = "http://cran.us.r-project.org", lib = temp_lib)
}

library(dplyr)
library(tidyr)

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
  isoform_matrix <- read.table(isoform_matrix_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  colnames(isoform_matrix)[1] <- "TranscriptID"  # Ensure the first column is named TranscriptID
  
  isoform_matrix <- isoform_matrix %>%
    pivot_longer(cols = -TranscriptID, names_to = "Tissue", values_to = "Isoform_Count")
  
  # Read and integrate the gene matrix file
  gene_matrix <- read.table(gene_matrix_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  colnames(gene_matrix)[1] <- "GeneID"  # Ensure the first column is named GeneID
  
  gene_matrix <- gene_matrix %>%
    pivot_longer(cols = -GeneID, names_to = "Tissue", values_to = "Gene_Count")
  
  # Join isoform matrix data to final data by TranscriptID, including tissue data
  final_data <- final_data %>%
    left_join(isoform_matrix, by = "TranscriptID") %>%
    left_join(gene_matrix, by = c("GeneID", "Tissue"))
  
  return(final_data)
}

# Process each pair of blp and upimapi files
species_list <- c("Hsap", "Mmus", "Cele", "Dmel", "Scer", "sprot")
combined_data <- bind_rows(lapply(species_list, function(species) {
  process_files(
    paste0(workdir, "/outdir/blast_results/", assembly, "_", species, "_blp.tsv"),
    paste0(workdir, "/outdir/annotations/upimapi/", species, "/", assembly, "_", species, "_upimapi.tsv"),
    gene_trans_map_file, species, isoform_matrix_file, gene_matrix_file
  )
}))

# Save the combined data to a single CSV file in the merged data directory
output_file <- paste0(mergedir, "/", assembly, "_combined_final.csv")
write.csv(combined_data, output_file, row.names = FALSE)

# Print a message
print("All data processed and saved into one CSV file successfully.")
