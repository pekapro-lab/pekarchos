# Seguridad en PekarchOS

## Medidas incluidas

### Firewall
- **ufw** se instala en la ISO y se activa automáticamente en `post-install.sh`.
- Política por defecto: denegar entrante, permitir saliente.
- SSH permitido.

### AppArmor
- Paquete `apparmor` incluido.
- El servicio se activa en la post-instalación.

### Kernel
- Se ofrece `linux-hardened` como opción en el netinstall (recomendado para mayor seguridad).

### Otras herencias de Arch
- Mitigaciones de compilador (PIE, RELRO, stack protector, NX, FORTIFY_SOURCE).
- Polkit configurado para que el grupo `wheel` administre.
- Limpieza correcta del usuario `live` durante la instalación.

## Recomendaciones post-instalación

- Mantener el sistema actualizado (`pacman -Syu`).
- Revisar reglas de ufw si se necesitan más puertos abiertos.
- Considerar `linux-hardened` si no se usan drivers propietarios problemáticos.
- Activar actualizaciones automáticas si se desea (por ejemplo con `pacman-contrib` + timer).

## Archivos relacionados

- `/usr/lib/pekarchos/post-install.sh` — Activa ufw y AppArmor.
- `docs/post-install.md` — Detalle del script de post-instalación.
