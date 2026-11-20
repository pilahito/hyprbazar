#!/usr/bin/env bash
# restaurar-ventana.sh — devuelve la ÚLTIMA ventana minimizada (una, no todas).
#
# Las minimizadas viven en el escritorio ESPECIAL "minimized" (ver
# minimizar.sh), que nunca se muestra: así que aquí no hay que "abrir" el
# cajón. Se saca la ventana de allí y se devuelve a su escritorio original.
#
# Uso:  restaurar-ventana.sh          -> devuelve la última
#       restaurar-ventana.sh todas    -> devuelve todas
set -uo pipefail

STACK="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-minimized-stack"
SPECIAL="special:minimized"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-minimized.json"

# ¿dónde devolverla si no sabemos de dónde venía? Al escritorio activo.
CUR="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // "1"')"
case "$CUR" in special:*|"") CUR="1" ;; esac

clientes() { hyprctl clients -j 2>/dev/null; }

sigue_minimizada() {
    clientes | jq -e --arg a "$1" --arg s "$SPECIAL" \
        '[.[] | select(.address == $a and .workspace.name == $s)] | length > 0' >/dev/null 2>&1
}

limpiar_estado() {
    [ -s "$STATE" ] || return 0
    local live
    live="$(clientes | jq -c --arg s "$SPECIAL" '[.[] | select(.workspace.name == $s) | .address]')"
    jq -c --argjson live "${LIVE:-$live}" \
        'with_entries(select(.key as $k | $live | index($k)))' \
        "$STATE" > "$STATE.tmp" 2>/dev/null && mv "$STATE.tmp" "$STATE"
}

devolver() {
    local adr="$1" ws
    [ -n "$adr" ] || return 1
    ws="$(jq -r --arg a "$adr" '.[$a].ws // empty' "$STATE" 2>/dev/null)"
    [ -n "$ws" ] && [ "$ws" != "$SPECIAL" ] || ws="$CUR"

    # Fuera del cajón, a su escritorio, subiéndola al frente y con el foco.
    hyprctl dispatch "hl.dsp.window.move({ window = \"address:$adr\", workspace = \"$ws\", follow = false })" >/dev/null 2>&1
    sleep 0.2
    hyprctl dispatch "hl.dsp.window.bring_to_top({ window = \"address:$adr\" })" >/dev/null 2>&1
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$adr\" })" >/dev/null 2>&1

    [ -s "$STATE" ] && jq -c --arg a "$adr" 'del(.[$a])' "$STATE" > "$STATE.tmp" 2>/dev/null \
        && mv "$STATE.tmp" "$STATE"
    return 0
}

if [ "${1:-}" = "todas" ]; then
    while read -r adr; do
        [ -n "$adr" ] && devolver "$adr"
        CUR="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // "1"')"
        case "$CUR" in special:*|"") CUR="1" ;; esac
    done < <(clientes | jq -r --arg s "$SPECIAL" '.[] | select(.workspace.name == $s) | .address')
    : > "$STACK" 2>/dev/null
    limpiar_estado
    exit 0
fi

# ── una sola: la última de la pila que siga siendo válida ───────────────────
adr=""
if [ -s "$STACK" ]; then
    while [ -s "$STACK" ]; do
        adr="$(tail -n1 "$STACK")"
        sed -i '$d' "$STACK" 2>/dev/null
        [ -n "$adr" ] && sigue_minimizada "$adr" && break
        adr=""
    done
fi

# Si la pila está vacía o no sirve, coger cualquiera que quede minimizada.
if [ -z "$adr" ]; then
    adr="$(clientes | jq -r --arg s "$SPECIAL" '[.[] | select(.workspace.name == $s)][0].address // empty')"
fi

[ -n "$adr" ] || exit 0
devolver "$adr"
limpiar_estado
