#!/bin/bash

FULL_PATH=`readlink -f $0 ` 
SCRIPT_ROOT=`dirname $FULL_PATH`
cd $SCRIPT_ROOT

if [ ! -e $SCRIPT_ROOT/downloads/CentOS-6.4-x86_64-netinstall.iso ]
then
  mkdir -p $SCRIPT_ROOT/downloads
  wget ftp://ftp.halifax.rwth-aachen.de/centos/6.4/isos/x86_64/CentOS-6.4-x86_64-netinstall.iso -O $SCRIPT_ROOT/downloads/CentOS-6.4-x86_64-netinstall.iso
fi

VBoxManage createvm --ostype Linux26_64 --name Siebel --register
VBoxManage modifyvm Siebel --memory 4096 --nic1 bridged --bridgeadapter1 eth0 --audio none --boot1 dvd
VBoxManage showvminfo --machinereadable Siebel > /tmp/vboxinfo.siebel
source /tmp/vboxinfo.siebel 2> /dev/null
rm /tmp/vboxinfo.siebel
basepath="`dirname "$CfgFile"`"
VBoxManage createhd --filename "${basepath}/Siebel.vdi" --size 70000 --format VDI --variant Standard
VBoxManage storagectl Siebel --name "SATA Controller" --add sata
VBoxManage storageattach Siebel --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${basepath}/Siebel.vdi"
VBoxManage storageattach Siebel --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium $SCRIPT_ROOT/downloads/CentOS-6.4-x86_64-netinstall.iso
VBoxManage storagectl Siebel --name "Floppy Controller" --add floppy
VBoxManage storageattach Siebel --storagectl "Floppy Controller" --port 0 --device 0 --type fdd --medium $SCRIPT_ROOT/../templates/kickstarter_disk_image.img
VBoxSDL --startvm Siebel
VBoxManage storageattach Siebel --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium none
VBoxManage storagectl Siebel --name "Floppy Controller" --remove
VBoxManage startvm Siebel
