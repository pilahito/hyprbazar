#!/usr/bin/env bash
# arreglar-barras.sh — devuelve las barras de título cuando desaparecen.
#
# Cuándo hace falta: `hyprctl reload` (recargar TODA la config) deja el plugin
# hyprbars cargado pero SIN decorar ninguna ventana: las ventanas se quedan
# sin barra y sin botones, y la sesión sigue viva. Recargar la config otra vez
# no lo arregla.
#
# Lo que hace: descarga y vuelve a cargar SOLO hyprbars. Al cargarse, el
# plugin re-decoriza las ventanas que ya existen y vuelve a leer la config
# (incluidos los tres botones de buttons.lua). No cierra nada ni reinicia
# sesión.
set -uo pipefail

SO="/var/cache/hyprpm/david/hyprland-plugins/hyprbars.so"
[ -f "$SO" ] || SO="$HOME/.local/share/hyprland-plugins/hyprbars/hyprbars.so"

hyprctl plugin unload "$SO" >/dev/null 2>&1
sleep 0.5
hyprctl plugin load "$SO" >/dev/null 2>&1
sleep 1

if hyprctl plugin list 2>/dev/null | grep -q "^Plugin hyprbars"; then
    echo "hyprbars recargado: las barras deberían haber vuelto."
    exit 0
fi
echo "no pude recargar hyprbars; revisa $SO" >&2
exit 1
