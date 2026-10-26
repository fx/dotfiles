# Keyboard Layouts

Keymap backups for QMK-based keyboards. Load them back with the configurator matching the format.

| File | Board | Format | Configurator |
|------|-------|--------|--------------|
| `CSTM65.json` | CSTM65 | Vial (`.vil`) | [vial.rocks](https://vial.rocks) / Vial app |
| `DROPALTV2.json` | Drop ALT v2 | Vial (`.vil`) | [vial.rocks](https://vial.rocks) / Vial app |
| `DOIOKB3X.json` | DOIO KB3X-01 (`d010:0001`) | VIA save file | [usevia.app](https://usevia.app) → Save + Load |

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
| Right dial, right | `KC_F14` (keysym `XF86Launch5`) | Hold-to-talk to the `pa` agent (`voice-pa`), bound in `hyprland.lua.tmpl` |

Bind by keysym — xkb maps F13/F14 to `XF86Tools`/`XF86Launch5`, not `F13`/`F14`. Hyprland's Lua `hl.bind` does not parse `code:NNN`: such a bind loads with an empty key and fires on any key without a keysym, e.g. the Stream Deck+'s `KEY_UNKNOWN` on dial presses.
