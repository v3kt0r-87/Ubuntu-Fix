#!/bin/bash -e

clear

# Ask for the type of device (PC or laptop)
read -p "What device is this? (pc / laptop) : " device_type

# Update system and enable i386 architecture
sudo apt update && sudo apt upgrade -y
sudo dpkg --add-architecture i386

# Install AAC Bluetooth codecs (Ubuntu doesn't ship them by default)
sudo add-apt-repository ppa:aglasgall/pipewire-extra-bt-codecs
sudo apt update && sudo apt upgrade -y

# Install Kernel Manager
sudo add-apt-repository ppa:cappelikan/ppa
sudo apt update && sudo apt install mainline -y

clear

# Prompt user for GPU driver preference
read -p "Which GPU driver to use? Type 'nvidia' or 'mesa': " gpu_driver

# Make sure Secure Boot is off otherwise you will get this error message below :
# NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. 
# Make sure that the latest NVIDIA driver is installed and running.

# Now using Latest 560 drivers instead of 555

if [ "$gpu_driver" == "nvidia" ]; then
    clear
    echo "Installing the latest Nvidia drivers..."
    sudo add-apt-repository ppa:graphics-drivers/ppa 
    sudo apt update
    sudo apt install -y nvidia-driver-560 libvulkan1 libvulkan1:i386
elif [ "$gpu_driver" == "mesa" ]; then
    clear
    echo "Installing the latest Mesa drivers..."
    sudo add-apt-repository ppa:kisak/kisak-mesa 
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y libgl1-mesa-dri:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386
else
    clear
    echo "Invalid choice. Please select either 'nvidia' or 'mesa'."
    exit 1
fi

clear

# Update Snap packages and remmove some snaps
sudo snap remove --purge snap-store
sudo snap remove --purge firefox
sudo snap refresh

# Install Flatpak
sudo add-apt-repository ppa:flatpak/stable
sudo apt update
sudo apt install flatpak gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install latest Git
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install -y git

clear

# Install flatpak apps
flatpak install com.github.tchx84.Flatseal org.mozilla.firefox onlyoffice org.gnome.Extensions io.github.peazip.PeaZip org.telegram.desktop com.dec05eba.gpu_screen_recorder localsend
flatpak update

# Optional: Install TLP if the device is a laptop
if [ "$device_type" == "laptop" ]; then
    read -p "Do you want to install TLP Service (y/n) : " install_tlp

    if [ "$install_tlp" == "y" ]; then
        clear
        sudo add-apt-repository ppa:linrunner/tlp
        sudo apt update
        sudo apt install tlp tlp-rdw -y
        sudo systemctl enable tlp.service
        sudo tlp start
    fi
fi

clear

# Install essential packages
sudo apt update
sudo apt install xfsprogs btrfs-progs exfatprogs f2fs-tools gparted gcc g++ build-essential stacer cmatrix htop lm-sensors net-tools mesa-utils openssh-server curl bison flex patchelf \
python3 python-is-python3 python3-pip python3-mako zip patchelf meson gamemode cabextract ttf-mscorefonts-installer gnome-browser-connector zram-tools corectrl 7zip ubuntu-restricted-extras libfuse2t64 vlc deluge -y 

# Optional: Install Cloudflare Warp
clear
read -p "Install Cloudflare Warp? (y/n): " install_warp

if [ "$install_warp" == "y" ]; then
    clear
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
    sudo apt-get update && sudo apt install cloudflare-warp -y
fi

# Cleanup
sudo apt autoremove --purge -y
sudo apt autoclean

# Finish: Notify and reboot
clear
echo "All done, Rebooting in 5 seconds..."
sleep 5 && sudo reboot
