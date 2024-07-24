#!/bin/bash

# setup_combioven
#
# Description:
# This script configures the NXP Yocto board for the first time to run the combioven application by updating or rolling back the application using files from a USB drive or a GitHub repository.
# It automates the process of copying application files, setting permissions, and configuring system services to ensure a seamless setup.
#
# Usage:
# ./setup_combioven.sh update usb
# ./setup_combioven.sh update github
# ./setup_combioven.sh rollback usb <software_version>
# ./setup_combioven.sh rollback github <software_version>
#
# Examples:
# ./setup_combioven.sh update usb                # Updates to the latest version available on the USB drive
# ./setup_combioven.sh rollback github 1.5.2     # Rolls back to version 1.5.2 from GitHub
#
# Note:
# Ensure the USB drive is mounted at /media/usb if using USB.
# This script requires 'sudo' privileges to execute certain commands.
#
# Dependencies:
# - sudo: To execute commands with superuser privileges
# - unzip: To extract application archives
# - curl or wget: To download files from the GitHub repository if using GitHub
#
# Author:
# Jose Adrian Perez Cueto
# adrianjpca@gmail.com
##

# Variables
LOG_FILE="/var/log/setup_combioven.log"
GITHUB_REPO_URL="https://github.com/adcueto/usb_combioven/archive/refs/heads/master.zip"
TEMP_DIR="/tmp/github_repo"
DOWNLOAD_FILE="/tmp/github_repo.zip"
USB_PATH="/media/usb"
APP_PATH_GITHUB="$TEMP_DIR/usb_combioven-master/app"
APP_PATH_USB="$USB_PATH/app"
APP_DEST="/usr/crank/apps/ProServices"

# Function to log messages to the log file
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Clear the log file at the start
> "$LOG_FILE"

# Check arguments
if [[ $# -lt 2 ]]; then
    log_message "Error: You must specify 'update' or 'rollback <software_version>' as an argument and 'usb' or 'github' as source."
    log_message "Usage: $0 update usb | update github | rollback usb <software_version> | rollback github <software_version>"
    exit 1
fi

operation=$1
source=$2
version=$3

if [[ "$operation" != "update" && "$operation" != "rollback" ]]; then
    echo "Error: Invalid operation. Use 'update' or 'rollback <software_version>'."
    exit 1
fi

if [[ "$operation" == "rollback" && -z "$version" ]]; then
    echo "Error: You must specify the software version for rollback."
    echo "Usage: $0 rollback usb <software_version> | rollback github <software_version>"
    exit 1
fi

log_message "Starting the application transfer..."

# Handle source: usb or github
if [[ "$source" == "github" ]]; then
    # Download the GitHub repository zip file
    log_message "Downloading the repository zip file from GitHub..."
    if [[ -f "$DOWNLOAD_FILE" ]]; then
        rm -f "$DOWNLOAD_FILE"
    fi

    curl -L "$GITHUB_REPO_URL" -o "$DOWNLOAD_FILE"
    if [[ $? -ne 0 ]]; then
        log_message "Error: Failed to download repository zip file."
        exit 1
    fi

    # Check if the file was downloaded
    if [[ ! -f "$DOWNLOAD_FILE" ]]; then
        log_message "Error: Downloaded file not found."
        exit 1
    fi

    # Extract the downloaded zip file
    log_message "Extracting the repository zip file..."
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    mkdir -p "$TEMP_DIR"
    unzip -o "$DOWNLOAD_FILE" -d "$TEMP_DIR"
    if [[ $? -ne 0 ]]; then
        log_message "Error: Failed to extract repository zip file."
        exit 1
    fi

    APP_PATH="$APP_PATH_GITHUB"
else
    APP_PATH="$APP_PATH_USB"
fi

# Verifying the extracted structure
log_message "Verifying extracted structure..."
ls -l "$TEMP_DIR/usb_combioven-master" | tee -a "$LOG_FILE"

# Check if the required directories exist
if [[ ! -d "$APP_PATH" ]]; then
    log_message "Error: Directory '$APP_PATH' does not exist."
    exit 1
fi

LATEST_VERSION=$(ls -v "$APP_PATH" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1)
log_message "Latest version found: $LATEST_VERSION"

# Create necessary directories
log_message "Creating directory structure..."
sudo mkdir -p /usr/crank/apps /usr/crank/runtimes /usr/crank/apps/ProServices

# Unzip file into runtimes
log_message "Unzipping linux-imx8yocto-armle-opengles file..."
if [[ "$source" == "github" ]]; then
    ZIP_FILE="$TEMP_DIR/usb_combioven-master/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip"
else
    ZIP_FILE="$USB_PATH/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip"
fi

if [[ ! -f "$ZIP_FILE" ]]; then
    log_message "Error: ZIP file not found: $ZIP_FILE"
    exit 1
fi
sudo unzip -o "$ZIP_FILE" -d /usr/crank/runtimes/
if [[ $? -ne 0 ]]; then
    log_message "Error: Failed to unzip $ZIP_FILE"
    exit 1
fi

# Set permissions
log_message "Setting 0775 permissions for runtimes and apps..."
sudo chmod -R 775 /usr/crank/runtimes /usr/crank/apps

# Copy scripts
log_message "Copying scripts to /usr/crank..."
if [[ -d "$APP_PATH/scripts" ]]; then
    sudo cp -f -r "$APP_PATH/scripts/"* /usr/crank/
    sudo chmod 775 /usr/crank/*
else
    log_message "Warning: Scripts directory not found. Skipping script copying."
fi

# Copy and configure services
log_message "Copying and configuring services..."
if [[ ! -d "$APP_PATH/services" ]]; then
    log_message "Error: Services directory not found."
    exit 1
fi

SERVICES=(
    "$APP_PATH/services/storyboard_splash.service:/etc/systemd/system/"
    "$APP_PATH/services/storyboard.service:/etc/systemd/system/"
    "$APP_PATH/services/combi_backend.service:/lib/systemd/system/"
    "$APP_PATH/services/wired.network:/etc/systemd/network/"
    "$APP_PATH/services/wireless.network:/etc/systemd/network/"
    "$APP_PATH/services/wpa_supplicant@wlan0.service:/etc/systemd/system/"
)

for service in "${SERVICES[@]}"; do
    IFS=":" read src dest <<< "$service"
    sudo cp -f "$src" "$dest"
    sudo chmod 0755 "$dest"
done

# Remove connection handlers
log_message "Removing connection handlers..."
sudo rm -f /etc/resolv.conf /etc/tmpfiles.d/connman_resolvconf.conf
sudo systemctl stop connman connman-env
sudo systemctl disable connman connman-env

# Enable services
log_message "Enabling services..."
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl stop wpa_supplicant
sudo systemctl disable wpa_supplicant
sudo systemctl daemon-reload

SERVICES_TO_ENABLE=(
    "storyboard_splash.service"
    "storyboard.service"
    "combi_backend.service"
    "wpa_supplicant@wlan0.service"
    "systemd-resolved.service"
)

for service in "${SERVICES_TO_ENABLE[@]}"; do
    sudo systemctl enable "$service"
    sudo systemctl start "$service"
done

# Rename weston service
log_message "Renaming weston service..."
if [[ -e "/lib/systemd/system/weston.service" ]]; then
    sudo mv /lib/systemd/system/weston.service /lib/systemd/system/weston_Pro_S.service
    log_message "The weston service was renamed successfully."
else
    log_message "The weston service file was already renamed."
fi

# Update or rollback the application
log_message "Copying version $version to the apps directory..."
if [[ "$operation" == "update" ]]; then
    log_message "Updating the application..."
    if [[ -z "$LATEST_VERSION" ]]; then
        log_message "No versions found in $APP_PATH"
        exit 1
    else
        sudo cp -f -r "$APP_PATH/$LATEST_VERSION/"* "$APP_DEST"
        log_message "Software version $LATEST_VERSION updated"
    fi
else
    log_message "Rolling back to version $version..."
    sudo cp -f -r "$APP_PATH/$version/"* "$APP_DEST"
fi

# Change boot logo
log_message "Changing the system boot logo..."
if [[ "$source" == "github" ]]; then
    BOOT_LOGO="$TEMP_DIR/usb_combioven-master/img/logo.bmp"
else
    BOOT_LOGO="$USB_PATH/img/logo.bmp"
fi

if [[ ! -f "$BOOT_LOGO" ]]; then
    log_message "Error: Boot logo file not found."
    exit 1
fi
sudo cp -f "$BOOT_LOGO" /run/media/mmcblk2p1/logo.bmp

# Remove temporary files if source is github
if [[ "$source" == "github" ]]; then
    log_message "Removing temporary files..."
    sudo rm -rf "$TEMP_DIR" "$DOWNLOAD_FILE"
fi

# Reboot
log_message "Rebooting..."
sudo reboot