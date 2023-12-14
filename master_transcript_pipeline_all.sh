#!/bin/bash

# Source variable script
source config.parameters_all

# Step 0: Transfer data
# -- Copy raw data files from sourcedir to rawdir.
# CORE PARAMETERS: sourcedir, rawdir
# INPUT: sourcedir
# WORK: rawdir
# OUTPUT: null
# PROCESS - File transfer
# cp "${sourcedir}/"*.fastq.gz "${rawdir}"

# Step 1A: FastQC on raw data
# -- Run FastQC on raw data to assess data quality before trimming.
# CORE PARAMETERS: modules, rawdir, qcdir, log
# INPUT: rawdir
# WORK: qcdir
# OUTPUT: null
# PROCESS - FastQC raw data
# qcfiles=${rawdir}
# export qcfiles
sbatch -d singleton --error="${log}/rawqc_%J.err" --output="${log}/rawqc_%J.out" --array="1-${sample_number}%10" "${moduledir}/1-fastqc_array.sh"

# Step 2A: Fastp trimming
# -- Trim adapters and low-quality bases from raw data using Fastp.
# CORE PARAMETERS: modules, rawdir, trimdir, qcdir, log
# INPUT: rawdir
# WORK: trimdir, qcdir
# OUTPUT: null
# PROCESS - trim
sbatch -d singleton --error="${log}/fastp_%J.err" --output="${log}/fastp_%J.out" --array="1-${sample_number}%10" "${moduledir}/2A-fastp_array.sh"  

# Step 1B: FastQC on trimmed data
# -- Run FastQC on trimmed data to assess data quality after trimming.
# CORE PARAMETERS: modules, trimdir, qcdir, log
# INPUT: trimdir
# WORK: qcdir
# OUTPUT: null
# PROCESS - FastQC trim data
# qcfiles=${trimdir}
# export qcfiles
sbatch -d singleton --error="${log}/trimqc_%J.err" --output="${log}/trimqc_%J.out" --array="1-${sample_number}%10" "${moduledir}/1-fastqc_array.sh"

# Step 2B: Kraken2 on trimmed data (kraken.sh) + filtering contaminant reads (2B-kraken2.sh)
# -- Run Kraken2 on trimmed data to further prune down after trimming.
# CORE PARAMETERS: modules, krakendir, trimdir, log
# INPUT: trimdir
# WORK: krakendir
# OUTPUT: kraken2
# PROCESS - kraken2 trim data
sbatch -d singleton --error="${log}/kraken2_%J.err" --output="${log}/kraken2__%J.out" --array="1-${sample_number}%10" "${moduledir}/kraken.sh"
sbatch -d singleton --error="${log}/kraken2_%J.err" --output="${log}/kraken2__%J.out" --array="1-${sample_number}%10" "${moduledir}/2B-kraken2.sh"

# Step 2C: rcorrector on kraken2 file
# -- Run Kraken2 on trimmed data to further prune down after trimming.
# CORE PARAMETERS: modules, krakendir, trimdir, log
# INPUT: krakendir
# WORK: rcordir
# OUTPUT: 
# PROCESS - rcorrector trim data
sbatch -d singleton --error="${log}/rcor_%J.err" --output="${log}/rcor__%J.out" --array="1-${sample_number}%10" "${moduledir}/2C-rcorrector.sh"

# Step 3: assembly (Trinity, MaSuRCA & Flye)
# -- Perform transcriptome assembly using Trinity.
# CORE PARAMETERS: modules, trimdir, log, assemblydir, workdir
# INPUT: trimdir
# WORK: assemblydir
# OUTPUT: assemby, assembly_gene_to_transcript
# PROCESS - Assembly
sbatch -d singleton --error="${log}/assembly_%J.err" --output="${log}/assembly_%J.out" "${moduledir}/3-trinity_assembly.sh"
sbatch -d singleton --error="${log}/assembly_%J.err" --output="${log}/assembly_%J.out" "${moduledir}/3-masurca_assembly.sh"
sbatch -d singleton --error="${log}/assembly_%J.err" --output="${log}/assembly_%J.out" "${moduledir}/3-flye_assembly.sh"

# Step 4: evigene
# -- Run evigene for gene annotation.
# CORE PARAMETERS: modules, assemblydir, assembly, evigenedir
# INPUT: assembly
# WORK: evigenedir
# OUTPUT: okayset
# PROCESS - evigene
sbatch -d singleton --error="${log}/evigene_%J.err" --output="${log}/evigene_%J.out" "${moduledir}/4-evigene.sh"

# Step 5: BUSCO analysis
# -- Run BUSCO to assess completeness of the assembly.
# CORE PARAMETERS: modules, assemblydir, assembly [assembly.fasta | assembly_okay.fasta] , buscodir
# INPUT: assembly.fasta | assembly_okay.fasta
# WORK: buscodir
# OUTPUT: summary ??
# PROCESS - Busco
sbatch -d singleton --error="${log}/busco_%J.err" --output="${log}/busco_%J.out" "${moduledir}/5-busco_singularity.sh"

# Step 6: trinity mapping
# comments
# CORE PARAMETERS: modules, assemblydir, assembly [assembly_okay.fasta] , rsemdir
# INPUT: trimdir [all files], assembly_okay.fasta
# WORK: rsemdir
# OUTPUT: 
# PROCESS - trinity mapping
sbatch -d singleton --error="${log}/rsem_%J.err" --output="${log}/rsem_%J.out" --array="1-${sample_number}%6" "${moduledir}/6-trinity-mapping.sh"

# Step 7: Summary stats and diff expression
# comments
# CORE PARAMETERS: modules, rsemdir, assembly
# INPUT: rsemdir
# WORK: rsemdir
# OUTPUT: 
# PROCESS - trinity post analysis
sbatch -d singleton --error="${log}/deg_%J.err" --output="${log}/deg_%J.out" "${moduledir}/7-rsem-post-reassemble.sh"

# Step 8: MultiQC report
# -- Generate a MultiQC report to summarize the results of all previous steps.
# CORE PARAMETERS: modules, workdir, multiqc
# INPUT: workdir
# WORK: multiqc
# OUTPUT: multiqc
# PROCESS - multiqc
sbatch -d singleton --error="${log}/multiqc_%J.err" --output="${log}/multiqc_%J.out" "${moduledir}/8-multiqc.sh"

# Step 9: Blastdb - download and make
# -- Download and configure blast databases
# CORE PARAMETERS: blastdb
# INPUT: webdownload
# WORK: blastdb
# OUTPUT: 
# PROCESS - blastdb download and configure
sbatch -d singleton --error="${log}/blastdb_%J.err" --output="${log}/blastdb_%J.out" "${moduledir}/9-blastdb.sh"

# Step 10: multispecies blast
# comments
# CORE PARAMETERS: modules, evigenedir (okayset/assembly.okay.aa), blastdb, blastout
# INPUT: blastdb, evigenedir (okayset/assembly.okay.aa)
# WORK: blastout
# OUTPUT: 
# PROCESS - blastp
sbatch -d singleton --error="${log}/blastp_%J.err" --output="${log}/blastp_%J.out" --array="0-5" "${moduledir}/10-blast.sh"

# Step 11: Extract annotation from Uniprot
# comments
# CORE PARAMETERS: modules, blastout, unimapi
# INPUT: blastout 
# WORK: unimapi
# OUTPUT:
# PROCESS - Annotation extraction
sbatch -d singleton --error="${log}/upimapi_%J.err" --output="${log}/upimapi_%J.out" "${moduledir}/11-upimapi.sh"

# Step 12: Extract orthologs from local genome database
# sbatch -d singleton --error="${log}/ortho_%J.err" --output="${log}/ortho_%J.out" "${moduledir}/orthofinder.sh"

# step 13: Create phylogenetic tree from orthologs retrieved 
# sbatch --error="${log}/ortho_%J.err" --output="${log}/ortho_%J.out" "${moduledir}/figtree.sh"
