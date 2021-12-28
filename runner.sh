run() {
    echo "[*] Cloning the repository..."
    git clone https://github.com/GGORG0/archer.git
    cd archer
    echo "[*] Starting Archer..."
    chmod +x *.sh
    ./archer.sh
}
run