#!/usr/bin/env bash
# /usr/lib/pekarchos/post-install.sh
# Se ejecuta al final de la instalación de Calamares (sistema instalado).
set -euo pipefail

USER_NAME="${1:-}"

echo "==> Post-instalación PekarchOS"

# --- Tema neon de Pacsea para el usuario principal ---
if [[ -n "${USER_NAME}" ]]; then
  USER_HOME=$(getent passwd "${USER_NAME}" | cut -d: -f6 || true)
  if [[ -n "${USER_HOME}" && -d "${USER_HOME}" ]]; then
    install -d -m 0755 -o "${USER_NAME}" -g "${USER_NAME}" \
      "${USER_HOME}/.config/pacsea"

    if [[ -f /usr/share/pekarch/pacsea/theme.conf ]]; then
      install -m 0644 -o "${USER_NAME}" -g "${USER_NAME}" \
        /usr/share/pekarch/pacsea/theme.conf \
        "${USER_HOME}/.config/pacsea/theme.conf"
      echo "    Tema Pacsea aplicado a ${USER_NAME}"
    fi
  fi
fi

# --- Servicios básicos ---
systemctl enable NetworkManager.service || true
systemctl enable bluetooth.service || true
systemctl enable cups.socket || true

# --- Firewall (ufw) ---
if command -v ufw >/dev/null 2>&1; then
  ufw --force enable || true
  ufw default deny incoming || true
  ufw default allow outgoing || true
  ufw allow ssh || true
  systemctl enable ufw.service || true
  echo "    Firewall ufw activado (denegar entrante, permitir saliente + SSH)"
fi

# --- AppArmor ---
if command -v apparmor_parser >/dev/null 2>&1; then
  systemctl enable apparmor.service || true
  echo "    AppArmor activado"
fi

# --- Locale y teclado (refuerzo) ---
if ! grep -q '^es_ES.UTF-8 UTF-8' /etc/locale.gen 2>/dev/null; then
  echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
fi
locale-gen >/dev/null 2>&1 || true

if [[ ! -f /etc/vconsole.conf ]] || ! grep -q 'KEYMAP=es' /etc/vconsole.conf; then
  printf 'KEYMAP=es\nFONT=lat9w-16\n' > /etc/vconsole.conf
fi

echo "==> Post-instalación PekarchOS completada"
