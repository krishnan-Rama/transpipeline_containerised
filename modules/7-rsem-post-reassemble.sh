#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=<HPC_partition> # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #
#SBATCH --mem=2G     # in megabytes, unless unit explicitly stated

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Write jobscript to output file (good for reproducability)
cat $0

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=trinityrnaseq/trinityrnaseq:2.15.1
SINGULARITY_IMAGE_NAME=trinityrnaseq_2.15.1.sif

if [ -f ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    singularity pull ${pipedir}/singularities/${SINGULARITY_IMAGE_NAME} docker://$IMAGE_NAME
fi

echo ${singularities}

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}

# Trinity requires max memory in GB not MB, script to convert mem to GB
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)

# Set working directory
WORKINGDIR=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/trinity_postanalysis_commands_${SLURM_JOB_ID}.sh <<EOF

#create gene to trans map file if it does not exist
#get_Trinity_gene_to_trans_map.pl XX_merge_190318_evigene.fasta > XX_merge_190318_evigene.gene_trans_map

#create samples file XX_samples.txt eg:
#condition_A     XX_all_tiss_map
#condition_B     XX_Chloro_map
#condition_C     XX_NC_map

#R
#source("http://bioconductor.org/biocLite.R")
#biocLite('edgeR')
#biocLite('qvalue')
#biocLite('limma')
#biocLite('DESeq2')
#biocLite('ctc')
#biocLite('Biobase')
#biocLite('fastcluster')
#install.packages('gplots', repos='http://cran.us.r-project.org')
#install.packages('ape', repos='http://cran.us.r-project.org')
#q()

cd ${rsemdir}

isoform_counts=\$(ls "${rsemdir}/"*"/RSEM.isoforms.results")

\$TRINITY_HOME/util/abundance_estimates_to_matrix.pl \
               --gene_trans_map "${assemblydir}/${assembly}_okay.gene_trans_map" \
               --name_sample_by_basedir --est_method RSEM \${isoform_counts} \
               --out_prefix "${rsemdir}/${assembly}_RSEM"

\$TRINITY_HOME/util/misc/count_matrix_features_given_MIN_TPM_threshold.pl "${rsemdir}/${assembly}_RSEM.gene.TPM.not_cross_norm" | tee "${rsemdir}/${assembly}_RSEM.qgenes_matrix.TPM.not_cross_norm.counts_by_min_TPM"

#$TRINITY_HOME/util/filter_low_expr_transcripts.pl
#other analysis can be for https://github.com/trinityrnaseq/trinityrnaseq/wiki/Trinity-Differential-Expression
#$TRINITY_HOME/Analysis/DifferentialExpression/

\$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix "${rsemdir}/${assembly}_RSEM.gene.counts.matrix" --samples "${metadata}" --CPM --log2 --compare_replicates

\$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix "${rsemdir}/${assembly}_RSEM.gene.counts.matrix" -s "${metadata}" --log2 --sample_cor_matrix

\$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix "${rsemdir}/${assembly}_RSEM.gene.counts.matrix" -s "${metadata}" --log2 --prin_comp 3

\$TRINITY_HOME/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix "${rsemdir}/${assembly}_RSEM.gene.counts.matrix" --samples_file "${metadata}" --method edgeR --output edgeR_results

\$TRINITY_HOME/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix "${rsemdir}/${assembly}_RSEM.gene.counts.matrix" -P 1e-3 -C 1.4 --samples "${metadata}"

mv "${pipedir}/${assembly}_RSEM"* ${rsem}/
mv "${pipedir}/edgeR_results ${rsem}/


echo TOTAL_RAM=${TOTAL_RAM}
echo CPU=${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/trinity_postanalysis_commands_${SLURM_JOB_ID}.sh
