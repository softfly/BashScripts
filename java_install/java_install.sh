#!/bin/bash
DIALOG=${DIALOG=dialog}
DIALOG_TITLE="Java Setup Centos 6.8"
DIALOG_BACKTITLE="Java Setup Centos 6.8"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function installPackage {
	if ! yum list installed $1 >/dev/null 2>&1; then
		sudo yum -y install $1
	fi
}
function installOracleJDK {
	echo "[INFO] ------------------------------------------------------------------------"
	echo "[INFO] Install Oracle JDK 6&7&8"
	echo "[INFO] ------------------------------------------------------------------------"
	export JAVA_HOME=/usr/java/default
	export JRE_HOME=/usr/java/default/jre
	export PATH=$PATH:/usr/java/default/bin:/usr/java/default/jre/bin
	sudo cp $DIR/java.sh /etc/profile.d/java.sh

	cd /tmp
	if [ ! -d '/usr/java/jdk1.6.0_45' ]; then
		wget -N --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
			"http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64-rpm.bin"
		sudo sh ./jdk-6u45-linux-x64-rpm.bin
		sudo alternatives --install /usr/bin/java java /usr/java/jdk1.6.0_45/bin/java 2
		#sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.6.0_45/bin/jar 2
		sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.6.0_45/bin/javac 2
	fi

	if [ ! -d '/usr/java/jdk1.7.0_79' ]; then
		sudo cp -R /usr/java/jdk1.6.0_45 /usr/java/jdk1.6.0_45copy
		wget -N --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
		"http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm"
		sudo yum localinstall -y jdk-7u79-linux-x64.rpm
		sudo alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_79/bin/java 2
		#sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_79/bin/jar 2
		sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_79/bin/javac 2
		sudo mv /usr/java/jdk1.6.0_45copy /usr/java/jdk1.6.0_45
	fi
	if ! yum list installed jdk1.8.0_91 >/dev/null 2>&1; then
		sudo cp -R /usr/java/jdk1.6.0_45 /usr/java/jdk1.6.0_45copy
		wget -N --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
		"http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jdk-8u91-linux-x64.rpm"
		sudo yum localinstall -y jdk-8u91-linux-x64.rpm
		sudo alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_91/bin/java 2
		#sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_91/bin/jar 2
		sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_91/bin/javac 2
		sudo mv /usr/java/jdk1.6.0_45copy /usr/java/jdk1.6.0_45
	fi
}
function setJDK {
	sudo alternatives --set java /usr/java/$1/bin/java
	#sudo alternatives --set jar /usr/java/$1/bin/jar
	sudo alternatives --set javac /usr/java/$1/bin/javac
	sudo rm /usr/java/default
	sudo ln -s /usr/java/$1 /usr/java/default
}
function setJDK6 {
	setJDK jdk1.6.0_45
}
function setJDK7 {
	setJDK jdk1.7.0_79
}
function setJDK8 {
	setJDK jdk1.8.0_91
}
function installEclipse {
	cd /tmp
	wget -N http://mirror.netcologne.de/eclipse//oomph/epp/neon/R/eclipse-inst-linux64.tar.gz
	tar -xf eclipse-inst-linux64.tar.gz
	mv /tmp/eclipse-installer ~/eclipse-installer
	~/eclipse-installer/eclipse-inst
}
function installWeblogic {
	installOracleJDK8
	cd ~/Downloads
	#wget http://download.oracle.com/otn/nt/middleware/12c/122110/fmw_12.2.1.1.0_wls_quick_Disk1_1of1.zip
	unzip fmw_12.2.1.1.0_wls_quick_Disk1_1of1.zip
	cd ~/Downloads/fmw_12.2.1.1.0_wls_quick_Disk1_1of1
	sudo /usr/java/jdk1.8.0_91/bin/java -jar ~/Downloads/fmw_12.2.1.1.0_wls_quick_Disk1_1of1/fmw_12.2.1.1.0_wls_quick.jar ORACLE_HOME=/opt
}
function installMaven {
	cd /tmp
	wget -N http://ftp.ps.pl/pub/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
	sudo tar xzf apache-maven-3.3.9-bin.tar.gz -C /usr/local
	cd /usr/local
	sudo ln -s apache-maven-3.3.9 maven
	grep -q -F "export M2_HOME=/usr/local/maven" /etc/profile.d/maven.sh || sudo /bin/sh -c 'echo "export M2_HOME=/usr/local/maven" >> /etc/profile.d/maven.sh'
	E='export PATH=${M2_HOME}/bin:${PATH}'
	#todo nie wstawia się
	grep -q -F 'export PATH=${M2_HOME}/bin:${PATH}' /etc/profile.d/maven.sh || sudo /bin/sh -c "echo '${E}' >> /etc/profile.d/maven.sh"
}
function displayOperations {
	op=$(
		$DIALOG --title "$DIALOG_TITLE" \
		--backtitle "$DIALOG_BACKTITLE" \
		--output-fd 1 \
		--menu "Avaible operation:"  40 40 8 \
		1 "Install Oracle JDK 6&7&8" \
		2 "Set default Oracle JDK 6" \
		3 "Set default Oracle JDK 7" \
		4 "Set default Oracle JDK 8" \
		5 "Install Maven 3.3.9"
		6 "Install Oracle WebLogic 12.2.1.1.0" \	
	);
	case $op in
		1) installOracleJDK ;;
		2) setJDK6 ;;
		3) setJDK7 ;;
		4) setJDK8 ;;
		5) installMaven ;;
		6) installWeblogic ;;		
		*) echo "INVALID NUMBER $op" ;
	esac
}
if [ -n "$1" ]
then
	$1
else
	installPackage dialog
	installPackage xdialog
	displayOperations
fi
