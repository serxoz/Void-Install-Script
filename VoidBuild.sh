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
echo "Use a PACKAGES.txt? (List of packages in a file) (y/n)"
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
