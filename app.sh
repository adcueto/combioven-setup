#!/bin/bash

# usb_ovenapp
# 
# Descripción:
# Este script se utiliza para actualizar o revertir (rollback) la aplicación en la placa Forlinx.
# 
# Uso:
# ./app.sh update
# ./app.sh rollback <versión_del_software>
# 
# Ejemplos:
# ./app.sh update                # Actualiza a la última versión
# ./app.sh rollback 1.5.2        # Revierte a la versión 1.5.2
# 
# Nota:
# Asegúrese de que la memoria USB está montada en /media/usb y que el script tiene permisos de ejecución.
#
# Dependencias:
# - sudo
# - unzip
# Autor: 
# Jose Adrian Perez Cueto
# adrianjpca@gmail.com
##

# Archivo de registro
LOG_FILE="/var/log/usboven.log"
APP_PATH="/media/usb/app"
APP_DEST="/usr/crank/apps/ProServices"
LATEST_VERSION=$(ls -v "$APP_PATH" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1)

# Función para registrar mensajes en el archivo de registro
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Limpiar el archivo de log al iniciar
> "$LOG_FILE"

if [ $# -eq 0 ]; then
    echo "Error: Debe especificar 'update' o 'rollback <versión_del_software>' como argumento."
    echo "Uso: $0 update | rollback <versión_del_software>"
    exit 1
fi

operation=$1
version=$2

if [ "$operation" != "update" ] && [ "$operation" != "rollback" ]; then
    echo "Error: Operación no válida. Use 'update' o 'rollback <versión_del_software>'."
    exit 1
fi

if [ "$operation" = "rollback" ] && [ -z "$version" ]; then
    echo "Error: Debe especificar la versión del software para rollback."
    echo "Uso: $0 rollback <versión_del_software>"
    exit 1
fi


log_message  "Starting whith the app transfer..."

# 1. Crear carpeta "crank" en /usr
log_message "Creando carpeta crank en /usr..."
sudo mkdir -p /usr/crank

# 2. Crear carpetas "apps" y "runtimes" dentro de "crank"
log_message "Creando carpetas apps y runtime dentro de crank..."
sudo mkdir -p /usr/crank/apps /usr/crank/runtimes
sudo mkdir -p /usr/crank/apps/ProServices

# 3. Copiar archivo zip a runtimes y descomprimirlo
log_message "Descomprimiendo archivo linux-imx8yocto-armle-opengles..." 
sudo unzip -o /media/usb/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip -d /usr/crank/runtimes/

# 4. Asignar permisos 775 a runtimes y apps
log_message "Asignnando permisos 775 al directorio runtimes y apps..."
sudo chmod -R 775 /usr/crank/runtimes /usr/crank/apps

# 5. Copiar scripts a /usr/crank
log_message "Copiando scripts a /usr/crank"
sudo cp -f -r /media/usb/scripts/* /usr/crank/

# 6. Asignar permisos 0755 a los scripts
log_message "Asignando permisos 644 a los scripts..."
sudo chmod 775 /usr/crank/*

# 7. Copiar servicios a sus respectivos directorios
log_message "Copiando servicios a directorios..." 
sudo cp -f /media/usb/services/storyboard_splash.service /etc/systemd/system/
sudo cp -f /media/usb/services/storyboard.service /etc/systemd/system/
sudo cp -f /media/usb/services/combi_backend.service /lib/systemd/system/
sudo cp -f /media/usb/services/wired.network /etc/systemd/network/
sudo cp -f /media/usb/services/wireless.network /etc/systemd/network/
sudo cp -f /media/usb/services/wpa_supplicant@wlan0.service /etc/systemd/system/

# 8. Asignar permisos a los servicios
log_message "Asignando permisos a los servicios..." 
sudo chmod 0644 /etc/systemd/system/storyboard_splash.service
sudo chmod 0777 /etc/systemd/system/storyboard.service
sudo chmod 0644 /lib/systemd/system/combi_backend.service
sudo chmod 0644 /etc/systemd/network/wired.network
sudo chmod 0644 /etc/systemd/network/wireless.network
sudo chmod 0644 /etc/systemd/system/wpa_supplicant@wlan0.service

# 9 Remover los manejadores de conexiones 
log_message "Removiendo manejadores de conexiones..."
sudo rm -f /etc/resolv.conf
sudo rm -f /etc/tmpfiles.d/connman_resolvconf.conf
sudo systemctl stop connman
sudo systemctl stop connman-env
sudo systemctl disable connman
sudo systemctl disable connman-env

#10. Activar servicios
log_message "Activando servicios..."
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl stop wpa_supplicant
sudo systemctl disable wpa_supplicant

sudo systemctl daemon-reload
sudo systemctl enable storyboard_splash.service
sudo systemctl enable storyboard.service
sudo systemctl enable combi_backend.service
sudo systemctl enable wpa_supplicant@wlan0.service
sudo systemctl enable systemd-resolved.service

sudo systemctl start storyboard_splash.service
sudo systemctl start storyboard.service
sudo systemctl start combi_backend.service
sudo systemctl start wpa_supplicant@wlan0.service
sudo systemctl start systemd-resolved.service


#11. Cambiar el nombre del servicio weston
log_message "Cambiando el nombre del servicio weston..." 

if [ -e "/lib/systemd/system/weston.service" ]; then #verifica si existe el archivo
    sudo mv /lib/systemd/system/weston.service /lib/systemd/system/weston_Pro_S.service
    log_message "El nombre del servicio weston fue cambiado correctamente."
else 
    log_message "El archivo weston fue cambiado."
fi

#12. Copiar contenido de la carpeta "Application" a /usr/crank/apps/Pro-Services"
log_message "Copiando la versión $version a la carpeta apps..." 

if [ "$operation" = "update" ]; then
    log_message "Actualizando la aplicación"
    if [ -z "$LATEST_VERSION" ]; then
        log_message "No versions found in $APP_PATH"
        exit 1
    else
        sudo cp -f -r $APP_PATH/$LATEST_VERSION/* $APP_DEST
        log_message "Software version $LATEST_VERSION updated"
    fi
else
    log_message "Haciendo rollback a la versión $version"
    sudo cp -f -r $APP_PATH/$version/* $APP_DEST
fi

#13. Cambiar el logo de arranque
log_message  "Cambiando el logo de arranque del sistema..."
cp -f /media/usb/img/logo.bmp /run/media/mmcblk2p1/logo.bmp

#14. Reiniciar
log_message  "rebooting..."
#sudo reboot