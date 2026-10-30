# Quickshell Dynamic Notch


A portable copy of the Quickshell notch for Hyprland. It includes the workspace switcher, clock, media controls, album-colour fade, lyrics view, and the optional focus, airplane-mode, and privacy indicators.


## Requirements


- Hyprland
- Quickshell 0.3 or newer
- Git


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


Run it now:


```sh
qs -c island
```


The installer copies `shell.qml` to `~/.config/quickshell/island/shell.qml`. If that file already exists, it saves a timestamped backup before replacing it.


## Start automatically with Hyprland


Add the matching startup entry once.


### Lua config (`~/.config/hypr/hyprland.lua`)


```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs --no-duplicate --config island")
end)
```


If your file already has an `hl.on("hyprland.start", ...)` block, add the `hl.exec_cmd(...)` line inside that block instead of creating a second one.


### Older hyprlang config (`~/.config/hypr/hyprland.conf`)


```ini
exec-once = qs --no-duplicate --config island
