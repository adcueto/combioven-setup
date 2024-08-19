
# CombiOven Setup Script

![Logo de la aplicación](/img/board.png)

Este repositorio contiene el script `combioven_setup.sh` que configura una tarjeta NXP Yocto para que funcione con la aplicación CombiOven. El script puede actualizar o hacer rollback de la aplicación utilizando archivos desde una unidad USB o desde un repositorio de GitHub.

## Descripción

El script `combioven_setup.sh` automatiza el proceso de copia de archivos de la aplicación, configuración de permisos y configuración de servicios del sistema para asegurar una instalación sin problemas.

## Uso

```bash
./combioven_setup.sh <operation> <source> [version]
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

## Pasos para cargar la aplicación desde una USB

1. **Crear carpeta USB**
   ```bash
   sudo mkdir /media/usb
   ```

2. **Listar los dispositivos conectados**
   ```bash
   ls -l /dev/sd*
   ```

3. **Montar la memoria USB**
   - Para sistemas de archivos FAT (Windows)
     ```bash
     sudo mount -t vfat /dev/sda1 /media/usb
     ```
   - Para sistemas de archivos ext4 (Linux)
     ```bash
     sudo mount -t ext4 /dev/sda1 /media/usb
     ```

4. **Dar permisos de ejecución**
   ```bash
   sudo chmod +x /media/usb/combioven_setup.sh
   ```

5. **Ejecutar el script para cargar la aplicación**
   - Ejemplo para realizar rollback
     ```bash
     /media/usb/combioven_setup.sh rollback usb 1.5.2 
     ```
   - Ejemplo para actualizar a la última versión de software
     ```bash
     /media/usb/combioven_setup.sh update usb
     ```

6. **Desmontar la memoria USB**
   ```bash
   sudo umount /media/usb
   ```

## Pasos para cargar la aplicación desde GitHub

1. **Conectarse a una red Wi-Fi**
   ```bash
   wifi.sh -i wlan0 -s NETWORK -p PASSWORD
   ```

2. **Ejecutar el script de actualización**
   - Para actualizar a la última versión
     ```bash
     curl -sS https://raw.githubusercontent.com/adcueto/combioven_setup/master/combioven_setup.sh | bash -s update github
     ```

   - Para realizar rollback a una versión anterior, asegúrate de que la versión exista en el repositorio.
     ```bash
     curl -sS https://raw.githubusercontent.com/adcueto/combioven_setup/master/combioven_setup.sh | bash -s rollback github 1.6.8
     ```

## Contribuciones

Las contribuciones son bienvenidas. Por favor, sigue las pautas del proyecto para contribuir.

## Licencia

Este proyecto está licenciado bajo los términos de la [Licencia MIT](LICENSE).
