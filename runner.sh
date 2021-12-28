run() {
    echo "[*] Making sure there is no archix folder..."
    rm -rf archix
    echo "[*] Making sure Git is installed..."
    pacman -Sy --noconfirm --needed git
    echo "[*] Cloning the repository..."
    git clone https://github.com/GGORG0/archix.git
    cd archix
    echo "[*] Starting Archix..."
    chmod +x *.sh
    ./archix.sh
    cd ..
}
run