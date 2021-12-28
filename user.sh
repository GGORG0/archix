#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECKMARK='\xE2\x9C\x94'
CROSS='\xE2\x9C\x98'
BULLET='‣'
QUESTION='?'
WARNING='!'

error() {
    echo -e "$RED  $CROSS $1$NC"
    exit 1
}

echo -e "$GREEN $CHECKMARK User switched!$NC"

echo -e "$BLUE $BULLET Installing Yay AUR helper...$NC"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin
echo -e "$GREEN  $CHECKMARK Yay AUR helper installed!$NC"

