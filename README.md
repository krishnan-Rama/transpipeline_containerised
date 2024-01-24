# transpipeline
A SLURM pipeline for transcriptome quality assessment, pre-processing, _de novo_ assembly, and annotation.

## Installation

1. Install the transpipeline resources into your HPC cluster directory in which you will be performing the assembly:  

```
git clone https://github.com/krishnan-Rama/transpipeline_containerised.git
```

2. Configure the location of `$sourcedir` (location of raw reads) through `config.parameters_all` or simply put the raw reads in `$rawdir`.  

3. Modify the HPC Slurm parameters in each individual script inside `modules` directory.

4. Run the pipeline `master_transcript_pipeline_all.sh` using `./master_transcript_pipeline_all.sh`.  

   Note: You can manually run individual steps in `master_transcript_pipeline_all.sh` by hashing out `(#)` `sbatch` jobs.   


### Workflow Diagram
![workflow](https://github.com/krishnan-Rama/transpipeline_containerised/assets/104147619/892ae381-69b3-45e8-a485-ccd50cf1794a)


### Concluding Note

To successfully run this pipeline, ensure that scripts in the specified `${module}` directory and `config.parameters_all` are properly configured for your system. Refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviours of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
