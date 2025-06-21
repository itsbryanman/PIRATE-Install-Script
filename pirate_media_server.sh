#!/bin/bash

# P.I.R.A.T.E. Media Server Install Script
#
# This script automates the setup of a comprehensive media server environment.
#
# Author: Gemini
# Version: 2.0

set -o errexit
set -o nounset
set -o pipefail

# --- Configuration ---

# Log file for the script's output
LOG_FILE="/var/log/pirate_media_server.log"

# --- Helper Functions ---

# Log a message to the console and the log file
log() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ${message}" | tee -a "${LOG_FILE}"
}

# Log an error message and exit the script
error() {
    local message="$1"
    log "ERROR: ${message}"
    exit 1
}

# Check if the script is being run with root privileges
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "This script must be run as root. Please use sudo."
    fi
}

# Detect the Linux distribution and package manager
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO=$ID
    else
        error "Unsupported distribution. Exiting."
    fi

    case $DISTRO in
        ubuntu|debian)
            PKG_MANAGER="apt"
            UPDATE_CMD="sudo apt-get update"
            INSTALL_CMD="sudo apt-get install -y"
            UNINSTALL_CMD="sudo apt-get remove -y"
            ;;
        fedora|rhel|centos)
            PKG_MANAGER="dnf"
            UPDATE_CMD="sudo dnf update -y"
            INSTALL_CMD="sudo dnf install -y"
            UNINSTALL_CMD="sudo dnf remove -y"
            ;;
        arch)
            PKG_MANAGER="pacman"
            UPDATE_CMD="sudo pacman -Syu --noconfirm"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            UNINSTALL_CMD="sudo pacman -Rns --noconfirm"
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            ;;
    esac
}

# Install the required dependencies
install_dependencies() {
    log "Installing common dependencies for ${DISTRO}..."
    ${UPDATE_CMD}
    ${INSTALL_CMD} curl wget git gnupg build-essential unzip ffmpeg whiptail
    log "Dependencies installed successfully."
}

# --- Tool Installation and Uninstallation Functions ---

# The following functions handle the installation and uninstallation of each tool.
# Each function should:
# 1. Add the necessary repository (if applicable).
# 2. Install the tool using the appropriate package manager.
# 3. Configure the tool (if necessary).
# 4. Log the installation/uninstallation status.

install_jellyfin() {
    log "Installing Jellyfin..."
    case $DISTRO in
        ubuntu|debian)
            wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
            echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
            ${UPDATE_CMD}
            ${INSTALL_CMD} jellyfin
            ;;
        *)
            error "Jellyfin installation is not supported on this distribution."
            ;;
    esac
    log "Jellyfin installed successfully."
}

uninstall_jellyfin() {
    log "Uninstalling Jellyfin..."
    ${UNINSTALL_CMD} jellyfin
    rm -f /etc/apt/sources.list.d/jellyfin.list
    log "Jellyfin uninstalled successfully."
}

# Add more installation and uninstallation functions for other tools here...

# --- Main Menu Functions ---

show_main_menu() {
    whiptail --title "P.I.R.A.T.E. Media Server" --menu "Choose an option:" 20 78 10 \
        "1" "Install Tools" \
        "2" "Uninstall Tools" \
        "3" "Update Tools" \
        "4" "Exit" 3>&1 1>&2 2>&3
}

show_install_menu() {
    whiptail --title "Install Tools" --checklist "Choose tools to install:" 20 78 10 \
        "Jellyfin" "Media server" OFF \
        "Plex" "Media server" OFF \
        "Sonarr" "TV Shows manager" OFF \
        "Radarr" "Movies manager" OFF \
        "Lidarr" "Music manager" OFF \
        "Prowlarr" "Indexer manager" OFF \
        "qBittorrent" "Torrent client" OFF \
        "Docker" "Containerization" OFF \
        "Portainer" "Docker management" OFF 3>&1 1>&2 2>&3
}

show_uninstall_menu() {
    whiptail --title "Uninstall Tools" --checklist "Choose tools to uninstall:" 20 78 10 \
        "Jellyfin" "Media server" OFF \
        "Plex" "Media server" OFF \
        "Sonarr" "TV Shows manager" OFF \
        "Radarr" "Movies manager" OFF \
        "Lidarr" "Music manager" OFF \
        "Prowlarr" "Indexer manager" OFF \
        "qBittorrent" "Torrent client" OFF \
        "Docker" "Containerization" OFF \
        "Portainer" "Docker management" OFF 3>&1 1>&2 2>&3
}

# --- Main Script Logic ---

main() {
    check_root
    detect_distro
    install_dependencies

    while true; do
        main_menu_choice=$(show_main_menu)
        case $main_menu_choice in
            1)
                install_menu_choice=$(show_install_menu)
                if [ -n "$install_menu_choice" ]; then
                    for tool in $install_menu_choice; do
                        tool_name=$(echo "$tool" | tr -d '"')
                        "install_${tool_name,,}"
                    done
                fi
                ;;
            2)
                uninstall_menu_choice=$(show_uninstall_menu)
                if [ -n "$uninstall_menu_choice" ]; then
                    for tool in $uninstall_menu_choice; do
                        tool_name=$(echo "$tool" | tr -d '"')
                        "uninstall_${tool_name,,}"
                    done
                fi
                ;;
            3)
                log "Updating all tools..."
                ${UPDATE_CMD}
                log "All tools updated successfully."
                ;;
            4)
                log "Exiting."
                exit 0
                ;;
            *)
                log "Invalid option. Exiting."
                exit 1
                ;;
        esac
    done
}

# --- Script Entry Point ---
main
