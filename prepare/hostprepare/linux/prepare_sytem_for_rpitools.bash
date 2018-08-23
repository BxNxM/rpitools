#!/bin/bash

required_app_list=("vim" "git" "python3" "python" "sshpass")
fail_cnt=0

echo -e "INSTALL REQUIRED APPLICATIONS FOR RPITOOLS DEPOYMENT"
for app in "${required_app_list[@]}"
do
	echo -e "INSTALL: $app"
	echo "Y" | sudo apt-get install "$app"
	if [ "$?" -ne 0 ]
	then
		echo -e "[ERROR] install was failed: $app"
		fail_cnt=$((fail_cnt+1))
	else
		echo -e "[OK] install was successful $app"
	fi
done

if [ ! -e ~/.ssh/id_rsa.pub ]
then
	echo -e "GENERATE SSH KEY FOR PASSWORDLESS LOGIN"
	ssh-keygen
	if [ "$?" -ne 0 ]
	then
		echo -e "[ERROR] SSH KEY generation failed"
		fail_cnt=$((fail_cnt+1))
	else
		echo -e "[OK] SSH KEY generation was successful"
	fi
fi

echo -e "Get raspbian lite image"
pushd ~/Downloads
	rm -f ./raspbian_lite_latest
	rm -f ./*.img

	wget https://downloads.raspberrypi.org/raspbian_lite_latest
	unzip raspbian_lite_latest
	if [ "$?" -ne 0 ]
	then
		echo -e "[ERROR] DOWNLOAD RASPBIAN LITE IMAGE FAILED"
		fail_cnt=$((fail_cnt+1))
	else
		echo -e "[OK] DOWNLOAD RASPBIAN LITE IMAGE DONE"
	fi	
popd

if [ "$fail_cnt" -eq 0 ]
then
	echo -e "REQUIREMENTS INSTALLATIONS WAS SUCCESSFUL :D"
else
	echo -e "SOMETHINGS WENT WRONG :("
fi

