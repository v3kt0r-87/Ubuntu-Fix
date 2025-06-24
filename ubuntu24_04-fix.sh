#!/bin/bash -e

clear

# Ask for the type of device
read -rp "What device is this? (pc / laptop): " device_type

# Add i386 architecture early
sudo dpkg --add-architecture i386

# Initial update & upgrade
sudo apt update && sudo apt upgrade -y

# Remove snap packages early
sudo snap remove --purge snap-store firefox || true
sudo snap refresh

# Add Bluetooth AAC codecs
sudo add-apt-repository -y ppa:aglasgall/pipewire-extra-bt-codecs
sudo apt update && sudo apt upgrade -y

# Install Kernel Manager
sudo add-apt-repository -y ppa:cappelikan/ppa
sudo apt update && sudo apt install -y mainline

clear

read -rp "Which GPU driver to use? (nvidia / mesa): " gpu_driver

if [ "$gpu_driver" == "nvidia" ]; then
    echo "Installing latest NVIDIA drivers..."
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt update && sudo apt install -y nvidia-driver-560 libvulkan1 libvulkan1:i386
elif [ "$gpu_driver" == "mesa" ]; then
    echo "Installing latest Mesa drivers..."
    sudo add-apt-repository -y ppa:kisak/kisak-mesa
    sudo apt update && sudo apt install -y \
        libgl1-mesa-dri:i386 \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        mesa-opencl-icd \
        ocl-icd-libopencl1 \
        clinfo
else
    echo "Invalid choice. Please enter 'nvidia' or 'mesa'."
    exit 1
fi

# Set up Flatpak and Flathub
sudo add-apt-repository -y ppa:flatpak/stable
sudo apt update && sudo apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Latest Git
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update && sudo apt install -y git

# Optional: Install TLP for laptops
if [[ "$device_type" == "laptop" ]]; then
    read -rp "Do you want to install TLP Service (y/n): " install_tlp
    if [[ "$install_tlp" =~ ^[Yy]$ ]]; then
        sudo add-apt-repository -y ppa:linrunner/tlp
        sudo apt update && sudo apt install -y tlp tlp-rdw
        sudo systemctl enable tlp.service
        sudo tlp start
    fi
fi

# Install essential APT packages
sudo apt install -y \
    xfsprogs btrfs-progs exfatprogs f2fs-tools gparted gcc g++ build-essential stacer \
    cmatrix htop lm-sensors net-tools mesa-utils openssh-server curl bison flex \
    patchelf python3 python-is-python3 python3-pip python3-mako zip ncdu meson gamemode \
    cabextract ttf-mscorefonts-installer gnome-browser-connector zram-tools \
    ubuntu-restricted-extras libfuse2t64 p7zip-full

# Flatpak apps
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    org.videolan.VLC \
    deluge \
    org.mozilla.firefox \
    onlyoffice \
    org.gnome.Extensions \
    io.github.peazip.PeaZip \
    org.telegram.desktop \
    com.dec05eba.gpu_screen_recorder \
    localsend

flatpak update -y

# Cloudflare Warp
read -rp "Install Cloudflare Warp? (y/n): " install_warp
if [[ "$install_warp" =~ ^[Yy]$ ]]; then
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/cloudflare-client.list > /dev/null
    sudo apt update && sudo apt install -y cloudflare-warp
fi

# Cleanup
sudo apt autoremove --purge -y
sudo apt autoclean
sudo apt clean

# Reboot notice
clear
echo "✅ All done! Rebooting in 5 seconds..."
sleep 5 && sudo reboot
