# Audio Y Bluetooth De Alta Fidelidad En Gentoo-LTC

Gentoo-LTC usa PipeWire, WirePlumber, ALSA y RTKit en la Lenovo ThinkCentre M75s Gen 2. La configuración favorece reproducción fiel y estable sin imponer un formato que el dispositivo de salida no haya anunciado.

## Hardware Del Perfil

- AMD Ryzen 5 Pro 5600G / Radeon Cezanne;
- salida analógica Realtek ALC623 mediante `snd_hda_intel`;
- HDMI/DisplayPort AMD Radeon mediante `snd_hda_intel`;
- coprocesador AMD ACP (`1022:15e2`);
- Intel Wireless-AC 9260 Bluetooth.

El kernel instala los controladores HDA Realtek, HDA HDMI y ACP en `contrib/kernel/config.d/15-audio-hardware.config`. No supone que una salida HDMI concreta ni el códec analógico soporten la misma tasa máxima: ALSA negocia las capacidades reales al abrir cada dispositivo.

## Política Hi-Fi

`contrib/pipewire/pipewire.conf.d/10-gentoo-ltc-hifi.conf` permite al grafo de PipeWire usar 44.1, 48, 88.2, 96, 176.4 o 192 kHz, conservando 48 kHz como predeterminado. PipeWire solo cambia la tasa del grafo cuando los dispositivos están inactivos; ésta es una limitación deliberada para no interrumpir una reproducción activa.

Cuando una sola aplicación, el grafo y el dispositivo negocian la misma tasa, no hay remuestreo en esa ruta. Con varios streams de distintas tasas, o con un dispositivo que no admita la tasa solicitada, habrá remuestreo: por ello no se promete una reproducción *bit-perfect* global.

Los clientes nativos, ALSA y PulseAudio compatible usan `resample.quality = 10` si deben remuestrear. Es un ajuste de calidad alta que consume más CPU y puede añadir latencia; no convierte una fuente de 16 bits o con pérdida en audio de mayor resolución. PipeWire procesa internamente el grafo en coma flotante; forzar `S32LE` al DAC no aumenta por sí solo la fidelidad, así que se deja que ALSA elija el formato nativo del dispositivo.

Tampoco se desactiva la suspensión de nodos. Si se perciben clics al reanudar audio, se puede ajustar de forma localizada tras identificar el nodo con `wpctl status`, sin mantener encendidos permanentemente HDMI y el códec interno.

## Bluetooth

`20-gentoo-ltc-hifi-bluetooth.conf` selecciona la preferencia de perfil A2DP por calidad. No fija una lista de códecs ni LDAC a 990 kb/s: PipeWire anuncia solo los códecs compilados localmente y compatibles con el auricular, conserva los valores de compatibilidad de su versión y puede adaptarse a interferencias.

Si están disponibles en la compilación y en el auricular, PipeWire puede usar SBC-XQ, AAC, LDAC, aptX o aptX HD. Todos los códecs Bluetooth A2DP son con pérdida; para una ruta sin pérdida usa la salida analógica/HDMI o un DAC USB. Los perfiles HFP/HSP destinados a llamadas tienen menor calidad que A2DP.

## Paquetes Y USE Flags

El perfil instala PipeWire, WirePlumber, RTKit, ALSA UCM, Plasma PA, BlueZ y Bluedevil. Para PipeWire habilita:

```text
media-video/pipewire bluetooth dbus extra ffmpeg flatpak liblc3 pipewire-alsa sound-server systemd
net-wireless/bluez obex readline systemd udev
sys-auth/rtkit systemd
```

`sound-server` instala PipeWire PulseAudio y la integración de hardware de WirePlumber; `pipewire-alsa` atiende aplicaciones ALSA sin daemon PulseAudio tradicional. `extra` incorpora utilidades de diagnóstico como `pw-play`; los códecs efectivos se comprueban en el sistema instalado.

## Verificación

Comprueba los dispositivos y el servicio de usuario:

```bash
wpctl status
systemctl --user status pipewire pipewire-pulse wireplumber
```

Durante una reproducción, `pw-top` muestra la tasa activa del grafo. Para comprobar qué eligió ALSA para una salida concreta, identifica primero la tarjeta y el PCM con `aplay -l`, y después consulta su `hw_params`; por ejemplo:

```bash
cat /proc/asound/card1/pcm0p/sub0/hw_params
```

Verifica los códecs Bluetooth negociados y el estado del adaptador con:

```bash
wpctl status
bluetoothctl show
rfkill list
```

`bluetooth.service` es un servicio de sistema. PipeWire, PipeWire Pulse y WirePlumber pertenecen a la sesión gráfica del usuario: no los reinicies con `sudo systemctl --user`.

## Aplicar A Una Instalación Existente

Tras actualizar el repositorio, ejecuta de nuevo el configurador o instala los fragmentos y reinicia la sesión gráfica. Para activar cambios de USE flags:

```bash
sudo emerge --ask --newuse --changed-use \
  media-video/pipewire media-video/wireplumber sys-auth/rtkit \
  net-wireless/bluez
```

Para aplicar el fragmento de kernel, cópialo junto con los demás fragmentos y recompila `sys-kernel/gentoo-kernel`; consulta [`KERNEL-PERSONALIZADO.md`](KERNEL-PERSONALIZADO.md) para el procedimiento.
