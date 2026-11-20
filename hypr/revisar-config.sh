#!/usr/bin/env bash
# revisar-config.sh — comprueba que la config de Hyprland carga sin errores.
#
# Úsalo después de actualizar Hyprland o de tocar ~/.config/hypr. Si hay
# errores los muestra (y en Hyprland salen como cartel rojo al iniciar sesión).
#
#   revisar-config.sh          solo comprueba
#   revisar-config.sh --barras comprueba y, si hace falta, recarga hyprbars
set -uo pipefail

errores="$(hyprctl configerrors 2>/dev/null)"
if [ -z "${errores// /}" ]; then
    echo "Config OK: sin errores."
    estado=0
else
    echo "Errores de configuración:"
    printf '%s\n' "$errores"
    estado=1
fi

if [ "${1:-}" = "--barras" ]; then
    "$HOME/.config/hypr/winbuttons/arreglar-barras.sh"
fi
exit "$estado"
