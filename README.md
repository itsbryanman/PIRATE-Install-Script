# 🏴‍☠️ P.I.R.A.T.E. Media Server Install Script 🏴‍☠️

**P.I.R.A.T.E.** stands for Platform Integration and Resource Automation for Tracking and Enrichment. This comprehensive install script sets up a robust, secure, and feature-rich media server environment, perfect for streaming your favorite content seamlessly across all your devices.

The script is designed to automatically detect your Linux distribution (Debian, Ubuntu, Fedora, CentOS, Arch, and others) and adapt its installation commands accordingly. To perform its tasks, the script requires administrator privileges (root or sudo access) to install packages, configure services, and manage dependencies.

---

## 📜 Table of Contents

- [🏴‍☠️ P.I.R.A.T.E. Media Server Install Script 🏴‍☠️](#-pirate-media-server-install-script-)
  - [📜 Table of Contents](#-table-of-contents)
  - [⚓ Introduction](#-introduction)
  - [🦜 Features](#-features)
  - [🛠 Installation](#-installation)
  - [🚢 Usage](#-usage)
  - [🛡 Security](#-security)
  - [🔧 Configuration](#-configuration)
  - [📦 Components](#-components)
  - [🤝 Contributing](#-contributing)
  - [📄 License](#-license)
  - [📫 Support](#-support)
- [🏴‍☠️ Happy Streaming! 🏴‍☠️](#-happy-streaming-)

---

##  Introduction

Welcome to the **P.I.R.A.T.E. Media Server Install Script**! This script automates the setup of a comprehensive media server environment, integrating various tools and services to manage, stream, and monitor your media collection effortlessly. Whether you're a media enthusiast or looking to centralize your content, P.I.R.A.T.E. has got you covered.

---

##  Features

* **Modular Design**: The script is designed to be easily extensible, allowing you to add new tools and features with minimal effort.
* **Support for Multiple Distributions**: The script automatically detects your Linux distribution and uses the appropriate package manager.
* **Unattended Installation**: The script can be run without any user interaction, making it ideal for automated deployments.
* **Error Handling and Logging**: The script includes robust error handling and logs all its actions to a file for easy debugging.
* **Uninstaller and Updater**: The script includes an uninstaller and an updater, making it easy to manage your media server.

---

##  Installation

1.  **Clone the Repository**
    ```bash
    git clone [https://github.com/yourusername/pirate-media-server.git](https://github.com/yourusername/pirate-media-server.git)
    cd pirate-media-server
    ```

2.  **Run the Install Script**
    ```bash
    sudo ./pirate_media_server.sh
    ```

---

##  Usage

The script will present you with a menu of options:

* **Install Tools**: This option allows you to select which tools you want to install.
* **Uninstall Tools**: This option allows you to select which tools you want to uninstall.
* **Update Tools**: This option updates all the installed tools to their latest versions.
* **Exit**: This option exits the script.

---

## Security

The script follows security best practices, such as:

* **Running as a non-root user**: The script will prompt for a password when it needs to perform actions that require root privileges.
* **Verifying the integrity of downloaded files**: The script verifies the integrity of downloaded files using checksums to prevent man-in-the-middle attacks.
* **Using official repositories**: The script uses official repositories whenever possible to ensure that you are getting the latest and most secure versions of the tools.

---

##  Configuration

The script will automatically configure the tools it installs. However, you can customize the configuration of each tool by editing its configuration file. The configuration files are located in the following directories:

* **Jellyfin**: `/etc/jellyfin/`
* **Plex**: `/var/lib/plexmediaserver/`
* **Sonarr**: `~/.config/NzbDrone/`
* **Radarr**: `~/.config/Radarr/`
* **Lidarr**: `~/.config/Lidarr/`
* **Prowlarr**: `~/.config/Prowlarr/`
* **qBittorrent**: `~/.config/qBittorrent/`
* **Docker**: `/etc/docker/`
* **Portainer**: `/var/lib/portainer/`

---

## Components

The script can install the following components:

* **Media Servers**: Jellyfin, Plex
* **Media Management**: Sonarr, Radarr, Lidarr, Prowlarr
* **Download Clients**: qBittorrent
* **Containerization**: Docker, Portainer

---

##  Contributing

Contributions are welcome! If you would like to contribute to the script, please fork the repository and submit a pull request.

---

## License

This script is licensed under the MIT License.

---

##  Support

If you have any questions or problems with the script, please open an issue on GitHub.

---

## 🏴‍☠️ Happy Streaming! 🏴‍☠️
