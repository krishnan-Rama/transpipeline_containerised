# transpipeline
A SLURM pipeline designed for comprehensive transcriptome analysis including quality assessment, pre-processing, _de novo_ assembly, and functional annotation. This pipeline is specifically optimized for deployment on high-performance computing (HPC) clusters and executed _via_ Slurm Workload Manager.

The **NextFlow version** of this pipeline is available at https://github.com/krishnan-Rama/transFlow.

## Key Features

- **Transcriptome Quality Assessment**: Ensures high-quality data processing with integrated quality checks.
- **Pre-processing**: Streamlines the handling of RNA-seq data to prepare for assembly.
- **De Novo Assembly**: Assembles transcripts from RNA-seq data without the need for a reference genome.
- **Functional Annotation**: Annotates assembled transcripts to provide insights into gene function and expression.
- **HPC Optimization**: Designed to efficiently utilize HPC resources for scalable and fast transcriptome analysis.


## Installation

1. Install the transpipeline resources into your HPC cluster directory in which you will be performing the assembly:  

```
git clone https://github.com/krishnan-Rama/transpipeline_containerised.git
```

2. Put the raw reads in `raw_data` folder.  

3. Run the pipeline using `./deploy.sh`  

4. The prompt will ask you to enter your preferred HPC partition name to submit the job and the species/project identifier (e.g. Hsap or Hsap_200524 for _Homo sapiens_), simply type the name and return.

 **Note:** 
- You can run the pipeline multiple times simultaneously with different raw reads, simply repeat the installation process in a different directory and `./deploy` with a different species/project identifier name.
- You can manually reconfigure Slurm parameters as per your HPC system (e.g memory, CPUs) by going through indivudal scripts in `modules` directory.  
- All the relevent outputs will be stored in `outdir` folder, and outputs for every individual steps in the pipeline can be found in `workdir`.
- To generate **PCR/heatmap plots** for differential gene expression data, modify the `metadata.txt` (example provided) file in the current directory as per the processed trimmed reads.
  
### Workflow Diagram
![workflow](https://github.com/krishnan-Rama/transpipeline_containerised/assets/104147619/892ae381-69b3-45e8-a485-ccd50cf1794a)


### Concluding Note

To successfully run this pipeline, ensure that SLURM parameters in the scripts in `${module}` directory are properly configured for your system. Refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviours of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
