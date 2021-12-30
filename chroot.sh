#!/bin/bash

echo -e "[*] Loading variables...$NC"
source /envs
echo -e " [*] Variables loaded!$NC"

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

echo -e "$GREEN $CHECKMARK Chrooted into the system!$NC"

echo -e "$GREEN $BULLET Checking for root access...$NC"
if [ "$EUID" -ne 0 ]; then
    error "You're not root. Please run this script as root."
else
    echo -e "$GREEN  $CHECKMARK You are root!$NC"
fi

echo -e "$BLUE $BULLET Please set your timezone:$NC"
timezone=$(tzselect) || error "Timezone not set!"
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
echo -e "$GREEN  $CHECKMARK Timezone set to $timezone!$NC"

echo -e "$BLUE $BULLET Setting hardware clock to UTC...$NC"
hwclock --systohc
echo -e "$GREEN  $CHECKMARK Hardware clock set to UTC!$NC"

echo -e "$BLUE $QUESTION Do you want to continue with the en_US locale?"
echo -e " $BULLET 1) Yes"
echo -e " $BULLET 2) No (Change it manually)"
echo -e "$NC"
read -p " Please enter your choice: " locale_choice

if [ "$locale_choice" == "1" ]; then
    echo -e "$BLUE $BULLET Setting locale to en_US...$NC"
    sed -i '177s/.//' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo -e "$GREEN  $CHECKMARK Locale set to en_US.UTF-8!$NC"
elif [ "$locale_choice" == "2" ]; then
    echo -e "$BLUE $BULLET Please set your locale:$NC"
    $EDITOR /etc/locale.gen
    locale-gen
    locale=$(grep -v '#' /etc/locale.gen | grep -v '^$' | head -n 1)
    echo "LANG=$locale" > /etc/locale.conf
    echo -e "$GREEN  $CHECKMARK Locale set!$NC"
else
    error "Invalid choice!"
fi

echo -e "$BLUE $BULLET Setting hostname...$NC"
read -p "Please enter your hostname: " hostname
echo "$hostname" > /etc/hostname
echo -e "$GREEN  $CHECKMARK Hostname set to $hostname!$NC"

echo -e "$BLUE $BULLET Setting hostname in hosts file...$NC"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo -e "$GREEN  $CHECKMARK Hostname set in hosts file!$NC"

echo -e "$BLUE $BULLET Setting root password...$NC"
passwd
echo -e "$GREEN  $CHECKMARK Root password set!$NC"

echo -e "$BLUE $BULLET Installing packages...$NC"
pacman -Sy

echo -e "$BLUE  $BULLET Installing GRUB packages...$NC"
pacman -S --noconfirm --needed grub efibootmgr os-prober

echo -e "$BLUE  $BULLET Installing networking packages...$NC"
pacman -S --noconfirm --needed networkmanager network-manager-applet wpa_supplicant avahi gvfs gvfs-smb nfs-utils \
                                inetutils dnsutils openssh rsync reflector openbsd-netcat nss-mdns
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer

echo -e "$BLUE  $BULLET Installing filesystem packages...$NC"
pacman -S --noconfirm --needed dosfstools exfat-utils fuse exfat-utils mtools ntfs-3g
systemctl enable fstrim.timer

echo -e "$BLUE  $BULLET Installing other packages...$NC"
pacman -S --noconfirm  --needed dialog wget sudo nano vim git base-devel linux-headers xdg-user-dirs xdg-utils \
                                alsa-utils pulseaudio pulseaudio-alsa bash-completion acpi acpid acpi_call \
                                sof-firmware terminus-font
systemctl enable acpid

echo -e "$BLUE $QUESTION Do you want to install Bluetooth support?"
echo -e " $BULLET 1) Yes"
echo -e " $BULLET 2) No"
echo -e "$NC"
read -p " Please enter your choice: " bluetooth_choice
if [ "$bluetooth_choice" == "1" ]; then
    echo -e "$BLUE $BULLET Installing Bluetooth support...$NC"
    pacman -S --noconfirm --needed bluez bluez-utils pulseaudio-bluetooth
    systemctl enable bluetooth.service
    echo -e "$GREEN  $CHECKMARK Bluetooth support installed!$NC"
elif [ "$bluetooth_choice" == "2" ]; then
    echo -e "$BLUE $BULLET Skipping Bluetooth support...$NC"
else
    error "Invalid choice!"
fi

echo -e "$BLUE $QUESTION Do you want to install printer support? (Including HP printer driver)"
echo -e " $BULLET 1) Yes"
echo -e " $BULLET 2) No"
echo -e "$NC"
read -p " Please enter your choice: " printer_choice
if [ "$printer_choice" == "1" ]; then
    echo -e "$BLUE $BULLET Installing printer support...$NC"
    pacman -S --noconfirm --needed cups hplip
    systemctl enable cups.service
    echo -e "$GREEN  $CHECKMARK Printer support installed!$NC"
elif [ "$printer_choice" == "2" ]; then
    echo -e "$BLUE $BULLET Skipping printer support...$NC"
else
    error "Invalid choice!"
fi

echo -e "$BLUE $QUESTION What is your graphics card?$NC"
echo -e " $BULLET 1) NVIDIA"
echo -e " $BULLET 2) AMD (Not tested)"
echo -e " $BULLET 3) Intel (Integrated)"
echo -e " $BULLET 4) Both (NVIDIA and Intel)"
echo -e " $BULLET 5) None (eg. VM)"
echo -e "$NC"
read -p " Please enter your choice: " graphics_card

if [ "$graphics_card" == "1" ]; then
    echo -e "$BLUE $BULLET Setting up NVIDIA drivers...$NC"
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    sed -i 's/^MODULES=()/MODULES=(nvidia)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo -e "$GREEN  $CHECKMARK NVIDIA drivers installed!$NC"
elif [ "$graphics_card" == "2" ]; then
    echo -e "$BLUE $BULLET Setting up AMD drivers...$NC"
    pacman -S --noconfirm xf86-video-amdgpu
    echo -e "$GREEN  $CHECKMARK AMD drivers installed!$NC"
elif [ "$graphics_card" == "3" ]; then
    echo -e "$BLUE $BULLET Setting up Intel drivers...$NC"
    pacman -S --noconfirm xf86-video-intel
    sed -i 's/^MODULES=()/MODULES=(i915)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo -e "$GREEN  $CHECKMARK Intel drivers installed!$NC"
elif [ "$graphics_card" == "4" ]; then
    echo -e "$BLUE $BULLET Setting up NVIDIA and Intel drivers...$NC"
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    pacman -S --noconfirm xf86-video-intel
    sed -i 's/^MODULES=()/MODULES=(nvidia i915)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo -e "$GREEN  $CHECKMARK NVIDIA and Intel drivers installed! Optimus Manager switching will be installed later.$NC"
elif [ "$graphics_card" == "5" ]; then
    echo -e "$BLUE $BULLET Skipping graphics card setup...$NC"
else
    error "Invalid choice!"
fi

echo -e "$BLUE $QUESTION Do you want to install TLP for laptop power management?$NC"
echo -e " $BULLET 1) Yes"
echo -e " $BULLET 2) No"
echo -e "$NC"
read -p " Please enter your choice: " tlp_choice
if [ "$tlp_choice" == "1" ]; then
    echo -e "$BLUE $BULLET Installing TLP...$NC"
    pacman -S --noconfirm --needed tlp
    systemctl enable tlp.service
    echo -e "$GREEN  $CHECKMARK TLP installed!$NC"
elif [ "$tlp_choice" == "2" ]; then
    echo -e "$BLUE $BULLET Skipping TLP...$NC"
else
    error "Invalid choice!"
fi

echo -e "$BLUE $BULLET Installing GRUB...$NC"
if [ "$firmware" == "2" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
else
    grub-install --target=i386-pc --recheck $device
fi
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "$GREEN  $CHECKMARK GRUB installed!$NC"

echo -e "$BLUE $BULLET Creating user...$NC"
read -p " Please enter your username: " username
useradd -m -s /bin/bash $username
passwd $username
echo -e "$BLUE  $BULLET Setting up sudo...$NC"
echo "$username ALL=(ALL) ALL" >> /etc/sudoers
echo -e "$GREEN   $CHECKMARK Sudo setup complete!$NC"
echo -e "$GREEN  $CHECKMARK User created!$NC"

echo -e "$BLUE $BULLET Getting mirrors...$NC"
reflector -a 6 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "$GREEN  $CHECKMARK Mirrors updated!$NC"

echo -e "$BLUE $BULLET Switching user...$NC"
su $username -c /user.sh
echo -e "$GREEN $CHECKMARK User script exited!$NC"

echo -e "$BLUE $QUESTION Which desktop environment do you want to install?$NC"
echo -e " $BULLET 1) KDE Plasma"
echo -e " $BULLET 2) GNOME"
echo -e " $BULLET 3) XFCE"
echo -e " $BULLET 4) None (TTY)"
echo -e "$NC"
read -p " Please enter your choice: " desktop_choice
if [ "$desktop_choice" == "1" ]; then
    echo -e "$BLUE $BULLET Installing KDE Plasma...$NC"
    pacman -S --noconfirm --needed xorg plasma sddm dolphin konsole
    systemctl enable sddm.service
    echo -e "$GREEN  $CHECKMARK KDE Plasma installed!$NC"
elif [ "$desktop_choice" == "2" ]; then
    echo -e "$BLUE $BULLET Installing GNOME...$NC"
    pacman -S --noconfirm --needed xorg gnome gnome-extra gdm
    systemctl enable gdm.service
    echo -e "$GREEN  $CHECKMARK GNOME installed!$NC"
elif [ "$desktop_choice" == "3" ]; then
    echo -e "$BLUE $BULLET Installing XFCE...$NC"
    pacman -S --noconfirm --needed xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    systemctl enable lightdm.service
    echo -e "$GREEN  $CHECKMARK XFCE installed!$NC"
elif [ "$desktop_choice" == "4" ]; then
    echo -e "$BLUE $BULLET Skipping desktop environment.$NC"
else
    error "Invalid choice!"
fi


