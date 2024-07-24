# Script to upload the crank software app to the forlinx board
![Logo de la aplicación](/img/board.png)

## Pasos para cargar la aplicación desde una USB:

### 1. Crear carpeta usb
Copia toda los archivos del repositorio a una memoria usb en formato EXT o FAT.
```bash
sudo mkdir /media/usb
```
### 2. Listar los dispositivos conectados
```bash
ls -l /dev/sd*
```

### 3. Montar la memoria USB
```bash
# Para sistemas de archivos FAT (windows)
sudo mount -t vfat /dev/sda1 /media/usb
```
```bash
# Para sistemas de archivos ext4 (linux)
sudo mount -t ext4 /dev/sda1 /media/usb
```
### 4. Dar permisos de ejecución
```bash
sudo chmod +x /media/usb/app.sh
```
### 5. Ejecutar el script para cargar la aplicación
#Ejemplo
```bash
/media/usb/app.sh rollback 1.5.2
/media/usb/app.sh update
```

### 6. Finalmente desmontar la memoria usb
```bash
sudo umount /media/usb
```

## Pasos para cargar la aplicación desde github:

### 1. Conectarse a una red wifi
```bash
wifi.sh -i wlan0 -s PRO-SERVICIOS -p M4W2_AE566x
```
### 2. Ejecutar el script de actualización
#Para actualizar a la ultima version
```bash
curl -sS https://raw.githubusercontent.com/adcueto/usb_combioven/master/app_from_github.sh | bash -s update
```

#Para realizar rollback a una version anterior, asegurate que la verion exista en el repositorio.
```bash
curl -sS https://raw.githubusercontent.com/adcueto/usb_combioven/master/app_from_github.sh | bash -s rollback 1.6.3
```
