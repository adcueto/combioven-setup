#!/bin/bash

# setup_combioven
#
# Description:
# This script configures the NXP Yocto board for the first time to run the combioven application by updating or rolling back the application using files from a USB drive or a GitHub repository.
# It automates the process of copying application files, setting permissions, and configuring system services to ensure a seamless setup.
#
# Author:
# Jose Adrian Perez Cueto
# adrianjpca@gmail.com
##

# Variables
LOG_FILE="/var/log/combioven-setup.log"
GITHUB_REPO_URL="https://github.com/adcueto/combioven-setup/archive/refs/heads/master.zip"
TEMP_DIR="/tmp/github_repo"
DOWNLOAD_FILE="/tmp/github_repo.zip"
USB_PATH="/media/usb"
EXTRACTED_DIR_NAME="combioven-setup-master"
APP_PATH_GITHUB="$TEMP_DIR/$EXTRACTED_DIR_NAME"
APP_PATH_USB="$USB_PATH"
APP_GUI="/usr/crank/apps/interface"
APP_BACKEND="/usr/crank/apps/backend"
APP_FIRMWARE="/usr/crank/apps/firmware"

# Trap to clean up temporary files on exit
trap "sudo rm -rf $TEMP_DIR $DOWNLOAD_FILE" EXIT

# Function to log messages to the log file
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local errmsg="$1"
    log_message "Error: $errmsg"
    exit 1
}

# Clear the log file at the start
> "$LOG_FILE"

# Check arguments
if [[ $# -lt 2 ]] || [[ "$1" != "update" && "$1" != "rollback" ]] || [[ "$2" != "usb" && "$2" != "github" ]] || ([[ "$1" == "rollback" ]] && [[ -z "$3" ]]); then
    handle_error "Invalid arguments. Usage: $0 update usb | update github | rollback usb <software_version> | rollback github <software_version>"
fi

operation=$1
source=$2
version=$3

log_message "Starting the application transfer..."

# Handle source: usb or github
if [[ "$source" == "github" ]]; then
    log_message "Downloading the repository zip file from GitHub..."
    [[ -f "$DOWNLOAD_FILE" ]] && rm -f "$DOWNLOAD_FILE"
    
    curl -L "$GITHUB_REPO_URL" -o "$DOWNLOAD_FILE" || handle_error "Failed to download repository zip file."
    [[ -f "$DOWNLOAD_FILE" ]] || handle_error "Downloaded file not found."

    log_message "Extracting the repository zip file..."
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    unzip -o "$DOWNLOAD_FILE" -d "$TEMP_DIR" || handle_error "Failed to extract repository zip file."

    APP_PATH="$APP_PATH_GITHUB"
else
    APP_PATH="$APP_PATH_USB"
fi

# Verify the extracted structure
log_message "Listing contents of the extracted directory:"
ls -l "$APP_PATH" | tee -a "$LOG_FILE"
[[ -d "$APP_PATH" ]] || handle_error "Directory '$APP_PATH' does not exist."

LATEST_VERSION=$(ls -v "$APP_PATH/gui" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1)
log_message "Latest version found: $LATEST_VERSION"

# Create necessary directories and clean existing ones
log_message "Creating and cleaning directory structure..."
sudo mkdir -p /usr/crank/apps /usr/crank/runtimes "$APP_GUI" "$APP_BACKEND" "$APP_FIRMWARE"
sudo rm -rf "${APP_GUI:?}"/* "${APP_BACKEND:?}"/* "${APP_FIRMWARE:?}"/*

# Unzip the file into runtimes
log_message "Unzipping linux-imx8yocto-armle-opengles file..."
ZIP_FILE="${APP_PATH}/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip"
[[ -f "$ZIP_FILE" ]] || handle_error "ZIP file not found: $ZIP_FILE"
sudo unzip -o "$ZIP_FILE" -d /usr/crank/runtimes/ || handle_error "Failed to unzip $ZIP_FILE"

# Set permissions
log_message "Setting permissions for runtimes and apps..."
sudo chmod -R 775 /usr/crank/runtimes /usr/crank/apps

# Copy scripts
log_message "Copying scripts to /usr/crank..."
if [[ -d "$APP_PATH/scripts" ]]; then
    log_message "Found scripts directory."
    ls -l "$APP_PATH/scripts" | tee -a "$LOG_FILE"
    sudo cp -f -r "$APP_PATH/scripts/"* /usr/crank/
    sudo chmod 775 /usr/crank/*
else
    log_message "Warning: Scripts directory not found. Skipping script copying."
fi

# Copy firmware and backend 
log_message "Copying firmware and backend files..."
for DEST in "$APP_FIRMWARE" "$APP_BACKEND"; do
    sudo cp -f -r "$APP_PATH/firmware/"* "$DEST"
    sudo chmod 775 "$DEST/"*
done

# Copy and configure services
log_message "Copying and configuring services..."
if [[ -d "$APP_PATH/services" ]]; then
    log_message "Found services directory."
    ls -l "$APP_PATH/services" | tee -a "$LOG_FILE"
    SERVICES=(
        "$APP_PATH/services/storyboard_splash.service:/etc/systemd/system/"
        "$APP_PATH/services/combioven_storyboard.service:/etc/systemd/system/"
        "$APP_PATH/services/combioven_backend.service:/lib/systemd/system/"
        "$APP_PATH/services/wired.network:/etc/systemd/network/"
        "$APP_PATH/services/wireless.network:/etc/systemd/network/"
        "$APP_PATH/services/wpa_supplicant@wlan0.service:/etc/systemd/system/"
    )

    for service in "${SERVICES[@]}"; do
        IFS=":" read src dest <<< "$service"
        sudo cp -f "$src" "$dest"
        sudo chmod 0755 "$dest"
    done
else
    handle_error "Services directory not found."
fi

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
    "combioven_storyboard.service"
    "combioven_backend.service"
    "wpa_supplicant@wlan0.service"
    "systemd-resolved.service"
)

log_message "Re-enabling and restarting services..."
ERROR=0
for service in "${SERVICES_TO_ENABLE[@]}"; do
    log_message "Enabling and starting $service..."
    systemctl enable "$service"
    systemctl restart "$service"
    if [[ $? -ne 0 ]]; then
        log_message "Error: Failed to restart $service"
        ERROR=1
    fi
done

[[ $ERROR -ne 0 ]] && handle_error "One or more services failed to restart."

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
        handle_error "No versions found in $APP_PATH/app"
    else
        sudo cp -f -r "$APP_PATH/gui/$LATEST_VERSION/"* "$APP_GUI"
        log_message "Software version $LATEST_VERSION updated"
    fi
else
    log_message "Rolling back to version $version..."
    sudo cp -f -r "$APP_PATH/gui/$version/"* "$APP_GUI"
fi

# Change boot logo
log_message "Changing the system boot logo..."
BOOT_LOGO="$APP_PATH/img/logo.bmp"
[[ -f "$BOOT_LOGO" ]] || handle_error "Boot logo file not found."
sudo cp -f "$BOOT_LOGO" /run/media/mmcblk2p1/logo.bmp

# Remove temporary files if source is github
if [[ "$source" == "github" ]]; then
    log_message "Removing temporary files..."
    sudo rm -rf "$TEMP_DIR" "$DOWNLOAD_FILE"
fi

# Sync changes and clear cache
log_message "Synchronizing file system and clearing cache..."
sync 
echo 3 > /proc/sys/vm/drop_caches

# Reboot
log_message "Rebooting..."
sleep 2
sudo reboot