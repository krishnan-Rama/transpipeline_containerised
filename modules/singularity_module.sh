#%Module1.0#####################################################################
## singularity_module

proc ModulesHelp { } {
    puts stderr "Sets up environment for Singularity"
}

set singularity_version 3.8.7
prepend-path PATH mnt/scratch/nodelete
