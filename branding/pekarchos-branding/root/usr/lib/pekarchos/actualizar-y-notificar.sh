#!/usr/bin/env bash
# Actualiza el sistema y notifica a los usuarios gráficos conectados.
set -euo pipefail

echo "==> Comprobando actualizaciones..."

# Actualizar bases de datos
pacman -Sy --noconfirm >/dev/null

# Contar paquetes pendientes
pendientes=$(pacman -Qu | wc -l)

if [[ "${pendientes}" -eq 0 ]]; then
  echo "Sistema ya actualizado."
  exit 0
fi

echo "Hay ${pendientes} paquetes pendientes. Actualizando..."
pacman -Su --noconfirm

# Notificar a usuarios gráficos
for usuario in $(who | awk '{print $1}' | sort -u); do
  uid=$(id -u "${usuario}" 2>/dev/null || true)
  [[ -z "${uid}" ]] && continue

  # Intentar notify-send como el usuario
  sudo -u "${usuario}" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" \
    notify-send -a "PekarchOS" -i system-software-update \
    "Actualizaciones aplicadas" \
    "Se han instalado ${pendientes} paquetes." \
    2>/dev/null || true
done

echo "==> Actualización completada y notificada."
