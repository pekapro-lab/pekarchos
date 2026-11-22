# Plantilla de notas de PekarchOS

Copia este archivo a `RELEASE_NOTES.md` al preparar una versión. El flujo de
GitHub publica ese archivo tal cual cuando se etiqueta `v*`. No dejes los
huecos: una release sin texto no explica nada.

```markdown
# PekarchOS X.Y.Z

Una frase de qué es esta imagen.

## Novedades

- …

## Requisitos

- Procesador de 64 bits
- 4 GiB de RAM
- 20 GiB de disco
- UEFI o BIOS

## Usuario del medio en vivo

Usuario `live`, contraseña `live`. El escritorio entra solo.
Antes de instalar, haz una copia de seguridad.

## Comprobar la descarga

SHA256SUMS trae el nombre del archivo, sin carpetas, y la suma de cada parte.

    sha256sum -c SHA256SUMS

## Unir las partes

Linux y Termux:

    cat pekarchos-X.Y.Z-x86_64.iso.part*.bin > pekarchos-X.Y.Z-x86_64.iso

Windows, en la carpeta de las partes (ajusta cuántas hay):

    copy /b pekarchos-X.Y.Z-x86_64.iso.part00.bin+pekarchos-X.Y.Z-x86_64.iso.part01.bin+pekarchos-X.Y.Z-x86_64.iso.part02.bin pekarchos-X.Y.Z-x86_64.iso

## Instalación

«Instalar PekarchOS» copia el live al disco y no necesita internet.

## Problemas conocidos

- …
```
