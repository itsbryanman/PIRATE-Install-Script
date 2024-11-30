#!/bin/bash

set -euo pipefail

# ASCII Art Header
printf "\033c"
echo "===================================================="
echo "     ____  _ __   __   ___    ____ ___   ______     "
echo "    / __ \\(_) /  / /  /   |  / __ )__ \\ / ____/     "
echo "   / /_/ / / /  / /  / /| | / __  /_/ // /          "
echo "  / _, _/ / /__/ /  / ___ |/ /_/ / __// /___        "
echo " /_/ |_/_/____/_/  /_/  |_/_____/____/\\____/        "
echo "===================================================="
echo "Welcome to PIRATE (Platform Integration and Resource"
echo "Automation for Tracking and Enrichment)."
echo "===================================================="
echo

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Using default values where applicable."
fi

# Detect Linux distribution and package manager
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Unsupported distribution. Exiting."
        exit 1
    fi

    case $DISTRO in
        ubuntu|debian)
            PKG_MANAGER="apt"
            UPDATE_CMD="sudo apt update"
            INSTALL_CMD="sudo apt install -y"
            ;;
        fedora|rhel|centos)
            PKG_MANAGER="dnf"
            UPDATE_CMD="sudo dnf update -y"
            INSTALL_CMD="sudo dnf install -y"
            ;;
        arch)
            PKG_MANAGER="pacman"
            UPDATE_CMD="sudo pacman -Syu --noconfirm"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            ;;
        *)
            echo "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Install prerequisites based on detected distribution
install_dependencies() {
    echo "Installing common dependencies for $DISTRO..."
    $UPDATE_CMD
    $INSTALL_CMD curl wget git gnupg build-essential unzip ffmpeg whiptail
    echo "Dependencies installed!"
}

# Add repository logic for Debian/Ubuntu
add_repository() {
    local tool=$1
    case $tool in
        "Jellyfin")
            echo "Adding repository for Jellyfin..."
            wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
            echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
            $UPDATE_CMD
            ;;
        "Plex")
            echo "Adding repository for Plex..."
            curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
            echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
            $UPDATE_CMD
            ;;
        "Sonarr"|"Radarr"|"Lidarr"|"Readarr"|"Prowlarr")
            echo "Adding repository for $tool..."
            wget -O - https://apt.sonarr.tv/sonarr.asc | sudo apt-key add -
            echo "deb https://apt.sonarr.tv/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/$tool.list
            $UPDATE_CMD
            ;;
        *)
            echo "No additional repository needed for $tool."
            ;;
    esac
}

# Install the selected tools
install_tool() {
    local tool=$1
    add_repository "$tool"  # Add repository for Debian/Ubuntu if needed

    case $tool in
        "Jellyfin")
            echo "Installing Jellyfin..."
            $INSTALL_CMD jellyfin
            ;;
        "Plex")
            echo "Installing Plex..."
            $INSTALL_CMD plexmediaserver
            ;;
        "Sonarr"|"Radarr"|"Readarr"|"Lidarr"|"Prowlarr")
            echo "Installing $tool..."
            bash <(curl -s https://wiki.servarr.com/$tool/installation/linux)
            ;;
        "qBittorrent")
            echo "Installing qBittorrent..."
            $INSTALL_CMD qbittorrent-nox
            ;;
        "Transmission")
            echo "Installing Transmission..."
            $INSTALL_CMD transmission-daemon
            ;;
        "NZBGet")
            echo "Installing NZBGet..."
            $INSTALL_CMD nzbget
            ;;
        "SABnzbd")
            echo "Installing SABnzbd..."
            $INSTALL_CMD sabnzbdplus
            ;;
        "Bazarr")
            echo "Installing Bazarr..."
            bash <(curl -s https://wiki.servarr.com/bazarr/installation/linux)
            ;;
        "Docker")
            echo "Installing Docker..."
            $INSTALL_CMD docker.io
            ;;
        "Portainer")
            echo "Installing Portainer..."
            sudo docker run -d -p 9000:9000 portainer/portainer-ce
            ;;
        "Jackett")
            echo "Installing Jackett..."
            bash <(curl -s https://wiki.servarr.com/jackett/installation/linux)
            ;;
        *)
            echo "Installation logic for $tool is not yet implemented."
            ;;
    esac
}

# Display tool selection menu
select_tools() {
    local options=("Jellyfin" "Media server" OFF
                   "Plex" "Media server" OFF
                   "Sonarr" "TV Shows manager" OFF
                   "Radarr" "Movies manager" OFF
                   "Lidarr" "Music manager" OFF
                   "Prowlarr" "Indexer manager" OFF
                   "qBittorrent" "Torrent client" OFF
                   "Docker" "Containerization" OFF
                   "Portainer" "Docker management" OFF)

    selected_tools=$(whiptail --title "Select Tools to Install" \
        --checklist "Use space to select tools:" 20 70 10 "${options[@]}" 3>&1 1>&2 2>&3)

    echo "$selected_tools"
}

# Main script logic
detect_distro
install_dependencies
selected_tools=$(select_tools)

echo "Installing selected tools..."
for tool in $selected_tools; do
    install_tool "$(echo $tool | tr -d '"')"  # Remove quotes from whiptail output
done

echo "Installation completed successfully!"
