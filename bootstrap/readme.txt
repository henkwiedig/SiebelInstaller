
#Create the VM see: http://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/
VBoxManage createvm --ostype Linux26_64 --name Siebel --register
VBoxManage modifyvm Siebel --memory 4096 --nic1 nat --audio none --boot1 dvd
VBoxManage createhd --filename Siebel.vdi --size 60000 --format VDI --variant Standard
VBoxManage storagectl Siebel --name "SATA Controller" --add sata
VBoxManage storageattach Siebel --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium Siebel.vdi
VBoxManage storageattach Siebel --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium CentOS-6.4-x86_64-netinstall.iso
VBoxManage startvm Siebel

#Kickstarter Support
VBoxManage storagectl Siebel --name "Floppy Controller" --add floppy
VBoxManage storageattach Siebel --storagectl "Floppy Controller" --port 0 --device 0 --type fdd --medium templates/kickstarter_disk_image.img

#boot and add 
ks=hd:fd0:/ks.cfg
#to cmdline using tab

#prepare centOS Kickstarter disk
dd bs=512 count=2880 if=/dev/zero of=imagefile.img
mkfs.msdos imagefile.img
sudo mkdir /media/floppy1/
sudo mount -o loop floppy.img /media/floppy1/
cp templates/anaconda-ks.cfg /media/floppy1/ks.cfg

