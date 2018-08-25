#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR_macos="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_macos}/terminal_setup"

required_app_list=("vim" "git" "python3" "python" "sshpass" "shellcheck" "wget")
fail_cnt=0

function prepare_macos_msg() {
	echo -e "\033[0;34m[MACOS HOST PREPARE]\033[0m $1"
}

function set_package_manager() {
    if [ ! -e "/usr/local/bin/brew" ]
    then
        prepare_macos_msg "Install home brew for macos package manager"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
	local output=$(/usr/local/bin/brew --help)
	if [ "$?" -ne 0 ]
        then
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
    fi
}

prepare_macos_msg "INSTALL REQUIRED APPLICATIONS FOR RPITOOLS DEPOYMENT"
for app in "${required_app_list[@]}"
do
	prepare_macos_msg "INSTALL: $app"
	if [ "$app" == "sshpass" ]
	then
		echo "Y" | brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
	else
		echo "Y" | /usr/local/bin/brew install "$app"
	fi
	if [ "$?" -ne 0 ]
	then
		prepare_macos_msg "[ERROR] install was failed: $app"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_macos_msg "[OK] install was successful $app"
	fi
done

if [ ! -e ~/.ssh/id_rsa.pub ]
then
	prepare_macos_msg "GENERATE SSH KEY FOR PASSWORDLESS LOGIN"
	ssh-keygen
	if [ "$?" -ne 0 ]
	then
		prepare_macos_msg "[ERROR] SSH KEY generation failed"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_macos_msg "[OK] SSH KEY generation was successful"
	fi
fi

prepare_macos_msg "Get raspbian lite image"
pushd ~/Downloads
	rm -f ./raspbian_lite_latest
	rm -f ./*.img

	wget https://downloads.raspberrypi.org/raspbian_lite_latest
	unzip raspbian_lite_latest
	if [ "$?" -ne 0 ]
	then
		prepare_macos_msg "[ERROR] DOWNLOAD RASPBIAN LITE IMAGE FAILED"
		fail_cnt=$((fail_cnt+1))
	else
		prepare_macos_msg "[OK] DOWNLOAD RASPBIAN LITE IMAGE DONE"
	fi
popd

if [ ! -e ~/.vimrc ]
then
    prepare_macos_msg "Set ~/.vimrc"
    cp "${REPOROOT}/template/vimrc" ~/.vimrc
else
    prepare_macos_msg "~/.vimrc is already set."
fi

if [ "$fail_cnt" -eq 0 ]
then
	prepare_macos_msg "REQUIREMENTS INSTALLATIONS WAS SUCCESSFUL :D"
else
	prepare_macos_msg "SOMETHINGS WENT WRONG :("
fi
