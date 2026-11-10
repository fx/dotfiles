# Keyboard Layouts

Keymap backups for QMK-based keyboards. Load them back with the configurator matching the format.

| File | Board | Format | Configurator |
|------|-------|--------|--------------|
| `CSTM65.json` | CSTM65 | Vial (`.vil`) | [vial.rocks](https://vial.rocks) / Vial app |
| `DROPALTV2.json` | Drop ALT v2 | Vial (`.vil`) | [vial.rocks](https://vial.rocks) / Vial app |
| `DOIOKB3X.json` | DOIO KB3X-01 (`d010:0001`) | VIA save file | [usevia.app](https://usevia.app) → Save + Load |
| `doio-kb12-01.py` | DOIO KB12-01 (`d010:1201`) | Script (VIA raw HID) | `python3 doio-kb12-01.py` |

Browser configurators need hidraw access, granted by `.chezmoiscripts/run_onchange_after_setup-vial-udev.sh.tmpl`.

## DOIO KB3X-01

Macropad: 6 keys on top, three clusters of 4 keys around a knob (knob presses unmapped). Top-left key cycles layers 0–5 with `TO(n)`; layers 3–5 are empty. Stock DOIO firmware (STM32F103), VIA protocol v11, no Vial.

The stock firmware reports product ID `0x0001`, but VIA's official definition ([`v3/doio/kb3x/kb3x-01.json`](https://github.com/the-via/keyboards/blob/master/v3/doio/kb3x/kb3x-01.json)) expects `0x3F01`, so VIA won't detect it automatically. Load a patched definition via usevia.app → Settings → Show Design tab → Design → Load Draft Definition:

```bash
curl -sL https://raw.githubusercontent.com/the-via/keyboards/master/v3/doio/kb3x/kb3x-01.json \
  | jq '.productId = "0x0001"' > /tmp/kb3x-01-stock.json
```

QMK's layout (and VIA's definition) shows each cluster's left and right keys swapped: the physical left key is matrix column 1, the right key column 3.

The firmware releases modifiers and key in a single HID report, and the kernel emits the modifier releases first. Hyprland release binds with modifiers (e.g. `SUPER + ALT + D`) therefore never fire from the pad — use plain keys like F13+ for hold-to-talk.

Custom mappings (layer 0):

| Key | Keycode | Purpose |
|-----|---------|---------|
| Right dial, down | `KC_F13` (keysym `XF86Tools`) | Hold-to-talk dictation (hyprwhspr), bound in `hyprland.lua.tmpl` |
| Right dial, right | `KC_F14` (keysym `XF86Launch5`) | Hold-to-talk into the chat on screen in `tx rc` (`voice-pa`), bound in `hyprland.lua.tmpl` |

Bind by keysym — xkb maps F13/F14 to `XF86Tools`/`XF86Launch5`, not `F13`/`F14`. Hyprland's Lua `hl.bind` does not parse `code:NNN`: such a bind loads with an empty key and fires on any key without a keysym, e.g. the Stream Deck+'s `KEY_UNKNOWN` on dial presses.

## DOIO KB12-01

Macropad: 12 keys in a 3×4 grid plus three dials. Stock DOIO firmware, VIA protocol v12. Matrix is 3×5: columns 0–3 are the keys, column 4 the dial presses. The first dial press is `TO(1)` and cycles layers 0–5; layers 1–4 are transparent, layer 5 turns the keys into RGB controls. Out of the box the keys send F1–F12, which collide with the main keyboard.

`doio-kb12-01.py` writes layer 0 directly over the raw HID interface — no VIA GUI or definition file needed — and reads each key back. Re-run it after a firmware reset.

| Key | Keycode | Purpose |
|-----|---------|---------|
| 1–12 (row by row) | `MEH(KC_F13)`–`MEH(KC_F24)` (Ctrl+Alt+Shift+F13…F24) | Unpressable by hand; bound in `hyprland.lua.tmpl` |
| 12 | `MEH(KC_F24)` | Mark the focused window as the pad's target |
| 1–5 | `MEH(KC_F13)`–`MEH(KC_F17)` | Send `1`, `2`, `3`, `Shift+D`, `5` to the target window (`padKeys` in `hyprland.lua.tmpl`) |

Hyprland's `send_shortcut` only reaches unfocused Wayland windows: for an XWayland window it hands the key to XWayland, which delivers it to the X-focused window instead (with the pad's Shift still held). Wine also drops synthetic keys (`xdotool key --window`) sent to an inactive window. Wine on its native Wayland driver doesn't drop them, but routes keys to its own active window, which only follows a real focus change; with two clients in one Wine server, `send_shortcut`'s brief keyboard hop scrambles focus. XWayland and Wine (`*.exe` class) targets therefore go through `send-key-to-window`, which focuses the target for ~50 ms, sends the key, then restores focus and cursor position.

The modifiers keep the pad from triggering the KB3X's plain F13/F14 binds. Press binds only — release binds with modifiers don't fire from DOIO pads (see above). The target is held in a Lua variable: it is lost on config reload or when the window closes; press key 12 again.
