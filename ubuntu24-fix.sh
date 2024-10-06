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

# Update Snap packages
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
sudo apt install xfsprogs exfatprogs f2fs-tools gparted gcc g++ build-essential stacer cmatrix htop lm-sensors net-tools mesa-utils openssh-server curl bison flex patchelf \
python3 python-is-python3 python3-pip python3-mako zip patchelf meson gamemode cabextract ttf-mscorefonts-installer -y 

# Optional: Install Cloudflare Warp
clear
read -p "Install Cloudflare Warp? (y/n): " install_warp

if [ "$install_warp" == "y" ]; then
    clear
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
    sudo apt-get update && sudo apt install cloudflare-warp -y
fi

# Finish: Notify and reboot
clear
echo "All done, Rebooting in 5 seconds..."
sleep 5 && sudo reboot
