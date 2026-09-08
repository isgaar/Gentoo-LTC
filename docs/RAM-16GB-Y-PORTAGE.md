# Ampliación A 16 GiB De RAM Y Portage

El perfil se instala de forma conservadora con 8 GiB de RAM:

```bash
PORTAGE_MAKEOPTS="-j2 -l2"
PORTAGE_EMERGE_DEFAULT_OPTS="--jobs=1 --load-average=2 --with-bdeps=y"
```

## Memoria Durante La Instalación Desde LiveCD

En el equipo de 8 GiB, el instalador activa automáticamente 4 GiB de ZRAM con
zstd antes de particionar o compilar. Es swap temporal del LiveCD, no ocupa el
disco destino y desaparece al reiniciar. Esto evita que el OOM killer termine
procesos `cc1plus` de paquetes pesados como Boost. Se puede ajustar en
`gentoo.conf` con `LIVE_ZRAM_SIZE`; mantén `PORTAGE_MAKEOPTS="-j2 -l2"`.

Cuando el equipo tenga 16 GiB totales y la memoria nueva haya sido reconocida
por el firmware y Linux, modifica estas dos líneas de `gentoo.conf` **antes de
iniciar una instalación nueva**:

```bash
PORTAGE_MAKEOPTS="-j6 -l6"
PORTAGE_EMERGE_DEFAULT_OPTS="--jobs=1 --load-average=6 --with-bdeps=y"
```

Se mantiene `--jobs=1` intencionalmente: Portage compila un paquete pesado a la
vez, mientras `MAKEOPTS` permite hasta seis procesos para ese paquete. Esto
evita multiplicar el consumo de RAM de compilaciones C++ grandes, como Boost,
Qt o WebEngine.

En un sistema ya instalado, aplica los mismos valores en
`/etc/portage/make.conf` y comprueba que quedaron activos:

```bash
emerge --info | grep -E '^(MAKEOPTS|EMERGE_DEFAULT_OPTS)='
free -h
```

Si durante una compilación la memoria disponible cae demasiado, aparece swap
intensivo o el kernel mata procesos por falta de memoria, vuelve al ajuste de
8 GiB. No se recomienda volver directamente a `-j12` ni usar varios paquetes
pesados en paralelo.

## Grupos Del Usuario Normal

El instalador agrega el usuario a los grupos existentes siguientes:

| Área | Grupos |
| --- | --- |
| Audio y GPU | `audio`, `video`, `render` |
| Entrada y dispositivos extraíbles | `input`, `plugdev`, `usb`, `cdrom`, `dialout` |
| Red | `netdev` |
| Impresión | `lp`, `lpadmin` |
| QEMU/KVM y libvirt | `kvm`, `libvirt` |
| VirtualBox | `vboxusers` |
| Administración opcional | `wheel` cuando se responde que sí a sudo |

`network` no es un grupo estándar de Gentoo; se usa `netdev`. Los grupos que
algún paquete no haya creado todavía se omiten con una advertencia, por lo que
el instalador no falla. Para revisar el resultado tras iniciar sesión:

```bash
id -nG
```
