#!/usr/bin/env bash
# minimizar-activa.sh — esconde UNA ventana en el cajón (o la que le pases).
#
#   minimizar-activa.sh                  -> minimiza la ventana ACTIVA
#   minimizar-activa.sh 0xADDR           -> minimiza esa (lo usa el botón "−")
#
# Por qué existe: el botón "−" de la barra de título no se puede pulsar cuando
# la ventana está MAXIMIZADA o a pantalla completa (Hyprland no dibuja las
# decoraciones en esos modos), así que no había forma de minimizarla. Con el
# atajo SUPER + ALT + M no hace falta la barra: funciona siempre.
#
# Además, si la ventana estaba maximizada/pantalla completa se le quita ese
# modo ANTES de esconderla; si no, al devolverla volvería a ocupar todo.
set -uo pipefail

AQUI="$(dirname "$(readlink -f "$0")")"
SPECIAL="special:minimized"
STACK="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-minimized-stack"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-minimized.json"

ADDR="${1:-}"
if [ -z "$ADDR" ]; then
    ADDR="$("$AQUI/_ventana-cursor.sh" 2>/dev/null || true)"
fi
if [ -z "$ADDR" ]; then
    ADDR="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')"
fi
[ -n "$ADDR" ] || exit 0

CLIENT="$(hyprctl clients -j 2>/dev/null | jq -c --arg a "$ADDR" '.[] | select(.address == $a)')"
[ -n "$CLIENT" ] || exit 0

FULL="$(echo "$CLIENT" | jq -r '.fullscreen // 0')"
WS="$(echo "$CLIENT" | jq -r '.workspace.name // ""')"

# ── 1) quitar maximizado / pantalla completa antes de esconder ──────────────
case "$FULL" in
    1) hyprctl dispatch "hl.dsp.window.fullscreen({ window = \"address:$ADDR\", mode = \"maximized\", action = \"toggle\" })" >/dev/null 2>&1 ;;
    2) hyprctl dispatch "hl.dsp.window.fullscreen({ window = \"address:$ADDR\", mode = \"fullscreen\", action = \"toggle\" })" >/dev/null 2>&1 ;;
esac
[ "$FULL" != "0" ] && sleep 0.15

# ── 2) apuntar de dónde viene (para devolverla a su sitio) ──────────────────
case "$WS" in special:*) WS="" ;; esac
PREV_WS="$(jq -r --arg a "$ADDR" '.[$a].ws // empty' "$STATE" 2>/dev/null)"
[ -n "$WS" ] || WS="$PREV_WS"

INFO="$(echo "$CLIENT" | jq -c --arg w "$WS" '{ws: $w, title: .title, class: .class}')"

# limpiar entradas de ventanas que ya no están en el cajón (antes de apuntar)
if [ -s "$STATE" ]; then
    LIVE="$(hyprctl clients -j 2>/dev/null | jq -c --arg s "$SPECIAL" '[.[] | select(.workspace.name == $s) | .address]')"
    jq -c --argjson live "${LIVE:-[]}" \
        'with_entries(select(.key as $k | $live | index($k)))' \
        "$STATE" > "$STATE.tmp" 2>/dev/null && mv "$STATE.tmp" "$STATE"
fi

{ [ -s "$STATE" ] && cat "$STATE" || echo '{}'; } \
    | jq -c --arg a "$ADDR" --argjson i "$INFO" \
        '.[$a] = ($i + {ts: (now | floor)})' > "$STATE.tmp" 2>/dev/null \
    && mv "$STATE.tmp" "$STATE"

# ── 3) al cajón oculto, sin seguirla ni cambiar de escritorio ───────────────
hyprctl dispatch "hl.dsp.window.move({ window = \"address:$ADDR\", workspace = \"$SPECIAL\", follow = false })" >/dev/null 2>&1

printf '%s\n' "$ADDR" >> "$STACK" 2>/dev/null
exit 0
