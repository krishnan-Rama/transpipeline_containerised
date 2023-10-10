# transpipeline
A slurm pipeline that transforms your transcriptome data into actionable insights in a seamless flow!

## Master Pipeline Overview 

This master pipeline `master_transcript_pipeline.sh` serves as a comprehensive workflow for transcriptome processing, from the initial transfer of raw data to the extraction of annotations. The script is organized into multiple steps, each encompassing a specific procedure in the pipeline. These procedures include data quality checks, trimming, taxonomic classification, assembly, annotation, and evaluation.

### Significance of the Pipeline

- **Comprehensiveness**: This pipeline offers an end-to-end solution for researchers working with transcriptome data, ensuring that each stage of processing and analysis is addressed.
  
- **Flexibility**: Each step of the pipeline is modular, meaning researchers can easily adapt the pipeline to suit specific requirements or integrate new tools.

- **Scalability**: The use of `sbatch` commands indicates that this script is designed to run on a high-performance computing environment, enabling the processing of large datasets in a parallel manner.

### Configuration through `config.parameters_all`

To maintain the flexibility and adaptability of the pipeline, the master script sources a separate configuration script named `config.parameters_all`. This script presumably contains all the variables and parameters used throughout the pipeline. By managing these variables in a centralized location, users can easily modify the behavior of the pipeline without diving into the intricacies of the master script.

### Linking to Bash Scripts in Every Step

Each step in the master pipeline script invokes an external bash script (found in `${moduledir}`) via the `sbatch` command. This design choice encapsulates the complexity of individual procedures, offering several benefits:

- **Modularity**: The separation of tasks into individual scripts allows for easy replacement, modification, or troubleshooting of specific steps.

- **Parallelization**: With the `--array` flag in some `sbatch` commands, certain steps can process multiple samples simultaneously, optimizing computational time.

- **Logging**: The error and output logs for each step are captured separately, simplifying the debugging process.

## Steps of the Master Pipeline

1. **Data Transfer**: Raw data files are copied from the source directory to a designated raw directory.  
   Script: `0-rawdata-preprocessing.sh`

2. **FastQC on Raw Data**: Quality control checks are performed on the raw data to assess its initial quality.  
   Script: `1-fastqc_array.sh`

3. **Fastp Trimming**: Adapters and low-quality bases are trimmed from the raw data.  
   Script: `2A-fastp_array.sh`

4. **FastQC on Trimmed Data**: Quality control checks post-trimming ensure data integrity.  
   Script: `1-fastqc_array.sh` (Reused for trimmed data)

5. **Kraken2 Classification**: The trimmed data undergoes taxonomic classification using Kraken2.  
   Script: `kraken.sh`

6. **Kraken2 Sub-classification**: The Kraken2 results containing taxonomy IDs undergo further classification to exclude/include user-specified taxonomy IDs using `extract_kraken_reads.py`.  
    Script: `2B-kraken2.sh`

7. **Rcorrector error correction**: _k_-mer based errors originating from the sequencer are removed.  
    Script: `2C-rcorrector.sh`

8. **Assembly**: Transcriptome assembly is executed using Trinity.  
   Script: `3-trinity_assembly.sh`

9. **Evigene Annotation**: The assembled transcriptome is annotated using the evigene tool.  
   Script: `4-evigene.sh`

10. **BUSCO Analysis**: Completeness of the assembled transcriptome is assessed using BUSCO.  
   Script: `5-busco_singularity.sh`

11. **Trinity Mapping**: Transcriptome data is further processed using Trinity tools for mapping.  
   Script: `6-trinity-mapping.sh`

12. **Summary Stats and Differential Expression**: Post-processing analysis of the mapped data.  
   Script: `7-rsem-post-reassemble.sh`

13. **MultiQC Report**: A comprehensive report is generated to summarize results from the previous steps.  
   Script: `8-multiqc.sh`

14. **Blastdb Configuration**: Blast databases are downloaded and configured.  
   Script: `9-blastdb.sh`

15. **Multispecies Blast**: A blastp search is performed against a multispecies database.  
   Script: `10-blast.sh`

16. **Annotation Extraction from UniProt**: Annotations are extracted based on blast search results from UniProt.  
   Script: `11-upimapi.sh`

### Concluding Note

To successfully run this pipeline, ensure that all external bash scripts are present in the specified `${moduledir}` directory and that `config.parameters_all` is properly configured. Always refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviors of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
