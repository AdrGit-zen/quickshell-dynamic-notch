# Quickshell Dynamic Notch

A portable Quickshell notch for Hyprland with a workspace switcher, four animated music bars, MPRIS controls, album-colour fade, lyrics, and optional focus, airplane-mode, and privacy indicators. The bars use the album accent and animate during playback.

The Island checker is supervised by a systemd user service. It watches both the Quickshell process and its Hyprland layer, waits through periods with no active monitor, and restores the notch when needed. The hourly timer restarts the supervised checker instead of launching a detached Quickshell process from a short-lived service.

## Requirements

- Hyprland
- Quickshell 0.3 or newer
- jq
- systemd user services

Quickshell's install method depends on your Linux distribution. Use the [official Quickshell installation guide](https://quickshell.org/docs/v0.3.0/guide/install-setup/) first.

Optional integrations:

- PipeWire running in your session for camera and microphone indicators.
- curl for lyric lookup through LRCLIB.
- NetworkManager (nmcli) and BlueZ (bluetoothctl) for airplane-mode detection.
- wf-recorder plus the MacShell recorder PID file for the recording indicator.
- MacShell's ~/.config/macbar/settings.json for its Focus mode indicator.
- A media app that exports MPRIS controls for the media player.

Missing optional tools only disable their related indicators or features.

## Install

~~~sh
git clone https://github.com/AdrGit-zen/quickshell-dynamic-notch.git
cd quickshell-dynamic-notch
bash install.sh
~~~

The installer copies shell.qml, the checker scripts, and the systemd user units. Existing files are saved as timestamped backups.

## Start now

From a terminal inside the Hyprland session:

~~~sh
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORM
systemctl --user restart island-checker.service
~~~

## Start automatically with Hyprland

Add this to the existing hl.on("hyprland.start", ...) block in ~/.config/hypr/hyprland.lua:

~~~lua
hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORM && systemctl --user restart island-checker.service")
~~~

If you use the older ~/.config/hypr/hyprland.conf format, add:

~~~ini
exec-once = systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORM && systemctl --user restart island-checker.service
~~~

The checker stays active while the monitor list is empty, then resumes layer checks when an output returns. The hourly timer restarts the checker service, which owns and supervises the Quickshell process.

## Update

From the cloned folder:

~~~sh
git pull
bash install.sh
systemctl --user restart island-checker.service
~~~

## Remove

Stop the services and remove the startup entry from Hyprland, then remove:

~~~sh
systemctl --user stop island-checker.service
systemctl --user disable --now island-hourly-reset.timer
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/island"
rm -f "$HOME/.local/bin/island-start" "$HOME/.local/bin/island-hourly-reset"
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/island-checker.service"
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/island-hourly-reset.service"
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/island-hourly-reset.timer"
systemctl --user daemon-reload
~~~

## Notes

- The notch is a separate Quickshell config named island, so it can live alongside other Quickshell shells.
- The workspace spacer and music-bar spacer are matching slim dividers; the notch remains compact when collapsed.
- The checker needs hyprctl, jq, and an active Hyprland Wayland session.
- The screen-recording dot is tied to MacShell's recorder PID file; installing wf-recorder by itself does not create that integration.
- Quickshell configuration paths and qs -c <name> usage are documented in the [Quickshell distribution guide](https://quickshell.org/docs/v0.3.0/guide/distribution/).
