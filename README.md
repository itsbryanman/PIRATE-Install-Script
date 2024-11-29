# 🏴‍☠️ P.I.R.A.T.E. Media Server Install Script 🏴‍☠️

**P.I.R.A.T.E.** stands for Platform Integration and Resource Automation for Tracking and Enrichment. This comprehensive install script sets up a robust, secure, and feature-rich media server environment, perfect for streaming your favorite content seamlessly across all your devices.

The script is designed to automatically detect your Linux distribution (Debian, Ubuntu, Fedora, CentOS, Arch, and others) and adapt its installation commands accordingly. To perform its tasks, the script requires administrator privileges (root or sudo access) to install packages, configure services, and manage dependencies.

---

## 📜 Table of Contents

- [🏴‍☠️ P.I.R.A.T.E. Media Server Install Script 🏴‍☠️](#-pirate-media-server-install-script-)
  - [📜 Table of Contents](#-table-of-contents)
  - [⚓ Introduction](#-introduction)
  - [🦜 Features](#-features)
    - [P.I.R.A.T.E. Acronym Breakdown](#pirate-acronym-breakdown)
  - [🛠 Installation](#-installation)
    - [Prerequisites](#prerequisites)
    - [Installation Steps](#installation-steps)
      - [1. Clone the Repository](#1-clone-the-repository)
      - [2. Configure Environment Variables](#2-configure-environment-variables)
      - [3. Run the Install Script](#3-run-the-install-script)
      - [4. Access the Dashboard](#4-access-the-dashboard)
      - [5. Post-Installation Setup](#5-post-installation-setup)
  - [🚢 Usage](#-usage)
  - [🛡 Security](#-security)
  - [🔧 Configuration](#-configuration)
  - [📦 Components](#-components)
  - [🤝 Contributing](#-contributing)
  - [📄 License](#-license)
  - [📫 Support](#-support)
- [🏴‍☠️ Happy Streaming! 🏴‍☠️](#-happy-streaming-)

---

## ⚓ Introduction

Welcome to the **P.I.R.A.T.E. Media Server Install Script**! This script automates the setup of a comprehensive media server environment, integrating various tools and services to manage, stream, and monitor your media collection effortlessly. Whether you're a media enthusiast or looking to centralize your content, P.I.R.A.T.E. has got you covered.

---

## 🦜 Features

### P.I.R.A.T.E. Acronym Breakdown

**P.I.R.A.T.E.** encapsulates the core functionalities of the install script, ensuring a seamless and efficient media server setup.

1. **P - Platform Integration**
   - **Purpose**: Seamlessly integrates various media services and tools into a unified platform.
   - **Components**:
     - **Plex** or **Jellyfin**: Core media streaming platforms.
     - **Organizr** or **Heimdall**: Unified dashboards for accessing all services.
     - **Docker** & **Portainer**: Containerization for easy deployment and management.

2. **I - Indexer Management**
   - **Purpose**: Efficiently manages and connects to multiple indexers for content discovery.
   - **Components**:
     - **Prowlarr**: Centralizes indexer management for Sonarr, Radarr, etc.
     - **Jackett**: Extends support for additional torrent indexers.

3. **R - Resource Automation**
   - **Purpose**: Automates the management and organization of media resources.
   - **Components**:
     - **Sonarr**, **Radarr**, **Lidarr**, **Readarr**: Automated downloading and organizing of TV shows, movies, music, and books.
     - **Watchtower**: Automatically updates Docker containers.
     - **Ansible**: Automates configuration and deployment tasks.

4. **A - Tracking and Monitoring**
   - **Purpose**: Provides comprehensive tracking and monitoring of server performance and media usage.
   - **Components**:
     - **Tautulli**: Monitors Plex usage and statistics.
     - **Netdata** or **Glances**: Real-time system monitoring.
     - **Prometheus** + **Grafana**: Advanced metrics collection and visualization.
     - **Fail2Ban**: Enhances security by protecting against unauthorized access.

5. **T - Transcoding and Enrichment**
   - **Purpose**: Enhances media quality and enriches metadata for an optimal viewing experience.
   - **Components**:
     - **FFmpeg**: Handles video and audio processing.
     - **FileBot**: Automates file renaming and organization.
     - **Bazarr**: Manages and downloads subtitles.
     - **MediaInfo**: Provides detailed metadata for media files.
     - **HandBrake**: Transcodes media files for compatibility across devices.

6. **E - Enhanced Storage and Backup**
   - **Purpose**: Manages storage solutions and ensures data integrity through reliable backups.
   - **Components**:
     - **MergerFS**/**UnionFS**: Pools multiple storage drives into a single virtual drive.
     - **rclone**/**Syncthing**: Synchronizes local and cloud storage.
     - **RAID** (using **mdadm** or **ZFS**): Implements RAID setups for data redundancy.
     - **Automated Backup Solutions**: Ensures regular backups of critical data.

---

## 🛠 Installation

### Prerequisites

Before running the P.I.R.A.T.E. install script, ensure you have the following:

- **Operating System**: Ubuntu 20.04 LTS or later (other Linux distributions may work with adjustments)
- **Docker**: Installed and running
- **Docker Compose**: Installed
- **Git**: Installed
- **Sufficient Storage**: Adequate disk space for media and applications


## Installation Steps

### 1. Clone the Repository
Clone the repository to your local machine:
```bash
git clone https://github.com/yourusername/pirate-media-server.git
cd pirate-media-server
```

### 2. (Optional) Configure the Environment Variables
The script uses a `.env` file to load configuration variables. You can customize these variables to match your setup.

1. Copy the example `.env` file to create your custom environment file:
   ```bash
   cp .env.example .env
   ```

2. Open the `.env` file in your preferred text editor:
   ```bash
   nano .env
   ```

3. Modify the variables in the `.env` file to suit your environment. For example:
   - Update `MEDIA_PATH` to the location of your media files.
   - Adjust ports for services like `PORTAINER_PORT`, `PLEX_PORT`, and `JELLYFIN_PORT` if needed.
   - Enable or disable the VPN by setting `VPN_ENABLED` to `true` or `false`.

4. Save and close the file.

### 3. Run the Installation Script
Start the script to begin the installation process:
```bash
./pirate_media_server.sh
```

Follow the on-screen prompts to select the categories and tools you want to install. The script will automatically handle dependencies and configurations.

---

## 🔧 Configuration

### Post-Installation Setup

#### Plex/Jellyfin
- Access the web interface:
  - **Plex**: `http://<your-server-ip>:32400`
  - **Jellyfin**: `http://<your-server-ip>:8096`
- Add libraries for TV shows, movies, and music.

#### Sonarr/Radarr
- Open their web interfaces:
  - **Sonarr**: `http://<your-server-ip>:8989`
  - **Radarr**: `http://<your-server-ip>:7878`
- Configure indexers via **Prowlarr** and link to your download clients.

#### Docker Tools
- Access **Portainer** to manage containers:  
  `http://<your-server-ip>:9000`

---

## 📦 Components

### Media Management Tools
Automate the organization and streaming of your media with tools like:
- **Plex** or **Jellyfin**: For seamless streaming.
- **Sonarr**, **Radarr**, **Readarr**, and **Lidarr**: Download, organize, and manage TV shows, movies, books, and music.

### Downloader Tools
Effortlessly manage downloads with:
- **qBittorrent**, **Transmission**, and **SABnzbd**: For torrenting and Usenet access.

### Supporting Tools
Enhance your server's media experience with:
- **Bazarr**: Automatic subtitle management.
- **Tautulli**: Plex usage monitoring.
- **FileBot** and **MediaInfo**: Metadata enrichment and file organization.

---

## 🏴‍☠️ Happy Streaming! 🏴‍☠️
```
