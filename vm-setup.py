#!/usr/bin/env python3

import os
import subprocess
import logging
from pathlib import Path
import pwd
import sys

# ================================
# Environment
# ================================
ENV = os.environ.copy()
ENV["DEBIAN_FRONTEND"] = "noninteractive"

HOME = Path.home()
LOG_FILE = HOME / "setup.log"

# ================================
# Logging
# ================================
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s"
)

def step(msg):
    print(f"\033[1;33m{msg}\033[0m")
    logging.info(msg)

def success(msg):
    print(f"\033[0;32m    └── {msg}\033[0m")
    logging.info(msg)

def run(cmd, sudo=False):
    if sudo:
        cmd = ["sudo"] + cmd
    subprocess.run(cmd, check=True, env=ENV)

# ================================
# Package Management
# ================================
def is_installed(pkg):
    result = subprocess.run(
        ["dpkg", "-s", pkg],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return result.returncode == 0

def install_packages(packages):
    missing = [p for p in packages if not is_installed(p)]
    if missing:
        run(["apt", "install", "-y"] + missing, sudo=True)
        success(f"Installed: {' '.join(missing)}")
    else:
        success("All packages already installed")

# ================================
# Files & Config
# ================================
def ensure_dirs(paths):
    for p in paths:
        Path(os.path.expanduser(p)).mkdir(parents=True, exist_ok=True)

def append_block_if_missing(path, marker, block):
    path = Path(path)
    if path.exists() and marker in path.read_text():
        success(f"{path.name} already configured")
        return

    with path.open("a") as f:
        f.write("\n" + block + "\n")

    success(f"Updated {path.name}")

# ================================
# Shell
# ================================
def ensure_bash_shell():
    current = os.environ.get("SHELL", "")
    if current != "/bin/bash":
        user = pwd.getpwuid(os.getuid()).pw_name
        run(["chsh", "-s", "/bin/bash", user])
        success("Default shell set to bash (log out & back in required)")
    else:
        success("Bash already default shell")

# ================================
# Downloads
# ================================
def download_binary(url, name):
    target = Path("/usr/bin") / name
    if target.exists():
        success(f"{name} already installed")
        return

    tmp = HOME / name
    run(["curl", "-L", "-o", str(tmp), url])
    run(["chmod", "+x", str(tmp)])
    run(["mv", str(tmp), str(target)], sudo=True)
    success(f"{name} installed")

# ================================
# Git
# ================================
def clone_repo(url, dest):
    dest = Path(dest)
    if dest.exists():
        success(f"{dest.name} already cloned")
        return
    run(["git", "clone", url, str(dest)])
    success(f"Cloned {dest.name}")

# ================================
# Main
# ================================
def main():
    step("Updating package list...")
    run(["apt", "update"], sudo=True)
    success("Package list updated")

    step("Installing core packages...")
    install_packages([
        "tmux", "fastfetch", "kali-wallpapers-all",
        "impacket-scripts", "dnsrecon", "smbclient",
        "ldap-utils", "krb5-user", "nikto", "smbmap",
        "terminator", "wordlists", "seclists",
        "feroxbuster", "nmap", "rlwrap", "gobuster",
        "python3-pip"
    ])

    step("Configuring tmux...")
    TMUX_BLOCK = """\
##### Custom Tmux Settings #####
set -g mouse on
set -g history-limit 10000
set -g terminal-overrides 'xterm*:smcup@rmcup@'
################################
"""
    append_block_if_missing(HOME / ".tmux.conf",
                            "##### Custom Tmux Settings #####",
                            TMUX_BLOCK)

    step("Creating directories...")
    ensure_dirs([
        "~/tools", "~/recon", "~/loot", "~/exploits", "~/htb"
    ])
    success("Directories created")

    step("Installing kerbrute...")
    download_binary(
        "https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64",
        "kerbrute"
    )

    step("Installing windapsearch...")
    download_binary(
        "https://github.com/ropnop/go-windapsearch/releases/download/v0.3.0/windapsearch-linux-amd64",
        "windapsearch"
    )

    step("Cloning tools...")
    clone_repo("https://github.com/21y4d/nmapAutomator", "/opt/nmapAutomator")
    run(["chmod", "+x", "/opt/nmapAutomator/nmapAutomator.sh"], sudo=True)
    run(["cp", "/opt/nmapAutomator/nmapAutomator.sh", "/usr/bin/recon.sh"], sudo=True)

    clone_repo("https://github.com/rebootuser/LinEnum", "/opt/LinEnum")
    run(["chmod", "+x", "/opt/LinEnum/LinEnum.sh"], sudo=True)

    clone_repo("https://github.com/carlospolop/PEASS-ng.git", HOME / "tools/PEASS-ng")
    clone_repo("https://github.com/samratashok/nishang.git", HOME / "tools/nishang")

    step("Configuring aliases...")
    ALIAS_BLOCK = """\
# ===== Custom Hacking Aliases =====
alias gobust='sudo gobuster dir -w /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt -o gobuster.out -b 404,403,301 -u'
alias nnmap='mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan && sleep 10 && sudo nmap -p- -T4 -A -oA nmap/full-port-scan'
alias nnmap1='mkdir -p nmap && sudo nmap -sCV -vvv -oA nmap/script-scan'
alias nnmap2='sudo nmap -p- -T4 -A -oA nmap/full-port-scan'
alias pyserv='python3 -m http.server'
alias c='clear'
alias htb='cd ~/htb'
alias vpn='sudo openvpn ~/Downloads/htb.ovpn'
alias opt='cd /opt'
alias linenum='cp /opt/LinEnum/LinEnum.sh .'
alias dl='cd ~/Downloads'
alias nnc='rlwrap nc -nvlp'
alias clone='sudo git clone'
alias pentmux='tmux new-session -d -s pentest -n vpn \\; new-window -n recon \\; new-window -n kali \\; attach-session -t pentest'
"""
    append_block_if_missing(HOME / ".bashrc",
                            "# ===== Custom Hacking Aliases =====",
                            ALIAS_BLOCK)

    step("Setting default shell...")
    ensure_bash_shell()

    step("Updating locate database...")
    run(["updatedb"], sudo=True)
    success("Locate database updated")

    print("\n\033[1;33mIMPORTANT:\033[0m Log out and log back in to apply shell changes.\n")

if __name__ == "__main__":
    if os.geteuid() == 0:
        print("Do not run this as root. Run as your user with sudo access.")
        sys.exit(1)
    main()
