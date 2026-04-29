# Star Citizen on this box

Hard-won setup for SC 4.7+ on CachyOS + RTX 4090 + Hyprland Wayland + multi-monitor. Don't deviate without reading the rationale below — most "obvious" tweaks make it worse.

## Required configuration

All four pieces below must hold simultaneously. Removing any one re-breaks the game.

### 1. D3D11 renderer (not native Vulkan)

`~/Games/star-citizen/drive_c/users/<user>/AppData/Local/star citizen/starcitizen_*/GraphicsSettings/GraphicsSettings.json`:

```json
{ "GraphicsSettings": { "SettingsVersion": 1, "GraphicsRenderer": 0 } }
```

`0` = DX11 routed through DXVK. `1` = SC's native Vulkan renderer, which **crashes** with `GPU Crash Vulkan - Nvidia - Device Timeout - Device Lost` on NVIDIA 595.58.03 open modules. Multi-game CachyOS-wide regression (also affects Elden Ring Nightreign, Cyberpunk) — see [discuss.cachyos.org](https://discuss.cachyos.org/) NVIDIA 595 threads. DXVK's translated Vulkan dodges the buggy code path.

### 2. Experimental Wayland Wine runner

[`lug-wine-tkg-staging-experimental-wayland-git`](https://github.com/starcitizen-lug/lug-wine-experimental/releases/latest), extracted to `~/Games/star-citizen/runners/`. The stock `lug-wine-tkg-git` runner uses XWayland and has cursor offset bugs on multi-monitor setups.

### 3. `sc-launch.sh` env vars

```bash
export DISPLAY=                       # forces native Wayland-Wine (NOT XWayland)
export WAYLANDDRV_PRIMARY_MONITOR=DP-6 # the gaming monitor; check `hyprctl monitors`
export PROTON_VKD3D_HEAP=1             # NVIDIA 595 hail-mary, harmless
export wine_path="/home/<user>/Games/star-citizen/runners/lug-wine-tkg-staging-experimental-wayland-git-X.Y-N/bin"
```

`WAYLANDDRV_PRIMARY_MONITOR` is **only honored** when the native Wayland driver is active, which requires `DISPLAY=` empty.

### 4. Resolution must match the pinned monitor exactly

`~/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen/LIVE/user/client/0/Profiles/default/attributes.xml`:

- `Width` × `Height` = monitor native res (3840×2160 for the 4K monitor)
- `WindowMode = 2` (exclusive fullscreen)
- `Upscaling = 0` — turn off FSR/DLSS. Upscaling > 0 makes SC render at a smaller internal res then scale; the cursor coordinate space stays in the small render res, reproducing the offset bug.
- `Resolution` is an in-game UI dropdown enum that maps to a specific resolution preset; if the in-game UI gets changed, this attribute can drift. Last known-working values: `Resolution=24` for 4K.

### 5. Hyprland window rules

Already in `dot_config/hypr/hyprland.conf.tmpl`:

```
windowrule = monitor DP-6, match:class starcitizen.exe
windowrule = fullscreen 2, match:class starcitizen.exe
windowrule = immediate true, match:class starcitizen.exe
windowrule = monitor DP-6, match:class rsi launcher.exe
windowrule = float yes, match:class rsi launcher.exe
```

Without these, Hyprland **tiles** the SC window, fighting SC's exclusive-fullscreen request. The swapchain bounces between 4K and ~1700×1000 (`VK_SUBOPTIMAL_KHR` repeatedly in `sc-launch.log`). Cursor coords lock to whichever sub-resolution the surface settled at last — exactly the "constrained to a smaller area" symptom.

Update the monitor name (`DP-6`) if you change cabling.

## Performance: swappiness

CachyOS defaults `vm.swappiness=150` for ZRAM-heavy workloads. SC's 16+ GiB working set + active swapping → frame stutter. Persist a lower value:

```bash
sudo tee /etc/sysctl.d/99-low-swappiness.conf <<<'vm.swappiness = 10'
```

Not yet in dotfiles since it's machine-specific (depends on RAM amount); consider templatizing if it becomes a pattern across machines.

## Things that have NOT worked, do not retry

- Kernel rollback to LTS — same Vulkan crash
- nvidia-utils -2 → -1 downgrade within 595.58.03 — same driver underneath
- `__GL_THREADED_OPTIMIZATIONS=0`, `DXVK_FILTER_DEVICE_NAME`, `VK_ICD_FILENAMES` filter — none addressed the Vulkan path bug
- `NVreg_EnableGpuFirmware=0` — silently ignored on open modules (which **require** GSP firmware)
- `pl_pit.forceSoftwareCursor=1` in `user.cfg` — irrelevant to surface-size offset
- `cursor:use_cpu_buffer=false` in Hyprland — orthogonal to Wine's coord math
- gamescope wrap — wraps the launcher too, breaks the launcher UI; complex to wrap only the game
- `winewayland.drv=` override (forces XWayland) — XWayland has its own multi-monitor cursor bugs

## Common operations

```bash
# Kill stuck SC (after the wineprefix's wineserver, version-specific path)
WINEPREFIX=/home/$USER/Games/star-citizen \
  /home/$USER/Games/star-citizen/runners/lug-wine-tkg-staging-experimental-wayland-git-*/bin/wineserver -k

# Reset graphics settings (keeps install, drops only user prefs)
mv "/home/$USER/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen/LIVE/user" \
   "/home/$USER/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen/LIVE/user.bak.$(date +%s)"
# Loses keybinds (actionmaps.xml) and character files (customcharacters/) — back up first

# Crash signature in Game.log
grep "GPU Crash Vulkan" "/home/$USER/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen/LIVE/Game.log"
# "Nvidia - Device Timeout - Device Lost" → 595 regression fingerprint
```

## Things that need re-checking after game updates

The launcher self-updates on every patch and **regenerates `attributes.xml`** with new defaults. After any SC update:

1. Verify `WindowMode=2`, `Upscaling=0`, `Width`/`Height`/`Resolution` still correct — the in-game UI can also flip these
2. Verify `GraphicsSettings.json` `GraphicsRenderer` still `0`
3. Confirm cursor still 1:1 in fullscreen; if not, `Upscaling` flipped or in-game res dropdown changed `Resolution`

## Future: when can this be simplified?

Revisit when CachyOS ships an NVIDIA driver beyond 595.58.03 (596+, or 595.58.03 with the regression patched):
- `GraphicsRenderer: 1` (native Vulkan) might work again
- The stock `lug-wine-tkg-git` runner might suffice (no need for experimental-wayland)
- `WAYLANDDRV_PRIMARY_MONITOR` may stop being needed if Wine's wayland driver matures

Re-test by reverting one change at a time, watching `Game.log` and the swapchain in `sc-launch.log` after each.
