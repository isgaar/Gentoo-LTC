# Perfil KDE Personalizado Orizaba

Gentoo-HP puede instalar y aplicar automáticamente el perfil KDE Orizaba
extraído de `MyKdeCustom/kde_backup`. El snapshot incluido en el repositorio
está saneado para conservar la apariencia y evitar trasladar secretos, sesiones
o ajustes ligados al hardware del equipo de origen.

La integración está habilitada de forma predeterminada:

```bash
INSTALL_KDE_CUSTOM_PROFILE=true
```

## Orden De Instalación

Durante `after_install`, el perfil sigue este orden:

1. crea el usuario normal;
2. instala Inter e Inter Display a nivel del sistema;
3. configura Fontconfig y reconstruye su caché;
4. configura el renderizado de FreeType;
5. instala el perfil y copia su configuración como el usuario normal;
6. instala el aplicador de primera sesión de Plasma;
7. instala después el perfil independiente de MySway y las carpetas XDG;
8. corrige finalmente el propietario de todo el directorio personal.

Las fuentes están disponibles antes de copiar la configuración que las
selecciona. De esta manera, el primer inicio de Plasma no sustituye
temporalmente Inter por otra familia.

## Fuentes Del Sistema

Las 36 variantes estáticas de Inter e Inter Display proceden de
`kdevoid/Fonts` y coinciden byte a byte con
`isgaar/kdevoid@6432e628cb73096bdb26f84839e8fd2a82e0288e`. Se distribuyen en:

```text
contrib/fonts/inter/
```

El instalador comprueba que no haya enlaces simbólicos, valida cada archivo con
`fc-scan` cuando está disponible y las instala como `root` en:

```text
/usr/local/share/fonts/gentoo-hp/inter/
```

La licencia se conserva en:

```text
/usr/local/share/doc/gentoo-hp/fonts/LICENSE-Inter.txt
```

Después se ejecuta `fc-cache -rs` mediante la configuración general de
Fontconfig. `/usr/local/share/fonts` es una ruta global estándar y también
queda expuesta en modo de solo lectura a las aplicaciones Flatpak.

JetBrains Mono y JetBrains Mono NL, presentes en el directorio original, no se
duplican dentro del repositorio. Se instalan y actualizan con Portage:

```text
media-fonts/jetbrains-mono
```

El perfil selecciona Inter como fuente general, Inter Display para menús y
títulos, y JetBrains Mono NL como fuente de ancho fijo.

## Archivos Instalados

| Origen en el repositorio | Destino instalado | Propósito |
| --- | --- | --- |
| `contrib/fonts/inter/` | `/usr/local/share/fonts/gentoo-hp/inter/` | Inter e Inter Display globales |
| `contrib/kde/orizaba/snapshot/` | `/usr/local/share/gentoo-hp/kde/orizaba/` | Snapshot Orizaba inmutable para los usuarios |
| `contrib/kde/orizaba/import_kde.sh` | `/usr/local/bin/gentoo-hp-apply-kde` | Importador y herramienta de reaplicación |
| `contrib/kde/orizaba/first_login.sh` | `/usr/local/bin/gentoo-hp-kde-first-login` | Aplicación idempotente del layout dentro de Plasma |
| `contrib/kde/orizaba/gentoo-hp-kde-first-login.desktop` | `/etc/xdg/autostart/gentoo-hp-kde-first-login.desktop` | Autostart exclusivo de KDE |

La copia del snapshot queda propiedad de `root:root`, con directorios `0755` y
archivos `0644`. El importador se instala con modo `0755`.

## Aplicación Durante El Chroot

El instalador no ejecuta el importador como `root`. Usa `runuser` con la
identidad del usuario creado y define explícitamente:

```text
HOME
USER
LOGNAME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
```

La llamada equivalente es:

```bash
runuser -u <usuario> -- env \
    HOME=/home/<usuario> \
    USER=<usuario> \
    LOGNAME=<usuario> \
    XDG_CONFIG_HOME=/home/<usuario>/.config \
    XDG_DATA_HOME=/home/<usuario>/.local/share \
    XDG_STATE_HOME=/home/<usuario>/.local/state \
    /usr/local/bin/gentoo-hp-apply-kde \
        --source /usr/local/share/gentoo-hp/kde/orizaba \
        --no-restart \
        --profile-digest <sha256-del-manifiesto> \
        --skip-if-applied
```

`--no-restart` es deliberado: dentro del chroot todavía no existe una sesión
gráfica ni un bus de usuario de Plasma que deban reiniciarse. El importador
deja preparados el tema, los recursos, el esquema de color, Konsole y la
configuración inicial, y programa la fase que necesita una sesión real.
El propio importador crea y reemplaza atómicamente el marcador con la identidad
del usuario. `root` no escribe archivos dentro del directorio de estado
controlado por ese usuario.

## Primera Sesión De Plasma

Copiar `plasma-org.kde.plasma.desktop-appletsrc` desde un chroot no basta para
que Plasma ejecute el script de layout de un tema global. Por eso el autostart
de Gentoo-HP se ejecuta en la fase 2 de la primera sesión KDE y hace
explícitamente:

```bash
plasma-apply-lookandfeel --apply Orizaba --resetLayout
plasma-apply-wallpaperimage \
    --fill-mode preserveAspectCrop \
    ~/.local/share/plasma/look-and-feel/Orizaba/contents/assets/usr/share/wallpapers/Path/contents/images/2560x1600.jpg
```

Así se reconstruyen dentro de Plasma el único panel inferior, sus widgets,
altura, flotación y opacidad, y se aplica el fondo a los escritorios que
existan en la sesión. El panel se crea en la pantalla primaria sin importar
EDID, conector ni UUID del equipo de origen.

La fase solo se ejecuta cuando el digest aplicado al usuario coincide con el
snapshot instalado. Si termina correctamente registra:

```text
~/.local/state/gentoo-hp/kde-first-login.sha256
```

En los inicios siguientes compara el digest y sale sin modificar el
escritorio. Si Plasma o el aplicador del fondo fallan, no escribe el marcador y
vuelve a intentarlo en la próxima sesión.

## Integridad E Idempotencia

El snapshot y las fuentes empaquetadas contienen `SHA256SUMS`. Antes de copiar,
Gentoo-HP compara el inventario real con el manifiesto: un archivo extra,
ausente o una línea malformada provoca el rechazo. Después valida los hashes
con:

```bash
sha256sum --check --quiet --strict SHA256SUMS
```

También rechaza snapshots que contengan enlaces simbólicos. Un origen externo
proporcionado con `--source` puede no tener manifiesto; en ese caso el
importador no puede validar sus archivos y solo debe usarse si se confía en su
procedencia.

El instalador calcula un digest del manifiesto ya instalado y lo registra para
el usuario en:

```text
~/.local/state/gentoo-hp/kde-profile.sha256
```

El marcador pertenece al usuario y tiene modo `0600`. Cuando el digest coincide
con el de la versión instalada, el perfil no se vuelve a aplicar. Esto conserva
los cambios que el usuario haya hecho en Plasma después de la instalación.

Si una versión futura del snapshot cambia su manifiesto, cambia también el
digest y el instalador vuelve a importarlo, creando antes un nuevo respaldo de
reversión. El marcador separado de primera sesión garantiza que también se
vuelva a ejecutar el layout nuevo una sola vez.

La ejecución manual de `gentoo-hp-apply-kde` siempre realiza una importación y
un respaldo. Verifica `SHA256SUMS` cuando está presente y elimina solamente el
marcador de primera sesión para programar la reaplicación del layout al volver
a entrar a Plasma; no modifica el marcador idempotente del instalador.

El importador rechaza su ejecución como `root`, rutas XDG relativas o
apuntando a `/`, snapshots con enlaces simbólicos, destinos Orizaba que sean
enlaces y solapamientos entre el tema y su respaldo. Los archivos de primer
nivel de `~/.config` se reemplazan sin seguir enlaces simbólicos y el enlace
anterior se conserva en el rollback.

## Snapshot Portable Y Plasma 6.6.6

El snapshot Orizaba procede de una sesión con Plasma `6.6.6`. Conserva:

- tema global, colores, iconos y cursores;
- panel, widgets y fondo;
- preferencias de Plasma y KWin;
- atajos globales;
- integración visual GTK 3 y GTK 4;
- Dolphin, Ark, Konsole y asociaciones de archivos.

El importador reubica el tema en `~/.local/share`, sustituye referencias al
directorio personal original y convierte las rutas del fondo en rutas internas
del paquete. Solo conserva una copia real del fondo a resolución 2560x1600;
Plasma la escala según cada salida. Los widgets declarados son componentes
estándar instalados por el perfil Gentoo-HP.

Las decoraciones GTK generadas por Breeze no se versionan. Gentoo-HP instala
`kde-plasma/kde-gtk-config`, que las crea para la versión de Plasma presente y
evita distribuir código generado de otra versión. El esquema de color y los
ajustes GTK portables sí forman parte del snapshot.

Orizaba es un paquete compuesto y mantiene `License=Custom`. La configuración
original de `isgaar` está bajo MIT; el fondo Path conserva LGPLv3 y el logo de
Gentoo su atribución CC BY-SA 2.5. El mapa se encuentra en
`Orizaba/THIRD-PARTY-NOTICES.md`.

Esto hace el snapshot portable entre usuarios y equipos, pero no congela la
versión de Plasma. KDE puede migrar opciones cuando se use una versión
posterior; una opción retirada o un cambio incompatible de formato podría
requerir actualizar el snapshot.

## Datos Excluidos Del Backup

El saneado elimina configuraciones que podrían romper otro equipo. La exclusión
afecta a los estados particulares del hardware, no a los paquetes ni a los
widgets correspondientes.

| Área | Archivos o datos excluidos | Motivo |
| --- | --- | --- |
| Bluetooth | `bluedevilglobalrc` | Podía conservar adaptadores o estados del equipo de origen y bloquear la detección |
| Audio | `plasmaparc` | Fijaba un dispositivo ALSA concreto |
| Pantallas | `kwinoutputconfig.json` y `local/share/kscreen/` | Guardaban EDID, conectores, UUID, posiciones y modos de monitores concretos |
| Energía y bloqueo | `kscreenlockerrc`, `powerdevilrc` y `powermanagementprofilesrc` | Podían desactivar bloqueo, suspensión o acciones de energía |
| Splash | `config.d/kdedefaults/ksplashrc` | Apuntaba a un splash Orizaba inexistente y podía producir un fallback vacío |
| Sesión | `ksmserverrc` y datos de actividades, migración e historial | Podían reabrir aplicaciones o importar estado de otra sesión |
| Secretos y estado efímero | KDE Wallet, cookies, credenciales, cachés, sockets y archivos de bloqueo | No son portables y nunca deben versionarse |
| Fuentes | Fontconfig del usuario y fuentes duplicadas | Gentoo-HP administra las fuentes globalmente |

WirePlumber, PipeWire, BlueZ, KScreen y PowerDevil generan así su estado para el
hardware nuevo durante el primer arranque.

## Reaplicación Manual

Debe ejecutarse como el usuario propietario de la sesión, sin `sudo`. Conviene
cerrar aplicaciones con trabajo pendiente antes de sobrescribir la
configuración.

Desde una sesión KDE:

```bash
gentoo-hp-apply-kde
```

El importador intenta detener y volver a iniciar `plasmashell`. Si no puede
hacerlo, avisa que se cierre la sesión. En ambos casos hay que cerrar la sesión
una vez para que el autostart vuelva a ejecutar el layout y el fondo exactos.

Desde una TTY, un chroot o cuando se prefiera reiniciar la sesión manualmente:

```bash
gentoo-hp-apply-kde --no-restart
```

También se puede indicar otra copia comprobada del snapshot:

```bash
gentoo-hp-apply-kde --source /ruta/al/snapshot --no-restart
```

Después de usar `--no-restart`, se debe cerrar la sesión KDE y volver a
iniciarla. La misma recomendación aplica después de una reaplicación normal.

## Respaldo Y Reversión

Antes de cada importación se crea un directorio único:

```text
~/.local/state/gentoo-hp/kde-restore/AAAAMMDD-HHMMSS-PID/
```

Su contenido se divide así:

| Directorio | Contenido anterior conservado |
| --- | --- |
| `config/` | Archivos de primer nivel de `~/.config` que el snapshot iba a reemplazar |
| `config.d/` | Recursos GTK y valores predeterminados de KDE reemplazados |
| `local-share-overwritten/` | Recursos existentes de `~/.local/share` reemplazados |
| `theme-overwritten/` | Archivos reemplazados o eliminados de un tema Orizaba anterior |
| `home-overwritten/` | Archivos existentes de `$HOME` reemplazados |

Para recuperar las versiones sobrescritas, primero se debe cerrar la sesión
KDE, entrar en una TTY y elegir el respaldo mostrado por el importador:

```bash
restore="$HOME/.local/state/gentoo-hp/kde-restore/AAAAMMDD-HHMMSS-PID"
test -d "$restore" || exit 1

rsync -a "$restore/config/" "$HOME/.config/"
rsync -a "$restore/config.d/" "$HOME/.config/"
rsync -a "$restore/local-share-overwritten/" "$HOME/.local/share/"
rsync -a "$restore/theme-overwritten/" \
    "$HOME/.local/share/plasma/look-and-feel/Orizaba/"
rsync -a "$restore/home-overwritten/" "$HOME/"
```

Estos comandos restauran los archivos que ya existían. Los recursos creados por
primera vez durante la importación no tienen una versión anterior y, por
seguridad, el importador no los borra automáticamente. Si se desea una
reversión total, deben compararse con el snapshot y eliminarse individualmente
después de confirmar que no contienen cambios propios.

Al terminar, se inicia de nuevo la sesión. No se debe ejecutar la reversión
como `root`, porque los archivos resultantes podrían quedar con un propietario
incorrecto.

## Desactivar El Perfil

Para una instalación nueva, se cambia en `gentoo.conf`:

```bash
INSTALL_KDE_CUSTOM_PROFILE=false
```

Esto omite la instalación y aplicación de Orizaba. Plasma, las aplicaciones KDE
y las fuentes globales continúan instalándose; el interruptor solo controla el
perfil personalizado.

En un sistema ya instalado, cambiar la variable no revierte una importación
anterior. Se debe usar un respaldo o restablecer manualmente la configuración
de Plasma.

## Comprobaciones

Después de instalar:

```bash
test -x /usr/local/bin/gentoo-hp-apply-kde
test -x /usr/local/bin/gentoo-hp-kde-first-login
test -f /etc/xdg/autostart/gentoo-hp-kde-first-login.desktop
test -f /usr/local/share/gentoo-hp/kde/orizaba/SHA256SUMS
test -f "$HOME/.local/state/gentoo-hp/kde-profile.sha256"
test -f "$HOME/.local/state/gentoo-hp/kde-first-login.sha256"

fc-match Inter
fc-match "Inter Display"
fc-match "JetBrains Mono"
fc-match "JetBrains Mono NL"
```

Para comprobar la integridad de la copia instalada:

```bash
(
    cd /usr/local/share/gentoo-hp/kde/orizaba
    sha256sum --check --strict SHA256SUMS
)
```

Para confirmar que no se importaron los estados de hardware excluidos:

```bash
test ! -e "$HOME/.config/bluedevilglobalrc"
test ! -e "$HOME/.config/plasmaparc"
test ! -e "$HOME/.config/kwinoutputconfig.json"
test ! -d "$HOME/.local/share/kscreen"
```

Estas cuatro últimas pruebas comprueban lo aportado por el snapshot. Una sesión
posterior de Plasma puede crear de nuevo alguno de esos archivos con valores
válidos para el hardware actual.
