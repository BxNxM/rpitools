#!/bin/bash

MYDIR_linux="$(dirname $(readlink -f $0))"

required_app_list=("vim" "git" "python3" "python" "sshpass" "shellcheck" "wget")
fail_cnt=0

function prepare_linux_msg() {
	echo -e "\e[104m[LINUX HOST PREPARE]\e[49m $1"
}

prepare_linux_msg "INSTALL REQUIRED APPLICATIONS FOR RPITOOLS DEPOYMENT"
for app in "${required_app_list[@]}"
do
	prepare_linux_msg "INSTALL: $app"
	echo "Y" | sudo apt-get install "$app"
	if [ "$?" -ne 0 ]
	then
		prepare_linux_msg "[ERROR] install was failed: $app"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_linux_msg "[OK] install was successful $app"
	fi
done

if [ ! -e ~/.ssh/id_rsa.pub ]
then
	prepare_linux_msg "GENERATE SSH KEY FOR PASSWORDLESS LOGIN"
	ssh-keygen
	if [ "$?" -ne 0 ]
	then
		prepare_linux_msg "[ERROR] SSH KEY generation failed"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_linux_msg "[OK] SSH KEY generation was successful"
	fi
fi

prepare_linux_msg "Get raspbian lite image"
pushd ~/Downloads
	rm -f ./raspbian_lite_latest
	rm -f ./*.img

	wget https://downloads.raspberrypi.org/raspbian_lite_latest
	unzip raspbian_lite_latest
	if [ "$?" -ne 0 ]
	then
		prepare_linux_msg "[ERROR] DOWNLOAD RASPBIAN LITE IMAGE FAILED"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_linux_msg "[OK] DOWNLOAD RASPBIAN LITE IMAGE DONE"
	fi
popd

if [ ! -e ~/.vimrc ]
then
    prepare_linux_msg "Set ~/.vimrc"
    cp "${REPOROOT}/template/vimrc" ~/.vimrc
else
    prepare_linux_msg "~/.vimrc is already set."
fi

if [ "$fail_cnt" -eq 0 ]
then
	prepare_linux_msg "REQUIREMENTS INSTALLATIONS WAS SUCCESSFUL :D"
else
	prepare_linux_msg "SOMETHINGS WENT WRONG :("
fi
