#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Using default values where applicable."
fi

# Define categories and their respective tools
declare -A categories_tools=(
    ["Media Management Tools"]="Plex Jellyfin Sonarr Radarr Readarr Lidarr Prowlarr"
    ["Downloader Tools"]="qBittorrent Transmission NZBGet SABnzbd"
    ["Supporting Tools"]="Bazarr Tautulli FileBot MediaInfo FFmpeg"
    ["File Management"]="rclone UnionFS MergerFS"
    ["Server Utilities"]="Docker Portainer Nginx Fail2Ban"
    ["Other Tools"]="Jackett HandBrake GrafanaLoki"
)

# Prerequisite installation (dependencies)
install_dependencies() {
    echo "Installing common dependencies..."
    sudo apt update
    sudo apt install -y curl wget git gnupg software-properties-common build-essential apt-transport-https unzip ffmpeg
    echo "Dependencies installed!"
}

# Define installation commands for each tool
install_tool() {
    case $1 in
        # Media Management Tools
        "Plex")
            echo "Installing Plex..."
            curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
            echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
            sudo apt update && sudo apt install plexmediaserver -y
            ;;
        "Jellyfin")
            echo "Installing Jellyfin..."
            sudo apt install jellyfin -y
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

        # Downloader Tools
        "qBittorrent")
            echo "Installing qBittorrent..."
            sudo apt install qbittorrent-nox -y
            ;;
        "Transmission")
            echo "Installing Transmission..."
            sudo apt install transmission-daemon -y
            ;;
        "NZBGet")
            echo "Installing NZBGet..."
            sudo apt install nzbget -y
            ;;
        "SABnzbd")
            echo "Installing SABnzbd..."
            sudo apt install sabnzbdplus -y
            ;;

        # Supporting Tools
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
            sudo apt install filebot -y
            ;;
        "MediaInfo")
            echo "Installing MediaInfo..."
            sudo apt install mediainfo -y
            ;;
        "FFmpeg")
            echo "Installing FFmpeg..."
            sudo apt install ffmpeg -y
            ;;

        # File Management
        "rclone")
            echo "Installing rclone..."
            curl https://rclone.org/install.sh | sudo bash
            ;;
        "UnionFS")
            echo "Installing UnionFS..."
            sudo apt install unionfs-fuse -y
            ;;
        "MergerFS")
            echo "Installing MergerFS..."
            sudo apt install mergerfs -y
            ;;

        # Server Utilities
        "Docker")
            echo "Installing Docker..."
            sudo apt install docker.io -y
            ;;
        "Portainer")
            echo "Installing Portainer..."
            sudo docker run -d -p "${DOCKER_PORT:-9000}":9000 portainer/portainer-ce
            ;;
        "Nginx")
            echo "Installing Nginx..."
            sudo apt install nginx -y
            ;;
        "Fail2Ban")
            echo "Installing Fail2Ban..."
            sudo apt install fail2ban -y
            ;;

        # Other Tools
        "Jackett")
            echo "Installing Jackett..."
            bash <(curl -s https://wiki.servarr.com/jackett/installation/linux)
            ;;
        "HandBrake")
            echo "Installing HandBrake..."
            sudo apt install handbrake -y
            ;;
        "GrafanaLoki")
            echo "Installing Grafana Loki..."
            sudo apt install grafana-loki -y
            ;;

        *) echo "Installation for $1 is not yet implemented." ;;
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
install_dependencies  # Install common dependencies

while true; do
    display_categories
    read -rp "Enter your choice: " category_choice
    if [[ $category_choice -eq 0 ]]; then
        echo "Exiting installer. Goodbye!"
        break
    fi

    # Get category name from choice
    category_name=$(echo "${!categories_tools[@]}" | awk -v n="$category_choice" '{print $n}')
    if [[ -z "$category_name" ]]; then
        echo "Invalid choice. Try again."
        continue
    fi

    # Display tools in the chosen category
    display_tools "$category_name"
    read -rp "Enter tool numbers to install (space-separated): " tool_choices
    if [[ $tool_choices == "0" ]]; then
        continue
    fi

    # Install selected tools
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
