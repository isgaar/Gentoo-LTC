# Funcionamiento Y Registro De Fixes

Este documento describe cómo funciona el perfil Gentoo-HP, qué problemas
resuelven los fixes incorporados y cómo auditar su historial.

La configuración y el diagnóstico de PipeWire, WirePlumber y BlueZ se
documentan por separado en [`AUDIO-Y-BLUETOOTH.md`](AUDIO-Y-BLUETOOTH.md).
QEMU/KVM, libvirt y VirtualBox se documentan en
[`VIRTUALIZATION.md`](VIRTUALIZATION.md).
El nombre persistente del kernel se documenta en
[`KERNEL-PERSONALIZADO.md`](KERNEL-PERSONALIZADO.md).
El perfil KDE Orizaba y sus fuentes se documentan en
[`KDE-PERSONALIZADO.md`](KDE-PERSONALIZADO.md).
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

## Commit De Integración KDE Orizaba

La integración de `MyKdeCustom` y las fuentes de `kdevoid` se prepara con este
asunto convencional:

```text
feat: integrate portable Orizaba KDE profile
```

El commit incluye las fuentes Inter globales, el snapshot portable y saneado,
el importador con rollback, la aplicación idempotente durante la primera sesión
Plasma, el saneado de audio/Bluetooth/pantallas, el mapa de licencias, las
pruebas de integridad y esta documentación. Su identificador local se consulta
sin depender de que ya se haya publicado:

```bash
git log -1 --format='%H%n%an <%ae>%n%aI%n%s'
git show --stat --oneline HEAD
```

## Commit De Integración MySway

La integración completa del perfil MySway se agrupó en este commit:

| Campo | Valor |
| --- | --- |
| Commit | `038bd63bff5f4ed89db9ec483c637255a8fc8af9` |
| Commit corto | `038bd63` |
| Commit anterior | `24eaa31a0df3a265731716547dba6316ffdd3695` |
| Autor | `isgaar <may17jun2002@outlook.com>` |
| Fecha | `2026-07-25T15:05:58-06:00` |
| Asunto | `feat: integrate isolated MySway profile with Kitty` |
| Resumen | `27 files changed, 1061 insertions(+), 117 deletions(-)` |

El commit sustituye la configuración Sway básica incrustada por un perfil
modular, instala Kitty como terminal principal, añade la sesión aislada de SDDM
y empaqueta Waybar, Wofi, Mako y los scripts auxiliares. También elimina Foot y
`swayidle` del conjunto de paquetes, mantiene el bloqueo únicamente manual y
prohíbe Quickshell mediante validaciones automáticas.

Para inspeccionarlo:

```bash
git show --stat 038bd63
git show 038bd63
git diff 24eaa31..038bd63
```

## Commit De Refinamiento Visual Y Pantallas

La personalización visual y la gestión eficiente de las pantallas se agruparon
en este commit:

| Campo | Valor |
| --- | --- |
| Commit | `31d98cc189206d49e2f1e7bb084191ca72c76e18` |
| Commit corto | `31d98cc` |
| Commit anterior | `acaa5265669624ec02872d24f5d868dbd0d04047` |
| Autor | `isgaar <may17jun2002@outlook.com>` |
| Fecha | `2026-07-25T16:53:55-06:00` |
| Asunto | `feat: refine MySway visuals and display handling` |
| Resumen | `11 files changed, 91 insertions(+), 27 deletions(-)` |

El commit aplica JetBrains Mono, una paleta grafito cálida y transparencia a
Kitty; elimina el módulo de CPU de Waybar; oculta la barra de título de
VSCodium; y mantiene separaciones uniformes de 5 px. También usa el interruptor
nativo de la tapa para desactivar `eDP-1` al cerrarla y fija el Xiaomi
`A22FAB-RAGL` en `1920x1080@75Hz`, sin añadir procesos residentes. Las
validaciones automáticas comprueban la fuente, las reglas de salida y la gestión
de la tapa.

Para inspeccionarlo:

```bash
git show --stat 31d98cc
git show 31d98cc
git diff acaa526..31d98cc
```

## Commit Del Monitor FHSD20VF01 A 100 Hz

La selección persistente del modo de alta frecuencia se agrupó en este commit:

| Campo | Valor |
| --- | --- |
| Commit | `3c372f883ed852d6d69460c234af9d12ea7cadf1` |
| Commit corto | `3c372f8` |
| Commit anterior | `323fd23fe6fbb746b8fcb7fc37c4a92934d3d9d1` |
| Autor | `isgaar <may17jun2002@outlook.com>` |
| Fecha | `2026-07-25T16:58:49-06:00` |
| Asunto | `feat: configure FHSD20VF01 at 100 Hz` |
| Resumen | `5 files changed, 12 insertions(+)` |

El commit configura el modo anunciado `1920x1080@100.054Hz` usando el
identificador persistente `DZM FHSD20VF01 0000000000001`. Así, la regla no
depende del nombre temporal `DP-1`, no afecta a otros monitores y queda cubierta
por la validación automática de MySway.

Para inspeccionarlo:

```bash
git show --stat 3c372f8
git show 3c372f8
git diff 323fd23..3c372f8
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

Kitty usa `media-fonts/jetbrains-mono` y una paleta grafito cálida con acento
ámbar. Los dieciséis colores ANSI quedan definidos en `kitty.conf`, por lo que
editores y herramientas TUI reutilizan la misma gama sin afectar Konsole.

Las ventanas en mosaico mantienen 5 px entre sí y frente a los extremos,
incluso cuando sólo hay una ventana, mediante `smart_gaps off`. El gap exterior
adicional queda en 0 para que no se sume al gap interior. VSCodium conserva un
borde de 1 px pero no la barra de título de Sway, y Kitty usa una opacidad de
0.90 sin depender de efectos exclusivos de SwayFX.

Los escritorios se recorren con `Super + ←/→`; el foco direccional continúa
disponible con `Super + H/J/K/L`. Waybar utiliza botones de escritorio compactos
para reducir el ancho del bloque izquierdo.

Waybar, sus tooltips, Wofi y Mako usan esquinas rectas (`border-radius: 0`) para
mantener una geometría uniforme en toda la sesión.

El reloj central usa un formateador español explícito, sin depender del locale
interpretado por Waybar ni mostrar un recuadro. Mako se ancla dos píxeles debajo
de la barra para evitar una separación excesiva.

El módulo de red combina iconos monocromáticos con etiquetas explícitas:
`Wi-Fi`, `LAN` y `Sin red`, evitando glifos ambiguos.

La barra no muestra un módulo de CPU; conserva únicamente la información de
memoria y los estados de hardware que resultan útiles en el uso diario.

La salida HDMI del Xiaomi `A22FAB-RAGL` se fija en el modo anunciado
`1920x1080@75Hz`. Sway recibe directamente los eventos de `Lid Switch`: al
cerrar la tapa deshabilita `eDP-1` y al abrirla vuelve a habilitarla. Las reglas
usan `bindswitch --reload`, por lo que el estado físico se aplica también al
iniciar o recargar la sesión. No se ejecuta ningún script, bucle de consulta ni
daemon adicional, así que esta función no reserva memoria RAM permanentemente.

El monitor DZM `FHSD20VF01` anuncia un modo de `1920x1080@100.054Hz`, que se
selecciona mediante el identificador persistente
`DZM FHSD20VF01 0000000000001`. La regla no depende del nombre temporal `DP-1`
y no se aplica a otros monitores.

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

### Perfil KDE Orizaba

Antes de aplicar KDE, el instalador coloca las 36 variantes de Inter e Inter
Display procedentes de `kdevoid/Fonts` en:

```text
/usr/local/share/fonts/gentoo-hp/inter/
```

JetBrains Mono y JetBrains Mono NL no se duplican desde el respaldo:
`media-fonts/jetbrains-mono` las instala mediante Portage. Fontconfig reconstruye
su caché antes de que el perfil seleccione Inter como fuente general, Inter
Display para menús y títulos, y JetBrains Mono NL para texto de ancho fijo.

El snapshot saneado procede de `MyKdeCustom/kde_backup`, fue extraído desde
Plasma 6.6.6 y se instala como recurso de solo lectura en:

```text
/usr/local/share/gentoo-hp/kde/orizaba/
```

El importador queda disponible en:

```text
/usr/local/bin/gentoo-hp-apply-kde
```

Durante el chroot, `configure_kde_desktop` lo ejecuta mediante `runuser`, con el
`HOME` y las rutas XDG del usuario final, y añade `--no-restart`. No intenta
contactar una sesión Plasma inexistente. También instala un autostart exclusivo
de KDE que, dentro de la primera sesión real, ejecuta:

```bash
plasma-apply-lookandfeel --apply Orizaba --resetLayout
plasma-apply-wallpaperimage --fill-mode preserveAspectCrop <fondo-Path>
```

Esto evita depender de que Plasma interprete un `appletsrc` copiado desde el
chroot y aplica de forma efectiva el panel, los widgets, la altura, la
flotación, el esquema Orizaba y el fondo. El perfil de Konsole queda seleccionado
explícitamente como predeterminado.

`SHA256SUMS` protege la integridad del snapshot y de las fuentes. El instalador
exige que cada manifiesto cubra exactamente todos los archivos y después usa
`sha256sum --check --strict`; los extras no declarados también abortan. Además,
guarda el digest del manifiesto KDE en
`~/.local/state/gentoo-hp/kde-profile.sha256`: si no cambia, omite la
reimportación y conserva las modificaciones posteriores del usuario. Cada
importación efectiva crea un respaldo bajo
`~/.local/state/gentoo-hp/kde-restore/`.

La primera sesión registra por separado
`~/.local/state/gentoo-hp/kde-first-login.sha256`. Solo vuelve a aplicar el
layout cuando cambia el perfil o se ejecuta manualmente el importador.
Ambos marcadores se escriben o reemplazan atómicamente desde el proceso del
usuario; el instalador con privilegios no redirige escrituras dentro de ese
directorio controlado por el usuario.

El saneado excluye los estados específicos de Bluetooth
(`bluedevilglobalrc`), audio (`plasmaparc`), pantallas
(`kwinoutputconfig.json` y KScreen), energía y bloqueo, y restauración de
sesión. También excluye credenciales, KDE Wallet, cachés y archivos efímeros.
Así PipeWire, WirePlumber, BlueZ, KScreen y PowerDevil detectan el hardware
actual en vez de heredar identificadores del equipo de origen.

Las rutas del usuario y del fondo se reescriben durante la importación para
hacer portable el perfil. Plasma puede migrar valores cuando cambie de versión;
la procedencia 6.6.6 no implica fijar Plasma a esa versión.

El snapshot tampoco fuerza un KSplash inexistente ni redistribuye decoraciones
GTK generadas por Breeze. `kde-plasma/kde-gtk-config` genera esas decoraciones
para la versión instalada. Orizaba incluye un mapa de licencias: configuración
original MIT, fondo Path LGPLv3 y logotipo Gentoo CC BY-SA 2.5.

La reaplicación manual se realiza como usuario, sin `sudo`:

```bash
gentoo-hp-apply-kde
```

Después hay que cerrar la sesión y volver a entrar para que el autostart
idempotente reconstruya el layout.

Desde una TTY o un chroot se usa:

```bash
gentoo-hp-apply-kde --no-restart
```

Para omitir Orizaba en una instalación nueva:

```bash
INSTALL_KDE_CUSTOM_PROFILE=false
```

La variable no desinstala KDE ni las fuentes globales. El procedimiento de
reversión, las limitaciones del respaldo, las comprobaciones y la descripción
completa del snapshot están en
[`KDE-PERSONALIZADO.md`](KDE-PERSONALIZADO.md).

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
| `contrib/fonts/inter/` | Inter e Inter Display instaladas globalmente antes de aplicar KDE |
| `contrib/kde/orizaba/snapshot/` | Perfil KDE Orizaba portable, saneado y protegido por sumas SHA-256 |
| `contrib/kde/orizaba/import_kde.sh` | Importador con respaldo, validación de integridad y reinicio opcional de Plasma |
| `contrib/kde/orizaba/first_login.sh` | Aplicador idempotente del layout y fondo dentro de una sesión Plasma |
| `tests/validate-kde-profile.sh` | Integridad exacta, fuentes, exclusiones, enlaces, primer inicio e importación en un HOME temporal |
| `contrib/dracut/90-gentoo-hp.conf` | Configuración persistente del initramfs |
| `contrib/kernel/config.d/99-gentoo-hp-localversion.config` | Nombre persistente del kernel compilado |
| `contrib/bin/gentoo-hp-update-boot` | Sincronización segura del kernel y el initramfs con el ESP |
| `contrib/kernel/postinst.d/95-gentoo-hp-esp.install` | Hook compatible con systemd kernel-install e installkernel tradicional |
| `contrib/screenshot.png` | Captura demostrativa de KDE Plasma y Fastfetch |
| `docs/KDE-PERSONALIZADO.md` | Instalación, idempotencia, reaplicación y reversión del perfil Orizaba |
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
    contrib/kernel/postinst.d/95-gentoo-hp-esp.install \
    contrib/kde/orizaba/import_kde.sh \
    contrib/kde/orizaba/first_login.sh
./tests/validate-mysway.sh
./tests/validate-kde-profile.sh
git diff --check
bash contrib/bin/gentoo-hp-update-boot --help
(cd contrib/kde/orizaba/snapshot && sha256sum --check --strict SHA256SUMS)
(cd contrib/fonts/inter && sha256sum --check --strict SHA256SUMS)
desktop-file-validate \
    contrib/kde/orizaba/gentoo-hp-kde-first-login.desktop
node --check \
    contrib/kde/orizaba/snapshot/Orizaba/contents/layouts/org.kde.plasma.desktop-layout.js
test "$(find contrib/fonts/inter -maxdepth 1 -type f \
    -name 'Inter*.ttf' | wc -l)" -eq 36
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

Orizaba se comprobó en una sesión aislada de Plasma 6.6.6 con Xvfb y D-Bus.
Los dos comandos de primera sesión devolvieron `0`; el resultado tuvo un único
panel inferior, un escritorio con el fondo Path portable, tema Orizaba y
Konsole abierto con `Perfil 1.profile`.

Estas comprobaciones validan sintaxis, consistencia estática y el arranque de
los perfiles en sesiones gráficas aisladas. No sustituyen una instalación
completa en hardware de prueba, porque el flujo real particiona el disco
seleccionado.

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
