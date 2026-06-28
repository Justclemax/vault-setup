#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  vault-setup.sh  —  Universal Vault installer
#  Platforms : macOS · Linux (Debian/Ubuntu · RHEL/Fedora · Arch)
#  Languages : English · Français
#  Modes     : Development · Production
#  Version   : 2.0.0
#
#  Usage:
#    bash vault-setup.sh              # normal install
#    bash vault-setup.sh --uninstall  # remove everything
# ════════════════════════════════════════════════════════════════════
set -euo pipefail
IFS=$'\n\t'

VERSION="2.0.0"
SECURE_DIR="$HOME/.vault-secure"
VAULT_LOG="/tmp/vault-setup.log"
CADDY_LOG="/tmp/caddy-setup.log"
NTFY_LOG="/tmp/ntfy-setup.log"
VAULT_PORT=8200
CADDY_PORT=443
NTFY_PORT=2586

# ── Colors (disabled when not a tty) ───────────────────────────────
if [[ -t 1 ]]; then
    G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' C='\033[0;36m' B='\033[1m' N='\033[0m'
else
    G='' Y='' R='' C='' B='' N=''
fi
ok()    { echo -e "${G}  ✅  $*${N}"; }
warn()  { echo -e "${Y}  ⚠️   $*${N}"; }
err()   { echo -e "${R}  ❌  $*${N}"; exit 1; }
info()  { echo -e "${C}  ℹ️   $*${N}"; }
title() {
    local txt="$*"
    local line="────────────────────────────────────────────────────────────"
    echo ""
    echo -e "${C}  ┌${line}┐${N}"
    echo -e "${C}  │${N}  ${B}${txt}${N}"
    echo -e "${C}  └${line}┘${N}"
}
step()  {
    STEP_N=$(( ${STEP_N:-0} + 1 ))
    echo -e "\n${B}  [${STEP_N}] $*${N}"
}

# ── ASCII banner ────────────────────────────────────────────────────
show_banner() {
    local _W
    _W=$(tput cols 2>/dev/null || echo 80)
    tput civis 2>/dev/null
    echo -e "${C}"

    # ── Naruto court à travers l'écran ────────────────────────────
    printf '\n\n\n\n\n'
    local _p=0 _f=0
    while [ "$_p" -lt $((_W - 14)) ]; do
        printf '\033[5A'
        local _s
        _s=$(printf '%*s' "$_p" '')
        case $((_f % 4)) in
            0) printf "\033[2K%s  _o>\n\033[2K%s  /|_\n\033[2K%s >>|\n\033[2K%s  / \\\n\033[2K%s_/\n"  "$_s" "$_s" "$_s" "$_s" "$_s" ;;
            1) printf "\033[2K%s  _o>\n\033[2K%s  /|_\n\033[2K%s >>|\n\033[2K%s _/\\\n\033[2K%s\n"     "$_s" "$_s" "$_s" "$_s" "$_s" ;;
            2) printf "\033[2K%s  _o>\n\033[2K%s  /|_\n\033[2K%s >>|\n\033[2K%s  /\\\n\033[2K%s  \\\n" "$_s" "$_s" "$_s" "$_s" "$_s" ;;
            3) printf "\033[2K%s  _o>\n\033[2K%s  /|_\n\033[2K%s >>|\n\033[2K%s  /\n\033[2K%s_/ \\\n"  "$_s" "$_s" "$_s" "$_s" "$_s" ;;
        esac
        sleep 0.05
        _p=$((_p + 3)); _f=$((_f + 1))
    done
    printf '\033[5A\033[2K\n\033[2K\n\033[2K\n\033[2K\n\033[2K'
    printf '\033[5A'
    sleep 0.15

    # ── Art Braille ligne par ligne ────────────────────────────────
    while IFS= read -r _line; do
        echo "$_line"
        sleep 0.04
    done << 'BRAILLE_ART'
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠻⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣏⢩⣛⠿⢿⢰⡙⣿⢟⣯⡞⣼⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⠿⠿⠿⠿⠆⣿⣿⣦⣼⣷⣶⣿⣿⣧⣽⣶⢇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣷⣌⠻⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⡶⢟⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⠟⣡⣶⣿⣿⡿⠋⢉⣠⣤⣄⠈⢿⡟⢯⢿⣷⣯⣛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠉⠉⠁⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⡿⠋⢴⣿⣿⣿⣿⠋⣠⣎⢿⣿⣿⡿⠇⢀⣙⠀⠁⠙⣏⢿⣾⣿⣿⣿⣿⢟⣝⠿⠟⠋⠁⠀⠀⠀⠀⢀⣀⣀⣀⣤⣤⣤⣈⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣶⢆⣽⣿⡟⣺⣿⣇⠿⣋⡵⣴⣿⠿⣿⣿⣷⣤⣨⢎⠛⠛⠛⠛⠋⢸⣿⣧⠀⢀⣠⣤⣶⣾⣿⣿⠟⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⡿⢣⣾⢿⣿⡇⠹⠿⢣⣾⣿⣿⣿⣴⣿⡿⢋⣵⣶⠇⣼⣰⣤⣤⣤⣤⢸⣿⣿⡏⣿⣿⣿⣿⠟⠉⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠙⡇⠀⣼⢫⠚⢿⣿⣿⣿⣿⣿⡿⣏⣥⣷⣿⣻⣿⣿⣿⣿⣼⣿⣿⣧⡿⠟⠋⠀⠀⣀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⠀⣄⣄⡳⣶⣶⣿⣿⣿⡿⢋⠴⢛⠘⣿⣹⡴⣏⠙⠛⠛⠛⢻⣿⣿⣿⠀⢀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣏⣍⢋⣼⣿⠋⠔⠉⢋⣴⣾⣿⣿⡗⠀⢰⣶⡦⡔⡂⣿⣿⣿⡈⠉⠻⠿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣞⢡⢾⠶⣶⣮⣶⣿⣿⠟⠋⠀⠀⠈⠱⢞⣭⠌⣿⣿⣿⣇⣤⣶⣶⡄⣠⣼⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡬⢿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣧⣿⣿⣿⣧⢻⣿⣿⡼⣶⣝⡻⠿⠟⠛⠛⠛⠋⠉⠉⠉⠉⠉⠉⠉⢉⣉⣥⣾
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣮⡸⣿⣿⣿⣯⢿⣿⣷⣹⣿⣿⠇⠀⣀⣤⣤⣤⣶⣶⠶⢛⣩⣵⣾⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠰⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⠿⠿⠿⠷⢹⣿⣿⣿⢺⣿⣿⢇⣿⡏⠀⠀⠘⠿⠛⣋⣥⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⢿⣿⣶⣶⠦⣔⣒⣒⣒⡛⣭⠋⡭⡁⣶⣷⢷⢸⣿⣿⡿⣾⣿⠏⢾⠏⣾⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⢛⣭⣶⣯⣹⣿⠟⣻⣿⢰⢟⣀⣣⣭⣼⣆⢿⡿⢟⣹⢿⣫⣾⠗⢁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⡾⢿⣷⣶⣶⠶⠿⢛⣭⡲⢾⣿⣿⣿⣿⣿⣾⡷⠗⠚⠛⠛⠁⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⢀⠁⠀⠀⠀⠀⠀⣠⠟⣵⣿⣆⠉⠙⠛⠛⠛⠉⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⣀⠀⠀⠀⠀⢸⠀⠀⠀⢀⣴⣿⢫⣾⣿⣿⣿⣷⣦⣄⣀⣀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣶⡆⠀⠈⠀⠀⠀⢸⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⣶⡆⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⣿⣿⣿⠇⠀⡘⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣰⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⣿⣿⣿⠀⢰⠁⠀⠀⢸⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⡿⢡⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣸⣿⣿⣿⠀⡈⠀⠀⠀⢸⣿⣿⣿⠟⢋⣼⣿⣿⣿⣿⣿⣿⢣⣿⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⣿⣿⣿⡟⠀⡇⠀⠀⠀⠸⠟⠋⢁⣴⣿⣿⣿⣿⣿⣿⣿⣳⣿⣿⣿⡇⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⢹⣿⣤⣉⠁⠀⡇⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣸⣿⣟⣁⣀⣀⣇⣀⣀⣀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⣀⣀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
BRAILLE_ART
    echo ''
    sleep 0.2
    echo '  ╔══════════════════════════════════════════════════════════════╗'; sleep 0.1
    printf "  ║   V A U L T  ·  S H I N O B I  ·  K O N O H A      v%-6s║\n" "${VERSION}"; sleep 0.08
    echo '  ╠══════════════════════════════════════════════════════════════╣'; sleep 0.08
    echo '  ║   Code like a Shinobi  ·  Strike Fast  ·  Leave No Trace   ║'; sleep 0.08
    echo '  ║   macOS · Linux · Windows                  EN / Français    ║'; sleep 0.08
    echo '  ╚══════════════════════════════════════════════════════════════╝'
    tput cnorm 2>/dev/null
    echo -e "${N}"
}

# ════════════════════════════════════════════════════════════════════
# OS DETECTION
# ════════════════════════════════════════════════════════════════════
OS=""
PKG_MGR=""
PKG_INSTALL=""

detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            PKG_MGR="brew"
            PKG_INSTALL="brew install"
            ;;
        Linux)
            OS="linux"
            if   command -v apt-get &>/dev/null; then PKG_MGR="apt";    PKG_INSTALL="sudo apt-get install -y"
            elif command -v dnf     &>/dev/null; then PKG_MGR="dnf";    PKG_INSTALL="sudo dnf install -y"
            elif command -v yum     &>/dev/null; then PKG_MGR="yum";    PKG_INSTALL="sudo yum install -y"
            elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"; PKG_INSTALL="sudo pacman -S --noconfirm"
            else PKG_MGR="unknown"; PKG_INSTALL=""; fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo ""
            echo "  Windows detected."
            echo "  This script requires WSL (Windows Subsystem for Linux)."
            echo ""
            echo "  To install WSL:"
            echo "    1. Open PowerShell as Administrator"
            echo "    2. Run: wsl --install"
            echo "    3. Restart your computer"
            echo "    4. Open Ubuntu from the Start menu"
            echo "    5. Run this script again inside Ubuntu"
            echo ""
            exit 1
            ;;
        *)
            err "Unsupported OS: $(uname -s)"
            ;;
    esac
}

# ════════════════════════════════════════════════════════════════════
# LANGUAGE
# ════════════════════════════════════════════════════════════════════
LANG_CODE="en"

select_language() {
    echo ""
    echo "┌────────────────────────────────────────┐"
    echo "│  Language / Langue                     │"
    echo "│  1) English                            │"
    echo "│  2) Français                           │"
    echo "└────────────────────────────────────────┘"
    read -rp "> " _lc
    [[ "${_lc:-1}" == "2" ]] && LANG_CODE="fr" || LANG_CODE="en"
}

# i18n helper — T "key"
T() {
    local k="$1"
    local en="" fr=""
    case "$k" in
        welcome)        en="Vault Setup — Universal Secrets Manager v${VERSION}"
                        fr="Installation Vault — Gestionnaire de Secrets v${VERSION}" ;;
        mode_title)     en="Installation mode"              fr="Mode d'installation" ;;
        mode_dev)       en="1) Development  — quick start, data lost on restart"
                        fr="1) Développement — démarrage rapide, données perdues au redémarrage" ;;
        mode_prod)      en="2) Production   — persistent data, auto-start service"
                        fr="2) Production    — données persistantes, service automatique" ;;
        notif_title)    en="Notification method"            fr="Mode de notification" ;;
        notif_1)        en="1) ntfy  (mobile app)"          fr="1) ntfy  (app mobile)" ;;
        notif_2)        en="2) Email (Apple Mail / sendmail)" fr="2) Email (Apple Mail / sendmail)" ;;
        notif_3)        en="3) Both"                        fr="3) Les deux" ;;
        notif_4)        en="4) None  (screen only)"         fr="4) Aucune (écran uniquement)" ;;
        deps_check)     en="Checking dependencies..."       fr="Vérification des dépendances..." ;;
        deps_missing)   en="Missing packages:"              fr="Paquets manquants :" ;;
        deps_auto_q)    en="Auto-install them? [Y/n]"       fr="Installer automatiquement ? [O/n]" ;;
        deps_manual)    en="Install manually then re-run:"  fr="Installez manuellement puis relancez :" ;;
        deps_ok)        en="All dependencies present"       fr="Toutes les dépendances sont présentes" ;;
        domain_q)       en="Vault domain [vault.local]: "   fr="Domaine Vault [vault.local] : " ;;
        email_q)        en="Recipient email: "              fr="Email du destinataire : " ;;
        sudo_msg)       en="This script needs sudo (port 443 + /etc/hosts)."
                        fr="Ce script nécessite sudo (port 443 + /etc/hosts)." ;;
        uninstall_warn) en="UNINSTALL — will remove Vault, Caddy, ntfy and all data."
                        fr="DÉSINSTALLATION — supprimera Vault, Caddy, ntfy et toutes les données." ;;
        uninstall_q)    en="Type 'yes' to confirm: "        fr="Tapez 'oui' pour confirmer : " ;;
        vault_ok)       en="Vault running"                  fr="Vault démarré" ;;
        caddy_ok)       en="Caddy running"                  fr="Caddy démarré" ;;
        svc_installing) en="Installing as system service..."fr="Installation en service système..." ;;
        svc_done)       en="Service installed — Vault starts automatically at boot"
                        fr="Service installé — Vault démarre automatiquement au boot" ;;
        unseal_warn)    en="Save these unseal keys — Vault is inaccessible without them after restart!"
                        fr="Sauvegardez ces clés ! Sans elles, Vault est inaccessible après redémarrage !" ;;
        ntfy_first)     en="FIRST-TIME ntfy SETUP"          fr="PREMIÈRE CONFIGURATION ntfy" ;;
        ntfy_install)   en="Install the ntfy app on your phone (iOS / Android)"
                        fr="Installez l'app ntfy sur votre téléphone (iOS / Android)" ;;
        ntfy_server)    en="Add server:"                    fr="Ajouter un serveur :" ;;
        ntfy_topic)     en="Subscribe to topic:"            fr="S'abonner au topic :" ;;
        ntfy_rerun)     en="Then re-run this script."       fr="Puis relancez ce script." ;;
        *)              en="$k" fr="$k" ;;
    esac
    [[ "$LANG_CODE" == "fr" ]] && echo "$fr" || echo "$en"
}

# ════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ════════════════════════════════════════════════════════════════════
MISSING_DEPS=()

check_dep() { command -v "$1" &>/dev/null || MISSING_DEPS+=("$1"); }

dep_install_cmd() {
    local dep="$1"
    case "$dep:$OS:$PKG_MGR" in
        vault:macos:*)     echo "brew tap hashicorp/tap && brew install hashicorp/tap/vault" ;;
        vault:linux:apt)   echo "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg && echo \"deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt-get update -q && sudo apt-get install -y vault" ;;
        vault:linux:dnf)   echo "sudo dnf install -y vault" ;;
        vault:linux:pacman)echo "sudo pacman -S --noconfirm vault" ;;
        caddy:macos:*)     echo "brew install caddy" ;;
        caddy:linux:apt)   echo "sudo apt-get install -y debian-keyring apt-transport-https && curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy-stable.list && sudo apt-get update && sudo apt-get install -y caddy" ;;
        caddy:linux:dnf)   echo "sudo dnf install -y caddy" ;;
        docker:macos:*)    echo "Download Docker Desktop: https://www.docker.com/products/docker-desktop/" ;;
        docker:linux:*)    echo "curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker \$USER" ;;
        openssl:macos:*)   echo "brew install openssl" ;;
        openssl:linux:*)   echo "$PKG_INSTALL openssl" ;;
        curl:macos:*)      echo "brew install curl" ;;
        curl:linux:*)      echo "$PKG_INSTALL curl" ;;
        *)                 echo "# see https://repology.org/project/$dep" ;;
    esac
}

check_dependencies() {
    title "$(T deps_check)"
    check_dep vault
    check_dep caddy
    check_dep docker
    check_dep openssl
    check_dep curl

    if [[ ${#MISSING_DEPS[@]} -eq 0 ]]; then
        ok "$(T deps_ok)"; return
    fi

    warn "$(T deps_missing)"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  • $dep"
        echo "    $(dep_install_cmd "$dep")"
    done
    echo ""
    read -rp "$(T deps_auto_q) " _auto
    if [[ "${_auto:-y}" =~ ^[YyOo1]$ ]]; then
        for dep in "${MISSING_DEPS[@]}"; do
            info "Installing $dep..."
            case "$dep:$OS" in
                vault:macos)   brew tap hashicorp/tap 2>/dev/null || true; brew install hashicorp/tap/vault ;;
                vault:linux)   eval "$(dep_install_cmd vault)" ;;
                caddy:macos)   brew install caddy ;;
                caddy:linux)   eval "$(dep_install_cmd caddy)" ;;
                docker:macos)  warn "Install Docker Desktop manually from https://www.docker.com/products/docker-desktop/" ;;
                docker:linux)  curl -fsSL https://get.docker.com | sh ;;
                openssl:macos) brew install openssl ;;
                openssl:linux) eval "$PKG_INSTALL openssl" ;;
                curl:macos)    brew install curl ;;
                curl:linux)    eval "$PKG_INSTALL curl" ;;
            esac
        done
        MISSING_DEPS=()
        ok "$(T deps_ok)"
    else
        err "$(T deps_manual)"
    fi
}

# ════════════════════════════════════════════════════════════════════
# SUDO — ask once upfront, keep alive during the script
# ════════════════════════════════════════════════════════════════════
require_sudo() {
    echo ""
    info "$(T sudo_msg)"
    sudo -v || err "sudo required"
    ( while true; do sudo -v; sleep 50; done ) &
    SUDO_KEEPER=$!
    trap "kill $SUDO_KEEPER 2>/dev/null; true" EXIT
}

# ════════════════════════════════════════════════════════════════════
# MODE + NOTIFICATION SELECTION
# ════════════════════════════════════════════════════════════════════
MODE=""
NOTIFY_CHOICE="4"
NOTIFY_EMAIL=""

select_mode() {
    title "$(T mode_title)"
    echo "  $(T mode_dev)"
    echo "  $(T mode_prod)"
    read -rp "> " _m
    if [[ "${_m:-}" == "2" ]]; then
        MODE="production"
    else
        MODE="development"
    fi
    ok "Mode: ${MODE}"
}

select_notification() {
    title "$(T notif_title)"
    echo "  $(T notif_1)"
    echo "  $(T notif_2)"
    echo "  $(T notif_3)"
    echo "  $(T notif_4)"
    read -rp "> " NOTIFY_CHOICE
    NOTIFY_CHOICE="${NOTIFY_CHOICE:-4}"
    if [[ "$NOTIFY_CHOICE" == "2" || "$NOTIFY_CHOICE" == "3" ]]; then
        read -rp "$(T email_q)" NOTIFY_EMAIL
        [[ -z "$NOTIFY_EMAIL" ]] && err "Email address required"
    fi
}

# ════════════════════════════════════════════════════════════════════
# DOMAIN + HOSTS
# ════════════════════════════════════════════════════════════════════
VAULT_DOMAIN="vault.local"
LOCAL_HOST="localhost"

setup_domain() {
    read -rp "$(T domain_q)" _d
    VAULT_DOMAIN="${_d:-vault.local}"
    ok "Domain: ${VAULT_DOMAIN}"

    LOCAL_HOST=$(scutil --get LocalHostName 2>/dev/null \
              || hostname -s 2>/dev/null \
              || echo "localhost")

    if ! grep -q "$VAULT_DOMAIN" /etc/hosts 2>/dev/null; then
        echo "127.0.0.1 $VAULT_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
        if [[ "$OS" == "macos" ]]; then
            sudo dscacheutil -flushcache
            sudo killall -HUP mDNSResponder 2>/dev/null || true
        else
            sudo systemctl restart systemd-resolved 2>/dev/null || true
        fi
        ok "${VAULT_DOMAIN} → 127.0.0.1"
    fi
}

# ════════════════════════════════════════════════════════════════════
# NTFY
# ════════════════════════════════════════════════════════════════════
NTFY_TOPIC_FILE="$SECURE_DIR/.ntfy-topic"
NTFY_TOPIC=""

setup_ntfy() {
    # Ensure Docker is running
    if ! docker info &>/dev/null 2>&1; then
        [[ "$OS" == "macos" ]] && open -a Docker
        local w=0
        until docker info &>/dev/null 2>&1 || [[ $w -ge 40 ]]; do sleep 2; w=$((w+2)); done
        docker info &>/dev/null || err "Docker not running — start it and re-run"
    fi

    # First-time setup: generate topic and guide user
    if [[ ! -f "$NTFY_TOPIC_FILE" ]]; then
        NTFY_TOPIC="vault-$(openssl rand -hex 16)"
        echo "$NTFY_TOPIC" > "$NTFY_TOPIC_FILE"
        chmod 600 "$NTFY_TOPIC_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  $(T ntfy_first)"
        echo ""
        echo "  1. $(T ntfy_install)"
        echo "     iOS  : https://apps.apple.com/app/ntfy/id1625396347"
        echo "     Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy"
        echo ""
        echo "  2. $(T ntfy_server)"
        echo "     http://${LOCAL_HOST}.local:${NTFY_PORT}"
        echo "     (same WiFi network required)"
        echo ""
        echo "  3. $(T ntfy_topic)"
        echo "     ${NTFY_TOPIC}"
        echo ""
        echo "  4. $(T ntfy_rerun)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi

    NTFY_TOPIC=$(cat "$NTFY_TOPIC_FILE")

    # Start container
    if docker inspect ntfy-vault &>/dev/null 2>&1; then
        local st
        st=$(docker inspect -f '{{.State.Status}}' ntfy-vault 2>/dev/null)
        [[ "$st" != "running" ]] && docker start ntfy-vault > /dev/null
    else
        docker run -d \
            --name ntfy-vault \
            --restart=unless-stopped \
            -p "${NTFY_PORT}:80" \
            -e "NTFY_BASE_URL=http://${LOCAL_HOST}.local:${NTFY_PORT}" \
            binwiederhier/ntfy \
            serve > "$NTFY_LOG" 2>&1
        sleep 2
    fi
    ok "ntfy → http://${LOCAL_HOST}.local:${NTFY_PORT}"
}

# ════════════════════════════════════════════════════════════════════
# CADDY
# ════════════════════════════════════════════════════════════════════
SECRET_PASS=""
PASS_HASH=""
CADDYFILE="$SECURE_DIR/Caddyfile"

setup_caddy_config() {
    SECRET_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)
    PASS_HASH=$(caddy hash-password --plaintext "$SECRET_PASS" 2>/dev/null) \
        || err "Cannot hash password — is caddy installed?"

    cat > "$CADDYFILE" << EOF
{
    local_certs
}

${VAULT_DOMAIN}:${CADDY_PORT} {
    tls internal
    basicauth * {
        vault ${PASS_HASH}
    }
    reverse_proxy localhost:${VAULT_PORT}
}
EOF
    chmod 600 "$CADDYFILE"
}

start_caddy() {
    pgrep -f "caddy run" &>/dev/null && { sudo pkill -f "caddy run"; sleep 1; } || true

    sudo -nE caddy run --config "$CADDYFILE" > "$CADDY_LOG" 2>&1 &
    local caddy_pid=$!
    sleep 3

    if ! kill -0 "$caddy_pid" 2>/dev/null; then
        echo ""; cat "$CADDY_LOG"
        err "Caddy failed to start — see log above"
    fi

    # Trust certificate (macOS only)
    if [[ "$OS" == "macos" ]]; then
        local ca="$HOME/Library/Application Support/Caddy/pki/authorities/local/root.crt"
        if [[ -f "$ca" ]] && ! security verify-cert -c "$ca" &>/dev/null 2>&1; then
            sudo security add-trusted-cert -d -r trustRoot \
                -k /Library/Keychains/System.keychain "$ca" 2>/dev/null \
                && ok "HTTPS certificate trusted" \
                || warn "Certificate trust failed — browser will show a warning (normal on first run)"
        fi
    fi

    ok "$(T caddy_ok) → https://${VAULT_DOMAIN}"
}

# ════════════════════════════════════════════════════════════════════
# VAULT — DEVELOPMENT MODE
# ════════════════════════════════════════════════════════════════════
ROOT_TOKEN=""

start_vault_dev() {
    pgrep -x vault &>/dev/null && { pkill -x vault; sleep 1; } || true

    vault server -dev \
        -dev-listen-address="127.0.0.1:${VAULT_PORT}" \
        > "$VAULT_LOG" 2>&1 &

    local w=0
    until grep -q "Root Token" "$VAULT_LOG" 2>/dev/null || [[ $w -ge 15 ]]; do
        sleep 1; w=$((w+1))
    done

    ROOT_TOKEN=$(grep "Root Token" "$VAULT_LOG" 2>/dev/null | awk '{print $NF}' | tail -1)
    [[ -z "$ROOT_TOKEN" ]] && { cat "$VAULT_LOG"; err "Root token not found"; }
    ok "$(T vault_ok) (dev mode)"
}

# ════════════════════════════════════════════════════════════════════
# VAULT — PRODUCTION MODE
# ════════════════════════════════════════════════════════════════════
VAULT_DATA_DIR="$SECURE_DIR/vault-data"
VAULT_CONFIG_FILE="$SECURE_DIR/vault.hcl"
UNSEAL_KEYS=()

start_vault_prod() {
    mkdir -p "$VAULT_DATA_DIR"
    chmod 700 "$VAULT_DATA_DIR"

    cat > "$VAULT_CONFIG_FILE" << EOF
storage "file" {
  path = "${VAULT_DATA_DIR}"
}

listener "tcp" {
  address     = "127.0.0.1:${VAULT_PORT}"
  tls_disable = "true"
}

api_addr = "http://127.0.0.1:${VAULT_PORT}"
ui       = true
EOF
    chmod 600 "$VAULT_CONFIG_FILE"

    pgrep -x vault &>/dev/null && { pkill -x vault; sleep 2; } || true

    vault server -config="$VAULT_CONFIG_FILE" > "$VAULT_LOG" 2>&1 &
    sleep 3

    export VAULT_ADDR="http://127.0.0.1:${VAULT_PORT}"
    local keys_file="$SECURE_DIR/.vault-keys"

    # Already initialized?
    if vault status 2>/dev/null | grep -q "Initialized.*true"; then
        # Unseal with saved keys
        if [[ -f "$keys_file" ]]; then
            mapfile -t UNSEAL_KEYS < <(grep "Unseal Key" "$keys_file" | awk '{print $NF}')
            ROOT_TOKEN=$(grep "Initial Root Token" "$keys_file" | awk '{print $NF}')
            vault operator unseal "${UNSEAL_KEYS[0]}" > /dev/null 2>&1 || true
            vault operator unseal "${UNSEAL_KEYS[1]}" > /dev/null 2>&1 || true
        else
            warn "Vault initialized but unseal keys not found — you must unseal manually"
        fi
    else
        # First-time init: 3 keys, threshold 2
        local init_output
        init_output=$(vault operator init -key-shares=3 -key-threshold=2 2>/dev/null)
        echo "$init_output" > "$keys_file"
        chmod 600 "$keys_file"

        mapfile -t UNSEAL_KEYS < <(echo "$init_output" | grep "Unseal Key" | awk '{print $NF}')
        ROOT_TOKEN=$(echo "$init_output" | grep "Initial Root Token" | awk '{print $NF}')

        vault operator unseal "${UNSEAL_KEYS[0]}" > /dev/null
        vault operator unseal "${UNSEAL_KEYS[1]}" > /dev/null
    fi

    ok "$(T vault_ok) (production)"
}

# ════════════════════════════════════════════════════════════════════
# SERVICE (auto-start at boot)
# ════════════════════════════════════════════════════════════════════
install_service() {
    title "$(T svc_installing)"
    if [[ "$OS" == "macos" ]]; then
        local plist="$HOME/Library/LaunchAgents/com.vaultsetup.vault.plist"
        cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>Label</key>            <string>com.vaultsetup.vault</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(command -v vault)</string>
        <string>server</string>
        <string>-config=${VAULT_CONFIG_FILE}</string>
    </array>
    <key>RunAtLoad</key>   <true/>
    <key>KeepAlive</key>   <true/>
    <key>StandardOutPath</key>  <string>${VAULT_LOG}</string>
    <key>StandardErrorPath</key><string>${VAULT_LOG}</string>
</dict></plist>
EOF
        launchctl unload "$plist" 2>/dev/null || true
        launchctl load -w "$plist"
    else
        sudo tee /etc/systemd/system/vault.service > /dev/null << EOF
[Unit]
Description=HashiCorp Vault
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$(command -v vault) server -config=${VAULT_CONFIG_FILE}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable vault
        sudo systemctl start vault
    fi
    ok "$(T svc_done)"
}

# ════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ════════════════════════════════════════════════════════════════════
send_notification() {
    local body
    body="$(printf \
"URL   : https://%s\nUser  : vault\nPass  : %s\nToken : %s" \
"$VAULT_DOMAIN" "$SECRET_PASS" "$ROOT_TOKEN")"

    # ntfy
    if [[ "$NOTIFY_CHOICE" == "1" || "$NOTIFY_CHOICE" == "3" ]]; then
        curl -sf \
            -H "Title: Vault 🔐" \
            -H "Priority: high" \
            -H "Tags: key,lock" \
            -d "$body" \
            "http://127.0.0.1:${NTFY_PORT}/${NTFY_TOPIC}" > /dev/null \
            && ok "ntfy notification sent" \
            || warn "ntfy send failed — check $NTFY_LOG"
    fi

    # Email
    if [[ "$NOTIFY_CHOICE" == "2" || "$NOTIFY_CHOICE" == "3" ]]; then
        if [[ "$OS" == "macos" ]]; then
            # Apple Mail via osascript (uses your configured mail account, no password needed)
            local safe="${body//$'\n'/\\n}"
            safe="${safe//\"/\\\"}"
            osascript << APPLESCRIPT 2>/dev/null \
                && ok "Email sent → ${NOTIFY_EMAIL}" \
                || warn "Apple Mail send failed — send manually"
tell application "Mail"
    set m to make new outgoing message with properties {subject:"🔐 Vault — Credentials", content:"${safe}", visible:false}
    tell m
        make new to recipient at end of to recipients with properties {address:"${NOTIFY_EMAIL}"}
    end tell
    send m
end tell
APPLESCRIPT
        elif command -v sendmail &>/dev/null; then
            printf "Subject: 🔐 Vault — Credentials\n\n%s" "$body" \
                | sendmail "$NOTIFY_EMAIL" \
                && ok "Email sent → ${NOTIFY_EMAIL}" \
                || warn "sendmail failed"
        else
            warn "No mail client found (sendmail not installed)"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════════
show_summary() {
    local W="════════════════════════════════════════════════════════════════"
    local w="────────────────────────────────────────────────────────────────"
    echo ""
    echo -e "${G}  ╔${W}╗${N}"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    echo -e "${G}  ║${N}   ✅  ${B}VAULT IS RUNNING${N}                                            ${G}║${N}"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    echo -e "${G}  ╠${w}╣${N}"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    printf  "${G}  ║${N}   🌐  %-12s ${C}https://%-36s${N}  ${G}║${N}\n"  "URL"      "${VAULT_DOMAIN}"
    printf  "${G}  ║${N}   👤  %-12s ${B}%-44s${N}  ${G}║${N}\n"          "Username" "vault"
    printf  "${G}  ║${N}   🔑  %-12s ${Y}%-44s${N}  ${G}║${N}\n"          "Password" "${SECRET_PASS}"
    printf  "${G}  ║${N}   🎫  %-12s ${B}%-44s${N}  ${G}║${N}\n"          "Token"    "${ROOT_TOKEN}"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"

    if [[ "$MODE" == "production" && ${#UNSEAL_KEYS[@]} -gt 0 ]]; then
        echo -e "${G}  ╠${w}╣${N}"
        echo -e "${G}  ║${N}   ${Y}⚠️  $(T unseal_warn)${N}"
        echo -e "${G}  ║${N}                                                                  ${G}║${N}"
        for key in "${UNSEAL_KEYS[@]}"; do
            printf  "${G}  ║${N}      ${Y}•  %-55s${N}  ${G}║${N}\n" "$key"
        done
        printf  "${G}  ║${N}      ${C}saved → %-50s${N}  ${G}║${N}\n" "$SECURE_DIR/.vault-keys"
        echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    fi

    echo -e "${G}  ╠${w}╣${N}"
    printf  "${G}  ║${N}   📄  Vault log  ${C}%-46s${N}  ${G}║${N}\n" "$VAULT_LOG"
    printf  "${G}  ║${N}   📄  Caddy log  ${C}%-46s${N}  ${G}║${N}\n" "$CADDY_LOG"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    printf  "${G}  ║${N}   🗑️   Uninstall  ${B}bash %-40s${N}  ${G}║${N}\n" "$(basename "$0") --uninstall"
    echo -e "${G}  ║${N}                                                                  ${G}║${N}"
    echo -e "${G}  ╚${W}╝${N}"
    echo ""
}

# ════════════════════════════════════════════════════════════════════
# UNINSTALL
# ════════════════════════════════════════════════════════════════════
do_uninstall() {
    echo ""
    warn "$(T uninstall_warn)"
    read -rp "$(T uninstall_q)" _c
    [[ "$_c" != "yes" && "$_c" != "oui" ]] && { echo "Cancelled."; exit 0; }

    pkill -x vault 2>/dev/null || true
    sudo pkill -f "caddy run" 2>/dev/null || true
    docker stop ntfy-vault 2>/dev/null || true
    docker rm   ntfy-vault 2>/dev/null || true

    # Remove /etc/hosts entries added by this script
    if [[ "$OS" == "macos" ]]; then
        sudo sed -i '' '/vault\.local\|vault\.justclemax/d' /etc/hosts 2>/dev/null || true
    else
        sudo sed -i '/vault\.local\|vault\.justclemax/d' /etc/hosts 2>/dev/null || true
    fi

    # Remove launchd service (macOS)
    local plist="$HOME/Library/LaunchAgents/com.vaultsetup.vault.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm -f "$plist"
    fi

    # Remove systemd service (Linux)
    if [[ -f /etc/systemd/system/vault.service ]]; then
        sudo systemctl stop vault 2>/dev/null || true
        sudo systemctl disable vault 2>/dev/null || true
        sudo rm -f /etc/systemd/system/vault.service
        sudo systemctl daemon-reload 2>/dev/null || true
    fi

    rm -rf "$SECURE_DIR"
    ok "Vault uninstalled — all data removed"
    # Supprimer le script lui-même — sauf si on est dans un dépôt git cloné
    if [[ -f "$0" ]]; then
        local _dir
        _dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
        if git -C "$_dir" rev-parse --git-dir &>/dev/null 2>&1; then
            info "Script conservé (dépôt git détecté — supprimez-le manuellement si besoin)"
        else
            rm -f "$0"
            ok "Script supprimé : $0"
        fi
    fi
    exit 0
}

# ════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════
main() {
    detect_os

    # Handle --uninstall before language selection
    if [[ "${1:-}" == "--uninstall" || "${1:-}" == "--desinstaller" ]]; then
        select_language
        do_uninstall
    fi

    select_language
    clear
    show_banner

    step "$(T sudo_msg | sed 's/This script //' | sed 's/Ce script //')"
    require_sudo
    step "$(T deps_check)"
    check_dependencies
    step "$(T mode_title)"
    select_mode
    step "$(T notif_title)"
    select_notification
    step "Domain"
    setup_domain

    mkdir -p "$SECURE_DIR"
    chmod 700 "$SECURE_DIR"

    # ntfy (only if selected)
    if [[ "$NOTIFY_CHOICE" == "1" || "$NOTIFY_CHOICE" == "3" ]]; then
        setup_ntfy
    fi

    setup_caddy_config

    if [[ "$MODE" == "development" ]]; then
        start_vault_dev
    else
        start_vault_prod
        install_service
    fi

    start_caddy
    send_notification
    show_summary
}

main "$@"
