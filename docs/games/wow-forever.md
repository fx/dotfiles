# WoW: Forever (Classic Beta) — Error #109 GPU hang on world entry

Affects `_classic_beta_` (`WowB.exe`, product `wow_classic_beta`), build
**1.60.1.69913**, shipped 2026-09-18. Not the retail client, not `_beta_`.

## Symptoms

Battle.net starts, WoW starts, character select works. Logging a character in
freezes at the very end of the load screen and the client dies ~20s later:

```
ERROR #109 (0x8510006d) A thread has become unresponsive.
Freeze Detected: thread N has been frozen for 20 seconds
```

`_classic_beta_/Logs/gx.log`:

```
Failure in WaitForFence
Device Removed Reason: GPU Hung. Timeout when waiting for queue: Graphics (0x80070102)
Device context was lost. Attempting recovery. Occurrence: 1
```

Kernel log, same timestamps:

```
NVRM: Xid (PCI:0000:01:00): 109, pid=..., name=WowB.exe, channel 0x1c,
      errorString CTX SWITCH TIMEOUT, Info 0x2c01f
```

## Diagnosing

The client's own `Error #109` only says a thread stalled. The useful evidence is
in two places:

```bash
journalctl -k -b | grep Xid                              # the GPU fault
ls -t "$HOME/Games/World of Warcraft/_classic_beta_/Errors"/*.txt | head
```

The crash report lists the graphics CVars in effect at the time
(`<CVar.giQuality>`, `<CVar.graphicsLightMode>`, ...) — check those, not
`Config.wtf`, since WoW rewrites `Config.wtf` on exit.

Note `Errors/` also fills with `ERROR #135` / `VoiceSpeakManager.cpp` assertion
reports. Those are unrelated noise; grep for `ERROR #109`.

## Cause

Game bug, not driver and not Proton. One compute shader in build 69913 — the GI
probe volume update, vkd3d-proton DXIL hash `2d79ed5755446f2f` — has two tree
traversal loops with no iteration bound. Cyclic node data spins it forever, and
a GPU cannot preempt a shader that never ends, so the context-switch watchdog
fires.

Reported across Pascal through Blackwell, D3D11 and D3D12 alike, on every Proton
build. Depending on GPU generation the driver reports it as Xid 109
(CTX SWITCH TIMEOUT), Xid 13 or Xid 8.

Upstream: [ValveSoftware/Proton#10157](https://github.com/ValveSoftware/Proton/issues/10157)

## Workarounds

**Lower the lighting CVars.** How often the shader hits bad data scales with
quality, so this makes the hang rare rather than impossible. Set all four —
reports pin hangs on the `RAID*` variants being left high:

```
SET giQuality "1"
SET RAIDgiQuality "1"
SET graphicsLightMode "1"
SET raidGraphicsLightMode "1"
```

In game (applies immediately, no restart): `/console RAIDgiQuality 1` etc.
The Quality preset slider silently resets `giQuality` to 3 — re-check after
touching it.

Only the *first* world entry after a cold client start hangs. Relogging to
character select and back does not reproduce it, which makes testing misleading.

**Patch the shaders (this is what actually works here).** Confirmed on this
machine 2026-09-21: world entry loads reliably with graphics settings back up.

Note this client reports `Using shader family dx_5_0` in `gx.log` — it feeds
vkd3d **DXBC**, not DXIL. The DXIL hash `2d79ed5755446f2f` quoted upstream does
not exist here, and neither does any single culprit hash: capping only the four
shaders carrying the `0x1FFFFFFF` traversal sentinel was **not** enough. What
worked was bounding every loop in every shader the client compiles.

Requires `spirv-tools` and `SET GxApi "D3D12"` (the override is vkd3d-only).

```bash
# 1. dump every shader the client compiles, through a full world entry
rm -f "$HOME/Games/World of Warcraft/_classic_beta_/vkd3d-proton.cache"
VKD3D_SHADER_DUMP_PATH=/tmp/wowdump battlenet     # then log a character in

# 2. add a 4096-iteration cap to every loop
vkd3d-cap-shader-loops /tmp/wowdump \
    "$HOME/.local/share/vkd3d-shader-override/wow-forever"

# 3. the battlenet launcher exports VKD3D_SHADER_OVERRIDE automatically
#    whenever that directory exists
```

Three things that will bite you:

- **The cache hides everything.** WoW writes `_classic_beta_/vkd3d-proton.cache`;
  with it present, nothing recompiles, so neither dumping nor the override does
  anything. Delete it *after* WoW has fully exited — it gets rewritten on
  shutdown, so deleting it while the process is still dying accomplishes nothing.
- **Character select compiles almost nothing.** You have to actually enter the
  world to see the shaders that matter.
- **The override is silent.** vkd3d logs nothing at `VKD3D_DEBUG=warn` when it
  substitutes a module. To verify it fired, dump and override at the same time:
  shaders that were overridden do not appear in the dump directory.

The override set is keyed by shader hash, so it is inert for other games and for
any shader it was not built from — but that also means a client patch or a
graphics-setting change can introduce an uncapped shader and bring the hang
back. Re-run the dump and the capper if it returns. The generated `.spv` files
are game data and deliberately live outside this repo.

## What does not help

Driver version (610.57.04 and 615.71.09 both affected), D3D11 vs D3D12, Proton
version, clearing DXVK/vkd3d/NVIDIA shader caches, locking the GPU memory clock,
disabling Reflex, `__NV_DISABLE_EXPLICIT_SYNC=1`, X11 vs Wayland.
