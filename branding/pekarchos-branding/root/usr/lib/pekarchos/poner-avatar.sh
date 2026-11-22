#!/usr/bin/env bash
# Avatar por defecto: el emblema de PekarchOS, en la cuenta y en SDDM.
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "Uso: poner-avatar.sh USUARIO" >&2
	exit 1
fi

usuario="$1"
if ! id "${usuario}" >/dev/null 2>&1; then
	echo "No existe el usuario ${usuario}." >&2
	exit 1
fi

hogar=$(getent passwd "${usuario}" | cut -d: -f6)
origen=""
for candidato in /usr/share/pekarchos/face.icon /usr/share/pekarchos/logo.png /etc/skel/.face.icon /usr/share/sddm/faces/.face.icon; do
	if [[ -f "${candidato}" ]]; then
		origen="${candidato}"
		break
	fi
done
if [[ -z "${origen}" || -z "${hogar}" ]]; then
	echo "No hay imagen de avatar; se sigue sin ella."
	exit 0
fi

install -d -o "${usuario}" -g "${usuario}" "${hogar}"
install -m 0644 -o "${usuario}" -g "${usuario}" "${origen}" "${hogar}/.face.icon"
install -m 0644 -o "${usuario}" -g "${usuario}" "${origen}" "${hogar}/.face"
install -d /usr/share/sddm/faces /var/lib/AccountsService/icons /var/lib/AccountsService/users
install -m 0644 "${origen}" "/usr/share/sddm/faces/${usuario}.face.icon"
install -m 0644 "${origen}" "/var/lib/AccountsService/icons/${usuario}"
cat >"/var/lib/AccountsService/users/${usuario}" <<EOF
[User]
Icon=/var/lib/AccountsService/icons/${usuario}
SystemAccount=false
EOF
chmod 0644 "/var/lib/AccountsService/users/${usuario}"
