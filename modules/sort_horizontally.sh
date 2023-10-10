#!/bin/bash

module load perl

for i in sprot Dmel Cele Mmus Scer Hsap; do

perl -F'\t' -alne '
   our @inds = sort { $F[$a] cmp $F[$b] } 0..$#F if $. == 1; 
   print join "\t", @F[@inds]
' ${i}/PscaXX_100523_${i}_upimapi.tsv > PscaXX_100523_${i}_upimapi.tsv


done
