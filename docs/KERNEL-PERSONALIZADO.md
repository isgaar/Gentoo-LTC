# Nombre Persistente Del Kernel

Gentoo-LTC compila `sys-kernel/gentoo-kernel` desde fuente y configura su
identidad para que la version informada por `uname` tenga esta forma:

```text
X.X.X-gentoo4thinkcentre-m75s
```

Por ejemplo, para Linux 6.18.39:

```text
6.18.39-gentoo4thinkcentre-m75s
```

Fastfetch obtiene esta informacion del kernel en ejecucion, por lo que despues
de arrancar el kernel nuevo mostrara:

```text
Kernel: Linux 6.18.39-gentoo4thinkcentre-m75s
```

## Configuracion Persistente

El repositorio incluye:

```text
contrib/kernel/config.d/99-gentoo-hp-localversion.config
```

El instalador lo copia antes de compilar el kernel a:

```text
/etc/kernel/config.d/99-gentoo-hp-localversion.config
```

Su contenido es:

```text
CONFIG_LOCALVERSION="-gentoo4thinkcentre-m75s"
# CONFIG_LOCALVERSION_AUTO is not set
```

`sys-kernel/gentoo-kernel` propone inicialmente `-gentoo-dist`. El sistema de
compilacion de los Distribution Kernels de Gentoo aplica los fragmentos de
`/etc/kernel/config.d` al final, por lo que el valor anterior se sustituye y no
se concatena. El resultado es `-gentoo4thinkcentre-m75s`, no
`-gentoo-dist-gentoo4thinkcentre-m75s`.

Desactivar `CONFIG_LOCALVERSION_AUTO` evita que un identificador de Git se
agregue automaticamente al nombre.

## Instalaciones Nuevas

No se necesita ningun comando adicional. El orden del instalador es:

1. configura Portage;
2. instala el fragmento de version local;
3. compila `sys-kernel/gentoo-kernel`;
4. instala kernel y modulos con la misma version completa;
5. genera el initramfs con Dracut;
6. sincroniza kernel e initramfs con el ESP.

Las rutas versionadas resultantes siguen el mismo nombre:

```text
/usr/src/linux-X.X.X-gentoo4thinkcentre-m75s
/lib/modules/X.X.X-gentoo4thinkcentre-m75s
/boot/kernel-X.X.X-gentoo4thinkcentre-m75s
```

El menu GRUB de Gentoo-HP conserva sus rutas estables:

```text
/boot/efi/vmlinuz.efi
/boot/efi/initramfs.img
```

Por ello no necesita contener la version en `grub.cfg`.

## Aplicarlo A Una Instalacion Existente

Instala primero el fragmento desde una copia actualizada del repositorio:

```bash
cd ~/Documentos/Gentoo-HP
sudo install -d -m0755 /etc/kernel/config.d
sudo install -m0644 \
  contrib/kernel/config.d/99-gentoo-hp-localversion.config \
  /etc/kernel/config.d/99-gentoo-hp-localversion.config
sudo install -d -m0755 \
  /etc/kernel/install.d \
  /etc/kernel/postinst.d \
  /usr/local/sbin
sudo install -m0755 \
  contrib/bin/gentoo-hp-update-boot \
  /usr/local/sbin/gentoo-hp-update-boot
sudo install -m0755 \
  contrib/kernel/postinst.d/95-gentoo-hp-esp.install \
  /etc/kernel/install.d/95-gentoo-hp-esp.install
sudo install -m0755 \
  contrib/kernel/postinst.d/95-gentoo-hp-esp.install \
  /etc/kernel/postinst.d/95-gentoo-hp-esp.install
```

Después recompila el paquete. Es necesario reconstruirlo aunque la version
disponible sea la misma:

```bash
sudo emerge --ask --oneshot sys-kernel/gentoo-kernel
sudo emerge --ask @module-rebuild
```

Cambiar la version local tambien crea un directorio nuevo en `/lib/modules`.
`@module-rebuild` recompila modulos externos, como los de VirtualBox, contra el
kernel nuevo. En una instalacion nueva esos paquetes se instalan despues del
kernel y no requieren este paso adicional.

El hook de postinstalacion debe regenerar el initramfs y actualizar el ESP. Se
puede repetir la sincronizacion indicando expresamente la version recien
compilada:

```bash
kver="$(basename "$(readlink -f /usr/src/linux)")"
kver="${kver#linux-}"
sudo gentoo-hp-update-boot "$kver"
```

Antes de reiniciar, verifica la configuracion y los modulos:

```bash
grep -E '^CONFIG_LOCALVERSION=|CONFIG_LOCALVERSION_AUTO' \
  /usr/src/linux/.config
readlink /usr/src/linux
find /lib/modules -maxdepth 1 -type d \
  -name '*-gentoo4thinkcentre-m75s'
```

Reinicia:

```bash
sudo reboot
```

Despues de iniciar sesion de nuevo, comprueba el kernel que realmente esta
ejecutandose:

```bash
uname -r
fastfetch
```

## Actualizaciones Futuras

No hay que volver a editar la configuracion. Cada version nueva de
`sys-kernel/gentoo-kernel` vuelve a leer el fragmento de `/etc/kernel/config.d`.
El instalador coloca el actualizador en los dos mecanismos compatibles:

```text
/etc/kernel/install.d/95-gentoo-hp-esp.install
/etc/kernel/postinst.d/95-gentoo-hp-esp.install
```

El primero es el plugin utilizado por `installkernel[systemd]`; el segundo
cubre el flujo tradicional. El hook recibe la version completa, Dracut utiliza
el directorio de modulos correspondiente y el actualizador copia los archivos
nuevos al ESP.

No renombres manualmente archivos de `/boot`, directorios de `/lib/modules` ni
el enlace `/usr/src/linux`: kernel, modulos e initramfs deben generarse juntos.

## Limitacion Del Kernel Binario

Esta personalizacion requiere:

```bash
KERNEL_TYPE=source
```

Un `sys-kernel/gentoo-kernel-bin` ya fue compilado con otra version local. No se
puede cambiar de forma segura renombrando sus archivos, porque su version
interna debe coincidir con `/lib/modules`. El perfil Gentoo-HP detiene la
instalacion si se intenta combinar este branding con `KERNEL_TYPE=bin`.
