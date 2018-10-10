#!/bin/bash

# script path n name
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../"

echo -e "-----------------------------------------------"
echo -e "     RPITOOLS PROJECT RESOURCE STATISTIC       "
echo -e "-----------------------------------------------"

bash_scripts="$(find ${MYDIR} -type f -iname "*.bash" | wc -l | xargs)"
bash_script_lines="$(find ${MYDIR} -type f -iname "*.bash" -exec cat {} \; | grep -v "^$" | wc -l | xargs)"
echo -e "-----------------------------------------------"
echo -e "bash scripts:\t\t$bash_scripts"
echo -e "bash program lines:\t$bash_script_lines"

html_scripts="$(find ${MYDIR} -type f -iname "*.html" | wc -l | xargs)"
html_script_lines="$(find ${MYDIR} -type f -iname "*.html" -exec cat {} \; | grep -v "^$" | wc -l | xargs)"
echo -e "-----------------------------------------------"
echo -e "html scripts:\t\t$html_scripts"
echo -e "html program lines:\t$html_script_lines"

python_scripts="$(find ${MYDIR} -type f -iname "*.py" | wc -l | xargs)"
python_script_lines="$(find ${MYDIR} -type f -iname "*.py" -exec cat {} \; | grep -v "^$" | wc -l | xargs)"
echo -e "-----------------------------------------------"
echo -e "python scripts:\t\t$python_scripts"
echo -e "python program lines:\t$python_script_lines"


php_scripts="$(find ${MYDIR} -type f -iname "*.php" | wc -l | xargs)"
php_script_lines="$(find ${MYDIR} -type f -iname "*.php" -exec cat {} \; | grep -v "^$" | wc -l | xargs)"
echo -e "-----------------------------------------------"
echo -e "php scripts:\t\t$php_scripts"
echo -e "php program lines:\t$php_script_lines"

echo -e "-----------------------------------------------"
java_scripts="$(find ${MYDIR} -type f -iname "*.java" | wc -l | xargs)"
java_script_lines="$(find ${MYDIR} -type f -iname "*.java" -exec cat {} \; | grep -v "^$" | wc -l | xargs)"
echo -e "-----------------------------------------------"
echo -e "java scripts:\t\t$java_scripts"
echo -e "java program lines:\t$java_script_lines"

echo -e "-----------------------------------------------"
program_requirements="$(cat ${MYDIR}/template/programs.dat | wc -l | xargs)"
echo -e "Autoinstalled apps:\t$program_requirements"
echo -e "See more: ${MYDIR}/template/programs.dat"

echo -e "-----------------------------------------------"
python_modules="$(cat ${MYDIR}/template/python_moduls.dat | wc -l | xargs)"
python_modules2="$(cat ${MYDIR}/template/python_moduls_pip.dat | wc -l | xargs)"
echo -e "Python modules:\t\t$(($python_modules+$python_modules2))"
echo -e "See more: ${MYDIR}/template/python_moduls.dat and ${MYDIR}/template/python_moduls_pip.dat"

echo -e "-----------------------------------------------"
aliases="$(cat ${MYDIR}/template/aliases | grep "alias" | wc -l | xargs)"
echo -e "Supported aliases:\t$aliases"
echo -e "${MYDIR}/template/aliases"

git_clones="$(grep -r "git clone" ../ | grep ".git" | grep -v "rpitools" | grep -v "setupmessage" | grep -v "echo" | cut -d':' -f2,3)"
git_clones_list=($git_clones)
echo -e "-----------------------------------------------"
clones=()
for clone in ${git_clones_list[@]}
do
    if [[ "${clones[*]}" != *"$clone"* ]] && [[ "${clone}" == *"http"* ]]
    then
        clones+=("$clone")
    fi
done
    echo -e "git clones:\t\t$(echo -e ${#clones[@]})"
    for clone in ${clones[@]}
    do
        echo -e "$clone"
    done
echo -e "-----------------------------------------------"

wget_resources="$(grep -r "wget http" ${MYDIR} | grep -v "mysshfs.bash" | grep -v "echo")"
wget_res_list=($wget_resources)
wgets=()
for wget_res in ${wget_res_list[@]}
do
    if [[ "${wgets[*]}" != *"$wget_res"* ]] && [[ "${wget_res}" == *"http"* ]]
    then
        wgets+=("$wget_res")
    fi
done
    echo -e "wget resources:\t\t$(echo -e ${#wgets[@]})"
    for w in ${wgets[@]}
    do
        echo -e "$w"
    done
echo -e "-----------------------------------------------"

curl_resources="$(grep -r "curl" ${MYDIR} | grep -v "stat.bash" | cut -d':' -f2,3)"
curl_res_list=($curl_resources)
curls=()
for curl_res in ${curl_res_list[@]}
do
    if [[ "${curls[*]}" != *"$curl_res"* ]] && ( [[ "${curl_res}" == *"http"* ]] || [[ "${curl_res}" == *"wttr."* ]] )
    then
        curls+=("$curl_res")
    fi
done
    echo -e "curl resources:\t\t${#curls[@]}"
    for c in ${curls[@]}
    do
        echo -e "$c"
    done

