#!/bin/bash

while IFS=$'\t' read -r -a filename; do

echo ${filename[0]}
echo ${filename[1]}

done < file_list.txt

