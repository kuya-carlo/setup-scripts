#!/bin/bash
LOGFILE="${HOME}/workstation-setup-$(date +%Y%m%d-%H%M%S).log"

log() {
    local message="[setup] $*"
    echo "$message" | tee -a "$LOGFILE"
}

# Configure dnf (fastest mirror, parallel downloads, disable telemetry)
# fastestmirror=1
log "Configuring dnf..."
printf "%s" "
max_parallel_downloads=10
countme=false
" | sudo tee -a /etc/dnf/dnf.conf > /dev/null

# Setup RPMFusion
log "Setting up RPMFusion..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf groupupdate core -y

# Setup Terra
log "Setting up Terra..."
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys

# Update system
log "Updating system..."
sudo dnf upgrade -y

# =============================================================================
# DEBLOAT - Remove unnecessary packages
# =============================================================================
debloat() {
    log "debloat"
    local -a debloat_packages
    debloat_packages=(
        # Hypervisor guest tools (only if running as guest)
        "hypervfcopyd"
        "hypervkvpd"
        "hypervvssd"
        "hyperv-daemons-license"
        "qemu-guest-agent"
        "spice-vdagent"
        "virtualbox-guest-additions"
        "xorg-x11-drv-vmware"
        "open-vm-tools"

        # Active Directory & enterprise (not needed for personal laptop)
        "realmd"
        "sssd"
        "adcli"

        # VPN clients (use Tailscale instead)
        "openvpn"
        "openconnect"
        "vpnc"
        "pptp"
        "ppp"

        # GNOME apps → move to Flatpak instead
        "gnome-calculator"
        "gnome-calendar"
        "gnome-characters"
        "gnome-clocks"
        "gnome-color-manager"
        "gnome-connections"
        "gnome-contacts"
        "gnome-font-viewer"
        "gnome-logs"
        "gnome-maps"
        "gnome-remote-desktop"
        "gnome-software"
        "gnome-system-monitor"
        "gnome-text-editor"
        "gnome-weather"
        "gnome-tour"
        "gnome-user-docs"
        "totem"
        "simple-scan"
        "snapshot"
        "loupe"
        "baobab"
        "yelp"
        "cheese"
        "gnome-classic-session"
        "gnome-boxes"

        # Network tools (optional)
        "mtr"
        "nmap-ncat"
        "traceroute"

        # System recovery/diagnostics (not needed for personal use)
        "anaconda*"
        "abrt*"
        "sos"
        "mediawriter"

        # Accessibility (Flatpak for niche needs)
        "orca"

        # Misc cruft
        "fedora-bookmarks"
        "fedora-chromium-config"
        "dos2unix"
        "nano"
        "nano-default-editor"
        "mailcap"

        # Unused utilities
        "kpartx"
        "teamd"
        "trousers"
        "brasero-libs"
        "cyrus-sasl-plain"

        # Old/rare firmware
        "zd1211-firmware"
        "libertas-usb8388-firmware"
        "geolite2*"
        "alsa-sof-firmware"
    )

    log "Removing bloat packages..."
    for pkg in ${debloat_packages[*]}; do
        sudo dnf remove -y "$pkg" 2>/dev/null || true
    done

    log "Debloat complete"
}

# =============================================================================
# DNF PACKAGES - Core development & system tools (bare-metal)
# =============================================================================
install_dnf() {
    log "Installing dnf packages..."
    local -a dnf_packages
    dnf_packages=(
        # Build essentials & compilers
        "gcc"
        "dbus-tools"
        "gcc-c++"
        "g++"
        "make"
        "cmake"
        "meson"
        "ninja-build"
        "clang"
        "clang-tools-extra"
        "bison"

        # Languages & package managers
        "python3"
        "python3-devel"
        "uv"
        "pnpm"

        # Version control & tools
        "git"
        "git-lfs"
        "gh"

        # SSH, GPG, security
        "openssh"
        "openssh-clients"
        "openssh-server"
        "gnupg2"
        "gnupg2-gpg-agent"
        "pinentry"

        # Editors (bare-metal only)
        "neovim"
        "vim"

        # Containers & hardware
        "podman"
        "podman-compose"
        "distrobox"
        "podman-docker"
        "buildah"
        "skopeo"
        "podman-compose"
        "qemu-system-x86"
        "qemu-system-arm"
        "qemu-system-aarch64"

        # Embedded & electronics
        "openocd"
        "stlink"
        "dfu-util"
        "avr-gcc"
        "avrdude"
        "minicom"

        # CLI utilities (modern replacements)
        "ripgrep"
        "fd-find"
        "eza"
        "bat"
        "fzf"
        "jq"
        "yq"
        "tmux"
        "fastfetch"
        "btop"
        "ncdu"
        "htop"
        "tree"
        "rsync"

        # Compression & media
        "unzip"
        "p7zip"
        "zstd"
        "aria2"
        "ffmpeg"
        "yt-dlp"
        "mpv"

        # Utilities
        "whois"
        "curl"
        "wget"
        "inotify-tools"
        "xsel"

        # Backup & storage
        "restic"
        "rclone"

        # System & networking
        "NetworkManager"
        "NetworkManager-wifi"
        "NetworkManager-bluetooth"
        "firewalld"
        "chrony"

        # Laptop power management
        "tlp"

        # Debugging & monitoring
        "gdb"
        "strace"
        "ltrace"
        "iotop-c"
        "nethogs"
        "dmidecode"
        "pciutils"

        # Shell
        "zsh"

        # Extra tooling
        "clang-tools-extra"      # in packages.txt, not in your dnf install
        "gdb"                    # in packages.txt, not in your dnf list
        "strace"                 # in packages.txt, not in dnf list
        "ltrace"                 # in packages.txt
        "rsync"                  # in packages.txt
        "tmux"                   # in packages.txt (you have zellij instead)
        "iotop-c"                # in packages.txt
        "nethogs"                # in packages.txt
        "pciutils"               # in packages.txt
        "dmidecode"              # in packages.txt
        "unzip"                  # in packages.txt
        "zstd"                   # in packages.txt
        "whois"                  # in packages.txt
        "tree"                   # in packages.txt
        "fedora-gpg-keys"        # in packages.txt (you have this from base)
        "gnome-user-share"       # WebDAV sharing UI in Settings

        # To not break File Sharing in settings
        "gvfs"                   # Backend for WebDAV
        "gvfs-fuse"              # FUSE mount support
        "gvfs-goa"               # GNOME Online Accounts integration
        "mod_dnssd"              # DNS-SD discovery (makes WebDAV visible on network)

        # Security
        "fail2ban"                    # SSH brute force protection
        "lynis"                       # security auditing

        # System recovery (keep just in case)
        "testdisk"                    # file recovery
        "smartmontools"               # disk health (you have in packages.txt)

        # Networking debug
        "nethogs"                     # per-process network usage (you have)
        "iftop"                       # bandwidth monitoring

    )
    sudo dnf install -y ${dnf_packages[*]}
}

# =============================================================================
# FLATPAK PACKAGES - Graphical applications (sandboxed by default)
# =============================================================================
install_flathub() {
    log "Installing Flatpak applications..."
    local -a flatpak_packages
    flatpak_packages=(
        # Browsers
        "app.zen_browser.zen"
        "com.google.Chrome"

        # Productivity & note-taking
        "md.obsidian.Obsidian"
        "org.localsend.localsend_app"
        "io.github.mrvladus.List"

        # Communication
        "org.mozilla.Thunderbird"
        "us.zoom.Zoom"

        # Creative & 3D
        "org.blender.Blender"
        "org.blender.Blender.Codecs"
        "org.kde.krita"
        "org.freecad.FreeCAD"
        "org.inkscape.Inkscape"
        "org.libreoffice.LibreOffice"

        # Media & streaming
        "com.obsproject.Studio"
        "com.obsproject.Studio.Plugin.OBSVkCapture"
        "org.pipewire.Helvum"

        # Data tools & databases
        "io.dbeaver.DBeaverCommunity"
        "io.dbeaver.DBeaverCommunity.Client.pgsql"
        "org.jaspstats.JASP"

        # System utilities
        "page.tesk.Refine"
        "com.github.tchx84.Flatseal"
        "io.github.flattool.Warehouse"
        "com.github.finefindus.eyedropper"
        "com.github.wwmm.easyeffects"
        "com.mattjakeman.ExtensionManager"
        "com.rcloneui.RcloneUI"

        # GNOME apps
        "org.gnome.baobab"
        "org.gnome.Calculator"
        "org.gnome.Calendar"
        "org.gnome.Characters"
        "org.gnome.Evince"
        "org.gnome.Loupe"
        "org.gnome.Maps"
        "org.gnome.Music"
        "org.gnome.World.PikaBackup"

        # Gaming & Proton
        "net.davidotek.pupgui2"
        "com.usebottles.bottles"
        "org.freedesktop.Platform.VulkanLayer.MangoHud"
        "org.freedesktop.Platform.VulkanLayer.OBSVkCapture"

        # Transmission (torrent)
        "com.transmissionbt.Transmission"

        # Optional utilities
        "org.kicad.KiCad"
        "net.krafting.HexColordle"
        "re.sonny.Junction"
        "com.github.GradienceTeam.Gradience"

        # Browsers
        "org.gnome.Epiphany"

        # System utilities
        "ca.desrt.dconf-editor"
        "org.gnome.font-viewer"
        "org.gnome.Papers"
        "org.gnome.Snapshot"
        "org.gnome.clocks"
	"org.gnome.TextEditor"
        "org.gtk.Gtk3theme.adw-gtk3"
        "org.gtk.Gtk3theme.adw-gtk3-dark"
        "org.gustavoperedo.FontDownloader"
        "re.sonny.Workbench"

        # Development
        "cc.arduino.IDE2"
        "cc.arduino.arduinoide"
        "com.jgraph.drawio.desktop"
        "com.one_ware.OneWare"
        "com.usebruno.Bruno"
        "io.github.BuddySirJava.SSH-Studio"
        "me.iepure.devtoolbox"
        "org.apache.netbeans"
        "org.jupyter.JupyterLab"
        "org.kicad.KiCad.Library.Footprints"
        "org.kicad.KiCad.Library.Packages3D"
        "org.kicad.KiCad.Library.Symbols"
        "org.kicad.KiCad.Library.Templates"

        # Creative
        "com.github.libresprite.LibreSprite"
        "org.darktable.Darktable"
        "org.gaphor.Gaphor"
        "org.kde.digikam"

        # Remote access
        "com.rustdesk.RustDesk"
        "com.thincast.client"
        "org.remmina.Remmina"

        # Communication
        "com.viber.Viber"

        # Productivity & note-taking
        "com.calibre_ebook.calibre"
        "com.github.mdh34.quickdocs"
        "com.sigil_ebook.Sigil"
        "com.super_productivity.SuperProductivity"
        "com.toolstack.Folio"
        "io.github.focustimerhq.FocusTimer"
        "net.ankiweb.Anki"

        # Gaming
        "io.itch.itch"
        "sh.ppy.osu"

        # Media & streaming
        "com.obsproject.Studio.Plugin.BackgroundRemoval"
        "com.obsproject.Studio.Plugin.DistroAV"
        "com.obsproject.Studio.Plugin.InputOverlay"
        "com.obsproject.Studio.Plugin.Ocr"
        "com.obsproject.Studio.Plugin.ScaleToSound"
        "com.obsproject.Studio.Plugin.SceneSwitcher"
        "com.obsproject.Studio.Plugin.SourceRecord"
        "com.obsproject.Studio.Plugin.Teleport"
        "com.obsproject.Studio.Plugin.VerticalCanvas"
        "org.jellyfin.JellyfinDesktop"

        # File & disk utilities
        "com.github.qarmin.czkawka"
        "de.haeckerfelix.Fragments"
        "io.gitlab.theevilskeleton.Upscaler"

        # Miscellaneous
        "dev.nicx.mimick"
        "info.febvre.Komikku"
        "io.github.IshuSinghSE.aurynk"
        "io.github.ra3xdh.qucs_s"
        "io.github.tobagin.Ntfyr"
    )
    flatpak install -y flathub ${flatpak_packages[*]}
}

# =============================================================================
# BARE-METAL INSTALLATIONS - Version managers & bare installers
# =============================================================================
install_bare_metal() {
    log "Installing bare-metal tools..."

    # nvm - Node Version Manager (user-space)
    log "Installing nvm (Node Version Manager)"
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node
        log "nvm installed, Node LTS installed"
    else
        log "nvm already installed"
    fi

    # rustup - Rust toolchain installer
    log "Installing rustup (Rust toolchain)"
    if ! command -v rustup &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        log "rustup installed"
    else
        log "rustup already installed"
    fi

    # gvm - Go Version Manager
    log "Installing gvm (Go Version Manager)"
    if [ ! -d "$HOME/.gvm" ]; then
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
        source $HOME/.gvm/scripts/gvm
        gvm install go1.23
        gvm use go1.23 --default
        log "gvm installed with Go 1.23"
    else
        log "gvm already installed"
    fi

    # sdkman - SDK Manager (Java, Kotlin, Gradle, etc.)
    log "Installing sdkman (SDK Manager)"
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk install java 21.0.1-tem
        log "sdkman installed with Java 21"
    else
        log "sdkman already installed"
    fi

    # Zed - Code editor (official installer with auto-updates)
    log "Installing Zed (code editor)"
    if ! command -v zed &> /dev/null; then
        curl https://zed.dev/install.sh | sh
        log "Zed installed"
    else
        log "Zed already installed"
    fi
}

# =============================================================================
# OPTIONAL TOOLS - Additional development utilities
# =============================================================================
install_optional() {
    log "Installing optional tools..."
    flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
    flatpak install -y flathub-beta org.gimp.GIMP

    # Skipping gemini-cli since antigravity bundles them by default.
    # antigravity (Google agentic coding)
    log "Installing antigravity..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash

    log "Installing Copilot CLI..."
    curl -fsSL https://gh.io/copilot-install | bash

    # spec-kit (GitHub spec generation)
    log "Installing spec-kit..."
    uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.9.5

    log "Optional tools installed"
}

fix_security() {
    # Kicksecure Security Hardening Scripts

    # Kernel hardening (mitigates many zero-days)
    sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/modprobe.d/30_security-misc.conf -o /etc/modprobe.d/30_security-misc.conf
    sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_security-misc.conf -o /etc/sysctl.d/30_security-misc.conf

    # CPU mitigations (Spectre/Meltdown)
    sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_cpu_mitigations.cfg -o /etc/grub.d/40_cpu_mitigations.cfg

    # IOMMU (prevents DMA attacks)
    sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_enable_iommu.cfg -o /etc/grub.d/40_enable_iommu.cfg

    # Update GRUB after adding
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    # More secure time sync(NTS):
    sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf -o /etc/chrony.conf
    sudo systemctl restart chronyd

    # GrapheneOS SSH Hardening
    sudo mkdir -p /etc/systemd/system/sshd.service.d
    sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/sshd.service.d/local.conf -o /etc/systemd/system/sshd.service.d/local.conf
    sudo systemctl daemon-reload

    # Fedora opens too many ports by default: Firewall Hardening
    sudo firewall-cmd --permanent --remove-port=1025-65535/udp
    sudo firewall-cmd --permanent --remove-port=1025-65535/tcp
    sudo firewall-cmd --permanent --remove-service=mdns
    sudo firewall-cmd --permanent --remove-service=ssh
    sudo firewall-cmd --permanent --remove-service=samba-client
    sudo firewall-cmd --reload

    # Simple but effective:
    chmod 700 /home/"$(whoami)"
}

# =============================================================================
# POST-INSTALL SETUP
# =============================================================================
post_install() {
    log "Running post-install setup..."

    # Set default shell
    log "Setting default shell to zsh"
    chsh -s /usr/bin/zsh

    # Git config (if not already configured)
    if [ -z "$(git config --global user.name)" ]; then
        log "Configure git: enter your name and email"
        read -p "Git name: " gitname
        read -p "Git email: " gitemail
        git config --global user.name "$gitname"
        git config --global user.email "$gitemail"
        git config --global gpg.program gpg2
    fi

    # Set umask to 077 (secure permissions)
    log "Setting umask to 027..."
    umask 027
    sudo sed -i 's/umask 022/umask 027/g' /etc/bashrc

    # Setup dnf security update auto-download
    sudo dnf install -y dnf-automatic
    sudo systemctl enable --now dnf-automatic.timer

    # Junction as default browser handler
    log "Setting Junction as default browser..."
    xdg-settings set default-web-browser re.sonny.Junction.desktop

    # GNOME window centering
    log "Configuring GNOME window behavior(center by default)..."
    gsettings set org.gnome.mutter center-new-windows true

    log "Post-install setup complete"
}

# =============================================================================
# MAIN ROUTINE
# =============================================================================
main() {
    log "Starting workstation setup"
    log "System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

    debloat
    install_dnf
    install_flathub
    install_bare_metal
    post_install

    log "Workstation setup complete!"
    log "Next steps:"
    log "  1. Log out and back in for zsh to take effect"
    log "  2. Reload shell: exec zsh"
    log "  3. Optional: bash $0 optional  (for copilot, antigravity, spec-kit)"
}

# Allow running individual functions or main
case "${1:-main}" in
    dnf) install_dnf ;;
    flathub) install_flathub ;;
    bare-metal) install_bare_metal ;;
    optional) install_optional ;;
    debloat) debloat ;;
    post-install) post_install ;;
    fix-security) fix_security ;;
    main|*) main ;;
esac
