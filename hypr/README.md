# Botones de ventana y utilidades para Hyprland

Copias de los scripts que usa [hyprbars](https://github.com/hyprwm/hyprland-plugins)
en este escritorio, más dos utilidades de mantenimiento. Están aquí como
referencia y por si te sirven tal cual.

| Script | Qué hace |
|---|---|
| `_ventana-cursor.sh` | encuentra la ventana cuya barra de título está bajo el cursor (hyprbars no le pasa ese dato a los scripts) |
| `minimizar.sh` | botón **−**: minimiza la ventana de la barra pulsada |
| `minimizar-activa.sh` | minimiza la ventana **activa** (atajo `SUPER + ALT + M`, funciona aunque no haya barra) |
| `restaurar-ventana.sh` | devuelve la última minimizada (`SUPER + SHIFT + M`) o todas (`+ ALT`) |
| `maximizar.sh` | botón **□**: maximiza/restaura esa ventana |
| `cerrar-ventana.sh` | botón **✕**: cierra solo esa ventana |
| `arreglar-barras.sh` | recarga **solo hyprbars** cuando las barras desaparecen |
| `revisar-config.sh` | dice si la config de Hyprland tiene errores (`hyprctl configerrors`) |

## Las dos trampas que nos costaron tiempo

### 1. `hyprctl reload` deja hyprbars sin barras

En Hyprland 0.57, recargar toda la configuración deja el plugin cargado pero
**sin decorar ninguna ventana**: desaparecen las barras y los botones. Recargar
otra vez no lo arregla. Solución:

```bash
./arreglar-barras.sh      # descarga y vuelve a cargar solo hyprbars
```

### 2. Los campos de plugins no valen en `hl.window_rule()`

La API Lua solo acepta `enabled`, `match` y `name`. Poner un campo del plugin
rompe la config entera y sale el cartel rojo al iniciar sesión:

```lua
-- MAL: error "unknown field 'hyprbars:no_bar'"
hl.window_rule({ match = { class = "^(mpv)$" }, ["hyprbars:no_bar"] = true })
```

Los ajustes del plugin se hacen en el plugin (`hl.config({ plugin = { hyprbars = { ... } } })`).

## Instalación

```bash
cp hypr/*.sh ~/.config/hypr/winbuttons/
chmod +x ~/.config/hypr/winbuttons/*.sh
```

En `~/.config/hypr/winbuttons/buttons.lua`:

```lua
hl.plugin.hyprbars.add_button({
    size = 22, icon = "–",
    action = "/home/TU_USUARIO/.config/hypr/winbuttons/minimizar.sh",
})
```

Atajos recomendados en `binds-user.lua`:

```lua
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd(".../minimizar-activa.sh"),
        { description = "Minimizar ventana activa" })
```
