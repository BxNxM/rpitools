#!/bin/bash

arglen="$#"
arglist=($@)

function apply_patch_if_needed() {
    local origin_file="$1"
    local patch_file="$2"
    sudo patch -p0 -N --dry-run --silent "$origin_file" "$patch_file" 2>/dev/null
    exit_code="$?"
    if [ "$exit_code" -eq 0 ]
    then
        echo -e "Patch is needed."
        echo -e "sudo bash -c \"patch $origin_file $patch_file\""
        sudo bash -c "patch $origin_file $patch_file"
    else
        echo -e "Already patched. Skipping..."
    fi

}

if [ "$arglen" -eq 2 ]
then
    if [ ! -e "${arglist[0]}" ]
    then
        echo -e "${arglist[0]} not exists!"
        exit 1
    fi
    if [ ! -e "${arglist[1]}" ]
    then
        echo -e "${arglist[1]} not exists!"
        exit 1
    fi
    if [[ "${arglist[1]}" != *".patch"* ]]
    then
        echo -e "${arglist[1]} not a patch file!"
        exit 2
    fi
    apply_patch_if_needed "${arglist[0]}" "${arglist[1]}"
else
    echo -e "Input error! [1] file [2] patch file"
fi
