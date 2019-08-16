#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

logs_path=($(find "${REPOROOT}" -iname "*.log"))
nohups=($(find "${REPOROOT}" -iname "nohup*"))
pycs_path=($(find "${REPOROOT}" -iname "*.pyc"))

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
