!#/bin/bash

dir="/mnt/scratch/smbpk/Ea/cul"

lib="Ealb_cul_180822"

count="Ealb_cul_180822_all.okay_RSEM.isoform.TMM.EXPR.matrix"

sort -k 1,1 ${dir}/${count} > ${dir}/${count}_sort

for i in sprot Hsap Mmus Dmel Cele Scer; do

sed 's/|/\t/g' "${dir}/${lib}_all_okay_aa_${i}_blp.tsv" | cut -f 1,3,4,13 | sort -u -k 1,1 | sort -k 3,3 > "${dir}/${lib}_${i}_uniq_blp.tsv"

sort -k 1,1 "${dir}/${lib}_${i}_uniprot_annot.tsv" > "${dir}/${lib}_${i}_uniprot_annot_sort.tsv"

join -1 3 -2 1 -a 1 -t $'\t' -e "." -o auto "${dir}/${lib}_${i}_uniq_blp.tsv" "${dir}/${lib}_${i}_uniprot_annot_sort.tsv" > "${dir}/${lib}_${i}_uniq_blp_annot.tsv"

sort -k 2,2 "${dir}/${lib}_${i}_uniq_blp_annot.tsv" > "${dir}/${lib}_${i}_uniq_blp_annot_sort.tsv"

join -1 1 -2 2 -a 1 -t $'\t' -e "." -o auto ${dir}/${count}_sort "${dir}/${lib}_sprot_uniq_blp_annot_sort.tsv" > ${dir}/${count}_sort

done

