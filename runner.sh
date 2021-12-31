run() {
    echo "[*] Making sure there is no archix.git folder..."
    rm -rf archix.git
    echo "[*] Making sure Git is installed..."
    pacman -Sy --noconfirm --needed git
    echo "[*] Cloning the repository..."
    git clone https://github.com/GGORG0/archix.git archix.git
    cd archix.git
    echo "[*] Starting Archix..."
    chmod +x *.sh
    ./archix.sh
}
run