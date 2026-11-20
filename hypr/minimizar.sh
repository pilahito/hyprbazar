#!/usr/bin/env bash
# minimizar.sh — botón "−" de la barra de título (hyprbars).
#
# El botón no dice qué ventana es, así que se deduce por la posición del ratón
# (la ventana sobre la que está el puntero al pulsar). Con esa dirección se
# llama a minimizar-activa.sh, que hace el trabajo real: quitar maximizado si
# lo hubiera y mandar la ventana al escritorio especial "minimized" (oculto).
#
# Si el botón no se puede pulsar (ventana maximizada o a pantalla completa,
# donde Hyprland no dibuja la barra), el atajo SUPER + ALT + M minimiza la
# ventana activa igual.
set -uo pipefail

AQUI="$(dirname "$(readlink -f "$0")")"

ADDR="$("$AQUI/_ventana-cursor.sh")" || exit 0
[ -n "$ADDR" ] || exit 0

exec "$AQUI/minimizar-activa.sh" "$ADDR"
