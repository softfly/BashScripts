#!/bin/bash
DIALOG=${DIALOG=dialog}
DIALOG_TITLE="Centos Setup"
DIALOG_BACKTITLE="Centos Setup"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function installPackage {
	if ! yum list installed $1 >/dev/null 2>&1; then
		sudo yum -y install $1
	fi
}
function addSudoers {
	sudo grep -q -F "$1 ALL=(ALL) ALL" /etc/sudoers || echo "$1 ALL=(ALL) ALL" >> /etc/sudoers
}
function setAutologinUser {
	grep -q -F "AutomaticLogin=$1" /etc/gdm/custom.conf || sudo sed --in-place "/\[daemon\]/a AutomaticLogin=$1" /etc/gdm/custom.conf
	grep -q -F "AutomaticLoginEnable=True" /etc/gdm/custom.conf || sudo sed --in-place "/\[daemon\]/a AutomaticLoginEnable=True" /etc/gdm/custom.conf
}
function installSVN {
	echo $DIR/wandisco-svn.repo
	sudo cp $DIR/etc/yum.repos.d/wandisco-svn.repo /etc/yum.repos.d/wandisco-svn.repo
	sudo yum install -y subversion
}
function installAnt {
	cd /tmp
	wget -N http://apache.cu.be//ant/binaries/apache-ant-1.9.7-bin.zip
	unzip apache-ant-1.9.7-bin.zip
	sudo mv apache-ant-1.9.7 /opt/apache-ant-1.9.7
	sudo ln -s -T -f /opt/apache-ant-1.9.7 /opt/ant
	sudo cp $DIR/etc/profile.d/ant.sh /etc/profile.d/ant.sh
	export ANT_HOME=/opt/ant
}
function displayAddSudoers {
	user=$(
	dialog --title "$DIALOG_TITLE" \
	 --backtitle "$DIALOG_BACKTITLE" \
	 --output-fd 1 \
	 --inputbox "Login user" 8 40 "centos"
	);
	addSudoers $user
}
function displaySetAutologinUser {
	user=$(
	dialog --title "$DIALOG_TITLE" \
	 --backtitle "$DIALOG_BACKTITLE" \
	 --output-fd 1 \
	 --inputbox "Login user" 8 40 "centos"
	);
	setAutologinUser $user
}
function displaySetTypeUser {
	typeUser=$(
		$DIALOG --title "$DIALOG_TITLE" \
		--backtitle "$DIALOG_BACKTITLE" \
		--output-fd 1 \
		--menu "Avaible operation for user:"  10 40 2 \
		1 "ROOT" \
		2 "Normal"
	);
	case $typeUser in
		1) displayRootOperation ;;
		2) displayUserOperation ;;
		*) echo "INVALID NUMBER $op" ;
	esac
}
function executeOperation {
	case $1 in
		1) displayAddSudoers 
		   displayRootOperation 
                   ;;
		2) installPackage epel-release 
	           displayUserOperation ;;
		3) installPackage open-vm-tools
		   installPackage open-vm-desktop 
		   displayUserOperation ;;
		4) displaySetAutologinUser 
	           displayUserOperation	;; 
		5) sudo yum update ;;
		*) echo "INVALID NUMBER $op" ;
	esac	
}
function displayRootOperation {
	operations=$(
		$DIALOG --title "$DIALOG_TITLE" \
		--backtitle "$DIALOG_BACKTITLE" \
		--output-fd 1 \
		--checklist "Set operations" 10 50 1 \
		1 "Add user to sudoers" on \
	);
	operations=$(echo $operations | tr " " "\n")
	for op in $operations
	do	
		op="${op%\"}"
		op="${op#\"}"
		executeOperation $op
	done
}
function displayUserOperation {
	operations=$(
		$DIALOG --title "$DIALOG_TITLE" \
		--backtitle "$DIALOG_BACKTITLE" \
		--output-fd 1 \
		--checklist "Set operations" 10 50 6 \
		2 "Install EPEL" on \
		3 "Install VM tools" on \
		4 "Autologin user" on
	);
	operations=$(echo $operations | tr " " "\n")
	for op in $operations
	do
		op="${op%\"}"
		op="${op#\"}"
		executeOperation $op	
	done
}


if [ -n "$1" ]
then
	$1
else
	installPackage dialog
	installPackage xdialog
	displaySetTypeUser
fi
