ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-base}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.12.5-204.bazzite.fc41.x86_64}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG JUPITER_FIRMWARE_VERSION="${JUPITER_FIRMWARE_VERSION:-jupiter-20241205.1}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

FROM ghcr.io/ublue-os/${KERNEL_FLAVOR}-kernel:${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS kernel
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} AS akmods-extra

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

# Update packages that commonly cause build issues
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --from repo=fedora \
    libusb1 \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    vulkan-loader \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    alsa-lib \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    gnutls \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glib2 \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    nspr \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    nss \
    nss-softokn \
    nss-softokn-freebl \
    nss-sysinit \
    nss-util \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    atk \
    at-spi2-atk \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libaom \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    gstreamer1 \
    gstreamer1-plugins-base \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libdecor \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libtirpc \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libuuid \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libblkid \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libmount \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cups-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libinput \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libopenmpt \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    llvm-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    zlib-ng-compat \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    fontconfig \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    pciutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libdrm \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    cpp \
    libatomic \
    libgcc \
    libgfortran \
    libgomp \
    libobjc \
    libstdc++ \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libX11 \
    libX11-common \
    libX11-xcb \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libv4l \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    elfutils-libelf \
    elfutils-libs \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    glibc \
    glibc-common \
    glibc-all-langpacks \
    glibc-gconv-extra \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    libxcrypt \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    SDL2 \
    || true && \
    rpm-ostree override remove \
    glibc32 \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

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
    if [[ "${FEDORA_MAJOR_VERSION}" == "rawhide" ]]; then \
    curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-rawhide/ryanabx-cosmic-epoch-fedora-rawhide.repo \
    ; else curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
    https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-$(rpm -E %fedora)/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo \
    ; fi && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-bazzite.repo https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-bazzite-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-bazzite-multilib.repo https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite-multilib/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-bazzite-multilib-fedora-"${FEDORA_MAJOR_VERSION}".repo?arch=x86_64 && \
    curl -Lo /etc/yum.repos.d/_copr_ublue-os-staging.repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo?arch=x86_64 && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-latencyflex.repo https://copr.fedorainfracloud.org/coprs/kylegospo/LatencyFleX/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-LatencyFleX-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-obs-vkcapture.repo https://copr.fedorainfracloud.org/coprs/kylegospo/obs-vkcapture/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-obs-vkcapture-fedora-"${FEDORA_MAJOR_VERSION}".repo?arch=x86_64 && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-wallpaper-engine-kde-plugin.repo https://copr.fedorainfracloud.org/coprs/kylegospo/wallpaper-engine-kde-plugin/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-wallpaper-engine-kde-plugin-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_ycollet-audinux.repo https://copr.fedorainfracloud.org/coprs/ycollet/audinux/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ycollet-audinux-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-rom-properties.repo https://copr.fedorainfracloud.org/coprs/kylegospo/rom-properties/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-rom-properties-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-webapp-manager.repo https://copr.fedorainfracloud.org/coprs/kylegospo/webapp-manager/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-webapp-manager-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_hhd-dev-hhd.repo https://copr.fedorainfracloud.org/coprs/hhd-dev/hhd/repo/fedora-"${FEDORA_MAJOR_VERSION}"/hhd-dev-hhd-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_che-nerd-fonts.repo https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo https://copr.fedorainfracloud.org/coprs/sentry/switcheroo-control_discrete/repo/fedora-"${FEDORA_MAJOR_VERSION}"/sentry-switcheroo-control_discrete-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_hikariknight-looking-glass-kvmfr.repo https://copr.fedorainfracloud.org/coprs/hikariknight/looking-glass-kvmfr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/hikariknight-looking-glass-kvmfr-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_mavit-discover-overlay.repo https://copr.fedorainfracloud.org/coprs/mavit/discover-overlay/repo/fedora-"${FEDORA_MAJOR_VERSION}"/mavit-discover-overlay-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_lizardbyte-beta.repo https://copr.fedorainfracloud.org/coprs/lizardbyte/beta/repo/fedora-"${FEDORA_MAJOR_VERSION}"/lizardbyte-beta-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_rok-cdemu.repo https://copr.fedorainfracloud.org/coprs/rok/cdemu/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rok-cdemu-fedora-"${FEDORA_MAJOR_VERSION}".rep && \
    curl -Lo /etc/yum.repos.d/_copr_rodoma92-kde-cdemu-manager.repo https://copr.fedorainfracloud.org/coprs/rodoma92/kde-cdemu-manager/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rodoma92-kde-cdemu-manager-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_rodoma92-rmlint.repo https://copr.fedorainfracloud.org/coprs/rodoma92/rmlint/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rodoma92-rmlint-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_ilyaz-lact.repo https://copr.fedorainfracloud.org/coprs/ilyaz/LACT/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ilyaz-LACT-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_atim-starship.repo https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-starship-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_sneexy-zen-browser.repo https://copr.fedorainfracloud.org/coprs/sneexy/zen-browser/repo/fedora-"${FEDORA_MAJOR_VERSION}"/sneexy-zen-browser-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_pgdev-ghostty.repo https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-"${FEDORA_MAJOR_VERSION}"/pgdev-ghostty-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_solopasha-hyprland.repo https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-"${FEDORA_MAJOR_VERSION}"/solopasha-hyprland-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_trs-sod-swaylock-effects.repo https://copr.fedorainfracloud.org/coprs/trs-sod/swaylock-effects/repo/fedora-"${FEDORA_MAJOR_VERSION}"/trs-sod-swaylock-effects-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_alebastr-sway-extras.repo https://copr.fedorainfracloud.org/coprs/alebastr/sway-extras/repo/fedora-"${FEDORA_MAJOR_VERSION}"/alebastr-sway-extras-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_aeiro-nwg-shell.repo https://copr.fedorainfracloud.org/coprs/aeiro/nwg-shell/repo/fedora-"${FEDORA_MAJOR_VERSION}"/aeiro-nwg-shell-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/zsh-autosuggest.repo https://download.opensuse.org/repositories/shells:zsh-users:zsh-autosuggestions/Fedora_Rawhide/shells:zsh-users:zsh-autosuggestions.repo && \
    curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo && \
    curl -Lo /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    sed -i 's@gpgcheck=1@gpgcheck=0@g' /etc/yum.repos.d/tailscale.repo && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    curl -Lo /etc/yum.repos.d/negativo17-fedora-steam.repo https://negativo17.org/repos/fedora-steam.repo && \
    curl -Lo /etc/yum.repos.d/negativo17-fedora-rar.repo https://negativo17.org/repos/fedora-rar.repo && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install Bazzite custom kernel
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=kernel,src=/tmp/rpms,dst=/tmp/kernel-rpms \
    rpm-ostree cliwrap install-to-root / && \
    echo "Will install ${KERNEL_FLAVOR} kernel" && \
    rpm-ostree override replace \
    --experimental \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm \
    /tmp/kernel-rpms/kernel-uki-virt-*.rpm && \
    rpm-ostree install \
    scx-scheds && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:kylegospo:bazzite \
    bootc \
    rpm-ostree \
    rpm-ostree-libs && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit


# Setup firmware
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
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
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Add ublue packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    rpm-ostree install \
    /tmp/akmods-rpms/kmods/*kvmfr*.rpm \
    /tmp/akmods-rpms/kmods/*xone*.rpm \
    /tmp/akmods-rpms/kmods/*openrazer*.rpm \
    /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
    /tmp/akmods-rpms/kmods/*wl*.rpm \
    /tmp/akmods-rpms/kmods/*framework-laptop*.rpm \
    /tmp/akmods-extra-rpms/kmods/*gcadapter_oc*.rpm \
    /tmp/akmods-extra-rpms/kmods/*nct6687*.rpm \
    /tmp/akmods-extra-rpms/kmods/*zenergy*.rpm \
    /tmp/akmods-extra-rpms/kmods/*vhba*.rpm \
    /tmp/akmods-extra-rpms/kmods/*gpd-fan*.rpm \
    /tmp/akmods-extra-rpms/kmods/*ayaneo-platform*.rpm \
    /tmp/akmods-extra-rpms/kmods/*ayn-platform*.rpm \
    /tmp/akmods-extra-rpms/kmods/*bmi260*.rpm \
    /tmp/akmods-extra-rpms/kmods/*ryzen-smu*.rpm \
    /tmp/akmods-extra-rpms/kmods/*evdi*.rpm \
    || true && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd \
    fwupd-plugin-flashrom \
    fwupd-plugin-modem-manager \
    fwupd-plugin-uefi-capsule-data && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland#
# Install patched switcheroo control with proper discrete GPU support
# Tempporary fix for GPU Encoding
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    mesa-dri-drivers.i686 && \
    mkdir -p /tmp/mesa-fix64/dri && \
    cp /usr/lib64/libgallium-*.so /tmp/mesa-fix64/ && \
    cp /usr/lib64/dri/kms_swrast_dri.so /tmp/mesa-fix64/dri/ && \
    cp /usr/lib64/dri/libdril_dri.so /tmp/mesa-fix64/dri/ && \
    cp /usr/lib64/dri/swrast_dri.so /tmp/mesa-fix64/dri/ && \
    cp /usr/lib64/dri/virtio_gpu_dri.so /tmp/mesa-fix64/dri/ && \
    mkdir -p /tmp/mesa-fix32/dri && \
    cp /usr/lib/libgallium-*.so /tmp/mesa-fix32/ && \
    cp /usr/lib/dri/kms_swrast_dri.so /tmp/mesa-fix32/dri/ && \
    cp /usr/lib/dri/libdril_dri.so /tmp/mesa-fix32/dri/ && \
    cp /usr/lib/dri/swrast_dri.so /tmp/mesa-fix32/dri/ && \
    cp /usr/lib/dri/virtio_gpu_dri.so /tmp/mesa-fix32/dri/ && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:kylegospo:bazzite-multilib \
    mesa-libxatracker \
    mesa-libglapi \
    mesa-dri-drivers \
    mesa-libgbm \
    mesa-libEGL \
    mesa-vulkan-drivers \
    mesa-libGL \
    pipewire \
    pipewire-alsa \
    pipewire-gstreamer \
    pipewire-jack-audio-connection-kit \
    pipewire-jack-audio-connection-kit-libs \
    pipewire-libs \
    pipewire-pulseaudio \
    pipewire-utils \
    pipewire-plugin-libcamera \
    bluez \
    bluez-obexd \
    bluez-cups \
    bluez-libs \
    xorg-x11-server-Xwayland \
    || true && \
    rsync -a /tmp/mesa-fix64/ /usr/lib64/ && \
    rsync -a /tmp/mesa-fix32/ /usr/lib/ && \
    rm -rf /tmp/mesa-fix64 && \
    rm -rf /tmp/mesa-fix32 && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    rpm-ostree install \
    libbluray \
    libbluray-utils && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion-*.repo && \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
    switcheroo-control && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
    ublue-os-update-services \
    firefox \
    firefox-langpacks \
    htop \
    || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install additional packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    git \
    discover-overlay \
    cpulimit \
    tailscale \
    lact \
    fastfetch \
    atuin \
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
    tmux \
    cascadia-code-nf-fonts \
    cascadia-mono-nf-fonts \
    cloudflare-warp \
    nerd-fonts \
    || true && \
    systemctl enable lactd || true && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install Steam & Lutris, plus supporting packages
# Downgrade ibus to fix an issue with the Steam keyboard
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:kylegospo:bazzite \
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
    # rpm-ostree install \
    # lutris \
    # umu-launcher \
    # wine-core.x86_64 \
    # wine-core.i686 \
    # wine-pulseaudio.x86_64 \
    # wine-pulseaudio.i686 \
    # libFAudio.x86_64 \
    # libFAudio.i686 \
    # winetricks \
    # latencyflex-vulkan-layer \
    # mesa-vulkan-drivers.i686 \
    # mesa-va-drivers.i686 \
    # vkBasalt.x86_64 \
    # vkBasalt.i686 \
    # mangohud.x86_64 \
    # mangohud.i686 \
    # libobs_vkcapture.x86_64 \
    # libobs_glcapture.x86_64 \
    # libobs_vkcapture.i686 \
    # libobs_glcapture.i686 \
    # || true && \
    # sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/winetricks.desktop && \
    # curl -Lo /tmp/latencyflex.tar.xz $(curl https://api.github.com/repos/ishitatsuyuki/LatencyFleX/releases/latest | jq -r '.assets[] | select(.name| test(".*.tar.xz$")).browser_download_url') && \
    # mkdir -p /tmp/latencyflex && \
    # tar --no-same-owner --no-same-permissions --no-overwrite-dir --strip-components 1 -xvf /tmp/latencyflex.tar.xz -C /tmp/latencyflex && \
    # rm -f /tmp/latencyflex.tar.xz && \
    # cp -r /tmp/latencyflex/wine/usr/lib/wine/* /usr/lib64/wine/ && \
    # rm -rf /tmp/latencyflex && \
    # curl -Lo /usr/bin/latencyflex https://raw.githubusercontent.com/KyleGospo/LatencyFleX-Installer/main/install.sh && \
    # chmod +x /usr/bin/latencyflex && \
    # sed -i 's@/usr/lib/wine/@/usr/lib64/wine/@g' /usr/bin/latencyflex && \
    # sed -i 's@"dxvk.conf"@"/usr/share/latencyflex/dxvk.conf"@g' /usr/bin/latencyflex && \
    # chmod +x /usr/bin/latencyflex && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Install and configure Cosmic DE
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
    cosmic-desktop && \
    rpm-ostree install \
    gnome-keyring NetworkManager-tui \
    NetworkManager-openvpn && \
    ostree container commit

# Install Gamescope, ROCM, and Waydroid on non-Nvidia images
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
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
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Homebrew
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    touch /.dockerenv && \
    mkdir -p /var/home && \
    mkdir -p /var/roothome && \
    curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh && \
    chmod +x /tmp/brew-install && \
    /tmp/brew-install && \
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew && \
    /usr/libexec/containerbuild/cleanup.sh && \
    ostree container commit

# Finalize
COPY override /
RUN mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    systemctl disable gdm || true && \
    systemctl disable sddm || true && \
    systemctl enable cosmic-greeter && \
    /usr/libexec/containerbuild/image-info && \
    /usr/libexec/containerbuild/build-initramfs && \
    /usr/libexec/containerbuild/cleanup.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    ostree container commit
