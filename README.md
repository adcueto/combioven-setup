# script to upload the app to the forlinx board

## Pasos para cargar la aplicación:

### 1. Crear carpeta usb
```bash
mkdir /media/usb
```
### 2. Listar los dispositivos conectados
```bash
ls -l /dev/sd*
```

### 3. Montar la memoria USB
```bash
# Para sistemas de archivos FAT
mount -t vfat /dev/sda1 /media/usb
# Para sistemas de archivos ext4
mount -t ext4 /dev/sdb1 /media/usb
```
### 4. Dar permisos de ejecución
```bash
chmod +x app.sh
```
### 4. Ejecutar el script para cargar la aplicación
```bash
#Ejemplo
./app.sh 1.5.2
```

### 5. Finalmente desmontar la memoria usb
```bash
umount /media/usb
```

