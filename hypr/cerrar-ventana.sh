#!/usr/bin/env bash
# cerrar-ventana.sh — cierra UNA sola ventana: la del botón X que pulsaste
#
# Por qué existe este script y no una orden directa:
#
#   · kill()  -> mata el PROCESO entero. Brave usa un solo proceso para
#                TODAS sus ventanas, así que cerraba todas de golpe.
#
#   · close() -> es un cierre suave (lo correcto), PERO actúa sobre la
#                ventana ACTIVA. Al pulsar la X de una ventana que no estaba
#                activa, cerraba la equivocada o ninguna.
#
# Lo que hace este script:
#   1. mira qué ventana hay DEBAJO DEL CURSOR (esa es la del botón pulsado)
#   2. cierra SOLO esa, por su dirección (sin cambiar el foco de tu trabajo)
#
# La detección vive en _ventana-cursor.sh, compartida con minimizar y maximizar.
set -uo pipefail

AQUI="$(dirname "$(readlink -f "$0")")"

ADDR="$("$AQUI/_ventana-cursor.sh")" || exit 0
[ -n "$ADDR" ] || exit 0

# Cierre suave SOLO de esa ventana. Si el dispatcher no aceptase el selector
# de ventana, se enfoca primero y se cierra la activa (que ya es la tuya).
hyprctl dispatch "hl.dsp.window.close({ window = \"address:$ADDR\" })" >/dev/null 2>&1
sleep 0.25
if hyprctl clients -j 2>/dev/null | jq -e --arg a "$ADDR" '.[] | select(.address == $a)' >/dev/null 2>&1; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$ADDR\" })" >/dev/null 2>&1
    sleep 0.15
    hyprctl dispatch 'hl.dsp.window.close()' >/dev/null 2>&1
fi
