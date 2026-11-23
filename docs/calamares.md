# Etapas de Calamares en PekarchOS

## Flujo completo (`settings.conf`)

### 1. Fase de interfaz (show)

Orden en el que el usuario ve las pantallas:

1. **welcome** — Pantalla de bienvenida
2. **locale** — Idioma y zona horaria
3. **keyboard** — Distribución de teclado
4. **partition** — Particionado del disco
5. **netinstall@escritorios** — Selección de escritorios extra
6. **netinstall@gpu** — Selección de drivers gráficos
7. **users** — Creación del usuario y contraseña
8. **summary** — Resumen antes de instalar

### 2. Fase de ejecución (exec)

Orden real de los pasos de instalación (dentro del chroot cuando corresponde):

| Orden | Módulo                  | Descripción |
|-------|-------------------------|-------------|
| 1     | partition               | Aplica el particionado elegido |
| 2     | mount                   | Monta las particiones |
| 3     | unpackfs                | Copia el sistema base desde el live |
| 4     | machineid               | Genera `/etc/machine-id` |
| 5     | fstab                   | Genera `/etc/fstab` |
| 6     | locale                  | Configura idioma |
| 7     | keyboard                | Configura teclado |
| 8     | localecfg               | Aplica configuración de locale |
| 9     | **shellprocess@limpiar**| Ejecuta `calamares-limpiar.sh` |
| 10    | initcpiocfg             | Configura mkinitcpio |
| 11    | initcpio                | Genera la imagen initramfs |
| 12    | users                   | Crea el usuario y grupos |
| 13    | **shellprocess@cuenta** | Ejecuta `poner-avatar.sh` + `colocar-lanzadores.sh` |
| 14    | displaymanager          | Configura SDDM |
| 15    | networkcfg              | Configura red |
| 16    | hwclock                 | Configura reloj de hardware |
| 17    | services-systemd        | Activa servicios |
| 18    | packages                | Instala paquetes seleccionados en netinstall |
| 19    | grubcfg                 | Genera configuración de GRUB |
| 20    | bootloader              | Instala el cargador de arranque |
| 21    | **shellprocess@cierre** | Ejecuta scripts de cierre |
| 22    | umount                  | Desmonta las particiones |

### 3. Fase final (show)

- **finished** — Pantalla de instalación completada

## Scripts personalizados por etapa

### shellprocess@limpiar
Ejecuta `calamares-limpiar.sh`:
- Quita la cuenta `live`
- Limpia archivos que solo sirven en el live
- Elimina paquetes exclusivos del live
- Engancha Plymouth
- Inicializa las claves de pacman

### shellprocess@cuenta
Ejecuta:
- `poner-avatar.sh` — Avatar por defecto del usuario
- `colocar-lanzadores.sh` — Crea carpetas XDG en español y copia lanzadores al escritorio

### shellprocess@cierre
Ejecuta:
- `gpu-390-hook.sh` — Gancho para NVIDIA 390 (actualmente desactivado)
- `instalar-firmware.sh` — Instala firmware necesario
- `post-install.sh` — Aplica el tema neon de Pacsea, activa servicios y refuerza locale/teclado

## Notas

- Los módulos `netinstall` permiten seleccionar escritorios extra y drivers gráficos durante la instalación.
- El usuario creado recibe automáticamente el tema de Pacsea gracias a `post-install.sh`.
- La mayoría de los scripts viven en `/usr/lib/pekarchos/`.
