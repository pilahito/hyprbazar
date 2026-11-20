#!/usr/bin/env bash
# install.sh — instala HyprBazar en el sistema del usuario.
#
#   ./install.sh            instala/actualiza
#   ./install.sh --check    solo comprueba dependencias
set -euo pipefail

AQUI="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

falta=()
for cmd in python3 magick jq curl git; do
    command -v "$cmd" >/dev/null 2>&1 || falta+=("$cmd")
done
python3 -c "import gi; gi.require_version('Gtk','4.0'); from gi.repository import Gtk" 2>/dev/null \
    || falta+=("python-gobject + gtk4")

if [ "${1:-}" = "--check" ]; then
    if [ ${#falta[@]} -eq 0 ]; then
        echo "Todo lo necesario está instalado."
    else
        echo "Falta: ${falta[*]}"
        echo "En Arch:  sudo pacman -S python-gobject gtk4 imagemagick jq curl git"
    fi
    exit 0
fi

if [ ${#falta[@]} -ne 0 ]; then
    echo "AVISO: falta ${falta[*]}" >&2
    echo "       En Arch: sudo pacman -S python-gobject gtk4 imagemagick jq curl git" >&2
fi

mkdir -p "$BIN" "$APPS"
for f in hyprbazar hyprbazar-paleta hyprbazar-tienda hyprbazar-tema teclado-sonido; do
    install -m 755 "$AQUI/bin/$f" "$BIN/$f"
    echo "  $f -> $BIN/$f"
done

# ── icono ──────────────────────────────────────────────────────────────────
ICONOS="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
if [ -f "$AQUI/assets/hyprbazar.svg" ]; then
    for tam in 512 256 128 64 48 32; do
        mkdir -p "$ICONOS/${tam}x${tam}/apps"
        if command -v magick >/dev/null 2>&1; then
            magick -background none "$AQUI/assets/hyprbazar.svg" -resize "${tam}x${tam}" \
                "$ICONOS/${tam}x${tam}/apps/hyprbazar.png" 2>/dev/null || true
        fi
    done
    mkdir -p "$ICONOS/scalable/apps"
    cp -f "$AQUI/assets/hyprbazar.svg" "$ICONOS/scalable/apps/hyprbazar.svg"
    gtk-update-icon-cache -f -t "$ICONOS" >/dev/null 2>&1 || true
    echo "  icono -> $ICONOS"
fi

cat > "$APPS/es.david.HyprBazar.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Version=1.0
Name=HyprBazar
Comment=Temas, fondos y paletas para Hyprland
Exec=hyprbazar
Icon=hyprbazar
Terminal=false
Categories=Settings;DesktopSettings;
Keywords=tema;temas;fondo;wallpaper;paleta;hyprland;
StartupWMClass=es.david.HyprBazar
DESK
update-desktop-database "$APPS" >/dev/null 2>&1 || true
# limpiar el nombre antiguo del lanzador, si quedó de una versión anterior
rm -f "$APPS/hyprbazar.desktop" 2>/dev/null || true

cat <<'FIN'

Instalado. Para abrirlo:  hyprbazar   (o búscalo como "HyprBazar" en el menú)

Atajo recomendado — añade esto a tu ~/.config/hypr/dms/binds-user.lua:

  hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd("hyprbazar"),
          { description = "HyprBazar (temas)" })

y recarga Hyprland.
FIN
