# Funcionamiento Y Registro De Fixes

Este documento describe cómo funciona el perfil Gentoo-HP, qué problemas
resuelven los fixes incorporados y cómo auditar su historial.

La configuración y el diagnóstico de PipeWire, WirePlumber y BlueZ se
documentan por separado en [`AUDIO-Y-BLUETOOTH.md`](AUDIO-Y-BLUETOOTH.md).
QEMU/KVM, libvirt y VirtualBox se documentan en
[`VIRTUALIZATION.md`](VIRTUALIZATION.md).
El nombre persistente del kernel se documenta en
[`KERNEL-PERSONALIZADO.md`](KERNEL-PERSONALIZADO.md).
La sincronización visual de KDE con Flatpak se documenta en
[`FLATPAK-DESKTOP-INTEGRATION.md`](FLATPAK-DESKTOP-INTEGRATION.md).

## Commit Base De Los Fixes

El primer lote de cambios funcionales se agrupó en este commit:

| Campo | Valor |
| --- | --- |
| Commit | `3db23422450897d6db210998b63cbbfdb6564f02` |
| Commit corto | `3db2342` |
| Commit anterior | `1ea4e22bb812f7a57995d379fba735f5cb1e6c4b` |
| Autor | `isgaar <may17jun2002@outlook.com>` |
| Fecha | `2026-07-23T15:27:11-06:00` |
| Asunto | `Mejorar arranque y entorno de escritorio` |

La identidad del autor está configurada únicamente en este repositorio. La
identidad de Git no autentica una cuenta de GitHub: la autenticación se realiza
aparte mediante OAuth en el navegador y ninguna contraseña o token debe
guardarse en los archivos versionados.

Para inspeccionar el commit:

```bash
git show --stat 3db2342
git show 3db2342
git diff 1ea4e22..3db2342
```

Las mejoras posteriores se registran en commits convencionales independientes.
El historial completo y actualizado se consulta con:

```bash
git log --oneline --decorate
```

## Flujo General De La Instalación

La instalación se divide en dos contextos:

1. `install` comienza en el LiveGUI de Gentoo.
2. Lee `gentoo.conf`, valida que se ejecuta como `root` y comprueba el modo UEFI.
3. Resuelve el NVMe de destino y muestra el esquema antes de modificarlo.
4. Crea las particiones, LUKS y Btrfs.
5. Descarga y extrae el stage3 de Gentoo.
6. Monta `/proc`, `/sys`, `/dev` y `/run`, y continúa dentro de un `chroot`.
7. Configura Portage, compila el sistema e instala los paquetes seleccionados.
8. Genera el initramfs, instala GRUB y coloca el kernel en la partición EFI.
9. Crea el usuario normal y aplica las configuraciones de escritorio.
10. Habilita los servicios necesarios para el primer arranque.

Las personalizaciones específicas están en `gentoo.conf`; el motor general de
instalación permanece en `install` y `scripts/`.

## MySway Aislado Y Kitty

El perfil gráfico completo vive en:

```text
contrib/mysway/rootfs/
├── .config/
│   ├── kitty/
│   ├── mako/
│   ├── sway/
│   ├── waybar/
│   └── wofi/
└── .local/bin/
```

`configure_sway_desktop` copia este árbol al usuario final e instala
`contrib/mysway/session/mysway-session` como wrapper de una entrada separada de
SDDM. Las variables Wayland quedan dentro de esa sesión y no se escriben en
`environment.d`, por lo que Plasma conserva su propio entorno.

Kitty sustituye a Foot tanto en los atajos como en Wofi, la terminal flotante y
el acceso de red desde Waybar. El instalador incluye `x11-terms/kitty` con
soporte X/Wayland y usa `media-fonts/fontawesome` para los iconos monocromáticos
de la barra.

Los escritorios se recorren con `Super + ←/→`; el foco direccional continúa
disponible con `Super + H/J/K/L`. Waybar utiliza botones de escritorio compactos
para reducir el ancho del bloque izquierdo.

No se instala Quickshell ni se inicia `swayidle`. El bloqueo automático queda
deshabilitado; `swaylock` permanece instalado únicamente para la acción manual
`Super + Ctrl + L` y el menú de sesión.

## Identidad Del Sistema

systemd 260 exige que los hostnames estatico y transitorio utilicen etiquetas
DNS formadas por ASCII en minusculas. El perfil conserva el nombre tecnico en:

```text
/etc/hostname
hpgentoo
```

y configura el nombre visible, que si admite mayusculas, en:

```text
/etc/machine-info
PRETTY_HOSTNAME="HPGentoo"
```

De esta manera KDE y otras interfaces compatibles pueden mostrar `HPGentoo`
sin introducir un hostname invalido. La terminal, DNS y el prompt siguen
utilizando `hpgentoo`. La validacion previa del instalador rechaza mayusculas
en `HOSTNAME` cuando se usa systemd para evitar una configuracion que fallaria
al arrancar. Se puede verificar con:

```bash
hostnamectl --static
hostnamectl --pretty
```

## Almacenamiento: NVMe, LUKS Y Btrfs

El modo predeterminado usa:

```bash
TARGET_DISK="auto-nvme"
create_classic_single_disk_layout \
    swap=16GiB type=efi luks=true root_fs=btrfs "$TARGET_DISK"
```

`auto-nvme` solamente continúa si detecta exactamente un disco NVMe. Esto evita
elegir arbitrariamente entre varios discos, pero la confirmación mostrada antes
de particionar sigue siendo obligatoria.

El esquema resultante es:

| Partición | Uso |
| --- | --- |
| Primera | Sistema EFI (ESP) |
| Segunda | Swap de 16 GiB |
| Tercera | Contenedor LUKS con la raíz Btrfs |

Btrfs utiliza un único subvolumen `root` montado como `/`. El perfil no crea
subvolúmenes independientes para `/home`, `/var` o snapshots.

## Arranque: Dracut, NVMe Y GRUB

El fix de arranque instala esta configuración persistente:

```text
/etc/dracut.conf.d/90-gentoo-hp.conf
```

Su configuración:

```bash
hostonly="no"
ro_mnt="yes"
compress="zstd"
add_dracutmodules+=" bash crypt crypt-gpg btrfs "
force_drivers+=" amdgpu nvme "
```

Esto hace que los initramfs nuevos incluyan:

- soporte para abrir el contenedor LUKS;
- soporte para montar la raíz Btrfs;
- el controlador NVMe desde la etapa temprana del arranque;
- AMDGPU para la inicialización temprana de la pantalla.

GRUB se instala en el ESP y utiliza nombres estables:

```text
/boot/efi/vmlinuz.efi
/boot/efi/initramfs.img
/boot/efi/grub/grub.cfg
```

No depende de `/boot/grub/grub.cfg`. Por ese motivo, ejecutar solamente
`grub-mkconfig -o /boot/grub/grub.cfg` no actualiza el menú utilizado por este
perfil.

### Nombre Persistente Del Kernel

Antes de compilar `sys-kernel/gentoo-kernel`, el perfil instala:

```text
/etc/kernel/config.d/99-gentoo-hp-localversion.config
```

con:

```text
CONFIG_LOCALVERSION="-gentoo4hp-pavilion-15"
# CONFIG_LOCALVERSION_AUTO is not set
```

El ebuild propone primero `CONFIG_LOCALVERSION="-gentoo-dist"`, pero
`kernel-build.eclass` fusiona los fragmentos de `/etc/kernel/config.d` al
final. El valor del perfil lo sustituye y produce:

```text
X.X.X-gentoo4hp-pavilion-15
```

La version completa se utiliza de forma coherente en `/usr/src/linux-*`,
`/lib/modules/*`, la imagen de `/boot` y Dracut. Desactivar
`CONFIG_LOCALVERSION_AUTO` evita sufijos adicionales basados en el repositorio
Git de las fuentes.

Este mecanismo solamente es valido para `KERNEL_TYPE=source`. Un kernel binario
ya contiene una version interna y no puede personalizarse renombrando sus
archivos. El procedimiento para instalaciones existentes y las comprobaciones
posteriores se detallan en
[`KERNEL-PERSONALIZADO.md`](KERNEL-PERSONALIZADO.md).

### Actualización Automática Del Kernel

El commit agrega:

```text
/usr/local/sbin/gentoo-hp-update-boot
/etc/kernel/install.d/95-gentoo-hp-esp.install
/etc/kernel/postinst.d/95-gentoo-hp-esp.install
```

Con `installkernel[systemd]`, `kernel-install` ejecuta el plugin de
`/etc/kernel/install.d`. La copia de `/etc/kernel/postinst.d` cubre el flujo
tradicional cuando systemd no realiza la instalacion. En ambos casos el hook
llama al actualizador cuando `sys-kernel/gentoo-kernel` instala un kernel. El
actualizador:

1. comprueba que se ejecuta como `root`;
2. comprueba que `/boot/efi` está montado;
3. prioriza el kernel seleccionado por `/usr/src/linux` y determina su versión;
4. reutiliza el initramfs correspondiente o lo genera con Dracut;
5. prepara archivos temporales dentro del ESP;
6. reemplaza los nombres estables solamente cuando ambos archivos están listos;
7. sincroniza el ESP.

La actualización manual equivalente es:

```bash
sudo gentoo-hp-update-boot
```

## Política De Compilación

El binhost genérico permanece desactivado:

```bash
ENABLE_BINPKG=false
KERNEL_TYPE=source
```

Por tanto, Portage compila normalmente el kernel, Mesa, LLVM, systemd, KDE
Plasma, Sway, TLP y PipeWire. El kernel compilado conserva el sufijo
`-gentoo4hp-pavilion-15` en cada actualizacion gracias al fragmento de
`/etc/kernel/config.d`.

Firefox es la excepción deliberada:

```text
www-client/firefox-bin
```

Esto reduce el tiempo de instalación del navegador sin convertir en binarios
genéricos los componentes centrales del sistema.

## KDE, Sway Y Herramientas De Escritorio

El perfil instala, entre otros:

```text
kde-apps/ark
kde-apps/dolphin
kde-apps/konsole
kde-plasma/discover
kde-plasma/breeze-gtk
kde-plasma/kde-gtk-config
app-arch/7zip
app-arch/unrar
app-arch/unzip
app-arch/zip
app-misc/fastfetch
sys-process/btop
sys-apps/flatpak
sys-apps/xdg-desktop-portal-gtk
```

Ark recibe soporte ZIP y se acepta de forma específica la licencia necesaria
para `app-arch/unrar`.

Sway conserva su configuración inicial con teclado `latam`, touchpad, Waybar,
Wofi, Mako, bloqueo de pantalla y atajos básicos.

## Flatpak Y Discover

Las banderas de Portage habilitan Flatpak en Discover, Plasma, PipeWire y
`xdg-desktop-portal`. Durante la configuración final se registra Flathub como
remoto del sistema:

```bash
flatpak remote-add --system --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo
```

Discover puede administrar las aplicaciones Flatpak. El sistema base y los
paquetes nativos continúan actualizándose mediante Portage.

El instalador también instala `org.gtk.Gtk3theme.Breeze//3.22` desde Flathub. El
módulo KDED de `kde-gtk-config` traduce las preferencias de Plasma a GSettings
en Wayland y a XSettings en X11: fuentes, iconos, cursor, escalado, animaciones,
modo claro/oscuro y colores Breeze.

Las fuentes no se copian dentro de cada aplicación. Flatpak expone
automáticamente `/usr/share/fonts`, `/usr/local/share/fonts` y
`$XDG_DATA_HOME/fonts` como rutas de solo lectura bajo `/run/host`. Este diseño
preserva el aislamiento del sandbox y evita overrides globales como
`--filesystem=home`.

Para los colores personalizados de Breeze sí se permite únicamente
`xdg-config/gtk-3.0:ro`. Esa ruta contiene el CSS y los recursos que genera
`kde-gtk-config`; no concede acceso al resto del directorio personal.

## Renderizado De Fuentes

Ademas de instalar Noto y configurar Fontconfig, el perfil escribe:

```bash
# /etc/environment
FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"
```

El mismo valor se instala en
`/etc/env.d/99gentoo-hp-font-rendering` y se procesa con `env-update`, ya que
las sesiones Gentoo consumen el `/etc/profile.env` generado desde `env.d`.
Mantener `/etc/environment` tambien cubre consumidores que leen directamente
ese archivo mediante PAM.

Asignar `no-stem-darkening=0` activa el stem darkening de FreeType para CFF y
el autofitter. Solo afecta procesos iniciados despues de recibir la variable;
para aplicarlo a toda la sesion grafica hay que cerrar sesion y volver a entrar
o reiniciar el equipo.

## Usuario, Permisos Y Carpetas XDG

El nombre de usuario, la contraseña y el acceso a `sudo` se preguntan durante la
instalación; no están almacenados en `gentoo.conf`.

Después de crear las configuraciones de KDE y Sway se corrige la propiedad de
todo el directorio personal:

```bash
chown -R <usuario>:<grupo-principal> /home/<usuario>
```

Esto incluye `.config` y evita que una sesión gráfica falle porque los archivos
creados desde el `chroot` pertenezcan a `root`.

El paquete `x11-misc/xdg-user-dirs` y la función
`configure_xdg_user_directories` crean:

```text
Escritorio
Descargas
Documentos
Imágenes
Música
Vídeos
```

También se generan:

```text
~/.config/user-dirs.dirs
~/.config/user-dirs.locale
```

Así KDE, Dolphin, Firefox y Flatpak comparten las mismas rutas en español.
`Plantillas` y `Público` se desactivan apuntando a `$HOME`.

El instalador no elimina `Desktop`, `Downloads` o `Pictures` en una instalación
existente, porque esas carpetas podrían contener datos. Su migración debe
hacerse después de revisar el contenido.

## Seguridad Y Datos Sensibles

La clave recibida mediante `GENTOO_INSTALL_ENCRYPTION_KEY` solamente se necesita
para preparar LUKS en el entorno LiveGUI. Antes de continuar con la instalación
interna se elimina del entorno:

```bash
unset GENTOO_INSTALL_ENCRYPTION_KEY
```

Esto evita que la clave llegue innecesariamente a procesos como `emerge`.

La autenticación con GitHub tampoco forma parte del sistema instalado:

- Git conserva el nombre y correo del autor del commit;
- OAuth autentica la cuenta en la interfaz o herramienta local;
- los tokens, códigos y contraseñas nunca deben añadirse al repositorio.

## Archivos Principales Del Perfil

| Archivo | Responsabilidad |
| --- | --- |
| `install` | Configuración de Debuginfod y limpieza de la clave LUKS antes del chroot |
| `gentoo.conf` | Paquetes, identidad, FreeType, Portage, Dracut, Flatpak, XDG y propiedad del usuario |
| `scripts/functions.sh` | Validaciones previas, incluida la restriccion de hostname para systemd |
| `contrib/mysway/rootfs/` | Perfil modular de Sway, Kitty, Waybar, Wofi y Mako instalado al usuario |
| `contrib/mysway/session/` | Wrapper aislado y entrada de MySway para SDDM |
| `tests/validate-mysway.sh` | Regresiones de Kitty, atajos, Waybar, bloqueo y ausencia de Quickshell |
| `contrib/dracut/90-gentoo-hp.conf` | Configuración persistente del initramfs |
| `contrib/kernel/config.d/99-gentoo-hp-localversion.config` | Nombre persistente del kernel compilado |
| `contrib/bin/gentoo-hp-update-boot` | Sincronización segura del kernel y el initramfs con el ESP |
| `contrib/kernel/postinst.d/95-gentoo-hp-esp.install` | Hook compatible con systemd kernel-install e installkernel tradicional |
| `contrib/screenshot.png` | Captura demostrativa de KDE Plasma y Fastfetch |
| `docs/KERNEL-PERSONALIZADO.md` | Instalacion, migracion y verificacion del nombre del kernel |
| `README.md` | Uso, recuperación, paquetes y comportamiento actualizado |

El resumen histórico de Git para el commit base `3db2342` es:

```text
7 files changed, 458 insertions(+), 6 deletions(-)
```

## Validaciones Realizadas

Antes de crear el commit se ejecutaron:

```bash
bash -n install configure gentoo.conf gentoo.conf.example \
    scripts/*.sh tests/*.sh \
    contrib/bin/gentoo-hp-update-boot \
    contrib/kernel/postinst.d/95-gentoo-hp-esp.install
./tests/validate-mysway.sh
git diff --check
bash contrib/bin/gentoo-hp-update-boot --help
grep -Fx 'CONFIG_LOCALVERSION="-gentoo4hp-pavilion-15"' \
    contrib/kernel/config.d/99-gentoo-hp-localversion.config
grep -Fx '# CONFIG_LOCALVERSION_AUTO is not set' \
    contrib/kernel/config.d/99-gentoo-hp-localversion.config
```

También se verificó que `contrib/screenshot.png` es un PNG válido de
1920 × 1080 y que el calculo oficial de `scripts/setlocalversion`, usando el
valor fusionado, produce `6.18.39-gentoo4hp-pavilion-15`.

El perfil MySway se comprobó además con el parser de Sway 1.11 dentro de una
sesión real. La prueba funcional cambió del escritorio 1 al 2 y regresó al 1
mediante `mysway-workspace`, confirmando los atajos numéricos.

Estas comprobaciones validan sintaxis y consistencia estática. No sustituyen una
instalación completa en hardware de prueba, porque el flujo real particiona el
disco seleccionado.

## Publicación En GitHub

El remoto configurado es:

```text
origin  https://github.com/isgaar/Gentoo-HP.git
```

Después de completar el inicio de sesión OAuth en el navegador, se debe
comprobar que la cuenta conectada sea `isgaar`. La publicación se realiza con:

```bash
git push origin main
```

El correo `may17jun2002@outlook.com` identifica al autor del commit, pero GitHub
solo lo asociará visualmente a la cuenta si ese correo está verificado en la
configuración de GitHub.
