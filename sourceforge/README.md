# PekarchOS 0.3.0

Arch Linux en español con KDE Plasma 6 en Wayland. Es una ISO en vivo: la arrancas desde un USB, la pruebas sin tocar el disco y, si te gusta, la instalas.

## Qué descargar

- `pekarchos-0.3.0-x86_64.iso`: la imagen completa, en un solo archivo.
- `SHA256SUMS`: las sumas para comprobar que la descarga está bien.

Comprueba la ISO en la carpeta donde la descargaste:

```bash
sha256sum -c --ignore-missing SHA256SUMS
```

## Grabarla en un USB

Necesitas un USB de 8 GiB o más. Vale con Ventoy (copias la ISO y listo), balenaEtcher, Rufus en modo DD o, en Linux:

```bash
sudo dd if=pekarchos-0.3.0-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Cambia `/dev/sdX` por tu USB: se borra entero.

## Arrancar

El menú de arranque, en BIOS y en UEFI, tiene tres entradas:

- **PekarchOS**: la normal.
- **Compatibilidad Ryzen/USB**: para placas Ryzen de primera generación que se quedan en pantalla negra o gris, o si el ratón y el teclado dejan de responder.
- **Gráficos seguros**: arranca con `nomodeset` y sin animación, por si falla la gráfica.

Usuario del modo en vivo: `live`, contraseña `live`.

## Instalar

En el escritorio, «Instalar PekarchOS (gráfico)» abre el instalador Calamares. «Instalar PekarchOS» es el instalador de terminal: copia el sistema al disco sin necesidad de internet. Haz una copia de seguridad antes de instalar.

## Requisitos

- Procesador de 64 bits
- 4 GiB de RAM (mejor 8)
- 20 GiB de disco
- UEFI o BIOS

## Problemas conocidos

- Las NVIDIA Fermi (serie 390, por ejemplo la GTX 570) no tienen controlador propietario; funcionan con nouveau.
- Algunas placas Ryzen de primera generación necesitan la entrada «Compatibilidad Ryzen/USB».
- Con nouveau antiguo puede no verse el logo de arranque.

## Más información

- Código, notas completas y fallos: https://github.com/pekapro-lab/pekarchos
- Notas de la versión: https://github.com/pekapro-lab/pekarchos/releases/tag/v0.3.0

Hecho por Peka (Pekapro). Licencia del logotipo: CC BY-SA 4.0.
