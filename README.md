- Python 3.8.5
# Script to upload the app to the forlinx board
![Logo de la aplicación](/img/board.png)
## Pasos para cargar la aplicación:
Copia toda los archivos del repositorio a una memoria usb en formato EXT o FAT.

### 1. Crear carpeta usb
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
sudo chmod +x app.sh
```
### 5. Ejecutar el script para cargar la aplicación
```bash
#Ejemplo
./app.sh rollback 1.5.2
./app.sh update
```

### 6. Finalmente desmontar la memoria usb
```bash
sudo umount /media/usb
```

