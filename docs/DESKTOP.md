# Desktop Profile Documentation

This document covers desktop-specific configuration, troubleshooting, and gaming setup for the `desktop` profile.

## Hyprland Configuration

Config location: `dot_config/hypr/hyprland.conf.tmpl`

Machine-specific overrides (monitors, VRR) go in `~/.config/hypr/local.conf` (not managed by dotfiles).

### Key Settings

**Rendering (misc section):**
```
misc {
    vfr = false                  # Always render every frame
    render_unfocused_fps = 120   # Keep unfocused windows rendering
}
```

**Render section:**
```
render {
    direct_scanout = 0           # Disabled - can cause issues with NVIDIA
}
```

**Gaming window rules:**
```
windowrule = immediate true, match:class steam_app_.*
windowrule = immediate true, match:class Battle.net.exe
windowrule = immediate true, match:class Wow.exe
```

The `immediate` rule enables tearing for better frame pacing in games.

## Gaming with Proton/Wine

### Battle.net Launcher

Script: `~/.local/bin/battlenet`

Usage:
```bash
battlenet              # Launch Battle.net
battlenet wow          # Launch WoW directly
battlenet d4           # Launch Diablo 4
battlenet --debug      # Show paths and debug info
```

### Environment Variables

The `battlenet` script sets these automatically:

```bash
# RTX 4000+ performance fix
PROTON_NVIDIA_LIBS_NO_32BIT=1

# Prevent freeze when switching workspaces (CRITICAL for D3D12 games)
DXVK_ASYNC=1
VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait
```

### Troubleshooting

#### Game freezes when switching workspaces

**Symptoms:** Game freezes permanently when switching to another workspace, never recovers even when switching back.

**Cause:** The `VK_KHR_present_wait` Vulkan extension can cause deadlocks when a D3D12 game loses focus. The game waits for a present that never completes.

**Fix:** Set `VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait` before launching. This is already configured in the `battlenet` script.

**References:**
- https://github.com/doitsujin/dxvk/issues/4510
- https://github.com/HansKristian-Work/vkd3d-proton/issues/1813

#### WoW-specific settings

WoW config location: `~/Games/World of Warcraft/_retail_/WTF/Config.wtf`

Recommended settings for Linux:
- `SET GxApi "D3D12"` - D3D12 generally works better than D3D11 on modern vkd3d-proton
- `SET useMaxFPSBk "0"` - Don't limit background FPS
- `SET Sound_EnableSoundWhenGameIsInBG "1"` - Keep sound in background
- `SET LowLatencyMode "0"` - NVIDIA Reflex doesn't work on Wine anyway

#### DXVK vs vkd3d-proton

- **DXVK**: Translates D3D9/D3D10/D3D11 to Vulkan
- **vkd3d-proton**: Translates D3D12 to Vulkan

WoW with `GxApi "D3D12"` uses vkd3d-proton. Environment variables prefixed with `VKD3D_` affect D3D12 games.

## NVIDIA-Specific

### Hyprland Environment Variables

Set in `hyprland.conf.tmpl`:
```
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
```

### WirePlumber NVIDIA Audio

The dotfiles configure WirePlumber to handle NVIDIA HDMI audio properly. Config is generated during `./install.sh` when an NVIDIA GPU is detected.

## Stream Deck (OpenDeck)

See `dot_config/opendeck/README.md` for encoder/button configuration details.

- **Encoder 1**: Volume control
- **Encoder 2**: Home Assistant light control (requires credentials setup)

## Adding New Fixes

When discovering new desktop/gaming fixes:

1. Add environment variables to the appropriate launch script (e.g., `battlenet`)
2. Document the issue, cause, and fix in this file
3. Include references to upstream issues/documentation
