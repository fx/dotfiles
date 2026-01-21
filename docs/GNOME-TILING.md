# GNOME Tiling Extensions Experiment

**Note:** GNOME is NOT installed by default. See "Installation" section below.

This document records our experiment with GNOME tiling window managers as an alternative to Hyprland.

## Installation

GNOME is optional and not installed by default. To install:

```bash
# Install GNOME
sudo pacman -S gnome-shell gnome-control-center gnome-tweaks

# Run dotfiles to apply configs
./install.sh
```

The dotfiles will automatically install `dot_config/dconf/` configs and run the GNOME configure script.

## Extensions Tested

### PaperWM

**Package:** `gnome-shell-extension-paperwm-git` (AUR)

**Pros:**
- Horizontal scrolling window layout
- Good keyboard navigation

**Cons:**
- No automatic vertical splitting (unlike Hyprland's dwindle layout)
- Windows default to full width - requires manual `winprops` config for 50% width
- Keybindings conflict with Pop Shell even when disabled

**Configuration:**
```ini
[org/gnome/shell/extensions/paperwm]
winprops=['{ "wm_class": "*", "preferredWidth": "50%" }']

[org/gnome/shell/extensions/paperwm/keybindings]
switch-left=['<Alt>Left']
switch-right=['<Alt>Right']
move-left=['<Shift><Alt>Left']
move-right=['<Shift><Alt>Right']
# etc.
```

### Pop Shell

**Package:** `gnome-shell-extension-pop-shell-git` (AUR)

**Pros:**
- Auto-tiling similar to i3/Hyprland
- Good window management

**Cons:**
- `tile-by-default` gsettings doesn't actually enable tiling programmatically (bug)
- Requires clicking the tiling toggle in the panel to enable
- **Keyboard window movement requires "adjustment mode"** - you must press a key (e.g., Alt+r) to enter adjustment mode, THEN use arrow keys to move windows, THEN press Escape to exit. This is fundamentally different from Hyprland where Shift+Alt+Arrow directly moves windows.
- 4K monitor issues - windows initially tile in upper-left quarter (fixed by GNOME restart)

**Configuration:**
```ini
[org/gnome/shell/extensions/pop-shell]
tile-by-default=true
toggle-tiling=['<Alt>t']
toggle-floating=['<Alt>v']
tile-enter=['<Alt>r']  # Enter adjustment mode
focus-left=['<Alt>Left']
focus-right=['<Alt>Right']
focus-up=['<Alt>Up']
focus-down=['<Alt>Down']
tile-resize-left=['<Control><Alt>Left']
tile-resize-right=['<Control><Alt>Right']
tile-resize-up=['<Control><Alt>Up']
tile-resize-down=['<Control><Alt>Down']
```

## GNOME Keybindings (Mirroring Hyprland)

We configured GNOME to use Alt as the main modifier (like Hyprland):

```ini
[org/gnome/desktop/wm/preferences]
mouse-button-modifier='<Alt>'
resize-with-right-button=true

[org/gnome/desktop/wm/keybindings]
close=['<Alt>q']
toggle-fullscreen=['<Alt>f']
switch-to-workspace-1=['<Alt>1']
# ... workspaces 2-10
move-to-workspace-1=['<Shift><Alt>1']
# ... move-to-workspace 2-10
move-to-monitor-left=['<Alt>comma']
move-to-monitor-right=['<Alt>period']

[org/gnome/shell/keybindings]
toggle-overview=['<Alt>d']

[org/gnome/settings-daemon/plugins/media-keys]
screensaver=['<Alt>l']

# Custom keybindings for apps
[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Alt>Return'
command='ghostty'
name='Terminal'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Alt>e'
command='nautilus'
name='File Manager'
```

## Files

- `dot_config/dconf/gnome.ini.tmpl` - GNOME dconf settings
- `.chezmoiscripts/run_onchange_after_configure-gnome.sh.tmpl` - Applies dconf settings

## Pitfalls Encountered

1. **Pop Shell adjustment mode**: Unlike Hyprland, you cannot directly move windows with keyboard shortcuts. You must enter "adjustment mode" first (Alt+r), then move, then exit (Escape).

2. **Extension conflicts**: Having both PaperWM and Pop Shell installed can cause keybinding conflicts even when one is disabled. Best to only install the one you're using.

3. **4K scaling issues**: Pop Shell may initially tile windows in the wrong position on 4K monitors. Restarting GNOME fixes this.

## Tiling Extensions (Optional)

To add tiling extensions:

1. Install the extension:
   ```bash
   # Pop Shell (recommended)
   yay -S gnome-shell-extension-pop-shell-git
   # OR PaperWM
   yay -S gnome-shell-extension-paperwm-git
   ```

2. Log out and back in to GNOME

3. Enable the extension in GNOME Extensions app

4. For Pop Shell: Click the tiling icon in the top panel to enable tiling

## Conclusion

Neither PaperWM nor Pop Shell provides the same seamless tiling experience as Hyprland. The main blocker is Pop Shell's adjustment mode requirement for keyboard window movement.
