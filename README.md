# Quickshell Dynamic Notch

A portable Quickshell notch for Hyprland with a workspace switcher, four animated music bars, MPRIS controls, album-colour fade, lyrics, and optional focus, airplane-mode, and privacy indicators. The bars use the album accent and animate during playback.

The included `island-start` checker runs in the logged-in Hyprland session. It watches both the Quickshell process and the `island` layer, and restarts the notch if it exits or its layer stays missing. It allows the notch to hide normally while a window is fullscreen.

## Requirements

- Hyprland
- Quickshell 0.3 or newer
- Git
- `jq` (used by the session checker)

Quickshell's install method depends on your Linux distribution. Use the [official Quickshell installation guide](https://quickshell.org/docs/v0.3.0/guide/install-setup/) first.

Optional integrations:

- PipeWire running in your session for camera and microphone indicators.
- `curl` for lyric lookup through LRCLIB.
- NetworkManager (`nmcli`) and BlueZ (`bluetoothctl`) for airplane-mode detection.
- `wf-recorder` plus the MacShell recorder PID file for the recording indicator.
- MacShell's `~/.config/macbar/settings.json` for its Focus mode indicator.
- A media app that exports MPRIS controls for the media player.

Missing optional tools only disable their related indicators or features.

## Install

```sh
git clone https://github.com/AdrGit-zen/quickshell-dynamic-notch.git
cd quickshell-dynamic-notch
bash install.sh
```

The installer copies `shell.qml` to `~/.config/quickshell/island/shell.qml` and installs `scripts/island-start` to `~/.local/bin/island-start`. Existing files are saved as timestamped backups before replacement.

Start the notch and checker now with:

```sh
sh ~/.local/bin/island-start
```

## Start automatically with Hyprland

Add the matching startup entry once.

### Lua config (`~/.config/hypr/hyprland.lua`)

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("sh " .. os.getenv("HOME") .. "/.local/bin/island-start")
end)
```

If your file already has an `hl.on("hyprland.start", ...)` block, add the `hl.exec_cmd(...)` line inside that block instead of creating a second one.

### Older hyprlang config (`~/.config/hypr/hyprland.conf`)

```ini
exec-once = sh ~/.local/bin/island-start
```

This starts the checker with Hyprland. It checks the Island layer every few seconds and restores Quickshell if the layer is missing after startup. The watcher exits when the Wayland session ends.

## Update

From the cloned folder:

```sh
git pull
bash install.sh
```

After changing `shell.qml`, restart the running Island once so Quickshell loads the updated file. The checker will keep watching it afterward.

## Remove

Remove the startup entry from your Hyprland config, stop the `island-start` watcher and Island Quickshell process, then remove:

```sh
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/island"
rm -f "$HOME/.local/bin/island-start"
```

## Notes

- The notch is a separate Quickshell config named `island`, so it can live alongside other Quickshell shells.
- The workspace spacer and music-bar spacer are matching slim dividers; the notch remains compact when collapsed.
- The checker needs `hyprctl` from Hyprland, `jq`, and an active Wayland session.
- The screen-recording dot is tied to MacShell's recorder PID file; installing `wf-recorder` by itself does not create that integration.
- Quickshell configuration paths and `qs -c <name>` usage are documented in the [Quickshell distribution guide](https://quickshell.org/docs/v0.3.0/guide/distribution/).
