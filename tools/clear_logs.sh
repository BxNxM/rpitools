#!/bin/bash

logs_path=($(find ../ -iname "*.log"))
nohups=($(find ../ -iname "nohup*"))
pycs_path=($(find ../ -iname "*pyc"))

#echo -e "${logs_path[*]}"
#echo -e "${nohups[*]}"

echo -e "Clean all log files:"
for file_path in "${logs_path[@]}"
do
    echo -e "\tRemove $file_path"
    rm -f "$file_path"
done
if [ "${#logs_path[@]}" == 0 ]
then
    echo -e "\tNone"
fi

echo -e "Clean all nohup files:"
for file_path in "${nohups[@]}"
do
    echo -e "\tRemove $file_path"
    rm -f "$file_path"
done
if [ "${#nohups[@]}" == 0 ]
then
    echo -e "\tNone"
fi

echo -e "Clean all pyc files:"
for file_path in "${pycs_path[@]}"
do
    echo -e "\tRemove $file_path"
    rm -f "$file_path"
done
if [ "${#pycs_path[@]}" == 0 ]
then
    echo -e "\tNone"
fi
