#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --partition=jumbo
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem=128000

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

module load evigene/18jan01

tr2aacds.pl -mrnaseq "${assemblydir}/${assembly}.fasta" -MINCDS=60 -NCPU=16 -MAXMEM=128000 -logfile -tidyup

mv dropset "${evigenedir}/dropset"
mv okayset "${evigenedir}/okayset"
cp "${evigenedir}/okayset/${assembly}.okay.fasta" "${assemblydir}/${assembly}_okay.fasta"

rm -r inputset
rm -r tmpfiles
rm -r ${assemblydir}/${assembly}nrcd1*
rm "${assemblydir}/${assembly}.tr2aacds.log"
rm "${assemblydir}/${assembly}.trclass"
rm "${assemblydir}/${assembly}.trclass.sum.txt"
rm "${assemblydir}/${assembly}nr.cds."*
rm -r "${assemblydir}/chrysalis"
rm -r "${assemblydir}/insilico_read_normalization"
rm -r "${assemblydir}/${assembly}_split"

module unload evigene/18jan01

module load trinityrnaseq/Trinity-v2.6.6

TrinityStats.pl "${assemblydir}/${assembly}_okay.fasta" > "${assemblydir}/${assembly}_okay_stats.txt"

get_Trinity_gene_to_trans_map.pl "${assemblydir}/${assembly}_okay.fasta" > "${assemblydir}/${assembly}_okay.gene_trans_map"

cp "${assemblydir}/${assembly}_okay.fasta" "${outdir}/${assembly}_okay.fasta"
cp "${assemblydir}/${assembly}_okay.gene_trans_map" "${outdir}/${assembly}_okay.gene_trans_map"
cp "${assemblydir}/${assembly}_okay_stats.txt" "${outdir}/${assembly}_okay_stats.txt"

module unload trinityrnaseq/Trinity-v2.6.6
