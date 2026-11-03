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

Obra de Pekapro para PekarchOS, CC0-1.0. Ver [CREDITS.md](CREDITS.md).

## Resto

- archiso `releng`: GPL-3.0-or-later, Arch Linux
- archinstall: GPL-3.0-or-later
- Paquetes del sistema: licencias de `core`, `extra` y, si el usuario activa el pack de juegos, `multilib`
