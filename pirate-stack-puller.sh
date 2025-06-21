#!/usr/bin/env bash
# pirate-stack-puller.sh - Pull ARR/media server Docker images without sudo

set -Eeuo pipefail
IFS=$'\n\t'

log() { printf '%s\n' "$*"; }

require_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log "ERROR: Docker is not installed. Install Docker first and rerun." >&2
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        log "ERROR: Docker daemon is unreachable or you lack permissions." >&2
        exit 1
    fi
}

pull_images() {
    local images=(
        # === P2P / Usenet ===
        "lscr.io/linuxserver/qbittorrent:latest"
        "lscr.io/linuxserver/sabnzbd:latest"

        # === The *ARR family ===
        "lscr.io/linuxserver/sonarr:latest"
        "lscr.io/linuxserver/radarr:latest"
        "lscr.io/linuxserver/prowlarr:latest"
        "lscr.io/linuxserver/bazarr:latest"

        # === Media servers ===
        "lscr.io/linuxserver/plex:latest"
        "lscr.io/linuxserver/emby:latest"
        "lscr.io/linuxserver/jellyfin:latest"

        # === Plumbing & management ===
        "qmcgaw/gluetun:latest"
        "containrrr/watchtower:latest"
        "portainer/portainer-ce:latest"
        "lscr.io/linuxserver/organizr:latest"
        "pihole/pihole:latest"
        "grafana/grafana-oss:latest"
    )

    log "[*] Pulling images…"
    for img in "${images[@]}"; do
        log "  → $img"
        docker pull "$img"
    done
    log "[✔] All images pulled successfully."
}

main() {
    require_docker
    pull_images
    log "Reminder: Trakt.tv has no container—add your Trakt credentials inside Sonarr/Radarr after they’re running."
}

main "$@"
