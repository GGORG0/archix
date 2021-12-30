#!/bin/bash

if [ "ARCHIX_DISABLE_COLORS" == "1" ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    NC-""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[1;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

if [ "ARCHIX_RICH_SYMBOLS" == "1" ]; then
    CHECKMARK='[\xE2\x9C\x94]'
    CROSS='[\xE2\x9C\x98]'
    BULLET='[‣]'
else
    CHECKMARK='[√]'
    CROSS='[X]'
    BULLET='[>]'
fi
QUESTION='[?]'
WARNING='[!]'

error() {
    echo -e "$RED  $CROSS $1$NC"
    exit 1
}

cd "$(dirname "$0")" || echo -e "Could not change directory to the script directory. Please download the script to a stable directory and try again."

echo -e "Welcome to Archix, a simple bash script to install a new Arch Linux system."
echo -e "Make sure to run this script as root in the ArchISO."
echo -e

echo -e "$GREEN $BULLET Checking for root access...$NC"
if [ "$EUID" -ne 0 ]; then
    error "You're not root. Please run this script as root."
    exit 1
else
    echo -e "$GREEN  $CHECKMARK You are root!$NC"
fi

echo -e "$BLUE $QUESTION What is your preferred editor?"
echo -e " $BULLET 1. nano"
echo -e " $BULLET 2. vim"
echo -e "$NC"
read -r -p " Please enter your choice: " editor
if [ "$editor" == "1" ]; then
    export EDITOR=nano
elif [ "$editor" == "2" ]; then
    export EDITOR=vim
else
    echo -e "$RED  $CROSS Invalid choice!$NC"
    exit 1
fi


echo -e "$BLUE $QUESTION What is your computer's firmware?"
echo -e " $BULLET 1. BIOS"
echo -e " $BULLET 2. UEFI"
echo -e "$NC"
read -p " Please enter your choice: " firmware

if [ "$firmware" == "2" ]; then
    echo -e "$BLUE $BULLET Checking UEFI boot mode...$NC"
    if [ "$(cat /sys/firmware/efi/fw_platform_size)" == "0" ]; then
        echo -e "$RED  $CROSS UEFI boot mode is not enabled."
        echo -e "   Please boot in UEFI mode and try again."
        echo -e "$NC"
        exit 1
    fi
    echo -e "$GREEN  $CHECKMARK UEFI boot mode is enabled.$NC"
fi

echo -e "$BLUE $BULLET Checking for internet connection...$NC"
if ping -q -c 1 -W 1 archlinux.org >/dev/null; then
    echo -e "$GREEN  $CHECKMARK Internet connection is available.$NC"
else
    echo -e "$RED  $CROSS Internet connection is not available."
    echo -e "   Please connect to the internet and try again."
    echo -e "$NC"
    exit 1
fi

echo -e "$BLUE $BULLET Refreshing repositories...$NC"
pacman -Syy || error "An error occurred while refreshing repositories."

echo -e "$BLUE $BULLET Enabling Pacman parallel downloads...$NC"
sed -i '37s/.//' /etc/pacman.conf

echo -e "$BLUE $BULLET Enabling NTP clock synchronization...$NC"
timedatectl set-ntp true || error "An error occurred while enabling NTP clock synchronization."
sleep 2
echo -e "$GREEN  $CHECKMARK Enabled NTP clock synchronization.$NC"

echo -e "$BLUE $QUESTION Have you already partitioned your hard drive?"
echo -e " $BULLET 1. Yes"
echo -e " $BULLET 2. No"
echo -e "$NC"
read -p "Please enter your choice: " partitioned

if [ "$partitioned" == "2" ]; then
    echo -e "$BLUE $QUESTION Do you want to partition your hard drive malually?"
    echo -e " $BULLET 1. Yes"
    echo -e " $BULLET 2. No (BIOS not yet supported)"
    echo -e "$NC"
    read -p "Please enter your choice: " manpartition
    
    if [ "$manpartition" == "1" ]; then
        echo -e "$YELLOW $BULLET $WARNING Only EXT4 partitions are supported.$NC"
        echo


        echo -e "$BLUE $BULLET Here is the list of devices you can use:$NC"
        lsblk -d -p -o NAME,SIZE
        read -p "Please enter the device name (e.g. /dev/sda): " device
        if [ -z "$device" ]; then
            echo -e "$RED $CROSS Device name is empty.$NC"
            exit 1
        fi
        if [ ! -b "$device" ]; then
            echo -e "$RED $CROSS Device name is not valid.$NC"
            exit 1
        fi

        if [ "$firmware" == "2" ]; then
            cgdisk $device || error "An error occurred while partitioning your hard drive."
        else
            echo -e "$YELLOW $BULLET $WARNING Please choose the DOS label.$NC"
            sleep 2
            cfdisk $device || error "An error occurred while partitioning your hard drive."
        fi
        
        echo -e "$BLUE $BULLET Here is the list of partitions you can use:$NC"
        lsblk -p -o NAME,SIZE $device

        read -p "Please enter the root partition (e.g. /dev/sda1): " rootdev
        if [ -z "$rootdev" ]; then
            echo -e "$RED $CROSS Device name is empty.$NC"
            exit 1
        fi
        if [ ! -b "$rootdev" ]; then
            echo -e "$RED $CROSS Device name is not valid.$NC"
            exit 1
        fi

        if [ "$firmware" == "2" ]; then
            read -p "Please enter the EFI System Partition (e.g. /dev/sda1): " efipart
            if [ -z "$efipart" ]; then
                echo -e "$RED $CROSS EFI System Partition is empty.$NC"
                exit 1
            fi
            if [ ! -b "$efipart" ]; then
                echo -e "$RED $CROSS EFI System Partition is not valid.$NC"
                exit 1
            fi
        else
            efipart=""
        fi

        read -p "Please enter the swap partition (e.g. /dev/sda2): " swapdev
        if [ -z "$swapdev" ]; then
            echo -e "$YELLOW $WARNING Swap partition is empty. Not using one. $NC"
        else
            if [ ! -b "$swapdev" ]; then
                echo -e "$RED $CROSS Swap partition is not valid.$NC"
                exit 1
            fi
        fi
    else
        # TODO: Auto partitioning for BIOS
        error "Automated partitioning for BIOS is not yet supported."


        echo -e "$BLUE $BULLET Here is the list of devices you can use:$NC"
        lsblk -d -p -o NAME,SIZE

        read -p "Please enter the device name (e.g. /dev/sda): " device

        if [ -z "$device" ]; then
            echo -e "$RED $CROSS Device name is empty.$NC"
            exit 1
        fi
        if [ ! -b "$device" ]; then
            echo -e "$RED $CROSS Device name is not valid.$NC"
            exit 1
        fi

        echo

        echo -e "$YELLOW $BULLET $WARNING Home partitions are not yet supported.$NC"
        echo -e "$YELLOW  $BULLET If you want to create a home partition, please choose manual partitioning.$NC"
        echo -e "$YELLOW $BULLET $WARNING Only EXT4 partitions are supported.$NC"
        echo -e "$BLUE $BULLET The following partitions will be created:"
        if [ "$firmware" == "2" ]; then
            echo -e " $BULLET 1. /boot (FAT32; EFI System Partition; 500 MB)"
            echo -e " $BULLET 2. swap (SWAP; SWAP; 2 GB)"
            echo -e " $BULLET 3. / (EXT4; Linux Filesystem; 100% of remaining space)"
        else
            echo -e " $BULLET 1. swap (SWAP; SWAP; 2 GB)"
            echo -e " $BULLET 2. / (EXT4; Linux Filesystem; 100% of remaining space)"
        fi
        echo -e "$NC"

        echo -e "$BLUE $QUESTION Do you want to continue?"
        echo -e " $BULLET 1. Yes"
        echo -e " $BULLET 2. No"
        echo -e "$NC"
        read -p "Please enter your choice: " cont
        if [ "$cont" == "2" ]; then
            echo -e "$RED $CROSS Aborting!$NC"
            exit 1
        fi

        echo -e "$BLUE $BULLET Partitioning your hard drive...$NC"
        echo -e "$BLUE $BULLET This may take a while...$NC"

        if [ "$firmware" == "2" ]; then
            sgdisk -o \
                -n 1:0:+500M -t 2:EF00 \ # /boot
                -n 2:0:+2G -t 3:8200 \ # swap
                -n 3:0:0 -t 3:8300 \ # /
                $device || error "An error occurred while partitioning your hard drive."
            efipart = "$device1"
            swapdev = "$device2"
            rootdev = "$device3"
        # else

            # sfdisk -o \
            #     -n 1:0:+2G -t 3:8200 \ # swap
            #     -n 2:0:0 -t 3:8300 \ # /
            #     $device || error "An error occurred while partitioning your hard drive."
            # efipart = ""
            # swapdev = "$device1"
            # rootdev = "$device2"
        fi

        echo -e "$GREEN $CHECKMARK Partitioning completed.$NC"
    fi
else
    
    echo -e "$YELLOW $BULLET $WARNING Home partitions are not yet supported.$NC"
    echo -e "$YELLOW  $BULLET If you want to use a home partition, please do it manually or re-run the script choosing to partition automatically.$NC"
    echo -e "$YELLOW $BULLET $WARNING Only EXT4 partitions are supported.$NC"

    echo -e "$BLUE $BULLET Here is the list of partitions you can use:$NC"
    lsblk -p -o NAME,SIZE,TYPE

    read -p "Please enter the root partition (e.g. /dev/sda2): " rootdev
    if [ -z "$rootdev" ]; then
        echo -e "$RED $CROSS Device name is empty.$NC"
        exit 1
    fi
    if [ ! -b "$rootdev" ]; then
        echo -e "$RED $CROSS Device name is not valid.$NC"
        exit 1
    fi

    if [ "$firmware" == "2" ]; then
        read -p "Please enter the EFI System Partition (e.g. /dev/sda1): " efipart
        if [ -z "$efipart" ]; then
            echo -e "$RED $CROSS EFI System Partition is empty.$NC"
            exit 1
        fi
        if [ ! -b "$efipart" ]; then
            echo -e "$RED $CROSS EFI System Partition is not valid.$NC"
            exit 1
        fi
    fi


    read -p "Please enter the swap partition (e.g. /dev/sda3): " swapdev
    if [ -z "$swapdev" ]; then
        echo -e "$YELLOW $WARNING Swap partition is empty. Not using one. $NC"
    else
        if [ ! -b "$swapdev" ]; then
            echo -e "$RED $CROSS Swap partition is not valid.$NC"
            exit 1
        fi
    fi
fi

echo -e "$BLUE $BULLET You entered the following information:"
echo -e " $BULLET 1. Device: $device"
echo -e " $BULLET 2. Root partition: $rootdev"
echo -e " $BULLET 3. Swap partition: $swapdev"
if [ "$firmware" == "2" ]; then
    echo -e " $BULLET 4. EFI System Partition: $efipart"
fi
echo -e "$NC"

echo -e "$BLUE $QUESTION Is this correct?$NC"
echo -e " $BULLET 1. Yes"
echo -e " $BULLET 2. No"
echo -e "$NC"
read -p "Please enter your choice: " cont
if [ "$cont" == "2" ]; then
    echo -e "$RED $CROSS Aborting!$NC"
    exit 1
fi

echo -e "$BLUE $BULLET Creating the filesystems...$NC"
echo -e "$BLUE $BULLET This may take a while...$NC"

if [ "$firmware" == "2" ]; then
    echo -e "$BLUE $BULLET Formatting EFI System Partition as FAT32 (VFAT)...$NC"
    mkfs.vfat $efipart || error "An error occurred while creating the EFI System Partition filesystem."
fi

echo -e "$BLUE $BULLET Formatting Root partition as EXT4...$NC"
mkfs.ext4 $rootdev || error "An error occurred while creating the Root partition filesystem."

echo -e "$BLUE $BULLET Formatting Swap partition as SWAP...$NC"
mkswap $swapdev || error "An error occurred while creating the Swap partition filesystem."

echo -e "$GREEN $CHECKMARK Filesystems created.$NC"

echo -e "$BLUE $BULLET Mounting the filesystems...$NC"

echo -e "$BLUE  $BULLET Mounting Root partition...$NC"
mount $rootdev /mnt || error "An error occurred while mounting the Root partition."
echo -e "$GREEN   $CHECKMARK Root partition mounted.$NC"

echo -e "$BLUE  $BULLET Creating /boot mountpoint...$NC"
mkdir -p /mnt/boot

if [ "$firmware" == "2" ]; then
    mkdir -p /mnt/boot/efi
    echo -e "$BLUE   $BULLET Mounting EFI System Partition...$NC"
    mount $efipart /mnt/boot/efi || error "An error occurred while mounting the EFI System Partition."
    echo -e "$GREEN    $CHECKMARK EFI System Partition mounted.$NC"
fi

echo -e "$BLUE  $BULLET Mounting Swap partition...$NC"
swapon $swapdev || error "An error occurred while mounting the Swap partition."
echo -e "$GREEN   $CHECKMARK Swap partition mounted.$NC"


echo -e "$BLUE $QUESTION Which kernel do you want to install?$NC"
echo -e " $BULLET 1. Linux"
echo -e " $BULLET 2. Linux-LTS"
echo -e "$NC"
read -p "Please enter your choice: " kernel
if [ "$kernel" == "2" ]; then
    kern="linux-lts"
else
    kern="linux"
fi

echo -e "$BLUE $QUESTION What is your CPU manufacturer?$NC"
echo -e " $BULLET 1. AMD"
echo -e " $BULLET 2. Intel"
echo -e "$NC"
read -p " Please enter your choice: " cpu
if [ "$cpu" == "2" ]; then
    ucode="intel-ucode"
else
    ucode="amd-ucode"
fi

echo -e "$BLUE $BULLET Installing the base system...$NC"
echo -e "$BLUE $BULLET This may take a while...$NC"
pacstrap /mnt base base-devel linux-firmware $kern git vim nano $ucode || error "An error occurred while installing the base system."
echo -e "$GREEN $CHECKMARK Base system installed.$NC"

echo -e "$BLUE $BULLET Generating fstab...$NC"
genfstab -U /mnt >> /mnt/etc/fstab || error "An error occurred while generating fstab."
echo -e "$GREEN $CHECKMARK fstab generated.$NC"

echo -e "$BLUE $BULLET Copying the installation script...$NC"
cp -r $PWD/chroot.sh /mnt/install.sh || error "An error occurred while copying the installation script."
cp -r $PWD/user.sh /mnt/user.sh || error "An error occurred while copying the installation script."
echo -e "$GREEN $CHECKMARK Installation script copied.$NC"

echo -e "$BLUE $BULLET Chrooting into the new system...$NC"
echo "export EDTOR=$EDTOR" >> /mnt/envs
echo "export device=$device" >> /mnt/envs
echo "export firmware=$firmware" >> /mnt/envs
echo "export kern=$kern" >> /mnt/envs
echo "export ARCHIX_DISABLE_COLORS=$ARCHIX_DISABLE_COLORS" >> /mnt/envs
echo "export ARCHIX_RICH_SYMBOLS=$ARCHIX_RICH_SYMBOLS" >> /mnt/envs
arch-chroot /mnt /install.sh || error "An error occurred while chrooting into the new system."
echo -e "$GREEN $CHECKMARK Chroot exited.$NC"

echo -e "$BLUE $BULLET Deleting the installation script...$NC"
rm /mnt/install.sh || error "An error occurred while deleting the installation script."
rm /mnt/user.sh || error "An error occurred while deleting the installation script."
rm /mnt/envs || error "An error occurred while deleting the installation script."
echo -e "$GREEN $CHECKMARK Installation script deleted.$NC"

echo -e "$BLUE $BULLET Unmounting the filesystems...$NC"
umount -R /mnt || error "An error occurred while unmounting the filesystems."
echo -e "$GREEN $CHECKMARK Filesystems unmounted.$NC"

echo -e "$GREEN $CHECKMARK Installation finished.$NC"
echo -e "$GREEN $CHECKMARK Enjoy!$NC"
echo -en "$BLUE $BULLET Rebooting in "
for i in {5..1}; do
    echo -en "$i "
    sleep 1
done
echo -e "$NC"
echo -e "$BLUE $BULLET Rebooting...$NC"
reboot
echo -e "$RED $CROSS An error occurred while rebooting."
