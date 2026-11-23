# post-install.sh

Script que se ejecuta al final de la instalación de Calamares (en el módulo `shellprocess@cierre`).

## Ubicación

```
/usr/lib/pekarchos/post-install.sh
```

## Invocación

Calamares lo llama con el nombre del usuario creado:

```bash
/usr/lib/pekarchos/post-install.sh "{{user}}"
```

## Qué hace

1. **Tema de Pacsea**
   - Si se le pasa un usuario válido, crea `~/.config/pacsea/`
   - Copia `/usr/share/pekarch/pacsea/theme.conf` al usuario
   - El usuario queda con el tema neon de PekarchOS en Pacsea

2. **Servicios**
   - Activa `NetworkManager.service`
   - Activa `bluetooth.service`
   - Activa `cups.socket`

3. **Locale y teclado (refuerzo)**
   - Asegura que `es_ES.UTF-8` esté en `/etc/locale.gen` y regenera locales
   - Asegura que `/etc/vconsole.conf` tenga `KEYMAP=es`

## Características

- Es idempotente (se puede ejecutar varias veces sin romper nada)
- No falla si falta el tema de Pacsea o el usuario
- Usa `|| true` en los servicios para no interrumpir la instalación si alguno no existe

## Relación con otros scripts

Se ejecuta después de:
- `gpu-390-hook.sh`
- `instalar-firmware.sh`

Y forma parte del cierre de la instalación, justo antes de desmontar las particiones.
