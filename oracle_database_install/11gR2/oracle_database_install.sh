#!/bin/bash
# This file is part of the Softfly/bash distribution (https://github.com/softfly or http://softfly.github.io).
# Copyright (c) 2016 Grzegorz Ziemski.
# 
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#================================================================
# HEADER
#================================================================
#% DESCRIPTION
#%    Based on instruction:
#%    http://www.tecmint.com/oracle-database-11g-release-2-installation-in-linux/
#%    http://blogs.oracle.com/opal/entry/how_i_enable_autostarting_of1
#%
#================================================================
#- IMPLEMENTATION
#-    version         1
#-    author          Grzegorz Ziemski
#-    copyright       Copyright (c) http://softfly.pl
#-    license         GNU General Public License
#-
#================================================================
#  HISTORY
#     2016/07/01 : gziemski : Script creation
# 
#================================================================
# END_OF_HEADER
#================================================================
DIR_INSTALL=/mnt/install
ORACLE_DB_PACKAGE1=$DIR_INSTALL/linux.x64_11gR2_database_1of2.zip
ORACLE_DB_PACKAGE2=$DIR_INSTALL/linux.x64_11gR2_database_2of2.zip
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function setSysctl {
	if grep -q -F "$1 =" /etc/sysctl.conf
	then
		sudo sed -i "s/^$1 =.*/$1 = $2/g" /etc/sysctl.conf
	else
		S="echo \"$1 = $2\" >> /etc/sysctl.conf"
		sudo sh -c "$S"
	fi	
}
function setLimit {
	if ! grep -q -F "$1 =" /etc/security/limits.conf
	then
		S="echo \"$1\" >> /etc/security/limits.conf"
		sudo sh -c "$S"
	fi
	
}

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Set SELINUXs=permissive"
echo "[INFO] ------------------------------------------------------------------------"
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/sysconfig/selinux

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Install required package"
echo "[INFO] ------------------------------------------------------------------------"
sudo yum install -y binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.x86_64 compat-libstdc++-33.i686 compat-gcc-44 compat-gcc-44-c++ gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 ksh.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686 libstdc++-devel.x86_64 libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 libXext.i686 libXext.x86_64 libXtst.i686 libXtst.x86_64 libX11.x86_64 libX11.i686 libXau.x86_64 libXau.i686 libxcb.i686 libxcb.x86_64 libXi.i686 libXi.x86_64 make.x86_64 unixODBC unixODBC-devel sysstat.x86_64

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Set kernel level parameters"
echo "[INFO] ------------------------------------------------------------------------"
setSysctl kernel.shmmax 4294967295
setSysctl kernel.shmall 2097152
setSysctl fs.aio-max-nr 1048576
setSysctl fs.file-max 6815744
setSysctl kernel.shmmni 4096
setSysctl kernel.sem "250 32000 100 128"
setSysctl net.ipv4.ip_local_port_range "9000 65500"
setSysctl net.core.rmem_default 262144
setSysctl net.core.rmem_max 4194304
setSysctl net.core.wmem_default 262144
setSysctl net.core.wmem_max 1048576

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Create new user oracle"
echo "[INFO] ------------------------------------------------------------------------"
sudo groupadd -g 200 oinstall
sudo groupadd -g 201 dba
sudo useradd -u 440 -g oinstall -G dba oracle
sudo usermod -a -G wheel oracle
sudo passwd oracle

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Create catalogs"
echo "[INFO] ------------------------------------------------------------------------"
sudo mkdir -p /u01/app/oracle/product/11.2.0.4
sudo mkdir -p /u01/app/oracle/oradata
sudo chown -R oracle:oinstall /u01
sudo chmod -R 775 /u01
ls -l /u01

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Set environment variables"
echo "[INFO] ------------------------------------------------------------------------"
if ! grep -q -F "## Oracle Env Settings" /etc/bashrc
then
	sudo sh -c "cat \"$DIR/bashrc\" >> /etc/bashrc"
fi

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Set /etc/security/limits.conf"
echo "[INFO] ------------------------------------------------------------------------"
setLimit "oracle	soft	nofile	1024"
setLimit "oracle	hard	nofile	65536"
setLimit "oracle	soft	nproc	2047"
setLimit "oracle	hard	nproc	16384"
setLimit "oracle	soft	stack	10240"
setLimit "oracle	hard	stack	32768"

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Set /etc/security/limits.d/90-nproc.conf"
echo "[INFO] ------------------------------------------------------------------------"
sudo sed -i "s/^.*soft.*nproc.*1024/*          -    nproc     16384/g" /etc/security/limits.d/90-nproc.conf

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Install autostart"
echo "[INFO] ------------------------------------------------------------------------"
#sudo cp $DIR/dbora /etc/init.d/dbora
#sudo chmod 750 /etc/init.d/dbora
#sudo chkconfig --add dbora
#sudo chkconfig dbora on

echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Unzip files"
echo "[INFO] ------------------------------------------------------------------------"
unzip $ORACLE_DB_PACKAGE1 -d /tmp
unzip $ORACLE_DB_PACKAGE2 -d /tmp
sudo chown -R oracle:oinstall /tmp/database


echo "[INFO] ------------------------------------------------------------------------"
echo "[INFO] Please now reboot os. After reboot execute commands:"
echo "[INFO] su - oracle"
echo "[INFO] ./tmp/database/runInstaller"
echo "[INFO] ------------------------------------------------------------------------"
