# Terceros

## Candy Icons

- Proyecto: [EliverLara/candy-icons](https://github.com/EliverLara/candy-icons)
- Licencia: GPL-3.0 (archivo `LICENSE` dentro del tema)
- Commit fijado: `branding/pins/candy-icons.commit`
- Uso: tema de iconos por defecto (`candy-icons`) en el live y en el sistema instalado
- Respaldo: `index.theme` queda con `Inherits=breeze-dark,breeze,Adwaita,hicolor`. Breeze ya va en la ISO, así que un icono que Candy no traiga sale del tema heredado.
- Cambio local: `FollowsColorScheme=false` para que Plasma no destiña el degradado neón. El resto del tema no se modifica.

La construcción clona ese commit. Los iconos no se guardan en git.

## Sweet (no incluido)

El tema Plasma [EliverLara/Sweet-kde](https://github.com/EliverLara/Sweet-kde) es CC BY-SA 4.0, pero declara `X-Plasma-API=5.0`. En Plasma 6 no sirve como estilo. El esquema de color, el acento y la decoración de ventanas son PekarchOS Neon (CC0) sobre el estilo Breeze (LGPL, paquete `breeze`), que toma esos colores. El cursor sigue siendo Breeze (`breeze_cursors`).

## Esquema, fondo, SDDM y Konsole

El fondo, los esquemas de color, el código QML del tema de SDDM y el perfil de Konsole son obra de Pekapro, CC0-1.0. Ver [CREDITS.md](CREDITS.md).

## Logotipo

- Autor: Peka / Pekapro
- Licencia: CC BY-SA 4.0. Ver [LICENSE-ARTWORK](LICENSE-ARTWORK)
- Origen: `branding/logo/logo-2-limpio.png`
- De ahí salen el emblema, los iconos `hicolor`, el avatar, el splash de Syslinux, Plymouth y el fondo del tema de GRUB (`tools/make_logo_icons.py`)
- La fuente del menú de GRUB es DejaVu Sans, recortada a Latin y empaquetada como `pekarchos.pf2` (licencia Bitstream Vera). No es el logotipo.
- Crédito: «Logotipo de PekarchOS, Peka / Pekapro, CC BY-SA 4.0»

## Google Chrome

Chrome no se redistribuye. Los términos del binario no permiten meterlo en la ISO. Firefox es el navegador por defecto. La bienvenida puede instalar el Flatpak `com.google.Chrome` desde Flathub: el paquete lo descarga el usuario desde Google y se actualiza por Flatpak. La licencia del binario sigue siendo la de Google.

## DXVK

- Paquete AUR [dxvk-bin](https://aur.archlinux.org/packages/dxvk-bin), commit en `branding/pins/dxvk-bin.commit`
- Licencia: zlib/libpng (DXVK)
- Traduce Direct3D 9/10/11 a Vulkan para Wine y Lutris. En los repos oficiales está `vkd3d` (Direct3D 12), no DXVK.

## PlayOnLinux

- Paquete AUR [playonlinux](https://aur.archlinux.org/packages/playonlinux), commit en `branding/pins/playonlinux.commit`
- Licencia: GPL
- No está en los repos oficiales. Depende de `wine`, que cubre `wine-staging` (lo proporciona y entra en conflicto con el paquete `wine`).

## FooBillard++

- Paquete AUR [foobillard++](https://aur.archlinux.org/packages/foobillard++), commit en `branding/pins/foobillard++.commit`
- Licencia: GPL-2.0
- El código de 3.42beta no declara `abs` sobre un `float` y GCC actual lo rechaza. La construcción añade `#include <math.h>` y cambia esa llamada a `fabsf`. El Makefile llama a `freetype-config`, que freetype2 ya no instala; en el contenedor de construcción se sustituye por `pkg-config freetype2`.

## Calamares

- [Calamares](https://codeberg.org/Calamares/calamares), GPL-3.0-or-later
- El paquete sale del AUR `calamares-git` en el commit de `branding/pins/calamares-git.commit`
- El código de Calamares queda fijado en `d62849a39a97dbcd4bd9389ebc38e9643a81fa86`, compilado con Python (`WITH_PYTHON`)
- [ckbcomp](https://salsa.debian.org/installer-team/console-setup) (GPL-2.0-or-later), commit en `branding/pins/ckbcomp.commit`, para la vista previa del teclado

## Resto

- archiso `releng`: GPL-3.0-or-later, Arch Linux
- archinstall: GPL-3.0-or-later
- Vokoscreen, KTorrent, Elisa, Falkon, Hydrogen, Yoshimi y el resto de la lista salen de `extra` o `multilib` con la licencia de cada paquete.
- Paquetes del sistema: licencias de `core`, `extra` y `multilib`
