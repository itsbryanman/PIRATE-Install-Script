#!/bin/bash

# Load environment variables from .env file
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
    $INSTALL_CMD curl wget git gnupg build-essential unzip ffmpeg
    echo "Dependencies installed!"
}

# Define installation commands for each tool
install_tool() {
    case $1 in
        "Plex")
            echo "Installing Plex..."
            curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
            echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
            $UPDATE_CMD
            $INSTALL_CMD plexmediaserver
            ;;
        "Jellyfin")
            echo "Installing Jellyfin..."
            $INSTALL_CMD jellyfin
            ;;
        "Sonarr")
            echo "Installing Sonarr..."
            bash <(curl -s https://wiki.servarr.com/sonarr/installation/linux)
            ;;
        "Radarr")
            echo "Installing Radarr..."
            bash <(curl -s https://wiki.servarr.com/radarr/installation/linux)
            ;;
        "Readarr")
            echo "Installing Readarr..."
            bash <(curl -s https://wiki.servarr.com/readarr/installation/linux)
            ;;
        "Lidarr")
            echo "Installing Lidarr..."
            bash <(curl -s https://wiki.servarr.com/lidarr/installation/linux)
            ;;
        "Prowlarr")
            echo "Installing Prowlarr..."
            bash <(curl -s https://wiki.servarr.com/prowlarr/installation/linux)
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
        "Tautulli")
            echo "Installing Tautulli..."
            bash <(curl -s https://wiki.tautulli.com/install)
            ;;
        "FileBot")
            echo "Installing FileBot..."
            $INSTALL_CMD filebot
            ;;
        "MediaInfo")
            echo "Installing MediaInfo..."
            $INSTALL_CMD mediainfo
            ;;
        "FFmpeg")
            echo "Installing FFmpeg..."
            $INSTALL_CMD ffmpeg
            ;;
        "rclone")
            echo "Installing rclone..."
            curl https://rclone.org/install.sh | sudo bash
            ;;
        "UnionFS")
            echo "Installing UnionFS..."
            $INSTALL_CMD unionfs-fuse
            ;;
        "MergerFS")
            echo "Installing MergerFS..."
            $INSTALL_CMD mergerfs
            ;;
        "Docker")
            echo "Installing Docker..."
            $INSTALL_CMD docker.io
            ;;
        "Portainer")
            echo "Installing Portainer..."
            sudo docker run -d -p "${DOCKER_PORT:-9000}":9000 portainer/portainer-ce
            ;;
        "Nginx")
            echo "Installing Nginx..."
            $INSTALL_CMD nginx
            ;;
        "Fail2Ban")
            echo "Installing Fail2Ban..."
            $INSTALL_CMD fail2ban
            ;;
        "Jackett")
            echo "Installing Jackett..."
            bash <(curl -s https://wiki.servarr.com/jackett/installation/linux)
            ;;
        "HandBrake")
            echo "Installing HandBrake..."
            $INSTALL_CMD handbrake
            ;;
        "GrafanaLoki")
            echo "Installing Grafana Loki..."
            $INSTALL_CMD grafana-loki
            ;;
        *)
            echo "Installation for $1 is not yet implemented."
            ;;
    esac
}

# Display categories
display_categories() {
    echo "Select a category:"
    local i=1
    for category in "${!categories_tools[@]}"; do
        echo "$i. $category"
        ((i++))
    done
    echo "0. Exit"
}

# Display tools within a category
display_tools() {
    local category="$1"
    echo "Select tools to install from $category (space-separated numbers):"
    local tools=(${categories_tools[$category]})
    for i in "${!tools[@]}"; do
        echo "$((i+1)). ${tools[$i]}"
    done
    echo "0. Back to categories"
}

# Main script
detect_distro
install_dependencies

while true; do
    display_categories
    read -rp "Enter your choice: " category_choice
    if [[ $category_choice -eq 0 ]]; then
        echo "Exiting installer. Goodbye!"
        break
    fi

    category_name=$(echo "${!categories_tools[@]}" | awk -v n="$category_choice" '{print $n}')
    if [[ -z "$category_name" ]]; then
        echo "Invalid choice. Try again."
        continue
    fi

    display_tools "$category_name"
    read -rp "Enter tool numbers to install (space-separated): " tool_choices
    if [[ $tool_choices == "0" ]]; then
        continue
    fi

    tools=(${categories_tools[$category_name]})
    for tool_num in $tool_choices; do
        tool_name="${tools[$((tool_num-1))]}"
        if [[ -n "$tool_name" ]]; then
            install_tool "$tool_name"
        else
            echo "Invalid tool number: $tool_num"
        fi
    done
done
