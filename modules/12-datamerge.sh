#!/bin/bash

#SBATCH --job-name=pipeline
#SBATCH --partition=jumbo       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4      #   
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Write jobscript to output file (good for reproducibility)
cat $0

##define pipeline parameters
#mergedir="/mnt/scratch/c23048124/pipeline_all/workdir/mergedir/mergedir2"
#rsemdir="/mnt/scratch/c23048124/pipeline_all/workdir/rsem/rsem_Gbull"
#assembly="Gbull_020823"
#assemblydir="/mnt/scratch/c23048124/pipeline_all/workdir/assembly/trinity_Gbull_assembly/trinity_preprocessed"
#blastout="/mnt/scratch/c23048124/pipeline_all/workdir/blastdir/blastdir_Gbull"
#upimapi="/mnt/scratch/c23048124/pipeline_all/workdir/upimapi_all/upimapi_Gbull/upimapi_Gbull_4"

##define module specific parameter
count=${assembly}_RSEM.isoform.TMM.EXPR.matrix


##Prepare upimapi annotation file by sorting horizontal columns ensuring Entry ID is first column 
module load perl

# for i in sprot Dmel Cele Mmus Scer Hsap; do
for i in sprot Dmel Cele Mmus Scer; do

#Rename Entry Name to Name and rename Entrry to AA_Entry
sed '1s/Entry Name/Name/' ${upimapi}/${i}/${assembly}_${i}_upimapi.tsv > ${upimapi}/${assembly}_${i}_upimapi_temp.tsv
sed -i '1s/Entry/A00_Entry/' ${upimapi}/${assembly}_${i}_upimapi_temp.tsv

#sort columns by column title so that AA_Entry is first
perl -F'\t' -alne '
   our @inds = sort { $F[$a] cmp $F[$b] } 0..$#F if $. == 1;
   print join "\t", @F[@inds]
' ${upimapi}/${assembly}_${i}_upimapi_temp.tsv > ${upimapi}/${assembly}_${i}_upimapi.tsv

#sort unpimapi by column 1 - AA_Entry
sort -k 1,1 "${upimapi}/${assembly}_${i}_upimapi.tsv" > "${upimapi}/${assembly}_${i}_upimapi_sort.tsv"

done

##Prepare Count file - adding transcript ID as first column identifier

sed '1s/^/A00_TransID/' "${rsemdir}/${count}" | sort -k 1,1 > "${rsemdir}/${count}_sort"

#sed '1d' "${rsemdir}/${count}" | sort -k 1,1 > "${rsemdir}/${count}_sort"

#prepare merge temp file
cat "${rsemdir}/${count}_sort" > "${mergedir}/temp.tsv"

# for i in sprot Hsap Mmus Dmel Cele Scer; do
for i in sprot Dmel Cele Mmus Scer; do

# Replace '|' with tab in entry match | select columns of use | Remove redundancy from blast results
sed 's/|/\t/g' "${blastout}/${assembly}_${i}_blp.tsv" | cut -f 1,3,4,13 | sort -u -k 1,1 > "${blastout}/${assembly}_${i}_filtered_uniq_blp.tsv"

#Add column headers to filtered blast results
sed '1s/^/A00_TransID\tA00_Entry\tName\tEValue\n/' "${blastout}/${assembly}_${i}_filtered_uniq_blp.tsv" | sort -k 2,2 > "${blastout}/${assembly}_${i}_uniq_blp.tsv" 

#join blast with upimapi results - AA_Entry
join -1 2 -2 1 -a 1 -t $'\t' -e "." -o auto "${blastout}/${assembly}_${i}_uniq_blp.tsv" "${upimapi}/${assembly}_${i}_upimapi_sort.tsv" > "${mergedir}/${assembly}_${i}_blp_upimapi.tsv"

#sort annotation mereged results by column 2 - AA_TransID
sort -k 2,2 "${mergedir}/${assembly}_${i}_blp_upimapi.tsv" > "${mergedir}/${assembly}_${i}_blp_upimapi_sort.tsv"

#join merge file with count data with annotation
join -1 1 -2 2 -a 1 -t $'\t' -e "." -o auto "${mergedir}/temp.tsv" "${mergedir}/${assembly}_${i}_blp_upimapi_sort.tsv" > "${mergedir}/temp2.tsv"

cat "${mergedir}/temp2.tsv" > "${mergedir}/temp.tsv"

done

cat "${mergedir}/temp.tsv" > "${mergedir}/${assembly}_merged_count_annot.tsv"

#rm "${mergedir}/temp"*


