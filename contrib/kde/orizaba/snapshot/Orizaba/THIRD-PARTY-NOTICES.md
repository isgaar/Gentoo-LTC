# Licencias Del Paquete Orizaba

`metadata.json` usa `Custom` porque Orizaba es un paquete compuesto. Cada
componente conserva su licencia:

- La configuración, los metadatos y el diseño propios de Orizaba son de
  `isgaar` y se distribuyen bajo MIT. El texto completo está en
  `LICENSES/MIT-Orizaba.txt`.
- El fondo `Path` es obra de Risto Saukonpää y conserva su declaración
  `LGPLv3`, metadatos y los textos LGPL-3.0/GPL-3.0 en
  `contents/assets/usr/share/wallpapers/Path/`.
- El logotipo de Gentoo conserva dentro del SVG su atribución y referencia a
  CC BY-SA 2.5.

Los artefactos generados de decoración GTK de Breeze no se distribuyen dentro
del snapshot. El paquete `kde-plasma/kde-gtk-config`, instalado por Gentoo-HP,
administra esa integración para la versión de Plasma presente en el sistema.

Tampoco se redistribuye el esquema Breeze de Konsole. `Perfil 1.profile`
referencia `ColorScheme=Breeze`, proporcionado por `kde-apps/konsole`.
