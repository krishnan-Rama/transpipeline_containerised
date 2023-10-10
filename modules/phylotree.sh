#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=jumbo       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #
#SBATCH --mem-per-cpu=64000     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Write jobscript to output file (good for reproducibility)
cat $0

# Source variable script
source config.parameters_all

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=perl-bioperl:1.7.8--hdfd78af_1
#SINGULARITY_IMAGE_NAME=trinityrnaseq_2.15.1.sif

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Set working directory
WORKINGDIR=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

# Check for the input Newick format file
if [ $# -ne 1 ]; then
  echo "Usage: $0 input.newick"
  exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Input file not found: $input_file"
  exit 1
fi

############# SOURCE COMMANDS ##################################
cat >${log}/tree_${SLURM_JOB_ID}.sh <<EOF

perl -MBio::TreeIO -e "
  my \$input_file = shift;
  my \$in = Bio::TreeIO->new(-file => \$input_file, -format => 'newick');
  my \$tree = \$in->next_tree;
  if (\$tree) {
    my \$out = Bio::TreeIO->new(-format => 'newick');
    \$out->write_tree(\$tree);
  } else {
    die 'Error: Unable to parse the input tree.';
  }
" "$input_file"

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/tree_${SLURM_JOB_ID}.sh
