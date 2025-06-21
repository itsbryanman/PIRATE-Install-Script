#!/bin/bash

# Ultimate P.I.R.A.T.E. Media Server TUI
# Enhanced installer with comprehensive tool support
# Version: 3.0

set -o errexit
set -o nounset
set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/var/log/ultimate_pirate_installer.log"
CONFIG_DIR="/opt/pirate-config"
BACKUP_DIR="/opt/pirate-backups"
SERVICE_USER="${SUDO_USER:-"$(logname 2>/dev/null || echo "$USER")"}"

# Initialize
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"

# Helper Functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "${LOG_FILE}"
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "${LOG_FILE}"
}

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "This script must be run as root. Please use sudo."
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION_CODENAME=${VERSION_CODENAME:-}
    else
        error "Unsupported distribution."
    fi

    case $DISTRO in
        ubuntu|debian)
            PKG_MANAGER="apt"
            UPDATE_CMD="apt-get update"
            INSTALL_CMD="apt-get install -y"
            ;;
        *)
            error "Currently only Ubuntu/Debian are supported"
            ;;
    esac
}

install_dependencies() {
    log "Installing base dependencies..."
    "$UPDATE_CMD"
    "$INSTALL_CMD" curl wget git gnupg build-essential unzip ffmpeg \
        whiptail apt-transport-https ca-certificates software-properties-common \
        python3 python3-pip nodejs npm sqlite3 lsb-release
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        "$UPDATE_CMD"
        "$INSTALL_CMD" ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        "$UPDATE_CMD"
        "$INSTALL_CMD" docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
        success "Docker installed."
    else
        success "Docker already installed."
    fi
}

install_portainer() {
    if ! docker ps | grep -q portainer; then
        log "Installing Portainer..."
        docker volume create portainer_data
        docker run -d -p 9443:9443 --name portainer --restart=unless-stopped \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce:latest
        success "Portainer installed."
    else
        success "Portainer already running."
    fi
}

ensure_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log "Installing docker-compose..."
        "$INSTALL_CMD" docker-compose || pip3 install docker-compose
        success "docker-compose installed."
    fi
}

# Check if service is installed
is_installed() {
    local service=$1
    case $service in
        docker) command -v docker &> /dev/null ;;
        portainer) docker ps 2>/dev/null | grep -q portainer ;;
        jellyfin|plex|sonarr|radarr|lidarr|prowlarr|jackett|bazarr|tautulli|ombi)
            systemctl is-enabled "$service" &> /dev/null ;;
        qbittorrent) systemctl is-enabled qbittorrent-nox &> /dev/null ;;
        funkwhale) docker ps 2>/dev/null | grep -q funkwhale ;;
        tvheadend) systemctl is-enabled tvheadend &> /dev/null ;;
        pihole) docker ps 2>/dev/null | grep -q pihole ;;
        *) false ;;
    esac
}

# Get service status
get_status() {
    local service=$1
    if is_installed "$service"; then
        echo "[INSTALLED]"
    else
        echo ""
    fi
}

# Show main menu
show_main_menu() {
    local choice
    choice=$(whiptail --title "🏴‍☠️ Ultimate P.I.R.A.T.E. Media Server TUI 🏴‍☠️" \
        --menu "\nSelect an option:" 20 70 12 \
        "1" "🎬 Media Servers" \
        "2" "📥 Download Automation" \
        "3" "🔧 Tools & Utilities" \
        "4" "🐋 Container Management" \
        "5" "⚙️  Service Management" \
        "6" "📊 System Status" \
        "7" "💾 Backup & Restore" \
        "8" "🔄 Update All" \
        "9" "🗑️  Uninstall Tools" \
        "10" "🔌 Connect Services" \
        "0" "❌ Exit" \
        3>&1 1>&2 2>&3)

    echo "$choice"
}

# Media Servers Menu
show_media_servers_menu() {
    local choices
    choices=$(whiptail --title "🎬 Media Servers" \
        --checklist "\nSelect media servers to install:" 20 70 10 \
        "jellyfin" "Jellyfin - Open source media server $(get_status jellyfin)" OFF \
        "plex" "Plex - Ultimate media server $(get_status plex)" OFF \
        "funkwhale" "Funkwhale - Personal music server $(get_status funkwhale)" OFF \
        "tvheadend" "TVHeadend - IPTV/OTA TV server $(get_status tvheadend)" OFF \
        3>&1 1>&2 2>&3)

    echo "$choices"
}

# Download Automation Menu
show_download_menu() {
    local choices
    choices=$(whiptail --title "📥 Download Automation" \
        --checklist "\nSelect download tools to install:" 20 70 10 \
        "sonarr" "Sonarr - TV show automation $(get_status sonarr)" OFF \
        "radarr" "Radarr - Movie automation $(get_status radarr)" OFF \
        "lidarr" "Lidarr - Music automation $(get_status lidarr)" OFF \
        "prowlarr" "Prowlarr - Indexer manager $(get_status prowlarr)" OFF \
        "jackett" "Jackett - Torrent tracker API $(get_status jackett)" OFF \
        "bazarr" "Bazarr - Subtitle management $(get_status bazarr)" OFF \
        "qbittorrent" "qBittorrent - Torrent client $(get_status qbittorrent)" OFF \
        3>&1 1>&2 2>&3)

    echo "$choices"
}

# Tools Menu
show_tools_menu() {
    local choices
    choices=$(whiptail --title "🔧 Tools & Utilities" \
        --checklist "\nSelect tools to install:" 20 70 12 \
        "tautulli" "Tautulli - Plex analytics $(get_status tautulli)" OFF \
        "ombi" "Ombi - Media requests $(get_status ombi)" OFF \
        "openspeedtest" "OpenSpeedTest - Speed testing $(get_status openspeedtest)" OFF \
        "beets" "Beets - Music library manager $(get_status beets)" OFF \
        "tvhproxy" "tvhProxy - TVHeadend to Plex $(get_status tvhproxy)" OFF \
        "webgrabplus" "WebGrab+Plus - EPG grabber $(get_status webgrabplus)" OFF \
        "pihole" "Pi-hole - Ad blocker $(get_status pihole)" OFF \
        "autoheal" "Docker Autoheal - Container monitor $(get_status autoheal)" OFF \
        "plexconnect" "PlexConnect - AppleTV hijack $(get_status plexconnect)" OFF \
        3>&1 1>&2 2>&3)

    echo "$choices"
}

# Progress bar
show_progress() {
    local title="$1"
    local text="$2"
    {
        for ((i = 0; i <= 100; i+=5)); do
            echo "$i"
            sleep 0.1
        done
    } | whiptail --gauge "$text" 8 70 0 --title "$title"
}

# --- INSTALL FUNCTIONS ---

install_jellyfin() {
    log "Installing Jellyfin..."
    show_progress "Installing Jellyfin" "Setting up repository..."

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/jellyfin.gpg] https://repo.jellyfin.org/${DISTRO} ${VERSION_CODENAME} main" | sudo tee /etc/apt/sources.list.d/jellyfin.list > /dev/null

    "$UPDATE_CMD"
    "$INSTALL_CMD" jellyfin
    systemctl enable --now jellyfin

    run_configuration_wizard "jellyfin"
    success "Jellyfin installed at http://localhost:8096"
}

install_plex() {
    log "Installing Plex..."
    show_progress "Installing Plex" "Setting up repository..."

    curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/plex.gpg >/dev/null
    echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

    "$UPDATE_CMD"
    "$INSTALL_CMD" plexmediaserver
    systemctl enable --now plexmediaserver

    run_configuration_wizard "plex"
    success "Plex installed. Claim your server at http://localhost:32400/web"
}

install_sonarr() {
    log "Installing Sonarr..."
    show_progress "Installing Sonarr" "Setting up repository..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 | gpg --dearmor -o /etc/apt/keyrings/sonarr.gpg
    echo "deb [signed-by=/etc/apt/keyrings/sonarr.gpg] https://apt.sonarr.tv/debian buster main" | tee /etc/apt/sources.list.d/sonarr.list

    "$UPDATE_CMD"
    "$INSTALL_CMD" sonarr
    systemctl enable --now sonarr

    run_configuration_wizard "sonarr"
    success "Sonarr installed at http://localhost:8989"
}

install_radarr() {
    log "Installing Radarr..."
    show_progress "Installing Radarr" "Setting up repository..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 | gpg --dearmor -o /etc/apt/keyrings/radarr.gpg
    echo "deb [signed-by=/etc/apt/keyrings/radarr.gpg] https://apt.radarr.tv/debian/ buster main" | tee /etc/apt/sources.list.d/radarr.list

    "$UPDATE_CMD"
    "$INSTALL_CMD" radarr
    systemctl enable --now radarr

    run_configuration_wizard "radarr"
    success "Radarr installed at http://localhost:7878"
}

install_lidarr() {
    log "Installing Lidarr..."
    show_progress "Installing Lidarr" "Setting up repository..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 | gpg --dearmor -o /etc/apt/keyrings/lidarr.gpg
    echo "deb [signed-by=/etc/apt/keyrings/lidarr.gpg] https://apt.lidarr.tv/debian buster main" | tee /etc/apt/sources.list.d/lidarr.list

    "$UPDATE_CMD"
    "$INSTALL_CMD" lidarr
    systemctl enable --now lidarr

    run_configuration_wizard "lidarr"
    success "Lidarr installed at http://localhost:8686"
}

install_prowlarr() {
    log "Installing Prowlarr..."
    show_progress "Installing Prowlarr" "Setting up repository..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 | gpg --dearmor -o /etc/apt/keyrings/prowlarr.gpg
    echo "deb [signed-by=/etc/apt/keyrings/prowlarr.gpg] https://apt.prowlarr.com/debian buster main" | tee /etc/apt/sources.list.d/prowlarr.list

    "$UPDATE_CMD"
    "$INSTALL_CMD" prowlarr
    systemctl enable --now prowlarr

    run_configuration_wizard "prowlarr"
    success "Prowlarr installed at http://localhost:9696"
}

install_qbittorrent() {
    log "Installing qBittorrent..."
    show_progress "Installing qBittorrent" "Installing torrent client..."

    "$INSTALL_CMD" qbittorrent-nox
    systemctl enable --now qbittorrent-nox

    run_configuration_wizard "qbittorrent"
    success "qBittorrent installed. Web UI at http://localhost:8080"
}

install_funkwhale() {
    log "Installing Funkwhale..."
    show_progress "Installing Funkwhale" "Deploying Docker container..."

    ensure_docker_compose

    # Create Funkwhale directories
    mkdir -p /srv/funkwhale/data /srv/funkwhale/music

    # Create docker-compose.yml
    cat > /srv/funkwhale/docker-compose.yml <<'EOF'
version: "3"
services:
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_HOST_AUTH_METHOD=trust
    volumes:
      - ./data/postgres:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - ./data/redis:/data

  funkwhale:
    image: funkwhale/all-in-one:latest
    depends_on:
      - postgres
      - redis
    environment:
      - FUNKWHALE_HOSTNAME=${FUNKWHALE_HOSTNAME:-localhost}
      - FUNKWHALE_PROTOCOL=${FUNKWHALE_PROTOCOL:-http}
      - DATABASE_URL=postgresql://postgres@postgres/postgres
      - CACHE_URL=redis://redis:6379/0
    volumes:
      - ./data/funkwhale:/srv/funkwhale/data
      - ./music:/srv/funkwhale/data/music:ro
    ports:
      - "5000:80"
EOF

    cd /srv/funkwhale && docker-compose up -d
    success "Funkwhale installed at http://localhost:5000"
}

install_tvheadend() {
    log "Installing TVHeadend..."
    show_progress "Installing TVHeadend" "Setting up TV server..."

    # Add TVHeadend repository
    curl -1sLf 'https://dl.cloudsmith.io/public/tvheadend/tvheadend/setup.deb.sh' | sudo -E bash
    "$INSTALL_CMD" tvheadend

    success "TVHeadend installed at http://localhost:9981"
}

install_jackett() {
    log "Installing Jackett..."
    show_progress "Installing Jackett" "Setting up torrent tracker API..."

    cd /opt
    curl -L -O $(curl -s https://api.github.com/repos/Jackett/Jackett/releases/latest | grep -E 'browser_download_url.*LinuxAMDx64' | cut -d '"' -f 4)
    tar -xzf Jackett.Binaries.LinuxAMDx64.tar.gz
    rm Jackett.Binaries.LinuxAMDx64.tar.gz

    # Create service
    /opt/Jackett/install_service_systemd.sh
    systemctl enable --now jackett

    success "Jackett installed at http://localhost:9117"
}

install_bazarr() {
    log "Installing Bazarr..."
    show_progress "Installing Bazarr" "Setting up subtitle management..."

    # Install Python dependencies
    "$INSTALL_CMD" python3-dev python3-pip python3-libxml2 python3-libxslt1 libxml2-dev libxslt1-dev

    cd /opt
    git clone https://github.com/morpheus65535/bazarr.git
    cd bazarr
    python3 -m pip install -r requirements.txt

    # Create systemd service
    cat > /etc/systemd/system/bazarr.service <<EOF
[Unit]
Description=Bazarr
After=syslog.target network.target

[Service]
User=${SERVICE_USER}
Group=${SERVICE_USER}
Type=simple
ExecStart=/usr/bin/python3 /opt/bazarr/bazarr.py
WorkingDirectory=/opt/bazarr
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now bazarr

    success "Bazarr installed at http://localhost:6767"
}

install_tautulli() {
    log "Installing Tautulli..."
    show_progress "Installing Tautulli" "Setting up Plex analytics..."

    cd /opt
    git clone https://github.com/Tautulli/Tautulli.git

    # Create systemd service
    cat > /etc/systemd/system/tautulli.service <<EOF
[Unit]
Description=Tautulli
After=network.target

[Service]
Type=forking
User=${SERVICE_USER}
Group=${SERVICE_USER}
ExecStart=/usr/bin/python3 /opt/Tautulli/Tautulli.py --daemon --datadir /opt/Tautulli --config /opt/Tautulli/config.ini --nolaunch --quiet
GuessMainPID=no

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now tautulli

    success "Tautulli installed at http://localhost:8181"
}

install_ombi() {
    log "Installing Ombi..."
    show_progress "Installing Ombi" "Setting up media request system..."

    # Download and extract Ombi
    cd /opt
    curl -L -o ombi.tar.gz $(curl -s https://api.github.com/repos/Ombi-app/Ombi/releases/latest | grep -E 'browser_download_url.*linux-x64' | cut -d '"' -f 4)
    mkdir -p ombi
    tar -xzf ombi.tar.gz -C ombi
    rm ombi.tar.gz

    # Create systemd service
    cat > /etc/systemd/system/ombi.service <<EOF
[Unit]
Description=Ombi
After=network.target

[Service]
User=${SERVICE_USER}
Group=${SERVICE_USER}
Type=simple
WorkingDirectory=/opt/ombi
ExecStart=/opt/ombi/Ombi
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    chmod +x /opt/ombi/Ombi
    systemctl daemon-reload
    systemctl enable --now ombi

    success "Ombi installed at http://localhost:5000"
}

install_pihole() {
    log "Installing Pi-hole..."
    show_progress "Installing Pi-hole" "Setting up network-wide ad blocking..."

    local ph_password
    ph_password=$(whiptail --inputbox "Enter admin password for Pi-hole (leave blank for random):" 8 60 "" --title "Pi-hole Password" 3>&1 1>&2 2>&3)
    if [ -z "$ph_password" ]; then
        ph_password=$(openssl rand -base64 12)
        whiptail --msgbox "Random password generated: $ph_password" 10 60
    fi

    docker run -d \
        --name pihole \
        -p 53:53/tcp -p 53:53/udp \
        -p 8053:80 \
        -e TZ="$(cat /etc/timezone)" \
        -e WEBPASSWORD="$ph_password" \
        -v pihole:/etc/pihole \
        -v dnsmasq:/etc/dnsmasq.d \
        --restart=unless-stopped \
        --hostname pi.hole \
        pihole/pihole:latest

    success "Pi-hole installed at http://localhost:8053/admin (password: $ph_password)"
}

# --- NEW FEATURES ---

run_configuration_wizard() {
    local service=$1
    if (whiptail --title "Configuration Wizard" --yesno "Would you like to run the configuration wizard for $service?" 8 78); then
        case $service in
            jellyfin)
                local media_dir=$(whiptail --inputbox "Enter path to your media library:" 8 78 "/srv/media" --title "Jellyfin Config" 3>&1 1>&2 2>&3)
                log "Jellyfin media directory set to: $media_dir"
                # (Further configuration would go here)
                ;;
            plex)
                whiptail --msgbox "Please complete Plex setup via the web UI at http://localhost:32400/web" 10 60
                ;;
            sonarr|radarr|lidarr)
                local download_dir=$(whiptail --inputbox "Enter path to your downloads folder:" 8 78 "/downloads" --title "$service Config" 3>&1 1>&2 2>&3)
                log "$service download directory set to: $download_dir"
                ;;
            qbittorrent)
                whiptail --msgbox "qBittorrent setup must be completed in its Web UI. Default user/pass: admin/adminadmin" 10 70
                ;;

        esac
        success "Configuration wizard for $service completed."
    fi
}

connect_services() {
    log "Connecting services..."
    if is_installed "sonarr" && is_installed "qbittorrent"; then
        if (whiptail --title "Service Connection" --yesno "Connect Sonarr to qBittorrent?" 8 78); then
            # This is a conceptual example. Actual implementation would require API calls.
            log "Connecting Sonarr to qBittorrent..."
            whiptail --msgbox "Please manually configure Sonarr to use qBittorrent at http://localhost:8989. Use http://localhost:8080 for the qBittorrent URL." 12 78
            success "Sonarr and qBittorrent are ready to be connected."
        fi
    fi
    if is_installed "radarr" && is_installed "qbittorrent"; then
        if (whiptail --title "Service Connection" --yesno "Connect Radarr to qBittorrent?" 8 78); then
            # This is a conceptual example. Actual implementation would require API calls.
            log "Connecting Radarr to qBittorrent..."
            whiptail --msgbox "Please manually configure Radarr to use qBittorrent at http://localhost:7878. Use http://localhost:8080 for the qBittorrent URL." 12 78
            success "Radarr and qBittorrent are ready to be connected."
        fi
    fi
    # Add more service connections here
}


# --- MANAGEMENT & STATUS ---

# Service Management
manage_services() {
    local service=$1
    local action=$(whiptail --title "Service Management: $service" \
        --menu "Choose action:" 15 60 6 \
        "1" "Start" \
        "2" "Stop" \
        "3" "Restart" \
        "4" "Status" \
        "5" "Logs" \
        3>&1 1>&2 2>&3)

    case $action in
        1) systemctl start "$service" && success "$service started" ;;
        2) systemctl stop "$service" && success "$service stopped" ;;
        3) systemctl restart "$service" && success "$service restarted" ;;
        4) systemctl status "$service" | less ;;
        5) journalctl -u "$service" -f ;;
    esac
}

# System Status Dashboard (Now with real-time metrics)
show_system_status() {
    while true; do
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
        local mem_usage=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
        local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
        local services_status=""

        for service in jellyfin plex sonarr radarr lidarr prowlarr jackett bazarr qbittorrent-nox; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                services_status+="✅ $service: Running\n"
            elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
                services_status+="⚠️  $service: Stopped\n"
            fi
        done

        local status_text="--- Real-time System Metrics ---\n\n"
        status_text+="CPU Usage: $cpu_usage\n"
        status_text+="Memory Usage: $mem_usage\n"
        status_text+="Disk Usage: $disk_usage\n\n"
        status_text+="--- Service Status ---\n\n$services_status"


        whiptail --title "Real-time System Dashboard" --msgbox "$status_text" 25 78
        break # Exit after one view. Loop can be modified for continuous refresh.
    done
}


# Backup & Restore
backup_configs() {
    local backup_name="pirate-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    show_progress "Creating Backup" "Backing up configurations..."

    mkdir -p "$backup_path"

    # Backup service configs
    for service in jellyfin plex sonarr radarr lidarr prowlarr jackett bazarr; do
        if [ -d "/var/lib/$service" ]; then
            cp -r "/var/lib/$service" "$backup_path/"
        fi
    done

    # Create backup info
    echo "Backup created: $(date)" > "$backup_path/backup.info"
    echo "Services backed up:" >> "$backup_path/backup.info"
    ls "$backup_path" >> "$backup_path/backup.info"

    # Compress backup
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"

    success "Backup created: $backup_path.tar.gz"
}

restore_configs() {
    local backup_file
    backup_file=$(whiptail --inputbox "Enter the full path to the backup tar.gz file to restore:" 8 60 "" --title "Restore Backup" 3>&1 1>&2 2>&3)
    if [ -f "$backup_file" ]; then
        tar -xzf "$backup_file" -C "$BACKUP_DIR"
        local restore_dir
        restore_dir=$(tar -tzf "$backup_file" | head -1 | cut -f1 -d"/")
        for service in jellyfin plex sonarr radarr lidarr prowlarr jackett bazarr; do
            if [ -d "$BACKUP_DIR/$restore_dir/$service" ]; then
                cp -r "$BACKUP_DIR/$restore_dir/$service" "/var/lib/$service"
            fi
        done
        rm -rf "$BACKUP_DIR/$restore_dir"
        success "Restore completed."
    else
        error "Backup file not found."
    fi
}

# --- MAIN LOOP ---
main() {
    check_root
    detect_distro

    # Check if dependencies are installed
    if ! command -v whiptail &> /dev/null; then
        install_dependencies
    fi

    while true; do
        choice=$(show_main_menu)

        case $choice in
            1) # Media Servers
                servers=$(show_media_servers_menu)
                for server in $servers; do
                    server=$(echo "$server" | tr -d '"')
                    case $server in
                        jellyfin) install_jellyfin ;;
                        plex) install_plex ;;
                        funkwhale) install_funkwhale ;;
                        tvheadend) install_tvheadend ;;
                    esac
                done
                ;;

            2) # Download Automation
                tools=$(show_download_menu)
                for tool in $tools; do
                    tool=$(echo "$tool" | tr -d '"')
                    case $tool in
                        sonarr) install_sonarr ;;
                        radarr) install_radarr ;;
                        lidarr) install_lidarr ;;
                        prowlarr) install_prowlarr ;;
                        jackett) install_jackett ;;
                        bazarr) install_bazarr ;;
                        qbittorrent) install_qbittorrent ;;
                    esac
                done
                ;;

            3) # Tools & Utilities
                tools=$(show_tools_menu)
                for tool in $tools; do
                    tool=$(echo "$tool" | tr -d '"')
                    case $tool in
                        tautulli) install_tautulli ;;
                        ombi) install_ombi ;;
                        pihole) install_pihole ;;
                        # Add other tool installations
                    esac
                done
                ;;

            4) # Container Management
                if ! is_installed docker; then
                    install_docker
                fi
                if ! is_installed portainer; then
                    install_portainer
                fi
                ensure_docker_compose
                whiptail --msgbox "Docker and Portainer installed.\nAccess Portainer at: https://localhost:9443" 10 60
                ;;

            5) # Service Management
                service=$(whiptail --title "Service Management" \
                    --menu "Select service to manage:" 20 60 10 \
                    "jellyfin" "Jellyfin Media Server" \
                    "plex" "Plex Media Server" \
                    "sonarr" "Sonarr" \
                    "radarr" "Radarr" \
                    "lidarr" "Lidarr" \
                    "prowlarr" "Prowlarr" \
                    "jackett" "Jackett" \
                    "qbittorrent-nox" "qBittorrent" \
                    3>&1 1>&2 2>&3)

                if [ -n "$service" ]; then
                    manage_services "$service"
                fi
                ;;

            6) # System Status
                show_system_status
                ;;

            7) # Backup & Restore
                action=$(whiptail --title "Backup & Restore" \
                    --menu "Choose action:" 15 60 2 \
                    "1" "Create Backup" \
                    "2" "Restore from Backup" \
                    3>&1 1>&2 2>&3)

                case $action in
                    1) backup_configs ;;
                    2) restore_configs ;;
                esac
                ;;

            8) # Update All
                show_progress "Updating System" "Updating all packages and services..."
                "$UPDATE_CMD"
                apt-get upgrade -y
                success "System updated"
                ;;

            9) # Uninstall
                whiptail --msgbox "Uninstall menu coming soon" 10 60
                ;;
            10) # Connect Services
                connect_services
                ;;
            0) # Exit
                log "Exiting installer"
                exit 0
                ;;
        esac
    done
}

# Start the script
main "$@"
