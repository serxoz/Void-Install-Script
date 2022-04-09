#!/bin/bash

#CHECK PERMISSIONS

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!" 
   exit 1
fi


#SETUP


clear
echo "THIS SCRIPT MUST BE RUN ON A SYSTEM WITH XBPS INSTALLED"
echo "That could be another linux system with a statically linked XBPS install, BUT I wholeheartedly recommend using a live image, OR an existing void install"
echo ""
echo ""
echo ""
echo "Which disk would you like to partition (make sure its all backed up, as this is completely destructive!)"
echo "The below list has your mounted partitions removed"
echo ""
lsblk | grep -v / | grep -v ─ | grep -v NAME | awk '{print $1 " " $4}'
echo ""
echo "This should be in the format /dev/sdX, or similar"
read -p "> /dev/" DISK2INSTALL
DISK2INSTALL="/dev/$DISK2INSTALL"

echo ""
printf "Install to" 
printf $DISK2INSTALL
printf "? (yes/no)"
echo ""
printf "> "
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
	exit 1
fi



echo ""
echo "Use a packages.txt? (List of packages in a file) (y/n)"
read -p "> " PACKAGES

REPO=https://alpha.de.repo.voidlinux.org/current

echo ""
echo "Architecture? (x86_64 or x86_64-musl for 64-bit, i686 for 32-bit)"
printf "> "
read ARCH
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "x86_64-musl" ] && [ "$ARCH" != "i686" ]; then
	echo "Invalid Architecture!"
	exit 1
fi

echo ""
echo "Locale? (en_US.UTF-8,en_GB.UTF-8,etc)"
printf "> "
read LOCALEFORINST

echo ""
echo "Hostname?"
printf "> "
read HOSTNAMEFORINST

echo ""
echo "Keymap? (uk,etc)"
printf "> "
read KEYMAPFORINST

echo ""
echo "Timezone? (Continent/City, eg:Europe/London)"
printf "> "
read TIMEZONEFORINST

echo ""
echo "Root password?"
printf "> "
read ROOTFORINST




#FINAL CONFIRMATION

clear

echo "DISK: " $DISK2INSTALL
echo "ARCH: " $ARCH
echo ""
echo "Is this OK? (This is also your final warning that this will delete EVERYTHING on this disk) (yes/no)"
printf "> "
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
        exit 1
fi

echo "Jo mama"

#INSTALL DEPS
xbps-install -S parted

#FORMAT DISKS

umount $DISK2INSTALL
dd if=$DISK2INSTALL of=$DISK2INSTALL bs=512 count=1 conv=notrunc
parted $DISK2INSTALL --script mklabel gpt
parted $DISK2INSTALL --script mkpart primary fat32 1MB 512MB
parted $DISK2INSTALL --script mkpart primary ext4 513MB 100%

mkfs.vfat $DISK2INSTALL"1"
mkfs.ext4 $DISK2INSTALL"2"

#MOUNT DISKS

mount $DISK2INSTALL"2" /mnt/
mkdir -p /mnt/boot/efi/
mount $DISK2INSTALL"1" /mnt/boot/efi

#INSTALL BASE
if [ "$PACKAGES" == "y" ]
then
	XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system $(echo packages.txt)
else
	XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system
fi

#BIND MOUNTS AND DNS

mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
cp /etc/resolv.conf /mnt/etc/

#CHROOT
if [ "$ARCH" == "x86_64" ]
then 
	echo $("echo" $HOSTNAMEFORINST ">> /etc/hostname") >> chroot.sh
	echo $("echo KEYMAP=" $KEYMAPFORINST ">> /etc/rc.conf") >> chroot.sh
	echo $("echo TIMEZONE=" $TIMEZONEFORINST ">> /etc/rc.conf") >> chroot.sh
	echo $("echo" $LOCALEFORINST ">> /etc/default/libc-locales") >> chroot.sh
	echo $("echo xbps-reconfigure -f glibc-locales") >> chroot.sh
	echo $("echo" $ROOTFORINST "| passwd --stdin") >> chroot.sh
	echo $("echo $(cat /proc/mounts | grep -v -e proc -e sys -e tmpfs -e pts ) >> tempfstab ") >> chroot.sh
	echo $("echo $(cat tempfstab | grep /boot/efi | awk '$6=$6"2"') >> tempfstab2") >> chroot.sh 
	echo $("echo $(cat tempfstab | grep ext4 | awk '$6=$6"1"') >> tempfstab2") >> chroot.sh 
	echo $("mv tempfstab2 /etc/fstab") >> chroot.sh 
	echo $("xbps-install grub-x86_64-efi") >> chroot.sh
	echo $("grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"") >> chroot.sh 
	echo $("xbps-reconfigure -fa") >> chroot.sh
fi

mv chroot.sh /mnt/
chmod +x /mnt/chroot.sh
chroot /mnt/ ./chroot.sh

echo "Done!"
