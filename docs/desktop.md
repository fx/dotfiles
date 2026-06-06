# Desktop Profile Documentation

This document covers desktop-specific configuration, troubleshooting, and gaming setup for the `desktop` profile.

## Hyprland Configuration

Config location: `dot_config/hypr/hyprland.conf.tmpl`

Machine-specific overrides (monitors, VRR) go in `~/.config/hypr/local.conf` (not managed by dotfiles).

### Dark Mode

Applications like Zed query the XDG Desktop Portal to detect the system color scheme. This requires:

1. **Packages** (in `packages.yaml`):
   - `xdg-desktop-portal` - Main portal service
   - `xdg-desktop-portal-hyprland` - Hyprland backend
   - `xdg-desktop-portal-gtk` - GTK fallback

2. **Portal Configuration** (`~/.config/xdg-desktop-portal/hyprland-portals.conf`):
   ```ini
   [preferred]
   default=hyprland;gtk
   org.freedesktop.impl.portal.Settings=hyprland
   ```

3. **Environment Variables** (in `hyprland.conf`):
   ```
   env = GTK_THEME,Adwaita:dark
   env = QT_QPA_PLATFORMTHEME,qt5ct
   ```

4. **Autostart** (in `hyprland.conf`):
   ```
   exec-once = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
   exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
   exec-once = systemctl --user restart xdg-desktop-portal.service
   ```

Applications should now correctly detect dark mode via the portal's Settings interface.

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

### Game resolution / fullscreen issues

If a game can't select 4K or ignores the monitor resolution after going fullscreen, the cause is Hyprland tiling the game window — the tiled size caps what the game sees as available resolution, and the swapchain thrashes between the tiled dimensions and the requested fullscreen size.

**Fix:** add per-game window rules to float the window and pin it to the gaming monitor:
```
windowrule = monitor DP-6, match:class steam_app_<APPID>
windowrule = float yes, match:class steam_app_<APPID>
```

Replace `DP-6` with your gaming monitor name (`hyprctl monitors` to check) and `<APPID>` with the Steam App ID (visible in the store URL).

If the game uses exclusive fullscreen and still misbehaves, also add:
```
windowrule = fullscreen 2, match:class steam_app_<APPID>
```

**XWayland primary monitor:** The autostart includes `xrandr --output DP-6 --primary` so XWayland games default to the 4K monitor. If you change which monitor is primary, update this line.

Active per-game rules: Star Citizen (`starcitizen.exe`), Stellaris (`steam_app_281990`).

## Gaming with Proton/Wine

Game-specific recipes:
- [Star Citizen](games/star-citizen.md) — required setup for SC 4.7+ on NVIDIA 595 + Hyprland Wayland multi-monitor

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

#### WoW won't launch — "Windows compatibility mode" error

**Symptoms:** Battle.net refuses to launch WoW, saying Windows compatibility mode is enabled. May also say Windows 10 is no longer supported.

**Cause:** Proton defaults the Wine version to `win7`. WoW dropped Win10 support and requires Windows 11+. Battle.net checks `GetVersionEx()` which Wine controls via `HKCU\Software\Wine\Version` (not the cosmetic `HKLM\..\CurrentVersion` registry keys).

**Fix:** The `battlenet` script automatically patches `user.reg` to set `Version`=`win11` under `Software\Wine`. No manual action needed — it runs on every launch and skips if already patched.

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

### Flatpak games run at single-digit FPS after an NVIDIA driver update

**Symptoms:** A Flatpak app/game (e.g. Hytale, `com.hypixel.HytaleLauncher`) runs at ~5fps even though native games and `nvidia-smi` are fine. Often appears right after a system NVIDIA driver update.

**Cause:** Flatpaks are sandboxed and ship their **own** NVIDIA userspace driver via a GL extension (`org.freedesktop.Platform.GL.nvidia-<version>`). This extension version must **exactly match** the host kernel module version (`cat /proc/driver/nvidia/version`). When the host driver is updated but the matching Flatpak extension isn't pulled, the in-sandbox NVIDIA GL/Vulkan context fails to initialize and the app silently falls back to **llvmpipe software rendering**.

**Diagnose:**
```bash
cat /proc/driver/nvidia/version | head -1        # host driver, e.g. 595.71.05
flatpak list | grep -i nvidia                     # installed extension version(s)
```
A version mismatch (e.g. host `595-71-05` vs extension `590-48-01`) is the problem.

**Fix:** Install the matching extension and remove the stale one. Note Flathub is often registered in **both** `--system` and `--user`; match the install scope of the app (Hytale is `--user`):
```bash
flatpak install --user flathub org.freedesktop.Platform.GL.nvidia-595-71-05
flatpak uninstall --user org.freedesktop.Platform.GL.nvidia-590-48-01
```
Then fully quit and relaunch the Flatpak (no reboot needed). `flatpak remote-ls --user flathub --runtime --columns=application,branch | grep GL.nvidia` lists available versions.

**Prevent (automated):** The `flatpak-nvidia-sync` script (`dot_local/bin/`) reconciles the user-scope Flatpak NVIDIA GL extension to the host kernel driver. It runs at login via Hyprland `exec-once` (NVIDIA systems only). Because driver upgrades require a reboot to load the new kernel module, the first session afterwards self-heals: the script reads `/proc/driver/nvidia/version`, pulls the matching `org.freedesktop.Platform.GL.nvidia-<version>` extension, removes the stale one, and notifies via `notify-send`. It's a cheap local no-op when already in sync. Run it manually any time with `flatpak-nvidia-sync`.

> Scope note: only **user**-scope Flatpaks are reconciled (no polkit prompt at login). System-scope Flatpaks still need a manual `sudo flatpak update`.

### Apps render on the AMD iGPU instead of the dGPU (stutter / low FPS)

**Symptoms:** Chrome video playback stutters and games run at a fraction of expected FPS (e.g. Hytale at ~15fps), even though the RTX dGPU sits nearly idle in `nvidia-smi`.

**Cause:** Zen 5 desktop CPUs (e.g. Ryzen 7 9850X3D, "Granite Ridge") include a tiny 2-CU RDNA2 iGPU. With both `nvidia_icd.json` and `radeon_icd.json` installed, the Vulkan loader enumerates the **iGPU as device 0**. Vulkan apps that don't explicitly pick a device — Chrome's compositor/video path and many games — default to the iGPU. OpenGL is unaffected (it correctly defaults to the dGPU via `__GLX_VENDOR_LIBRARY_NAME`).

**Diagnose:**
```bash
vulkaninfo --summary | grep deviceName   # iGPU listed first = problem
```

**Fix:** Hide the AMD Vulkan ICD so only the dGPU is visible. Set in the NVIDIA env block of `hyprland.conf.tmpl`:
```
env = VK_LOADER_DRIVERS_DISABLE,*radeon*
```
The Vulkan loader does the glob matching itself (not the shell). No-op on pure-NVIDIA systems where no radeon ICD exists. Takes effect after `./install.sh` + a fresh Hyprland session (re-login).

**Verify:**
```bash
VK_LOADER_DRIVERS_DISABLE='*radeon*' vulkaninfo --summary | grep deviceName  # only the dGPU
```

## DisplayPort Monitor Not Detected on Cold Boot

### Symptoms

One or more monitors connected via DisplayPort aren't detected after a cold boot, but all monitors show in SDDM. A reboot fixes the issue.

### Cause

AMD GPU DisplayPort link training can timeout on cold boot before the monitor is ready. The kernel logs show:
```
[drm] *ERROR* Sending link address failed with -5
```

### Fix

**1. Add amdgpu to early KMS modules** (recommended):

```bash
sudo sed -i 's/^MODULES=.*/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
sudo mkinitcpio -P
```

This loads the GPU driver earlier in boot, giving more time for DP link training.

**2. Monitor check script** (included in dotfiles):

The `monitor-check` script runs at Hyprland startup and notifies you if monitors are missing. If you see the notification, try:
- Physically unplug/replug the DisplayPort cable
- Or reboot

### Verification

Check current MODULES setting:
```bash
grep "^MODULES=" /etc/mkinitcpio.conf
```

Should show `MODULES=(amdgpu)`.

## Game Streaming (Sunshine + Moonlight)

The dotfiles configure Sunshine (game streaming host) for streaming games to other devices via the Moonlight client.

### Installation

Install both packages (CachyOS/Arch):
```bash
paru -S sunshine moonlight-qt
```

### Sunshine (Host)

Sunshine allows streaming games FROM this PC to other devices (Steam Deck, phone, TV, etc.).

**First-time setup:**
1. Start sunshine: `systemctl --user start sunshine`
2. Open the web UI: https://localhost:47990
3. Create admin credentials when prompted
4. Pair your Moonlight client by entering the PIN displayed in the web UI

**Configuration files:**
- `~/.config/sunshine/sunshine.conf` - Main config (managed by dotfiles)
- `~/.config/sunshine/apps.json` - Applications to expose (managed by dotfiles)

**Enable at startup:**
```bash
systemctl --user enable sunshine
```

**Adding applications:**
Edit `apps.json` or use the web UI to add games. Example entry:
```json
{
  "name": "Game Name",
  "detached": ["steam steam://rungameid/12345"],
  "cmd": ""
}
```

### Moonlight (Client)

Moonlight receives streams TO this PC from another Sunshine/GameStream host.

**Usage:**
1. Launch `moonlight-qt`
2. Select the host PC from discovered servers
3. Pair if prompted (enter PIN shown on host)
4. Select an application to stream

**Hyprland integration:**
The Moonlight window has `immediate true` (tearing) enabled for lowest latency streaming.

### Troubleshooting

#### Sunshine won't start
Check if another instance is running or port 47990 is in use:
```bash
ss -tlnp | grep 47990
```

#### Pairing fails
Ensure both devices are on the same network. Check Sunshine logs:
```bash
journalctl --user -u sunshine -f
```

#### High latency in Moonlight
- Enable hardware decoding in Moonlight settings
- Use HEVC (H.265) codec if both host and client support it
- Connect via Ethernet instead of WiFi when possible

## Stream Deck (OpenDeck)

See `dot_config/opendeck/README.md` for encoder/button configuration details.

- **Encoder 1**: Volume control
- **Encoder 2**: Home Assistant light control (requires credentials setup)

## Adding New Fixes

When discovering new desktop/gaming fixes:

1. Add environment variables to the appropriate launch script (e.g., `battlenet`)
2. Document the issue, cause, and fix in this file
3. Include references to upstream issues/documentation
