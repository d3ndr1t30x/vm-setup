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
echo "==== VM Setup Log - $(date) ====" > "$LOG_FILE"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

step() {
    echo -e "${YELLOW}$1${NC}"
    echo "== $1 ==" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}    └── $1${NC}"
    echo "    └── $1" >> "$LOG_FILE"
}

# ================================
# Start Setup
# ================================

step "[+] Updating system package list..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"
success "Package list updated."

step "[+] Installing 1337 H4x0R Wallpapers..."
sudo apt install -y kali-wallpapers-all 2>&1 | tee -a "$LOG_FILE"
success "Kali wallpapers installed."

step "[+] Installing Terminator..."
sudo apt install -y terminator 2>&1 | tee -a "$LOG_FILE"
success "Terminator installed."

step "[+] Installing core tools..."
sudo apt install -y wordlists seclists feroxbuster nmap rlwrap gobuster python3-pip tmux 2>&1 | tee -a "$LOG_FILE"
success "Core tools installed."

step "[+] Creating folder structure..."
mkdir -p ~/tools ~/recon ~/loot ~/exploits ~/htb 2>&1 | tee -a "$LOG_FILE"
success "Folders created: tools, recon, loot, exploits, htb."

step "[+] Installing kerbrute..."
curl -L -o kerbrute https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64 2>&1 | tee -a "$LOG_FILE"
chmod +x kerbrute 2>&1 | tee -a "$LOG_FILE"
sudo mv kerbrute /usr/bin/kerbrute 2>&1 | tee -a "$LOG_FILE"
success "kerbrute installed."

step "[+] Installing windapsearch..."
curl -L -o windapsearch https://github.com/ropnop/go-windapsearch/releases/download/v0.3.0/windapsearch-linux-amd64 2>&1 | tee -a "$LOG_FILE"
chmod +x windapsearch 2>&1 | tee -a "$LOG_FILE"
sudo mv windapsearch /usr/bin/windapsearch 2>&1 | tee -a "$LOG_FILE"
success "windapsearch installed."

step "[+] Cloning nmapAutomator..."
sudo git clone https://github.com/21y4d/nmapAutomator /opt/nmapAutomator 2>&1 | tee -a "$LOG_FILE"
sudo chmod +x /opt/nmapAutomator/nmapAutomator.sh 2>&1 | tee -a "$LOG_FILE"
sudo cp /opt/nmapAutomator/nmapAutomator.sh /usr/bin/recon.sh 2>&1 | tee -a "$LOG_FILE"
success "nmapAutomator set up."

step "[+] Cloning LinEnum..."
sudo git clone https://github.com/rebootuser/LinEnum /opt/LinEnum 2>&1 | tee -a "$LOG_FILE"
sudo chmod +x /opt/LinEnum/LinEnum.sh 2>&1 | tee -a "$LOG_FILE"
success "LinEnum ready."

step "[+] Cloning PEASS-ng..."
git clone https://github.com/carlospolop/PEASS-ng.git ~/tools/PEASS-ng 2>&1 | tee -a "$LOG_FILE"
ln -sf ~/tools/PEASS-ng/linPEAS/linpeas.sh ~/tools/linpeas.sh
ln -sf ~/tools/PEASS-ng/winPEAS/winPEAS.bat ~/tools/winpeas.bat
success "PEASS-ng with symlinks set."

step "[+] Cloning Nishang..."
git clone https://github.com/samratashok/nishang.git ~/tools/nishang 2>&1 | tee -a "$LOG_FILE"
success "Nishang cloned."

step "[+] Running updatedb..."
sudo updatedb -v 2>&1 | tee -a "$LOG_FILE"
success "File paths updated."

# ================================
# Aliases
# ================================
ALIASES=$(cat << 'EOF'

# ===== Custom Hacking Aliases =====
alias gobust='sudo gobuster dir -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -o gobuster.out -b 404,403,301 -u'
alias nnmap='mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan && sleep 10 && sudo nmap -p- -T4 -A -oA nmap/full-port-scan'
alias nnmap1='mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan'
alias nnmap2='sudo nmap -p- -T4 -A -oA nmap/full-port-scan'
alias pyserv='python3 -m http.server'
alias c='clear'
alias htb='cd ~/htb'
alias vpn='sudo openvpn ~/Downloads/htb.ovpn'
alias mp='sudo mousepad'
alias hosts='sudo mousepad /etc/hosts'
alias opt='cd /opt'
alias linenum='cp /opt/LinEnum/LinEnum.sh .'
alias dl='cd ~/Downloads'
alias dirser='sudo dirsearch -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -o dirsearch.out -u'
alias cphp='cp /opt/Web-Shells/laudanum/php/php-reverse-shell.php .'
alias psh='cp ~/tools/nishang/Shells/Invoke-PowerShellTcpOneLine.ps1 .'
alias nnc='rlwrap nc -nvlp'
alias webshells-nishang='cd ~/tools/nishang/Shells'
alias clone='sudo git clone'
EOF
)

step "[+] Adding custom aliases..."
for shellrc in ~/.bashrc ~/.zshrc; do
    if ! grep -q "# ===== Custom Hacking Aliases =====" "$shellrc"; then
        echo "$ALIASES" >> "$shellrc"
        success "Aliases added to $shellrc."
    else
        success "Aliases already exist in $shellrc."
    fi
done

# ================================
# Final Message
# ================================
log "${GREEN}[✔] Setup complete. Welcome to your new hacker home.${NC}"
log "${YELLOW}[*] To activate aliases, run: 'source ~/.bashrc' or open a new terminal.${NC}"
