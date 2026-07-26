# Perfil KDE Orizaba

Este directorio contiene una adaptación portable de
`MyKdeCustom/import_kde.sh` y un snapshot saneado de
`MyKdeCustom/kde_backup`, extraído desde Plasma 6.6.6.

El saneado conserva la apariencia, el panel, los atajos, GTK y Konsole, pero
excluye estados de Bluetooth, audio, monitores, energía, bloqueo y sesión. La
lista completa está en `snapshot/EXCLUSIONES.txt`.

Los archivos del snapshot están cubiertos por `snapshot/SHA256SUMS`. El fondo
`Path` conserva su autoría y licencia LGPL-3 en sus metadatos y junto al
recurso. El SVG del logotipo de Gentoo conserva dentro del propio archivo la
autoría y la referencia CC BY-SA 2.5 originales. Las fuentes Inter se
distribuyen por separado bajo OFL-1.1 en `contrib/fonts/inter`. La configuración
original de Orizaba usa MIT; el mapa completo está en
`snapshot/Orizaba/THIRD-PARTY-NOTICES.md`.

Consulta [`docs/KDE-PERSONALIZADO.md`](../../../docs/KDE-PERSONALIZADO.md)
para instalación, reaplicación y reversión.
