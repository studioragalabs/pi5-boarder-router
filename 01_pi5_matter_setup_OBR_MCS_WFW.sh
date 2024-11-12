#!/bin/bash

# --- Step 1: Update and Upgrade the System ---
echo "Step 1: Updating and upgrading system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# --- Step 2: Install Essential Development Tools and Libraries ---
echo "Step 2: Installing essential development tools..."
sudo apt-get install -y git build-essential cmake libssl-dev libdbus-1-dev \
python3 python3-pip python3-setuptools python3-wheel python3-dev \
net-tools avahi-daemon avahi-discover nmap libboost-dev libglib2.0-dev \
libevdev-dev libavahi-client-dev libavahi-common-dev ufw curl

# --- Step 3: Install Docker (Optional, for containerized applications) ---
echo "Step 3: Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# --- Step 4: Configure UFW (Uncomplicated Firewall) ---
echo "Step 4: Configuring UFW firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow necessary ports for Border Router and Matter
sudo ufw allow 80/tcp     # HTTP for Web UI
sudo ufw allow 8080/tcp    # Diagnostics Interface
sudo ufw allow 5683/udp    # CoAP protocol for Matter/Thread devices
sudo ufw allow 443/tcp     # HTTPS for secure Matter communication

sudo ufw enable
sudo ufw status

# --- Step 5: Set Up OpenThread Border Router on Raspberry Pi 5 ---
echo "Step 5: Setting up OpenThread Border Router..."
git clone https://github.com/openthread/ot-br-posix.git
cd ot-br-posix
./script/bootstrap
mkdir build
cd build
cmake -DOTBR_OPTIONS="..."
make
sudo make install
sudo systemctl enable otbr-agent
sudo systemctl start otbr-agent

# --- Step 6: Install NCP (Network Co-Processor) Firmware for OpenThread ---
echo "Step 6: Installing NCP firmware..."
git clone https://github.com/openthread/ot-ncp.git
cd ot-ncp
make -f examples/Makefile-nrf52840

# --- Step 7: Set Up Matter (Connected Home over IP) ---
echo "Step 7: Setting up Matter (Connected Home over IP)..."
cd ~
git clone https://github.com/project-chip/connectedhomeip.git
cd connectedhomeip
source scripts/activate.sh
git submodule update --init

# Install dependencies and bootstrap the Matter project
./scripts/bootstrap.sh

# Build Matter Lighting Example for testing purposes
cd examples/lighting-app/linux
gn gen out/debug
ninja -C out/debug

# --- Step 8: Set Up Matter Controller (For Commissioning Devices) ---
echo "Step 8: Setting up Matter Controller..."
cd ~/connectedhomeip/src/controller/python
python3 -m venv venv
source venv/bin/activate
pip install --requirement requirements.txt

# Start the Matter controller using the CLI
python3 chip-device-ctrl

# --- Step 9: Wi-Fi Configuration for Matter Devices (Panasonic Air Conditioner) ---
echo "Step 9: Configuring Wi-Fi and commissioning Matter-supported devices..."
# This part is crucial for configuring the Matter-supported device over Wi-Fi

# Configure the Wi-Fi connection on the Raspberry Pi
# Make sure you have Wi-Fi enabled on your Raspberry Pi and connected to the correct network
sudo raspi-config nonint do_wifi_country US
sudo raspi-config nonint do_wifi_ssid_passphrase "Your_SSID" "Your_Passphrase"

# Commission the Matter-supported Panasonic Air Conditioner
python3 chip-device-ctrl << EOF
# Example commands for Matter Controller to commission devices
connect -ble 3840
commission 3840 12345678 20202021
EOF

# --- Step 10: Final UFW Check and Firewall Status ---
echo "Step 10: Rechecking UFW firewall settings..."
sudo ufw status

echo "Setup complete! Your Raspberry Pi 5 is now configured to connect to Matter-supported devices over Wi-Fi."

