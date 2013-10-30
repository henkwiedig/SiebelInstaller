
#Create the VM see: http://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/

#boot and add 
ks=hd:fd0:/ks.cfg
#to cmdline using tab

#prepare centOS Kickstarter disk
dd bs=512 count=2880 if=/dev/zero of=imagefile.img
mkfs.msdos imagefile.img
mkdir /media/floppy1/
mount -o loop imagefile.img /media/floppy1/
cp templates/anaconda-ks.cfg /media/floppy1/ks.cfg
umount /media/floppy1/
rm -r /media/floppy1/
cat imagefile.img > templates/kickstarter_disk_image.img
rm imagefile.img

