#!/bin/bash

# ================================
# Colors
# ================================
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

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

step "[+] Installing Kali wallpapers..."
sudo apt install -y kali-wallpapers-all 2>&1 | tee -a "$LOG_FILE"
success "Wallpapers installed."

step "[+] Installing Fastfetch..."
sudo apt install -y fastfetch 2>&1 | tee -a "$LOG_FILE"
success "Fastfetch installed."

step "[+] Installing tmux..."
sudo apt install -y tmux 2>&1 | tee -a "$LOG_FILE"
success "Tmux installed."

# ================================
# Tmux Configuration
# ================================

step "[+] Configuring tmux (mouse, scrollback, terminal overrides)..."

TMUX_CONF="$HOME/.tmux.conf"

if ! grep -q "##### Custom Tmux Settings #####" "$TMUX_CONF" 2>/dev/null; then
cat << 'EOF' >> "$TMUX_CONF"

##### Custom Tmux Settings #####
set -g mouse on
set -g history-limit 10000
set -g terminal-overrides 'xterm*:smcup@rmcup@'
################################

EOF
    success "Tmux configuration added."
else
    success "Tmux configuration already present."
fi

# ================================
# Default Shell
# ================================

step "[+] Setting Bash as default shell..."

if [ "$SHELL" != "/bin/bash" ]; then
    chsh -s /bin/bash "$USER" 2>&1 | tee -a "$LOG_FILE"
    success "Default shell set to Bash (log out and back in to apply)."
else
    success "Bash is already the default shell."
fi

# ================================
# Tooling
# ================================

step "[+] Installing core tools..."
sudo apt install -y \
    impacket-scripts dnsrecon smbclient ldap-utils krb5-user nikto smbmap \
    terminator wordlists seclists feroxbuster nmap rlwrap gobuster python3-pip \
    2>&1 | tee -a "$LOG_FILE"
success "Core tools installed."

step "[+] Creating folder structure..."
mkdir -p ~/tools ~/recon ~/loot ~/exploits ~/htb 2>&1 | tee -a "$LOG_FILE"
success "Folders created."

step "[+] Installing kerbrute..."
curl -L -o kerbrute https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64
chmod +x kerbrute
sudo mv kerbrute /usr/bin/kerbrute
success "kerbrute installed."

step "[+] Installing windapsearch..."
curl -L -o windapsearch https://github.com/ropnop/go-windapsearch/releases/download/v0.3.0/windapsearch-linux-amd64
chmod +x windapsearch
sudo mv windapsearch /usr/bin/windapsearch
success "windapsearch installed."

step "[+] Cloning nmapAutomator..."
sudo git clone https://github.com/21y4d/nmapAutomator /opt/nmapAutomator
sudo chmod +x /opt/nmapAutomator/nmapAutomator.sh
sudo cp /opt/nmapAutomator/nmapAutomator.sh /usr/bin/recon.sh
success "nmapAutomator ready."

step "[+] Cloning LinEnum..."
sudo git clone https://github.com/rebootuser/LinEnum /opt/LinEnum
sudo chmod +x /opt/LinEnum/LinEnum.sh
success "LinEnum ready."

step "[+] Cloning PEASS-ng..."
git clone https://github.com/carlospolop/PEASS-ng.git ~/tools/PEASS-ng
ln -sf ~/tools/PEASS-ng/linPEAS/linpeas.sh ~/tools/linpeas.sh
ln -sf ~/tools/PEASS-ng/winPEAS/winPEAS.bat ~/tools/winpeas.bat
success "PEASS-ng ready."

step "[+] Cloning Nishang..."
git clone https://github.com/samratashok/nishang.git ~/tools/nishang
success "Nishang cloned."

step "[+] Running updatedb..."
sudo updatedb
success "Locate database updated."

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
alias psh='cp ~/tools/nishang/Shells/Invoke-PowerShellTcpOneLine.ps1 .'
alias nnc='rlwrap nc -nvlp'
alias clone='sudo git clone'
alias pentmux='tmux new-session -d -s pentest -n vpn \; new-window -n recon \; new-window -n kali \; attach-session -t pentest'
EOF
)

step "[+] Adding aliases..."
for shellrc in ~/.bashrc ~/.zshrc; do
    if ! grep -q "# ===== Custom Hacking Aliases =====" "$shellrc" 2>/dev/null; then
        echo "$ALIASES" >> "$shellrc"
        success "Aliases added to $shellrc."
    else
        success "Aliases already present in $shellrc."
    fi
done

# ================================
# Final Message
# ================================

log "${GREEN}[✔] Setup complete.${NC}"
log "${YELLOW}[*] IMPORTANT: Log out and log back in to apply the Bash shell change.${NC}"
log "${YELLOW}[*] Then run: source ~/.bashrc (or open a new terminal).${NC}"
