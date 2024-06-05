#!/bin/bash

# Verificación de argumento de versión
if [ $# -eq 0 ]; then
    echo "Error: Debe especificar la versión del software como argumento."
    echo "Uso: $0 <versión_del_software>"
    exit 1
fi
# Versión del software proporcionada como argumento
version="$1"

# Archivo de registro
log_file = "out.log"
rm -f $log_file

# Función para registrar mensajes en el archivo de registro
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$log_file"
}

log_message  "Starting whith the app transfer..."

# 1. Crear carpeta "crank" en /usr
log_message "Creando carpeta crank en /usr"
sudo mkdir -p /usr/crank

# 2. Crear carpetas "apps" y "runtimes" dentro de "crank"
log_message "Creando carpetas apps y runtime dentro de crank"
sudo mkdir -p /usr/crank/apps /usr/crank/runtimes
sudo mkdir -p /usr/crank/apps/ProServices

# 3. Copiar archivo zip a runtimes y descomprimirlo
log_message "Descomprimiendo archivo linux-imx8yocto-armle-opengles" 
sudo unzip /media/usb/linux/linux-imx8yocto-armle-opengles_2.0-7.0-40118.zip -d /usr/crank/runtimes/


# 4. Asignar permisos 775 a runtimes y apps
log_message "Asignnando permisos 775 al directorio runtimes y apps"
sudo chmod -R 775 /usr/crank/runtimes /usr/crank/apps

# 5. Copiar scripts a /usr/crank
log_message "Copiar scripts a /usr/crank"
sudo cp -f -r /media/usb/scripts/* /usr/crank/

# 6. Asignar permisos 0755 a los scripts
log_message "Asignando permisos 644 a los scripts"
sudo chmod 775 /usr/crank/*

# 7. Copiar servicios a sus respectivos directorios
log_message "Copiando servicios a sus respectivos directorios" 
sudo cp -f /media/usb/services/storyboard_splash.service /etc/systemd/system/
sudo cp -f /media/usb/services/storyboard.service /etc/systemd/system/
sudo cp -f /media/usb/services/combi_backend.service /lib/systemd/system/

# 8. Asignar permisos a los servicios
log_message "Asignando permisos a los servicios" 
sudo chmod 0644 /etc/systemd/system/storyboard_splash.service
sudo chmod 0777 /etc/systemd/system/storyboard.service
sudo chmod 0644 /lib/systemd/system/combi_backend.service

# 9. Activar servicios
log_message "Activando servicios"
sudo systemctl daemon-reload
sudo systemctl enable storyboard_splash.service
sudo systemctl enable storyboard.service
sudo systemctl enable combi_backend.service
sudo systemctl start storyboard_splash.service
sudo systemctl start storyboard.service
sudo systemctl start combi_backend.service

# 10. Cambiar el nombre del servicio weston
log_message "Cambiando el nombre del servicio weston" 
if [ -e "/lib/systemd/system/weston.service"];then #verifica si existe el archivo
    sudo mv /lib/systemd/system/weston.service /lib/systemd/system/weston_Pro_S.service
else 
    log_message "El archivo ya fue cambiado."

# 11. Copiar contenido de la carpeta "Application" a /usr/crank/apps/Pro-Services"
log_message "Copiando la versión $version a la carpeta apps" 
sudo cp -f -r /media/usb/app/* /usr/crank/apps/ProServices/
sudo cp -f -r /media/usb/app/$version/* /usr/crank/apps/ProServices/


# 12. Cambiar el logo de arranque
echo "Cambiando el logo de arranque"
cp -f /media/usb/img/logo.bmp /run/media/mmcblk2p1/logo.bmp

#13. Reiniciar
sudo reboot

