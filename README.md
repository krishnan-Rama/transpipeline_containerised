# transpipeline
A slurm pipeline that transforms your transcriptome data into actionable insights in a seamless flow!

## Master Pipeline Overview 

This master pipeline `master_transcript_pipeline.sh` serves as a comprehensive workflow for transcriptome processing, from the initial transfer of raw data to the extraction of annotations. The script is organized into multiple steps, each encompassing a specific procedure in the pipeline. These procedures include data quality checks, trimming, taxonomic classification, assembly, annotation, and evaluation.

## Installation

1. Install the transpipeline code into the folder in which you will be performing the assembly:  

```
git clone https://github.com/krishnan-Rama/transpipeline_containerised.git
```

2. Configure the location of `$sourcedir` through `config.parameters_all` or simply put the raw reads in `$rawdir`.  

3. Modify the HPC nodes or SLURM parameters in the scripts through `modules` directory.

4. Run the pipeline `master_transcript_pipeline_all.sh` using `./master_transcript_pipeline_all.sh`.  

   Note: You can manually run individual steps in `master_transcript_pipeline_all.sh` by hashing out `(#)` `sbatch` jobs.   


### Workflow Diagram
![workflow](https://github.com/krishnan-Rama/transpipeline_containerised/assets/104147619/892ae381-69b3-45e8-a485-ccd50cf1794a)


### Concluding Note

To successfully run this pipeline, ensure that all external bash scripts are present in the specified `${moduledir}` directory and that `config.parameters_all` is properly configured. Always refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviors of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
