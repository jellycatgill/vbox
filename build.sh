#!/bin/bash



function install_packages {
	if [[ ! -f  /etc/apt/sources.list/oracle-virtualbox.list ]]; then
		echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/oracle-virtualbox.list
	fi
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
	apt-get update
	apt-get install wget dkms apt-transport-https -y --allow-unauthenticated
	apt-get install virtualbox-6.0 -y --allow-unauthenticated

	wget https://download.virtualbox.org/virtualbox/6.0.4/Oracle_VM_VirtualBox_Extension_Pack-6.0.4.vbox-extpack
	echo y | vboxmanage extpack install Oracle_VM_VirtualBox_Extension_Pack-6.0.4.vbox-extpack
	vboxmanage list extpacks
}

function download_image_ubuntu {
	SETUP_DIR=$1
	mkdir -p $SETUP_DIR
	cd $SETUP_DIR
	wget http://sg.releases.ubuntu.com/16.04/ubuntu-16.04.6-server-amd64.iso	
}

function vm_create {
	SETUP_DIR=$1
	IMAGE_NAME=$2
	
	if [[ ! -f $SETUP_DIR/ubuntu-16.04.6-server-amd64.iso ]]; then
		printf "\n\nERROR: ISO image for Ubuntu VM has not been downloaded into \"$SETUP_DIR\" yet. Use -p option to download"
	fi
	
	vboxmanage createvm --name $IMAGE_NAME --ostype Ubuntu_64 --register --basefolder $SETUP_DIR
	vboxmanage modifyvm $IMAGE_NAME --memory 1024 --boot1 dvd --vrde on --vrdeport 5001 --nic1 nat
	vboxmanage storagectl $IMAGE_NAME --name "${IMAGE_NAME}_SATA" --add sata
	vboxmanage createhd --filename $SETUP_DIR/$IMAGE_NAME.vdi --size 10280 --format VDI --variant Standard
	vboxmanage storageattach $IMAGE_NAME --storagectl ${IMAGE_NAME}_SATA --port 1 --type hdd --medium $SETUP_DIR/$IMAGE_NAME.vdi
	vboxmanage storageattach $IMAGE_NAME --storagectl ${IMAGE_NAME}_SATA --port 0 --type dvddrive --medium ${SETUP_DIR}/ubuntu-16.04.6-server-amd64.iso
	vboxmanage startvm ${IMAGE_NAME} --type headless

	vm_list	
}

function vm_list {
	printf "\n----- Running VMs -----\n"	
	vboxmanage list runningvms

}


function chk_partition_size {

	# partition size min 10g ?
	SETUP_DIR=$1
	printf "\n\nChecking \"$SETUP_DIR\" partition size is min 10gb..."
}

function chk_setup_dir {
	SETUP_DIR=$1
	if [[ -z $SETUP_DIR ]]; then
		printf "\n\nERROR: Setup directory not defined."
		show_usage 1
	fi			
}

function show_usage {
	EXIT="$1"
	printf "\n\nUsage: $(basename $0) [-h] [-i] [-d <dir> [-p|-c <vm-name>]] [-v]\n" >&2
	printf "\n[-h] : Show this help"
	printf "\n[-i]: Install Virtualbox"
	printf "\n[-d <dir>]: Specify dir to download Ubuntu Image and/or to create new VM"
	printf "\n[-p] : Download Ubuntu 16.04 image"
	printf "\n[-c <vm-name>] : Create new Ubuntu 16.04 VM with specified name"
	printf "\n[-v] : View attributes of running VMs\n\n"

	if [[ $EXIT == "1" ]]; then
		exit 1
	fi
}


if [[ $USER != "root" ]]; then
	printf "\n\nERROR: To be run as root only\n";
	exit 1
fi	

if [[ $# == 0 ]]; then
	show_usage 1
fi	


while getopts 'id:pc:vh:' OPTION; do
  	case "$OPTION" in
    i)
      	printf "\n\nInstalling Virtualbox & necessary packages...\n" 
		install_packages
      	;;
    d)
		SETUP_DIR="$OPTARG"
      	printf "\n\nSetup Directory: $SETUP_DIR\n"
		chk_partition_size $SETUP_DIR
		;;
    p)
		chk_setup_dir $SETUP_DIR
      	printf "\n\nDownloading Virtualbox image for Ubuntu 16.04 to ${SETUP_DIR}...\n"
		download_image_ubuntu $SETUP_DIR
		;;
	c)
		chk_setup_dir $SETUP_DIR
		IMAGE_NAME="$OPTARG"
      	printf "\n\nCreating VM \"${IMAGE_NAME}\"...\n"
		vm_create $SETUP_DIR $IMAGE_NAME
		;;
	v)
		printf "\n\nView VM attributes"
		;;
    ?|h)
		show_usage 1
      ;;
  esac
done
shift "$(($OPTIND -1))"


echo
