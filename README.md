# Script to upload the crank software app to the forlinx board
![Logo de la aplicación](/img/board.png)


Este repositorio contiene el script `setup_combioven.sh` que configura una tarjeta NXP Yocto para que funcione con la aplicación CombiOven. El script puede actualizar o hacer rollback de la aplicación utilizando archivos desde una unidad USB o desde un repositorio de GitHub.

## Descripción

El script `setup_combioven.sh` automatiza el proceso de copia de archivos de la aplicación, configuración de permisos y configuración de servicios del sistema para asegurar una instalación sin problemas.

## Uso

```bash
./setup_combioven.sh <operation> <source> [version]
```

### Operaciones

- `update`: Actualiza la aplicación a la última versión disponible.
- `rollback`: Realiza un rollback a una versión específica de la aplicación.

### Fuentes

- `usb`: Utiliza archivos desde una unidad USB montada en `/media/usb` con o sin internet.
- `github`: Descarga y utiliza archivos desde un repositorio de GitHub.

### Parámetros

- `<operation>`: `update` o `rollback`.
- `<source>`: `usb` o `github`.
- `[version]`: La versión específica para hacer rollback (requerido solo para `rollback`).

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
#Para sistemas de archivos FAT (windows)
```bash
sudo mount -t vfat /dev/sda1 /media/usb
```

#Para sistemas de archivos ext4 (linux)
```bash
sudo mount -t ext4 /dev/sda1 /media/usb
```
### 4. Dar permisos de ejecución
```bash
sudo chmod +x /media/usb/setup_combioven.sh
```
### 5. Ejecutar el script para cargar la aplicación
#Ejemplo para realizar rollback
```bash
/media/usb/setup_combioven.sh rollback usb 1.5.2 
```
#Ejemplo para realizar actualizar a la ultima versión de software
```bash
/media/usb/setup_combioven.sh update usb
```

### 6. Finalmente desmontar la memoria usb
```bash
sudo umount /media/usb
```

## Pasos para cargar la aplicación desde github:

### 1. Conectarse a una red wifi
```bash
wifi.sh -i wlan0 -s NETWORK -p PASSWORD
```
### 2. Ejecutar el script de actualización
#Para actualizar a la ultima version
```bash
curl -sS https://raw.githubusercontent.com/adcueto/usb_combioven/master/setup_combioven.sh | bash -s update github
```

#Para realizar rollback a una version anterior, asegurate que la versión exista en el repositorio.
```bash
curl -sS https://raw.githubusercontent.com/adcueto/usb_combioven/master/setup_combioven.sh | bash -s rollback github 1.6.3
```