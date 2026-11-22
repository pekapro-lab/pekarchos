#!/usr/bin/env bash
# Deja los lanzadores en el escritorio, ejecutables, en una sola carpeta.
# Plasma 6 marca como no fiables los .desktop sin bit de ejecución y enseña
# el triángulo. En español la carpeta es Escritorio: no se crea también Desktop.
set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Uso: colocar-lanzadores.sh USUARIO [--live]" >&2
	exit 1
fi

usuario="$1"
en_vivo=0
if [[ "${2:-}" == "--live" ]]; then
	en_vivo=1
fi

if ! id "${usuario}" >/dev/null 2>&1; then
	echo "No existe el usuario ${usuario}." >&2
	exit 1
fi

hogar=$(getent passwd "${usuario}" | cut -d: -f6)
if [[ -z "${hogar}" || ! -d "${hogar}" ]]; then
	echo "No hay hogar para ${usuario}." >&2
	exit 1
fi

install -d -o "${usuario}" -g "${usuario}" "${hogar}/.config"
cat >"${hogar}/.config/user-dirs.dirs" <<EOF
XDG_DESKTOP_DIR=${hogar}/Escritorio
XDG_DOWNLOAD_DIR=${hogar}/Descargas
XDG_TEMPLATES_DIR=${hogar}/Plantillas
XDG_PUBLICSHARE_DIR=${hogar}/Público
XDG_DOCUMENTS_DIR=${hogar}/Documentos
XDG_MUSIC_DIR=${hogar}/Música
XDG_PICTURES_DIR=${hogar}/Imágenes
XDG_VIDEOS_DIR=${hogar}/Vídeos
EOF
printf 'enabled=True\nfilename_encoding=UTF-8\n' >"${hogar}/.config/user-dirs.conf"
chown "${usuario}:${usuario}" "${hogar}/.config/user-dirs.dirs" "${hogar}/.config/user-dirs.conf"

while IFS= read -r linea || [[ -n "${linea}" ]]; do
	[[ -z "${linea}" || "${linea}" == \#* ]] && continue
	dir="${linea#*=}"
	install -d -o "${usuario}" -g "${usuario}" "${dir}"
done <"${hogar}/.config/user-dirs.dirs"

# Una carpeta inglesa vacía, si la hubiera, no se queda al lado de Escritorio.
if [[ -d "${hogar}/Desktop" ]]; then
	rmdir "${hogar}/Desktop" 2>/dev/null || true
fi

escritorio="${hogar}/Escritorio"
install -d -o "${usuario}" -g "${usuario}" "${escritorio}"

copiar() {
	local origen="$1"
	[[ -f "${origen}" ]] || return 0
	install -m 0755 -o "${usuario}" -g "${usuario}" "${origen}" "${escritorio}/$(basename "${origen}")"
}

copiar /usr/share/applications/pekarchos-welcome.desktop
if [[ "${en_vivo}" -eq 1 ]]; then
	copiar /usr/share/applications/pekarchos-install.desktop
	if [[ -f /usr/share/pekarchos/LEEME.txt ]]; then
		install -m 0644 -o "${usuario}" -g "${usuario}" /usr/share/pekarchos/LEEME.txt "${escritorio}/LEEME.txt"
	fi
fi
