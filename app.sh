#!/bin/bash

# usb_combioven
#
# Description:
# This script updates or rolls back the application on the Forlinx board. It automates
# the process of copying application files, setting permissions, and configuring system
# services to ensure a seamless update or rollback.
#
# Usage:
# ./app.sh update
# ./app.sh rollback <software_version>
#
# Examples:
# ./app.sh update                # Updates to the latest version available on the USB drive
# ./app.sh rollback 1.5.2        # Rolls back to version 1.5.2
#
# Note:
# Ensure the USB drive is mounted at /media/usb and that the script has execution permissions.
# This script requires 'sudo' privileges to execute certain commands.
#
# Dependencies:
# - sudo: To execute commands with superuser privileges
# - unzip: To extract application archives
#
# Author:
# Jose Adrian Perez Cueto
# adrianjpca@gmail.com
##

# Variables
LOG_FILE="/var/log/usboven.log"
APP_PATH="/media/usb/app"
APP_DEST="/usr/crank/apps/ProServices"
LATEST_VERSION=$(ls -v "$APP_PATH" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1)

# Function to log messages to the log file
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Clear the log file at the start
> "$LOG_FILE"

# Check arguments
if [[ $# -eq 0 ]]; then
    log_message  "Error: You must specify 'update' or 'rollback <software_version>' as an argument."
    log_message  "Usage: $0 update | rollback <software_version>"
    exit 1
fi

operation=$1
version=$2


if [[ "$operation" != "update" && "$operation" != "rollback" ]]; then
    echo "Error: Invalid operation. Use 'update' or 'rollback <software_version>'."
    exit 1
fi

if [[ "$operation" == "rollback" && -z "$version" ]]; then
    echo "Error: You must specify the software version for rollback."
    echo "Usage: $0 rollback <software_version>"
    exit 1
fi

log_message "Starting the application transfer..."

# Create necessary directories
log_message "Creating directory structure..."
sudo mkdir -p /usr/crank/apps /usr/crank/runtimes /usr/crank/apps/ProServices

# Unzip file into runtimes
log_message "Unzipping linux-imx8yocto-armle-opengles file..."
sudo unzip -o /media/usb/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip -d /usr/crank/runtimes/

# Set permissions
log_message "Setting 0775 permissions for runtimes and apps..."
sudo chmod -R 775 /usr/crank/runtimes /usr/crank/apps

# Copy scripts
log_message "Copying scripts to /usr/crank..."
sudo cp -f -r /media/usb/scripts/* /usr/crank/
sudo chmod 775 /usr/crank/*

# Copy and configure services
log_message "Copying and configuring services..."

SERVICES=(
    "/media/usb/services/storyboard_splash.service:/etc/systemd/system/"
    "/media/usb/services/storyboard.service:/etc/systemd/system/"
    "/media/usb/services/combi_backend.service:/lib/systemd/system/"
    "/media/usb/services/wired.network:/etc/systemd/network/"
    "/media/usb/services/wireless.network:/etc/systemd/network/"
    "/media/usb/services/wpa_supplicant@wlan0.service:/etc/systemd/system/"
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
sudo cp -f /media/usb/img/logo.bmp /run/media/mmcblk2p1/logo.bmp

#14. Reiniciar
log_message  "rebooting..."
sudo reboot