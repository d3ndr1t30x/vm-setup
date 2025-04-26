#!/bin/bash

# ================================
# Colors
# ================================
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# ================================
# Log File
# ================================
LOG_FILE="setup.log"
echo "==== VM Setup Log - $(date) ====" > $LOG_FILE

log() {
    echo -e "$1" | tee -a $LOG_FILE
}

step() {
    echo -e "${YELLOW}$1${NC}"
    echo "== $1 ==" >> $LOG_FILE
}

success() {
    echo -e "${GREEN}    └── $1${NC}"
    echo "    └── $1" >> $LOG_FILE
}

# ================================
# Start Setup
# ================================

step "[+] Updating system package list..."
sudo apt update 2>&1 | tee -a $LOG_FILE
success "Package list updated."

step "[+] Installing 1337 H4x0R Wallpapers..."
sudo apt install kali-wallpapers-all -y
success "Kali wallpapers installed."

step "[+] Installing Terminator..."
sudo apt install terminator -y
success "Terminator installed."

step "[+] Installing core tools..."
sudo apt install -y wordlists seclists feroxbuster nmap rlwrap gobuster python3-pip tmux 2>&1 | tee -a $LOG_FILE
success "Core tools installed."

step "[+] Creating folder structure..."
mkdir -p ~/tools ~/recon ~/loot ~/exploits ~/htb 2>&1 | tee -a $LOG_FILE
success "Folders created."

step "[+] Installing kerbrute..."
curl -L -o kerbrute https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64 2>&1 | tee -a $LOG_FILE
chmod +x kerbrute
sudo mv kerbrute /usr/bin/kerbrute
success "kerbrute installed."

step "[+] Installing windapsearch..."
curl -L -o windapsearch https://github.com/ropnop/go-windapsearch/releases/download/v0.3.0/windapsearch-linux-amd64 2>&1 | tee -a $LOG_FILE
chmod +x windapsearch
sudo mv windapsearch /usr/bin/windapsearch
success "windapsearch installed."

step "[+] Cloning nmapAutomator..."
sudo git clone https://github.com/21y4d/nmapAutomator /opt/nmapAutomator
success "nmapAutomator cloned."

step "[+] Installing nmapAutomator script to /usr/bin..."
sudo chmod +x /opt/nmapAutomator/nmapAutomator.sh
sudo cp /opt/nmapAutomator/nmapAutomator.sh /usr/bin/recon.sh
success "nmapAutomator installed."

step "[+] Cloning LinEnum..."
sudo git clone https://github.com/rebootuser/LinEnum /opt/LinEnum
success "LinEnum cloned."

step "[+] Making LinEnum executable..."
sudo chmod +x /opt/LinEnum/LinEnum.sh
success "LinEnum executable."

step "[+] Cloning PEASS-ng..."
git clone https://github.com/carlospolop/PEASS-ng.git ~/tools/PEASS-ng
success "PEASS-ng cloned."

step "[+] Creating symlinks for linpeas and winpeas..."
ln -sf ~/tools/PEASS-ng/linPEAS/linpeas.sh ~/tools/linpeas.sh
ln -sf ~/tools/PEASS-ng/winPEAS/winPEAS.bat ~/tools/winpeas.bat
success "Symlinks created."

step "[+] Cloning Nishang..."
git clone https://github.com/samratashok/nishang.git ~/tools/nishang
success "Nishang cloned."

step "[+] Updating file paths with updatedb..."
sudo updatedb -v
success "File paths updated."

# ================================
# Aliases (No Dupes)
# ================================

add_alias_if_missing() {
    local file=$1
    local line=$2
    if [ -f "$file" ]; then
        grep -qxF "$line" "$file" || echo "$line" >> "$file"
    else
        echo "$line" >> "$file"
    fi
}

ALIASES_LIST=(
"alias gobust='sudo gobuster dir -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -o gobuster.out -b 404,403,301 -u'"
"alias nnmap='sudo mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan && sleep 10 && sudo nmap -p- -T4 -A -oA nmap/full-port-scan'"
"alias nnmap1='sudo mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan'"
"alias nnmap2='sudo nmap -p- -T4 -A -oA nmap/full-port-scan'"
"alias pyserv='python3 -m http.server'"
"alias c='clear'"
"alias htb='cd /home/kali/htb'"
"alias vpn='sudo openvpn /home/kali/Downloads/htb.ovpn'"
"alias mp='sudo mousepad'"
"alias hosts='sudo mousepad /etc/hosts'"
"alias opt='cd /opt'"
"alias linenum='sudo cp /opt/LinEnum/LinEnum.sh .'"
"alias dl='cd /home/kali/Downloads'"
"alias dirser='sudo dirsearch -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -o dirsearch.out -u'"
"alias cphp='sudo cp /opt/Web-Shells/laudanum/php/php-reverse-shell.php .'"
"alias psh='sudo cp ~/tools/nishang/Shells/Invoke-PowerShellTcpOneLine.ps1 .'"
"alias nnc='rlwrap nc -nvlp'"
"alias webshells-nishang='cd ~/tools/nishang/Shells'"
"alias clone='sudo git clone'"
)

step "[+] Adding aliases to ~/.bashrc and ~/.zshrc..."

for alias_line in "${ALIASES_LIST[@]}"; do
    add_alias_if_missing ~/.bashrc "$alias_line"
    add_alias_if_missing ~/.zshrc "$alias_line"
done

success "Aliases added (no duplicates)."

step "[+] Sourcing shells if present..."

if [ -f ~/.bashrc ]; then
    source ~/.bashrc && success ".bashrc sourced."
fi

if [ -f ~/.zshrc ]; then
    source ~/.zshrc && success ".zshrc sourced."
fi

# ================================
# Final Message
# ================================
log "${GREEN}[✔] Setup complete. Welcome to your new hacker home.${NC}"
