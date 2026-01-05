# OpenDeck Configuration

Stream Deck configuration for OpenDeck on Linux.

## Icons

Icons are sourced from [Tabler Icons](https://tabler.io/icons) - MIT licensed, 5900+ free icons.

### Adding New Icons

1. Find an icon on [tabler.io/icons](https://tabler.io/icons)
2. Download SVG via unpkg CDN:
   - Outline: `https://unpkg.com/@tabler/icons@latest/icons/outline/<icon-name>.svg`
   - Filled: `https://unpkg.com/@tabler/icons@latest/icons/filled/<icon-name>.svg`
3. Color the SVG (replace `currentColor`): `sed 's/currentColor/#e78a4e/g' icon.svg > icon-colored.svg`
4. Convert to 128x128 PNG: `magick -background none -density 300 icon-colored.svg -resize 128x128 icon.png`
5. Place in `icons/` directory

### Icon Cache

**IMPORTANT**: OpenDeck caches icons in `~/.config/opendeck/images/<device-serial>/Default/<context>/`.

The `run_onchange_after_configure-opendeck.sh` script copies icons from `~/.config/opendeck/icons/` to the cache directory. Cache paths use the encoder context format:
- `Encoder.0.0/0.png` - First encoder icon
- `Encoder.1.0/0.png` - Second encoder icon
- `Keypad.0.0/0.png` - First button state 0
- `Keypad.0.0/1.png` - First button state 1

If icons don't update after `./install.sh`, the cache may need manual clearing or opendeck restart.

## Profile Format

Profiles are JSON files in `profiles/`. The `profile-default.json.tmpl` is a chezmoi template that gets applied to device-specific profiles.

### Encoder Context Format

**IMPORTANT**: Encoder contexts use `Encoder.<row>.0` format, NOT `Encoder.0.<index>`.

For Stream Deck Plus (4 encoders in a vertical row):
- Encoder 1: `Encoder.0.0`
- Encoder 2: `Encoder.1.0`
- Encoder 3: `Encoder.2.0`
- Encoder 4: `Encoder.3.0`

### Button Context Format

Buttons use `Keypad.<row>.<column>` format:
- Button 1 (top-left): `Keypad.0.0`
- Button 2: `Keypad.0.1`
- etc.

## Device-Specific Profiles

OpenDeck creates device-specific profiles at runtime:
- `~/.config/opendeck/profiles/sd-<SERIAL>/Default.json`

The chezmoi template (`profile-default.json.tmpl`) syncs to these device profiles via a modify script.

## Current Configuration

### Encoders
1. **Volume** - Rotate to adjust volume, press to mute
2. **Lights** - Rotate to dim, press to toggle (requires Home Assistant credentials)

### Buttons
1. **Audio Toggle** - Switch between speakers/headphones

## Home Assistant Integration

See main CLAUDE.md for Home Assistant credential setup. Credentials are stored at `~/.config/home-assistant/credentials` (not managed by chezmoi).
