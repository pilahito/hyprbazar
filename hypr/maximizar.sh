#!/usr/bin/env bash
# maximizar.sh — botón "□": maximiza / restaura UNA ventana: la del botón.
#
# Antes la acción era directa:
#     hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'
# y los dispatchers actúan sobre la ventana ACTIVA. Al pulsar la barra de una
# ventana que no tenía el foco se maximizaba OTRA (o ninguna) y la tuya se
# quedaba igual o tapada. Este script mira la ventana que hay debajo del
# cursor — la de la barra que pulsaste — y actúa sobre ESA.
set -uo pipefail

AQUI="$(dirname "$(readlink -f "$0")")"

ADDR="$("$AQUI/_ventana-cursor.sh")" || exit 0
[ -n "$ADDR" ] || exit 0

estado() {
    hyprctl clients -j 2>/dev/null \
        | jq -r --arg a "$ADDR" '.[] | select(.address == $a) | .fullscreen' 2>/dev/null
}

ANTES="$(estado)"

# 1) intento dirigido (con selector de ventana)
hyprctl dispatch "hl.dsp.window.fullscreen({ window = \"address:$ADDR\", mode = \"maximized\", action = \"toggle\" })" >/dev/null 2>&1
sleep 0.2

# 2) si no cambió nada, es que este dispatcher no acepta selector:
#    se enfoca ESA ventana y se repite el toggle clásico.
if [ "$ANTES" = "$(estado)" ]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$ADDR\" })" >/dev/null 2>&1
    sleep 0.15
    hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' >/dev/null 2>&1
fi
