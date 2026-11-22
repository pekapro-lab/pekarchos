# Créditos

- Perfil de arranque: [archiso](https://gitlab.archlinux.org/archlinux/archiso) `releng`, GPL-3.0-or-later, Arch Linux.
- Instalador del disco: `pekarchos-install`, de Pekapro, GPL-3.0-or-later. Copia el live. `archinstall` queda como alternativa con red.
- Paquetes del sistema: repositorios oficiales `core`, `extra` y `multilib` de Arch Linux.
- Logotipo (anillo con la P, «PekarchOS», «Arch de Peka»): Peka / Pekapro, CC BY-SA 4.0. Origen `branding/logo/logo-2-limpio.png`. Los iconos, el avatar, el splash, Plymouth y el tema de GRUB salen de ese archivo. Ver [LICENSE-ARTWORK](LICENSE-ARTWORK).
- Fondo de pantalla, esquemas PekarchOS Neon, código del tema de SDDM y perfil de Konsole: obra de Pekapro, CC0-1.0. El wordmark del fondo está dibujado con un alfabeto de píxeles propio; no se incrusta ninguna fuente.
- Iconos Candy: EliverLara, GPL-3.0, commit fijado. Detalle y respaldo Breeze en [THIRD-PARTY.md](THIRD-PARTY.md).
- `tools/generate_assets.py` regenera el fondo. `tools/make_logo_icons.py` regenera el logotipo y sus derivados. Hace falta Pillow solo para eso, no para construir la ISO.
