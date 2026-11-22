#!/usr/bin/env bash
# Lo llama Calamares dentro del sistema ya copiado (chroot).
set -euo pipefail
# shellcheck source=comun.sh
source /usr/lib/pekarchos/comun.sh
quitar_cuenta_live
limpiar_archivos_live
quitar_paquetes_live
enganchar_plymouth
echo "==> Llavero de pacman"
pacman-key --init || true
pacman-key --populate archlinux || true
