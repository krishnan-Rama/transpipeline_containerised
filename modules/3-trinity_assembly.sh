#!/bin/bash

#SBATCH --job-name=<pipeline>
#SBATCH --partition=<HPC_partition>     
#SBATCH --nodes=1              
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=16      
#SBATCH --mem=30000     

echo "Environment Info:"
echo "================="
echo "hostname=$(hostname)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE} MB"

module load singularity/3.8.7

IMAGE_NAME=trinityrnaseq/trinityrnaseq:latest
SINGULARITY_IMAGE_NAME=trinityrnaseq:latest
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}
WORKINGDIR=${pipedir}

if [ ! -f "${SINGIMAGEDIR}/${SINGIMAGENAME}" ]; then
    echo "Pulling Trinity image..."
    singularity pull "${SINGIMAGEDIR}/${SINGIMAGENAME}" docker://$IMAGE_NAME
else
    echo "✅ Singularity image already exists."
fi

export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR},${rcordir}:${rcordir}"
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)
CMD_SCRIPT="${log}/trinity_assembly_commands_${SLURM_JOB_ID}.sh"

cat > "$CMD_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail

echo "🧬 Trinity Assembly Mode: \${ASSEMBLY_MODE:-de_novo}"
echo "RAM: ${TOTAL_RAM}G | CPUs: ${SLURM_CPUS_PER_TASK}"

if [[ "\${ASSEMBLY_MODE:-de_novo}" == "genome_guided" && -f "${rcordir}/aligned.sorted.bam" ]]; then
    echo "📌 Running genome-guided Trinity"

    Trinity --genome_guided_bam "${rcordir}/aligned.sorted.bam" \\
            --genome_guided_max_intron 10000 \\
            --CPU ${SLURM_CPUS_PER_TASK} \\
            --max_memory ${TOTAL_RAM}G \\
            --output "${assemblydir}/" \\
            --full_cleanup

    cp "${assemblydir}.Trinity-GG.fasta" "${assemblydir}/Trinity.fasta"
    cp "${assemblydir}.Trinity-GG.fasta.gene_trans_map" "${assemblydir}/Trinity.fasta.gene_trans_map"

else
    echo "📌 Running de novo Trinity"

    cat ${rcordir}/*_1.cor.fq.gz > ${rcordir}/all_1.fastq.gz
    cat ${rcordir}/*_2.cor.fq.gz > ${rcordir}/all_2.fastq.gz

    Trinity --seqType fq \\
            --left "${rcordir}/all_1.fastq.gz" \\
            --right "${rcordir}/all_2.fastq.gz" \\
            --CPU ${SLURM_CPUS_PER_TASK} \\
            --max_memory ${TOTAL_RAM}G \\
            --output "${assemblydir}/" \\
            --full_cleanup
fi

# Rename output
mv "${assemblydir}/Trinity.fasta" "${assemblydir}/${assembly}.fasta"
mv "${assemblydir}/Trinity.fasta.gene_trans_map" "${assemblydir}/${assembly}.gene_trans_map"

# Tag contigs with species name
sed -i "s/TRINITY_DN/\${SPECIES_IDENTIFIER}_/g" "${assemblydir}/${assembly}.fasta"
sed -i "s/TRINITY_GG/\${SPECIES_IDENTIFIER}_/g" "${assemblydir}/${assembly}.fasta"

# Generate stats
/usr/local/bin/util/TrinityStats.pl "${assemblydir}/${assembly}.fasta" > "${assemblydir}/${assembly}_stats.txt"

# Copy to output
mkdir -p "${outdir}/raw_assembly"
cp "${assemblydir}/${assembly}.fasta" "${outdir}/raw_assembly/"
cp "${assemblydir}/${assembly}_stats.txt" "${outdir}/raw_assembly/"
cp "${assemblydir}/${assembly}.gene_trans_map" "${outdir}/raw_assembly/"
EOF

# Execute Trinity script inside container
singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash "$CMD_SCRIPT"
