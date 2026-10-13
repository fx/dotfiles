# Desktop Profile Documentation

This document covers desktop-specific configuration, troubleshooting, and gaming setup for the `desktop` profile.

## Hyprland Configuration

Config location: `dot_config/hypr/hyprland.lua.tmpl` (Lua config; hyprlang `hyprland.conf` is deprecated since 0.55). API stubs: `/usr/share/hypr/stubs/hl.meta.lua`. Check a rendered config with `Hyprland --verify-config -c <file>`.

Machine-specific overrides (monitors, VRR) go in `~/.config/hypr/local.lua` (not managed by dotfiles), loaded via `require("local")`.

Runtime changes use `hyprctl eval '<lua>'` — `hyprctl keyword` is legacy-only, and `hyprctl dispatch` takes Lua (`hyprctl dispatch 'hl.dsp.window.close()'`).

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

3. **Environment Variables** (in `hyprland.lua`):
   ```lua
   hl.env("GTK_THEME", "Adwaita:dark")
   hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
   ```

4. **Autostart** (in `hyprland.lua`'s `hl.on("hyprland.start", ...)`):
   ```lua
   hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
   hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
   hl.exec_cmd("systemctl --user restart xdg-desktop-portal.service")
   ```

Applications should now correctly detect dark mode via the portal's Settings interface.

### Key Settings

**Rendering:**
```lua
hl.config({
    misc   = { render_unfocused_fps = 120 }, -- Keep unfocused windows rendering
    render = { direct_scanout = 0 },         -- Disabled - can cause issues with NVIDIA
})
```

**Gaming window rules** (one rule per class: `steam_app_.*`, `Battle.net.exe`, `Wow.exe`, ...):
```lua
hl.window_rule({ match = { class = "steam_app_.*" }, immediate = true })
```

The `immediate` rule enables tearing for better frame pacing in games.

### Game resolution / fullscreen issues

If a game can't select 4K or ignores the monitor resolution after going fullscreen, the cause is Hyprland tiling the game window — the tiled size caps what the game sees as available resolution, and the swapchain thrashes between the tiled dimensions and the requested fullscreen size.

**Fix:** add per-game window rules to float the window and pin it to the gaming monitor:
```lua
hl.window_rule({
    name  = "my-game",
    match = { class = "steam_app_<APPID>" },
    monitor = "DP-6", float = true,
})
```

Replace `DP-6` with your gaming monitor name (`hyprctl monitors` to check) and `<APPID>` with the Steam App ID (visible in the store URL).

If the game uses exclusive fullscreen and still misbehaves, also add `fullscreen = true` to the rule.

**XWayland primary monitor:** The autostart includes `xrandr --output DP-6 --primary` so XWayland games default to the 4K monitor. If you change which monitor is primary, update this line.

Active per-game rules: Star Citizen (`starcitizen.exe`), Stellaris (`steam_app_281990`).

## Gaming with Proton/Wine

Game-specific recipes:
- [Star Citizen](games/star-citizen.md) — required setup for SC 4.7+ on NVIDIA 595 + Hyprland Wayland multi-monitor
- [WoW: Forever](games/wow-forever.md) — Error #109 / Xid 109 GPU hang on world entry, build 1.60.1.69913

### Installing Steam + Battle.net

Script: `~/.local/bin/battlenet-install`

```bash
battlenet-install           # install whatever is missing
battlenet-install --force   # re-run the Battle.net installer
```

The `battlenet` launcher does not use the Steam client, but it does depend on a
Steam *installation* — it finds the library root, the Proton build and the Wine
prefix by reading Steam's on-disk layout. `battlenet-install` produces that
layout without requiring a Steam login:

1. Installs the `steam` package (also declared in `.chezmoidata/packages.yaml`,
   so a desktop `./install.sh` already brings it in)
2. Creates `~/.local/share/Steam` with a minimal `config/libraryfolders.vdf`,
   plus the usual `~/.steam/root` and `~/.steam/steam` symlinks, if Steam has
   never been started
3. Installs the latest GE-Proton into `compatibilitytools.d` (checksum
   verified) — but only if no Proton is present already
4. Downloads `Battle.net-Setup.exe` and runs it under Proton in a prefix at
   `steamapps/compatdata/2147483651`

Steps 1–3 are unattended. Step 4 is not: the Blizzard installer is a GUI wizard
and the account login needs 2FA, so click through it when it appears.

**Prefix app ID:** `2147483651` is arbitrary and fixed by the script. Steam
assigns non-Steam shortcuts IDs above 2^31, so it cannot collide with a real
app. If you *also* add Battle.net to Steam as a non-Steam game, there will be
two prefixes and the launcher picks whichever it scans first — pick one.

**Steam Linux Runtime:** `SteamLinuxRuntime_sniper` is a Steam depot and needs a
logged-in client to download, so this path does not get it. The launcher
detects that and runs Proton directly instead of inside the pressure-vessel
container; `battlenet --debug` prints which one is in use. If you later log into
Steam and the runtime appears, the launcher starts using it with no changes.

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

**Fix:** The `battlenet` script sets `Version`=`win11` under the bare
`[Software\\Wine]` key in the prefix, via `reg.exe` through Proton. It runs on
every launch and skips if already set.

**Two traps this originally fell into** (the patch silently did nothing for
months — check with the commands below before trusting it):

1. *The guard was too broad.* It grepped the whole of `user.reg` for
   `"Version"="win11"`. GE-Proton ships `Software\Wine\AppDefaults\*` entries
   for unrelated games, at least one of which is already `win11`, so the grep
   matched and the patch returned early every time.
2. *The target key does not exist.* A fresh prefix has
   `Software\Wine\AppDefaults\...` subkeys but no bare `[Software\\Wine]` key,
   so an in-place `sed` substitution had nothing to match. `reg.exe` creates it.

**Verify it actually applied** — scope the check to the key, and note that
`awk -v` eats the doubled backslashes in `user.reg` key paths, so pass them
through the environment instead:

```bash
UR=~/.local/share/Steam/steamapps/compatdata/<appid>/pfx/user.reg
RK='[Software\\Wine]' RN='"Version"="win11"' awk '
    index($0,"[")==1 { inkey = (index($0,ENVIRON["RK"])==1) }
    inkey && $0==ENVIRON["RN"] { ok=1 }
    END { exit(ok?0:1) }' "$UR" && echo "win11 set" || echo "NOT set"
```

#### Battle.net login form renders black / "can't see content"

**Symptoms:** The launcher opens and the login form is laid out, but the
embedded Chromium (CEF) surface is solid black — no text, no fields visible.

**Cause:** The client offers its embedded browser the renderers
`d3d11,warp,desktop` (see `Supplying list of renderers` in the client log) and
picks the hardware one first. Under Proton that surface comes up black. The page
itself is fine — it loads with `statusCode=200`; you just cannot see it.

**Fix:** Force software rendering in the client config:

```json
"Client": { "HardwareAcceleration": "false" }
```

in `<prefix>/pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config`.
The `battlenet` launcher now asserts this before every launch (`jq`), because
the client rewrites that file when it exits. Confirmed on AMD Radeon 780M
(RADV) under Hyprland.

> The first launch after `battlenet-install` comes from the installer wizard,
> not from `battlenet`, so that one window can still be black. Close it and run
> `battlenet`.

**If the surface is blank rather than black, check the network instead.** CEF
logs to the prefix, and an empty panel is often a page that never loaded:

```bash
LOGS=~/.local/share/Steam/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/AppData/Local/Battle.net/Logs
grep -c 10051 "$(ls -t "$LOGS"/libcef-*.log | head -1)"      # 10051 = WSAENETUNREACH
grep -E "UAuth: (begin loading|finished loading)" "$(ls -t "$LOGS"/battle.net-*.log | head -1)"
```

A healthy run ends with `UAuth: finished loading. statusCode=200 state=Login`.
A broken one shows repeated `connect failed: 10051` in the CEF log and
`UAuth: tassadar Login URL is empty!` in the client log.

Two log lines are **benign** and appear in working runs — don't chase them:
`WSALookupServiceBegin failed with: 0` (Wine has no network-change notifier),
and a single early `missing tassadar url` that is immediately followed by
`UAuth: setting url: https://account.battle.net/... reason: reset`.

Note the client log timestamps are UTC while `stat` and the shell are local
time; a run can look hours adrift when it is not.

To see what the prefix is actually doing on the wire, trace winsock rather than
guessing — `connect failed, status 0xc00000a3` is `WSAEWOULDBLOCK` on a
non-blocking socket and is normal, not an error:

```bash
WINEDEBUG=+winsock <proton>/proton run "<prefix>/.../Battle.net.exe" 2>&1 | tee /tmp/winsock.log
grep -oE 'address [0-9.]+, port [0-9]+' /tmp/winsock.log | sort | uniq -c
```

**Dead end — do not repeat:** a burst of `connect failed: 10051` in the CEF log
on the *very first* launch right after install, with empty caches, does not
recur and is not worth chasing — later launches connect cleanly with no change
made. It is also not the black-screen cause: the page loads fine while the
surface is black.

**Dead end — do not repeat:** WPAD. If the LAN search domain resolves `wpad`
(`getent hosts wpad` returns an address) to a host that does not serve
`wpad.dat`, proxy autodiscovery looks like an excellent explanation for every
CEF connect failing at once. It is not: setting
`"AutoDetect"=dword:00000000` under
`HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings` does
**not** stop the `wpad` lookups (verified by count in a winsock trace before and
after), and the lookups are present in healthy runs too.

#### Game freezes when switching workspaces

**Symptoms:** Game freezes permanently when switching to another workspace, never recovers even when switching back.

**Cause:** The `VK_KHR_present_wait` Vulkan extension can cause deadlocks when a D3D12 game loses focus. The game waits for a present that never completes.

**Fix:** Set `VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait` before launching. This is already configured in the `battlenet` script.

**References:**
- https://github.com/doitsujin/dxvk/issues/4510
- https://github.com/HansKristian-Work/vkd3d-proton/issues/1813

#### WoW freezes at 100% on the load screen, then "Error #109"

WoW: Forever / Classic Beta (`_classic_beta_`, `WowB.exe`) build 1.60.1.69913 has
a game-side compute shader that never terminates, hanging the GPU on world
entry. Not a dotfiles or driver problem. Full recipe and workarounds:
[WoW: Forever](games/wow-forever.md).

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

Set in `hyprland.lua.tmpl`:
```lua
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "egl")
```

### Chrome GPU process crashes during video playback ("freaks out" on videos)

**Symptoms:** Chrome doesn't hard-crash, but playing video makes it glitch/flicker, tabs flash black, and playback freezes then recovers. Crash dumps accumulate in `~/.config/google-chrome/Crash Reports/` with the GPU process dying inside `VaapiVideoDecoder`.

**Cause:** Chrome's hardware video decode goes through `libva-nvidia-driver` (the NVDEC VA-API shim). Its newer `direct` backend (`NVD_BACKEND=direct`) is fast but crashes Chromium's GPU process on certain streams. When the GPU process dies, Chrome restarts it — hence the "freak out."

**Diagnose:**
```bash
ls -t ~/.config/google-chrome/Crash\ Reports/completed/*.dmp | head
strings <newest>.dmp | grep -iE "gpu-process|VaapiVideoDecoder"   # confirms GPU-process VA-API crash
```

**Don't** just disable HW decode (`chrome://flags` → "Hardware-accelerated video decode" → Disabled): it stops the crashes but forces CPU software decode, which lags badly at 4K/high-refresh.

**Fix:** Switch the NVDEC VA-API driver to its `egl` backend (slower than `direct` but stable in Chrome): set `hl.env("NVD_BACKEND", "egl")` in `hyprland.lua.tmpl`, `./install.sh`, then re-login. Keep Chrome's HW decode **enabled**. Verify the backend with `vainfo` (should read `[egl backend]`).

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

**Fix:** Hide the AMD Vulkan ICD so only the dGPU is visible. Set in the NVIDIA env block of `hyprland.lua.tmpl`:
```lua
hl.env("VK_LOADER_DRIVERS_DISABLE", "*radeon*")
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

## Dictation (hyprwhspr)

[hyprwhspr](https://github.com/goodroot/hyprwhspr) (AUR) does local Whisper speech-to-text. Hold **Alt+A** (or F13, the DOIO macropad's right-dial down key), speak, release: the text is pasted into the focused window and Enter is pressed. **Alt+Z** (or F14) sends the transcription to today's voice chat with the `pa` agent in `tx rc` instead (`~/.local/bin/voice-pa`).

- **One-time setup:** `hyprwhspr setup` picks the backend/model and installs the `hyprwhspr.service` user unit. Hyprland starts it on `hyprland.start`.
- **Config:** `.chezmoidata/hyprwhspr.yaml` keys are merged into `~/.config/hyprwhspr/config.json` (`use_hypr_bindings`, `auto_submit`); everything else is left as setup wrote it.
- **Release binds need the modifier still held.** The `{ release = true }` bind on Alt+A only fires if Alt is down when A comes up — release A first, or recording keeps running (`hyprwhspr record stop` ends it). Devices that release modifier and key in one report (the DOIO pad) need modifier-less keys.

## Package Management (paru)

### System upgrades during install

`./install.sh` does **not** upgrade the system. It installs packages declared in
`.chezmoidata/packages.yaml` that are missing, and leaves everything else alone.
Opt in explicitly when you do want the upgrade:

```bash
./install.sh --update           # or: DOTFILES_UPDATE=1 ./install.sh
./install.sh --no-update        # explicit form of the default
```

The flag is exported as `DOTFILES_UPDATE` and read by
`.chezmoiscripts/run_onchange_after_install-arch-packages.sh`, which inherits
install.sh's environment. It only matters on runs where that script actually
executes — `run_onchange_` scripts run when their contents change, so an apply
that changes nothing never upgrades either way.

**The one caveat:** Arch does not support partial upgrades. Installing against a
stale sync DB can pull a package built against newer libraries than the ones on
disk. If an install fails with a missing target or a library mismatch, re-run
with `--update` (or `sudo pacman -Syu` separately) and try again.


### `paru -Syu` fails: "breaks dependency ... required by lib32-*"

**Symptom:**
```
error: failed to prepare transaction (could not satisfy dependencies)
:: installing audit (4.2.1-1.1) breaks dependency 'audit=4.1.4' required by lib32-audit
```

**Cause:** Some AUR packages pin an exact repo version — `lib32-audit` declares
`depends=(audit=$pkgver)`. paru always runs the repo `pacman -Syu` as its own
transaction before building AUR packages, so the repo upgrade is evaluated while the
installed AUR package still requires the old version. `paru -Qua` shows the matching AUR
update exists; paru just never gets to it.

**`CombinedUpgrade` does NOT fix this** (verified). It gives one combined menu and one
sudo prompt, but paru still downloads the PKGBUILDs and *then* runs the repo transaction
separately — which fails at the same point. There is no paru.conf setting that resolves
this; it needs a manual combined transaction.

**Fix** — build the AUR package, then hand it to pacman together with its repo
dependency so both versions land at once. Using `lib32-audit`/`audit` as the example:

```bash
# 1. Build the AUR package without installing it (the version pin is a RUNTIME
#    dep, so --nodeps is safe here — check the PKGBUILD if unsure).
cp -r ~/.cache/paru/clone/lib32-audit /tmp/ && cd /tmp/lib32-audit
makepkg -s --nodeps

# 2. Download the repo package (--nodeps, or the download itself trips the same
#    dependency resolution).
sudo pacman -Sw --nodeps audit

# 3. Install BOTH in one -U transaction. This is the step that works: pacman sees
#    audit 4.2.1 and lib32-audit 4.2.1 together, so the pin is satisfied.
sudo pacman -U /var/cache/pacman/pkg/audit-4.2.1-*.pkg.tar.zst \
               /tmp/lib32-audit/lib32-audit-4.2.1-*.pkg.tar.zst

# 4. Now the normal upgrade proceeds.
paru -Syu
```

Note `pacman -S` does not accept file paths — step 3 must be `-U`, and it cannot be
merged with `-Syu`. Before running it, confirm nothing *else* pins the same package:

```bash
for p in $(pactree -rl audit | tail -n +2 | sort -u); do
  pacman -Qi "$p" | grep -oP 'audit[=><][^ ]*' | sed "s|^|$p -> |"
done
```

If only the `lib32-` package appears, upgrading the repo package on its own is safe.

### `local (X) is newer than extra (X)` warnings

Harmless on CachyOS. The CachyOS repos ship their own builds with a bumped pkgrel
(e.g. `pipewire 1:1.6.8-1.2` vs Arch's `1:1.6.8-1`), so the Arch version legitimately
looks older. Not related to upgrade failures.

## Adding New Fixes

When discovering new desktop/gaming fixes:

1. Add environment variables to the appropriate launch script (e.g., `battlenet`)
2. Document the issue, cause, and fix in this file
3. Include references to upstream issues/documentation
