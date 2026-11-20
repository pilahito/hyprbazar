#!/usr/bin/env bash
# _ventana-cursor.sh — imprime la dirección de la ventana cuya BARRA DE TÍTULO
# está debajo del cursor (la del botón que acabas de pulsar).
#
# hyprbars no le dice a los scripts de qué ventana es el botón, así que hay que
# deducirlo por la posición del ratón. Se hace en dos pasadas:
#
#   1) ventanas cuya franja de BARRA contiene el punto (el ratón está en la
#      barra de arriba, no en el contenido). De ésas, la primera por
#      focusHistoryID (0 = la última enfocada, que es la que se dibuja encima).
#   2) si ninguna cumple (p. ej. barra desactivada en esa app), se usa el
#      rectángulo completo de la ventana, igual que antes.
#
#   El modo 1 evita el fallo típico: con dos ventanas grandes solapadas, el
#   rectángulo del contenido de la de atrás también contiene el punto, y antes
#   se minimizaba la ventana equivocada.
set -uo pipefail

POS="$(hyprctl cursorpos 2>/dev/null)"
[ -n "$POS" ] || exit 1
X="${POS%%,*}"; Y="${POS##*, }"
case "${X}${Y}" in *[!0-9]*) exit 1 ;; esac

CLIENTES="$(hyprctl clients -j 2>/dev/null)"

# ── pasada 1: franja de la barra (34 px de alto, dibujada encima del contenido)
ADDR="$(printf '%s' "$CLIENTES" | jq -r --argjson x "$X" --argjson y "$Y" '
    [ .[]
      | select(.mapped == true)
      | select(.at[0] - 4 <= $x and (.at[0] + .size[0] + 4) >= $x)
      | select($y >= (.at[1] - 42) and $y <= (.at[1] + 8))
    ]
    | sort_by(.focusHistoryID // 9999)
    | .[0].address // empty')"

# ── pasada 2: rectángulo completo (respaldo)
if [ -z "$ADDR" ]; then
    ADDR="$(printf '%s' "$CLIENTES" | jq -r --argjson x "$X" --argjson y "$Y" '
        [ .[]
          | select(.mapped == true)
          | select(
              (.at[0] - 4              <= $x) and
              (.at[1] - 60             <= $y) and
              ((.at[0] + .size[0] + 4) >= $x) and
              ((.at[1] + .size[1])     >= $y)
            )
        ]
        | sort_by([(.focusHistoryID // 9999), (.size[0] * .size[1])])
        | .[0].address // empty')"
fi

[ -n "$ADDR" ] && printf '%s\n' "$ADDR"
