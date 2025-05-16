ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.12.5-204.bazzite.fc41.x86_64}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-42}"
ARG JUPITER_FIRMWARE_VERSION="${JUPITER_FIRMWARE_VERSION:-jupiter-20241205.1}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods-extra

FROM scratch AS ctx
COPY build /build

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS stellarite

ARG IMAGE_NAME="${IMAGE_NAME:-stellarite}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.12.5-204.bazzite.fc41.x86_64}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG JUPITER_FIRMWARE_VERSION="${JUPITER_FIRMWARE_VERSION:-jupiter-20241205.1}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system /

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
#
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

# Setup Copr repos
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    if [[ "${FEDORA_MAJOR_VERSION}" == "rawhide" ]]; then \
    curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-rawhide/ryanabx-cosmic-epoch-fedora-rawhide.repo \
    ; else curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-$(rpm -E %fedora)/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo \
    ; fi && \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/LatencyFleX \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        che/nerd-fonts \
        hikariknight/looking-glass-kvmfr \
        mavit/discover-overlay \
        rok/cdemu \
        lizardbyte/beta; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*" && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Bazzite custom kernel
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    rpm-ostree cliwrap install-to-root / && \
    echo "Will install ${KERNEL_FLAVOR} kernel" && \
    /ctx/build/install-kernel-akmods && \
    dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y install \
        scx-scheds && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y swap --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite bootc bootc && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Setup firmware
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    mkdir -p /tmp/linux-firmware-neptune && \
    curl -Lo /tmp/linux-firmware-neptune/cs35l41-dsp1-spk-cali.bin https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/cs35l41-dsp1-spk-cali.bin && \
    curl -Lo /tmp/linux-firmware-neptune/cs35l41-dsp1-spk-cali.wmfw https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/cs35l41-dsp1-spk-cali.wmfw && \
    curl -Lo /tmp/linux-firmware-neptune/cs35l41-dsp1-spk-prot.bin https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/cs35l41-dsp1-spk-prot.bin && \
    curl -Lo /tmp/linux-firmware-neptune/cs35l41-dsp1-spk-prot.wmfw https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/cs35l41-dsp1-spk-prot.wmfw && \
    curl -Lo /tmp/linux-firmware-neptune/rtl8822cu_fw.bin https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/rtl_bt/rtl8822cu_fw.bin && \
    xz --check=crc32 /tmp/linux-firmware-neptune/* && \
    mv -vf /tmp/linux-firmware-neptune/rtl8822cu_fw.bin.xz /usr/lib/firmware/rtl_bt/rtl8822cu_fw.bin.xz && \
    mv -vf /tmp/linux-firmware-neptune/* /usr/lib/firmware/cirrus/ && \
    rm -rf /tmp/linux-firmware-neptune && \
    mkdir -p /tmp/linux-firmware-galileo && \
    curl https://gitlab.com/evlaV/linux-firmware-neptune/-/archive/"${JUPITER_FIRMWARE_VERSION}"/linux-firmware-neptune-"${JUPITER_FIRMWARE_VERSION}".tar.gz?path=ath11k/QCA206X -o /tmp/linux-firmware-galileo/ath11k.tar.gz && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --no-overwrite-dir -xvf /tmp/linux-firmware-galileo/ath11k.tar.gz -C /tmp/linux-firmware-galileo && \
    xz --check=crc32 /tmp/linux-firmware-galileo/ath11k/QCA206X/hw2.1/* && \
    rm -f /usr/lib/firmware/ath11k/QCA206X/* && \
    rm -rf /usr/lib/firmware/ath11k/QCA2066 && \
    mv -vf /tmp/linux-firmware-galileo/ath11k/QCA206X /usr/lib/firmware/ath11k/QCA206X && \
    rm -rf /tmp/linux-firmware-galileo/ath11k && \
    rm -rf /tmp/linux-firmware-galileo/ath11k.tar.gz && \
    ln -s QCA206X /usr/lib/firmware/ath11k/QCA2066 && \
    curl -Lo /tmp/linux-firmware-galileo/hpbtfw21.tlv https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/qca/hpbtfw21.tlv && \
    curl -Lo /tmp/linux-firmware-galileo/hpnv21.309 https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/qca/hpnv21.309 && \
    curl -Lo /tmp/linux-firmware-galileo/hpnv21.bin https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/qca/hpnv21.bin && \
    curl -Lo /tmp/linux-firmware-galileo/hpnv21g.309 https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/qca/hpnv21g.309 && \
    curl -Lo /tmp/linux-firmware-galileo/hpnv21g.bin https://gitlab.com/evlaV/linux-firmware-neptune/-/raw/"${JUPITER_FIRMWARE_VERSION}"/qca/hpnv21g.bin && \
    xz --check=crc32 /tmp/linux-firmware-galileo/* && \
    mv -vf /tmp/linux-firmware-galileo/* /usr/lib/firmware/qca/ && \
    rm -rf /tmp/linux-firmware-galileo && \
    rm -rf /usr/share/alsa/ucm2/conf.d/acp5x/Valve-Jupiter-1.conf && \
    ln -s /usr/local/firmware/aw87xxx_acf.bin /usr/lib/firmware/aw87xxx_acf.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_air1s.bin /usr/lib/firmware/aw87xxx_acf_air1s.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_kun.bin /usr/lib/firmware/aw87xxx_acf_kun.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_minipro.bin /usr/lib/firmware/aw87xxx_acf_minipro.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_orangepi.bin /usr/lib/firmware/aw87xxx_acf_orangepi.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_airplus.bin /usr/lib/firmware/aw87xxx_acf_airplus.bin && \
    ln -s /usr/local/firmware/aw87xxx_acf_flip.bin /usr/lib/firmware/aw87xxx_acf_flip.bin && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland#
# Install patched switcheroo control with proper discrete GPU support
# Tempporary fix for GPU Encoding
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    declare -A toswap=( \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite"]="wireplumber" \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib"]="pipewire bluez xorg-x11-server-Xwayland" \
        ["terra-extras"]="switcheroo-control" \
        ["terra-mesa"]="mesa-filesystem" \
        ["copr:copr.fedorainfracloud.org:ublue-os:staging"]="fwupd" \
    ) && \
    for repo in "${!toswap[@]}"; do \
        for package in ${toswap[$repo]}; do dnf5 -y swap --repo=$repo $package $package; done; \
    done && unset -v toswap repo package && \
    dnf5 versionlock add \
        pipewire \
        pipewire-alsa \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-pulseaudio \
        pipewire-utils \
        wireplumber \
        wireplumber-libs \
        bluez \
        bluez-cups \
        bluez-libs \
        bluez-obexd \
        xorg-x11-server-Xwayland \
        switcheroo-control \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-va-drivers \
        mesa-vulkan-drivers \
        fwupd \
        fwupd-plugin-flashrom \
        fwupd-plugin-modem-manager \
        fwupd-plugin-uefi-capsule-data && \
    dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
        libaacs \
        libbdplus \
        libbluray \
        libbluray-utils && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree override remove \
    ublue-os-update-services \
    firefox \
    firefox-langpacks \
    htop \
    || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install additional packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    git \
    discover-overlay \
    cpulimit \
    tailscale \
    lact \
    fastfetch \
    btop \
    fzf \
    zoxide \
    eza \
    vim \
    zsh \
    starship \
    zsh \
    zsh-autosuggestions \
    ghostty \
    ptyxis \
    tmux \
    cascadia-code-nf-fonts \
    cascadia-mono-nf-fonts \
    nerd-fonts \
    || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Steam plus supporting packages
# Downgrade ibus to fix an issue with the Steam keyboard
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:bazzite-org:bazzite \
    ibus \
    ibus-gtk2 \
    ibus-gtk3 \
    ibus-gtk4 \
    ibus-libs \
    ibus-panel \
    ibus-setup \
    ibus-xinit && \
    rpm-ostree install \
    jupiter-sd-mounting-btrfs \
    at-spi2-core.i686 \
    atk.i686 \
    vulkan-loader.i686 \
    alsa-lib.i686 \
    fontconfig.i686 \
    gtk2.i686 \
    libICE.i686 \
    libnsl.i686 \
    libxcrypt-compat.i686 \
    libpng12.i686 \
    libXext.i686 \
    libXinerama.i686 \
    libXtst.i686 \
    libXScrnSaver.i686 \
    NetworkManager-libnm.i686 \
    nss.i686 \
    pulseaudio-libs.i686 \
    libcurl.i686 \
    systemd-libs.i686 \
    libva.i686 \
    libvdpau.i686 \
    libdbusmenu-gtk3.i686 \
    libatomic.i686 \
    pipewire-alsa.i686 \
    gobject-introspection \
    clinfo \
    steam \
    || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Lutris and some additional packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    lutris \
    umu-launcher \
    wine-core.x86_64 \
    wine-core.i686 \
    wine-pulseaudio.x86_64 \
    wine-pulseaudio.i686 \
    libFAudio.x86_64 \
    libFAudio.i686 \
    winetricks \
    latencyflex-vulkan-layer \
    mesa-vulkan-drivers.i686 \
    mesa-va-drivers.i686 \
    vkBasalt.x86_64 \
    vkBasalt.i686 \
    mangohud.x86_64 \
    mangohud.i686 \
    libobs_vkcapture.x86_64 \
    libobs_glcapture.x86_64 \
    libobs_vkcapture.i686 \
    libobs_glcapture.i686 \
    || true && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/winetricks.desktop || true && \
    curl -Lo /tmp/latencyflex.tar.xz $(curl https://api.github.com/repos/ishitatsuyuki/LatencyFleX/releases/latest | jq -r '.assets[] | select(.name| test(".*.tar.xz$")).browser_download_url') || true && \
    mkdir -p /tmp/latencyflex || true && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir --strip-components 1 -xvf /tmp/latencyflex.tar.xz -C /tmp/latencyflex || true && \
    rm -f /tmp/latencyflex.tar.xz || true && \
    cp -r /tmp/latencyflex/wine/usr/lib/wine/* /usr/lib64/wine/ || true && \
    rm -rf /tmp/latencyflex || true && \
    curl -Lo /usr/bin/latencyflex https://raw.githubusercontent.com/KyleGospo/LatencyFleX-Installer/main/install.sh || true && \
    chmod +x /usr/bin/latencyflex || true && \
    sed -i 's@/usr/lib/wine/@/usr/lib64/wine/@g' /usr/bin/latencyflex || true && \
    sed -i 's@"dxvk.conf"@"/usr/share/latencyflex/dxvk.conf"@g' /usr/bin/latencyflex || true && \
    chmod +x /usr/bin/latencyflex || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Heroic and some additional packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    heroic-games-launcher-bin \
    umu-launcher \
    wine-core.x86_64 \
    wine-core.i686 \
    wine-pulseaudio.x86_64 \
    wine-pulseaudio.i686 \
    libFAudio.x86_64 \
    libFAudio.i686 \
    winetricks \
    || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install cloudflare-warp supplied from local file
# Will be used later along with script
COPY vendor/cloudflare-warp /usr/share/ublue-os/packages

# Install and configure Cosmic DE
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    cosmic-desktop && \
    # Install gnome-software and gnome-disks
    rpm-ostree install \
    gnome-software \
    gnome-disk-utility \
    gparted \
    gnome-keyring NetworkManager-tui \
    NetworkManager-openvpn && \
    # We remove cosmic-store and replace it with gnome-software for better functionality
    rpm-ostree remove \
    cosmic-store || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install Gamescope, ROCM, and Waydroid on non-Nvidia images
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    gamescope.x86_64 \
    gamescope-libs.i686 \
    gamescope-shaders \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    waydroid \
    cage \
    wlr-randr && \
    sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' /usr/lib/waydroid/data/scripts/waydroid-net.sh && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Homebrew
# For some reason some devices don't get homebrew installed on their machine when rebasing.
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    dnf5 install -y ublue-brew && \
    curl -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/ublue-os/bash-preexec/master/bash-preexec.sh && \
    /ctx/build/cleanup.sh && \
    ostree container commit

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 install -y --enable-repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
        ublue-os-media-automount-udev && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Install WinApps dependencies
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    rpm-ostree install \
    podman-compose \
    dialog \
    nmap-ncat \
    xfreerdp \
    || true && \
    /ctx/build/cleanup.sh && \
    ostree container commit

# Finalize
COPY override /
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    # Service management
    systemctl enable lactd || true && \
    systemctl disable gdm || true && \
    systemctl disable sddm || true && \
    systemctl enable cosmic-greeter && \
    systemctl enable brew-dir-fix.service && \
    systemctl enable brew-setup.service && \
    systemctl disable brew-upgrade.timer && \
    systemctl disable brew-update.timer && \
    systemctl disable waydroid-container.service && \
    systemctl --global enable podman.socket && \
    # Enabling just files
    echo "import \"/usr/share/ublue-os/just/80-stellarite.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/81-stellarite-fix.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-stellarite-waydroid.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/84-stellarite-virt.just\"" >> /usr/share/ublue-os/justfile && \
    # Adding good stuff
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/bin/waydroid-choose-gpu https://raw.githubusercontent.com/KyleGospo/waydroid-scripts/main/waydroid-choose-gpu.sh && \
    chmod +x /usr/bin/waydroid-choose-gpu && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/incus.ini && \
    # Disabling copr for faster sync
    for repo in \
        fedora-cisco-openh264 \
        fedora-steam \
        fedora-rar \
        terra \
        terra-extras \
        negativo17-fedora-multimedia \
        _copr_ublue-os-akmods; \
    do \
        sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/$repo.repo; \
    done && for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/LatencyFleX \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        che/nerd-fonts \
        mavit/discover-overlay \
        lizardbyte/beta \
        rok/cdemu \
        hikariknight/looking-glass-kvmfr; \
    do \
        dnf5 -y copr disable $copr; \
    done && unset -v copr && \
    dnf5 config-manager setopt "*tailscale*".enabled=0 && \
    dnf5 config-manager setopt "terra-mesa".enabled=0 && \
    dnf5 config-manager setopt "*charm*".enabled=0 && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' enabled=0)" && \
    sed -i 's#/var/lib/selinux#/etc/selinux#g' /usr/lib/python3.*/site-packages/setroubleshoot/util.py && \
    sed -i 's|#default.clock.allowed-rates = \[ 48000 \]|default.clock.allowed-rates = [ 44100 48000 ]|' /usr/share/pipewire/pipewire.conf && \
    sed -i 's|^ExecStart=.*|ExecStart=/usr/libexec/rtkit-daemon --no-canary|' /usr/lib/systemd/system/rtkit-daemon.service && \
    sed -i 's/balanced=balanced$/balanced=balanced-bazzite/' /etc/tuned/ppd.conf && \
    sed -i 's/performance=throughput-performance$/performance=throughput-performance-bazzite/' /etc/tuned/ppd.conf && \
    sed -i 's/balanced=balanced-battery$/balanced=balanced-battery-bazzite/' /etc/tuned/ppd.conf && \
    ln -s /usr/bin/true /usr/bin/pulseaudio && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    # Finishing stuff
    /ctx/build/image-info && \
    /ctx/build/build-initramfs && \
    /ctx/build/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
