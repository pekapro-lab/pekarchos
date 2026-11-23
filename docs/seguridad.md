# Seguridad en PekarchOS

## Medidas incluidas

### Firewall
- **ufw** se instala en la ISO y se activa automáticamente en `post-install.sh`.
- Política por defecto: denegar entrante, permitir saliente.
- SSH permitido.

### AppArmor
- Paquete `apparmor` incluido.
- El servicio se activa en la post-instalación.

### Actualizaciones automáticas
- Timer diario `pekarchos-update.timer` que ejecuta `pacman -Syu --noconfirm`.
- Se activa automáticamente en la post-instalación.
- Retraso aleatorio de hasta 1 hora para no sobrecargar los espejos.

### Kernel
- Se ofrece `linux-hardened` como opción recomendada para mayor seguridad.

### Otras herencias de Arch
- Mitigaciones de compilador (PIE, RELRO, stack protector, NX, FORTIFY_SOURCE).
- Polkit configurado para que el grupo `wheel` administre.
- Limpieza correcta del usuario `live` durante la instalación.

## Recomendaciones post-instalación

- Las actualizaciones automáticas ya están activas.
- Revisar reglas de ufw si se necesitan más puertos abiertos.
- Considerar `linux-hardened` si no se usan drivers propietarios problemáticos.

## Archivos relacionados

- `/usr/lib/pekarchos/post-install.sh` — Activa ufw, AppArmor y el timer de actualizaciones.
- `/usr/lib/systemd/system/pekarchos-update.service` y `.timer`
- `docs/post-install.md` — Detalle del script de post-instalación.
