# transpipeline
A SLURM pipeline for transcriptome quality assessment, pre-processing, _de novo_ assembly, and annotation.

## Installation

1. Install the transpipeline resources into your HPC cluster directory in which you will be performing the assembly:  

```
git clone https://github.com/krishnan-Rama/transpipeline_containerised.git
```

2. Put the raw reads in `raw_data` folder.  

3. Run the pipeline using `./deploy.sh`.  

4. The prompt will ask you to enter your preferred HPC partition name to submit the job, simply type the name and return.

 Note: You can manually reconfigure Slurm parameters as per your HPC system (e.g memory, CPUs) by going through indivudal scripts in `modules` directory.  

### Workflow Diagram
![workflow](https://github.com/krishnan-Rama/transpipeline_containerised/assets/104147619/892ae381-69b3-45e8-a485-ccd50cf1794a)


### Concluding Note

To successfully run this pipeline, ensure that scripts in the specified `${module}` directory and `config.parameters_all` are properly configured for your system. Refer to individual bash scripts and the configuration file for more detailed information or to modify specific behaviours of the pipeline.

### Author Information

Rama Krishnan - krishnanr1@cardiff.ac.uk
