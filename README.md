# Gentoo-LTC

Perfil automatizado y optimizado de Gentoo Linux para **Lenovo ThinkCentre M75s Gen 2** con procesador **AMD Ryzen 5 5600G**.

Basado en el instalador de [oddlama/gentoo-install](https://github.com/oddlama/gentoo-install), configurado de forma atómica para este hardware: arranque UEFI obligatorio, cifrado de disco completo con LUKS sobre Btrfs, aceleración gráfica AMDGPU/RadeonSI, conectividad de red nativa (Ethernet Gigabit Realtek y Wi-Fi/Bluetooth Intel), servicio de impresión CUPS, y dos entornos de escritorio preconfigurados: **KDE Plasma 6 (perfil Orizaba)** y **MySway (Wayland modular)**.

![Gentoo-LTC ejecutando KDE Plasma y Fastfetch](contrib/screenshot.png)

---

## Especificaciones del Perfil de Hardware

| Componente | Configuración y Optimización |
| :--- | :--- |
| **Equipo** | Lenovo ThinkCentre M75s Gen 2 |
| **CPU** | AMD Ryzen 5 5600G (Cezanne / Zen 3 / znver3, 6 núcleos / 12 hilos, `-march=znver3 -O2 -pipe`) |
| **Flags CPU** | `aes avx avx2 bmi1 bmi2 f16c fma3 mmx mmxext pclmul popcnt rdrand sha sse sse2 sse3 sse4_1 sse4_2 sse4a ssse3 vaes vpclmulqdq` |
| **GPU** | AMD Cezanne Radeon Vega integrada (`VIDEO_CARDS="amdgpu radeonsi"`, RADV Vulkan, VA-API, VDPAU) |
| **Red Cableada** | Realtek RTL8111/8168/8411 PCIe Gigabit Ethernet (controlador `r8169`, interfaz `enp4s0f0`) |
| **Red Wi-Fi** | Intel Dual Band Wireless-AC 9260 160MHz (controlador `iwlwifi` / `iwlmvm`, interfaz `wlp3s0`) |
| **Bluetooth** | Intel Wireless-AC 9260 Bluetooth Adapter (controlador `btusb`, `bluetooth.service`) |
| **Impresión** | CUPS (`net-print/cups`, `cups-filters`, `kde-plasma/print-manager`, grupos `lp` y `lpadmin`) |
| **Almacenamiento** | Detección automática de unidad NVMe interna (`TARGET_DISK="auto-nvme"`) |
| **Particionado** | UEFI / ESP en `/boot/efi` (FAT32), Swap de 20 GiB, Root Btrfs cifrado con LUKS |
| **Initramfs** | Dracut persistente (`90-gentoo-hp.conf`) con módulos tempranos `nvme` y `amdgpu` |
| **Kernel** | Compilado localmente (`sys-kernel/gentoo-kernel`) como `X.X.X-gentoo4thinkcentre-m75s` |
| **Sonido Hi-Fi** | PipeWire + WirePlumber (tasas de 44.1–192 kHz negociadas, resampleador sinc Q10, preferencia A2DP por calidad y RTKit) |
| **Escritorios** | KDE Plasma 6 (perfil Orizaba saneado e importador idempotente) y MySway modular |
| **Gestor de Inicio**| SDDM con sesión Wayland y menú de arranque GRUB UEFI con tema personalizado |

---

## Preparación del Medio de Instalación

1. Descarga la imagen oficial **Gentoo LiveGUI amd64** (`livegui-amd64-*.iso`) desde [gentoo.org](https://www.gentoo.org/downloads/).
2. Graba la imagen en una memoria USB (usando Fedora Media Writer, Rufus en modo DD, o `dd`).
3. Conecta el USB al ThinkCentre M75s Gen 2.
4. Enciende el equipo y presiona repetidamente **F12** para abrir el menú de selección de arranque de Lenovo.
5. Selecciona la memoria USB en modo **UEFI**.
6. Conéctate a internet desde el entorno gráfico o mediante terminal con `nmtui`.

El instalador comprueba las herramientas del LiveGUI, sincroniza el reloj antes
de validar el stage3 y se detiene antes de modificar el disco si falta una
dependencia, no se arrancó en UEFI o no detecta exactamente un NVMe.

---

## Instalación Paso a Paso

Abre una terminal en el LiveGUI y entra como root:

```bash
sudo -i
```

Verifica la conectividad a internet:

```bash
ping -c 3 gentoo.org
```

Si `git` no está disponible en el entorno en vivo, instálalo rápidamente:

```bash
emerge-webrsync && emerge -qv dev-vcs/git
```

Clona este repositorio e inicia la instalación:

```bash
git clone https://github.com/isgaar/Gentoo-LTC.git
cd Gentoo-LTC
./install
```

### Proceso de Instalación Automatizado

1. **Detección del disco:** El instalador verifica el modo UEFI y busca exactamente una unidad NVMe (`auto-nvme`). Muestra la distribución en pantalla antes de aplicar cambios.
2. **Particionado y Cifrado:** Crea la partición EFI, 20 GiB de swap y el volumen raíz Btrfs protegido con LUKS.
3. **Descarga y Extracción:** Obtiene el stage3 `amd64-systemd` más reciente validando firmas criptográficas y digest oficial.
4. **Optimización de Portage:** Sincroniza el árbol Git firmado desde el espejo oficial, configura espejos redundantes globales (`GENTOO_MIRRORS`), compila con `-march=znver3`, hasta seis procesos por paquete y un solo paquete pesado a la vez para aprovechar 16 GiB de RAM sin agotar memoria. Finaliza con `emerge --update --deep --newuse @world` para dejar el sistema en las versiones estables actuales.
5. **Kernel y Drivers:** Aplica el fragmento persistente de hardware de red (`10-network-hardware.config`), compila `sys-kernel/gentoo-kernel` y genera el initramfs con Dracut.
6. **Pila de Software y Servicios:** Instala KDE Plasma, MySway, PipeWire, BlueZ, CUPS, NetworkManager, libvirt/QEMU, fuentes Inter/JetBrains Mono y utilidades de sistema.
7. **Configuración de Usuario:** Pregunta interactivamente el nombre de usuario, contraseña y privilegios de `sudo` (grupo `wheel`) antes de las compilaciones largas; la contraseña no se guarda en `gentoo.conf`. Después configura directorios personales XDG en español protegidos contra sobreescritura.
8. **Reanudación segura:** Cada fase terminada se guarda junto a `gentoo.conf` en un archivo privado de estado. Si una fase falla, ejecutar `./install` continúa desde el último checkpoint y no vuelve a particionar ni a repetir las compilaciones ya finalizadas. El archivo no almacena contraseñas ni claves.

---

## Primer Arranque

Al finalizar la instalación, reinicia el equipo:

```bash
reboot
```

1. Retira la memoria USB de instalación.
2. Introduce tu contraseña de cifrado LUKS en la pantalla de bienvenida.
3. En el gestor de inicio **SDDM**, introduce tus credenciales y selecciona el entorno deseado:
   - **KDE Plasma:** Aplica en el primer inicio el perfil visual Orizaba (fuentes Inter, colores grafito, panel flotante, Konsole).
   - **MySway:** Sesión Wayland aislada basada en Sway con Kitty, Waybar, Wofi y Mako.

---

## Conexión de Red

El equipo utiliza **NetworkManager** con backend **iwd** para gestionar tanto la conexión cableada como inalámbrica.

- **Ethernet (cable):** La interfaz Gigabit `enp4s0f0` se configura automáticamente por DHCP al conectar el cable.
- **Wi-Fi:** Puedes conectarte desde el applet de red de KDE Plasma, o desde consola mediante:

```bash
nmtui
```

O directamente con `nmcli`:

```bash
nmcli device wifi list
nmcli device wifi connect "NOMBRE_DE_TU_RED" password "TU_CONTRASENA"
```

---

## Servicio de Impresión (CUPS)

El demonio de impresión se encuentra habilitado y administrado por systemd (`cups.service`, `cups.socket`, `cups.path`). El usuario principal pertenece a los grupos `lp` y `lpadmin`:

- Puedes añadir y configurar impresoras USB o de red directamente desde **Preferencias del Sistema → Impresoras** en KDE Plasma.
- Para administrarlo mediante la interfaz web de CUPS: accede a [http://localhost:631](http://localhost:631) en tu navegador.
- Comprobación del servicio:

```bash
systemctl status cups
```

---

## Atajos de Teclado en MySway

| Atajo | Acción |
| :--- | :--- |
| `Super + Enter` | Abrir terminal Kitty |
| `Super + Shift + Enter` | Abrir terminal Kitty en ventana flotante |
| `Super + d` | Lanzador de aplicaciones (Wofi) |
| `Super + q` | Cerrar ventana activa |
| `Super + ← / →` | Cambiar al espacio de trabajo anterior o siguiente |
| `Super + Shift + c` | Recargar configuración de Sway |
| `Super + Shift + e` | Salir de Sway a SDDM |
| `Super + Ctrl + l` | Bloquear pantalla manualmente |
| `Print` | Captura de pantalla completa |
| `Shift + Print` | Captura de región seleccionada |

---

## Actualizaciones y Mantenimiento

Para actualizar el sistema completo:

```bash
emerge --sync
emerge --ask --verbose --update --deep --newuse @world
```

Cuando una actualización instale un kernel nuevo, el hook persistente actualiza automáticamente la partición EFI. Para repetir la sincronización manualmente:

```bash
sudo gentoo-hp-update-boot
```

Comprobar la versión del kernel activo y la información del sistema:

```bash
uname -r
fastfetch
```

---

## Recuperación del Sistema (Chroot desde LiveGUI)

Si necesitas acceder al sistema instalado desde el USB LiveGUI para reparaciones:

```bash
sudo -i
cryptsetup open /dev/nvme0n1p3 root
mount -o subvol=/root /dev/mapper/root /mnt/gentoo
mount /dev/nvme0n1p1 /mnt/gentoo/boot/efi

mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev
mount --rbind /run /mnt/gentoo/run && mount --make-rslave /mnt/gentoo/run

chroot /mnt/gentoo /bin/bash
source /etc/profile
```

Al concluir las reparaciones, sal y desmonta limpiamente:

```bash
exit
umount -R /mnt/gentoo
cryptsetup close root
reboot
```

---

## Documentación Detallada

Para más información sobre la arquitectura y componentes específicos, consulta las guías dedicadas en la carpeta `docs/`:

- [`docs/KERNEL-PERSONALIZADO.md`](docs/KERNEL-PERSONALIZADO.md): Gestión del kernel Distribution Kernel y fragmentos persistentes en `/etc/kernel/config.d/`.
- [`docs/AUDIO-Y-BLUETOOTH.md`](docs/AUDIO-Y-BLUETOOTH.md): Pila multimedia de alta fidelidad, negociación de formato/tasa y Bluetooth A2DP.
- [`docs/KDE-PERSONALIZADO.md`](docs/KDE-PERSONALIZADO.md): Perfil Orizaba, restauración, fuentes y personalización de Plasma.
- [`docs/FLATPAK-DESKTOP-INTEGRATION.md`](docs/FLATPAK-DESKTOP-INTEGRATION.md): Integración de Discover, tema GTK Breeze y fuentes del sistema en Flatpak.
- [`docs/VIRTUALIZATION.md`](docs/VIRTUALIZATION.md): Uso de QEMU/KVM, libvirt, Virt-Manager y VirtualBox.
- [`docs/RAM-16GB-Y-PORTAGE.md`](docs/RAM-16GB-Y-PORTAGE.md): Ajuste seguro de Portage al ampliar la memoria a 16 GiB y grupos del usuario.
- [`docs/FUNCIONAMIENTO-Y-FIXES.md`](docs/FUNCIONAMIENTO-Y-FIXES.md): Registro técnico de arquitectura, decisiones de diseño y fixes implementados.
