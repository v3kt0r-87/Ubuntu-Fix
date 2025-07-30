#!/bin/bash -e

clear
read -rp "What device is this? (pc / laptop): " device_type

clear
echo "Adding i386 architecture support..."
sleep 2
sudo dpkg --add-architecture i386 >/dev/null 2>&1

clear
echo "Updating your system..."
sleep 2
sudo apt update >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1

clear
echo "Removing Snap packages (if installed)..."
sleep 2
sudo snap remove --purge snap-store firefox >/dev/null 2>&1 || true
sudo snap refresh >/dev/null 2>&1

clear
echo "🎧 Adding Bluetooth AAC codec support..."
sleep 2
sudo add-apt-repository -y ppa:aglasgall/pipewire-extra-bt-codecs >/dev/null 2>&1
sudo apt update >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1

clear
read -rp "Install Xanmod Kernel? (y/n): " install_xanmod
if [[ "$install_xanmod" =~ ^[Yy]$ ]]; then
    clear
    echo "Enabling NTSYNC module..."
    sleep 2
    echo ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null

    echo "🌐 Adding Xanmod Kernel repository..."
    sleep 2
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /etc/apt/keyrings/xanmod-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $(lsb_release -sc) main" | \
        sudo tee /etc/apt/sources.list.d/xanmod-release.list >/dev/null
        
    echo "Installing Xanmod Kernel..."
    sleep 2
    sudo apt update >/dev/null 2>&1 && sudo apt install -y linux-xanmod-edge-x64v3 dkms libdw-dev lld >/dev/null 2>&1
fi

clear
echo "Installing Mainline Kernel Manager..."
sleep 2
sudo add-apt-repository -y ppa:cappelikan/ppa >/dev/null 2>&1
sudo apt update >/dev/null 2>&1 && sudo apt install -y mainline >/dev/null 2>&1

clear
read -rp "Which GPU driver to use? (Mesa (AMD and Intel) / Nvidia (GTX 10 series and above ...)): " gpu_driver
if [[ "$gpu_driver" == "nvidia" ]]; then
    clear
    echo "Installing latest NVIDIA drivers..."
    sleep 2
    sudo add-apt-repository -y ppa:graphics-drivers/ppa >/dev/null 2>&1
    sudo apt update >/dev/null 2>&1 && sudo apt install -y nvidia-driver-575 libvulkan1 libvulkan1:i386 >/dev/null 2>&1
elif [[ "$gpu_driver" == "mesa" ]]; then
    clear
    echo "🎮 Installing latest Mesa drivers (AMD/Intel)..."
    sleep 2
    sudo add-apt-repository -y ppa:kisak/kisak-mesa >/dev/null 2>&1
    sudo apt update >/dev/null 2>&1 && sudo apt install -y \
        libgl1-mesa-dri:i386 \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        mesa-opencl-icd \
        ocl-icd-libopencl1 \
        clinfo >/dev/null 2>&1
else
    clear
    echo "❌ Invalid choice. Please enter 'nvidia' or 'mesa' ... aborting "
    exit 1
fi

clear
echo "Setting up Flatpak + Flathub..."
sleep 2
sudo add-apt-repository -y ppa:flatpak/stable >/dev/null 2>&1
sudo apt update >/dev/null 2>&1 && sudo apt install -y flatpak gnome-software-plugin-flatpak >/dev/null 2>&1
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1

clear
echo "Installing latest Git..."
sleep 2
sudo add-apt-repository -y ppa:git-core/ppa >/dev/null 2>&1
sudo apt update >/dev/null 2>&1 && sudo apt install -y git >/dev/null 2>&1

clear
if [[ "$device_type" == "laptop" ]]; then
    read -rp "Do you want to install TLP Power Manager? (y/n): " install_tlp
    if [[ "$install_tlp" =~ ^[Yy]$ ]]; then
        clear
        echo "Installing TLP for better battery performance..."
        sleep 2
        sudo add-apt-repository -y ppa:linrunner/tlp >/dev/null 2>&1
        sudo apt update >/dev/null 2>&1 && sudo apt install -y tlp tlp-rdw >/dev/null 2>&1
        sudo systemctl enable tlp.service >/dev/null 2>&1
        sudo tlp start >/dev/null 2>&1
    fi
fi

clear
echo "Installing essential system packages..."
sleep 2
sudo apt install -y \
    xfsprogs btrfs-progs exfatprogs f2fs-tools gparted gcc g++ build-essential stacer \
    cmatrix htop lm-sensors net-tools mesa-utils openssh-server curl bison flex \
    patchelf python3 python-is-python3 python3-pip python3-mako zip ncdu meson-1.5 gamemode \
    cabextract ttf-mscorefonts-installer gnome-browser-connector zram-tools \
    ubuntu-restricted-extras libfuse2t64 p7zip-full glslang-tools vulkan-tools util-linux util-linux-extra >/dev/null 2>&1

clear
echo "Setting the RTC (hardware clock) to local time"
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true
sudo hwclock --systohc 

clear
echo "Installing Flatpak apps..."
sleep 2
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
    localsend >/dev/null 2>&1

clear
echo "Updating Flatpak apps..."
sleep 2
flatpak update -y >/dev/null 2>&1

clear
read -rp "Install Cloudflare WARP VPN? (y/n): " install_warp
if [[ "$install_warp" =~ ^[Yy]$ ]]; then
    clear
    echo "Installing Cloudflare WARP VPN..."
    sleep 2
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | \
        sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg >/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null
    sudo apt update >/dev/null 2>&1 && sudo apt install -y cloudflare-warp >/dev/null 2>&1
fi

clear
echo "🧹 Cleaning up unused packages..."
sleep 2
sudo apt autoremove --purge -y >/dev/null 2>&1
sudo apt autoclean >/dev/null 2>&1
sudo apt clean >/dev/null 2>&1

clear
echo "All done! , Please reboot your system ..."
sleep 2
