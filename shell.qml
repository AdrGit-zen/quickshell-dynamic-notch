// Notch-style island for Hyprland (Quickshell 0.3+).
//   - flush with the top edge: flat top, rounded bottom (like a MacBook notch)
//   - workspaces 1-4 (click to switch) and animated music bars
//   - hides itself while an app is fullscreen (F11, videos, games)
//   - hover to expand: date + media player for ANY MPRIS app
//     (SimpMusic, Rambox, Spotify, VLC, mpv, Firefox, Chrome, ...)
// File: ~/.config/quickshell/island/shell.qml    Run: qs -c island
//
// Only the notch itself receives mouse input (see `mask`), so this window never
// blocks the bar underneath. Works with hyprlang and Lua (0.55+) Hyprland configs.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // MacShell saves Focus mode in this settings file; watch it so the notch follows live toggles.
    FileView {
        id: macSettings
        path: Quickshell.env("HOME") + "/.config/macbar/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    // Bind PipeWire nodes and links to read media classes and active link states.
    PwObjectTracker {
        objects: Pipewire.nodes.values.concat(Pipewire.linkGroups.values)
    }

    // Hyprland doesn't always announce when a workspace gains or loses a fullscreen
    // window, so ask for fresh workspace info whenever that could have changed.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "fullscreen" || n === "workspacev2" || n === "closewindow" || n === "movewindowv2")
                Hyprland.refreshWorkspaces();
        }
    }

    // ---------- building blocks ----------

    // Icons are drawn in code, so nothing depends on installed fonts.
    component Glyph: Canvas {
        id: g

        property string kind: "play"
        property color tint: "white"
        property real size: 18

        width: size
        height: size
        onKindChanged: requestPaint()
        onTintChanged: requestPaint()
        onSizeChanged: requestPaint()

        // Filled polygon with rounded corners from a flat [x, y, x, y, ...] list.
        function poly(ctx, pts) {
            ctx.beginPath();
            ctx.moveTo(pts[0], pts[1]);
            for (let i = 2; i < pts.length; i += 2)
                ctx.lineTo(pts[i], pts[i + 1]);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            ctx.scale(width / 24, height / 24);
            ctx.fillStyle = tint;
            ctx.strokeStyle = tint;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (kind === "play") {
                poly(ctx, [8, 5.5, 8, 18.5, 18.5, 12]);
            } else if (kind === "pause") {
                ctx.fillRect(6.5, 5, 3.8, 14);
                ctx.fillRect(13.7, 5, 3.8, 14);
            } else if (kind === "prev") {
                ctx.fillRect(4.5, 5.5, 2.4, 13);
                poly(ctx, [19.5, 6, 19.5, 18, 9.5, 12]);
            } else if (kind === "next") {
                ctx.fillRect(17.1, 5.5, 2.4, 13);
                poly(ctx, [4.5, 6, 4.5, 18, 14.5, 12]);
            } else if (kind === "back" || kind === "fwd") {
                // Circular arrow; "fwd" is the mirror image of "back".
                if (kind === "fwd") {
                    ctx.translate(24, 0);
                    ctx.scale(-1, 1);
                }
                ctx.beginPath();
                ctx.arc(12, 13.5, 7.5, Math.PI, -Math.PI / 2, true);
                ctx.stroke();
                poly(ctx, [12, 2, 6.5, 6, 12, 10]);
            } else if (kind === "repeat" || kind === "repeat1") {
                ctx.beginPath();
                ctx.moveTo(4.5, 12.5);
                ctx.lineTo(4.5, 8.5);
                ctx.arcTo(4.5, 6, 7, 6, 2.5);
                ctx.lineTo(15.5, 6);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(19.5, 11.5);
                ctx.lineTo(19.5, 15.5);
                ctx.arcTo(19.5, 18, 17, 18, 2.5);
                ctx.lineTo(8.5, 18);
                ctx.stroke();
                poly(ctx, [16, 2.8, 21, 6, 16, 9.2]);
                poly(ctx, [8, 14.8, 3, 18, 8, 21.2]);
                if (kind === "repeat1") {
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    ctx.moveTo(10.5, 10.6);
                    ctx.lineTo(12.2, 9.2);
                    ctx.lineTo(12.2, 14.8);
                    ctx.stroke();
                }
            } else if (kind === "note") {
                ctx.beginPath();
                ctx.arc(8, 17.5, 3.2, 0, 2 * Math.PI, false);
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(11, 17.5);
                ctx.lineTo(11, 5);
                ctx.bezierCurveTo(13, 7.5, 17.5, 7, 17.5, 11.5);
                ctx.stroke();
            } else if (kind === "moon") {
                ctx.beginPath();
                ctx.arc(12, 12, 9.1, 0, 2 * Math.PI, false);
                ctx.fill();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(16.3, 8.5, 7.5, 0, 2 * Math.PI, false);
                ctx.fill();
                ctx.globalCompositeOperation = "source-over";
            } else if (kind === "airplane") {
                ctx.beginPath();
                ctx.moveTo(12, 2.4);
                ctx.lineTo(12, 21.6);
                ctx.stroke();
                poly(ctx, [2.7, 14, 12, 9.3, 21.3, 14]);
                poly(ctx, [8, 20.7, 12, 18, 16, 20.7]);
            } else if (kind === "lyrics") {
                ctx.beginPath();
                ctx.moveTo(7, 3.5);
                ctx.lineTo(16, 3.5);
                ctx.lineTo(20, 7.5);
                ctx.lineTo(20, 20.5);
                ctx.lineTo(4, 20.5);
                ctx.lineTo(4, 3.5);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(16, 3.8);
                ctx.lineTo(16, 7.8);
                ctx.lineTo(19.7, 7.8);
                ctx.moveTo(7.5, 11);
                ctx.lineTo(16.5, 11);
                ctx.moveTo(7.5, 14.5);
                ctx.lineTo(16.5, 14.5);
                ctx.moveTo(7.5, 18);
                ctx.lineTo(14, 18);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // Round button used by the media controls.
    component CtlButton: Rectangle {
        id: rb

        property string icon: "play"
        property string badge: ""          // small number drawn inside the icon
        property bool highlighted: false   // e.g. loop is on
        property bool primary: false       // the big white play / pause button
        property bool usable: true         // false: faded out, ignores clicks
        property bool dim: false           // slightly faded but still clickable
        property real iconSize: primary ? 22 : 18
        signal activated()

        anchors.verticalCenter: parent.verticalCenter
        width: primary ? 46 : 34
        height: width
        radius: width / 2
        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.06 : 1)
        opacity: !usable ? 0.3 : (dim ? 0.55 : 1)
        color: primary
               ? (area.pressed ? "#c8c8c8" : (area.containsMouse ? "#ebebeb" : "white"))
               : (area.pressed ? "#3a3a3c" : (area.containsMouse ? "#2c2c2e" : "transparent"))

        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Glyph {
            anchors.centerIn: parent
            kind: rb.icon
            size: rb.iconSize
            tint: rb.primary ? "black" : (rb.highlighted ? "#4da3ff" : "white")
        }

        Text {
            visible: rb.badge !== ""
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: rb.badge
            font.pixelSize: 8
            font.bold: true
            color: rb.highlighted ? "#4da3ff" : "white"
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: rb.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.activated()
        }
    }

    // ---------- the notch ----------

    PanelWindow {
        id: win

        // ---- tweak these ----
        property var workspaceIds: [1, 2, 3, 4]
        property bool hideOnFullscreen: true   // Hide the notch while an app is fullscreen.
        property int barH: 36          // notch height when collapsed
        property int expandedH: 204    // notch height when hovered
        property int lyricsExpandedH: 390
        property int expandedW: 392    // minimum notch width when hovered
        property int skip: 10          // seconds jumped by the back / forward buttons

        readonly property int collapsedW: topRow.implicitWidth + 36
        readonly property int openW: Math.max(expandedW, collapsedW)
        readonly property int contentH: lyricsVisible ? lyricsExpandedH : expandedH
        property bool expanded: false
        readonly property int activeWorkspaceIndex: {
            const active = Hyprland.focusedWorkspace;
            return active ? workspaceIds.indexOf(active.id) : -1;
        }
        readonly property bool focusMode: {
            if (!macSettings.loaded)
                return false;
            try { return JSON.parse(macSettings.text()).dnd === true; }
            catch (e) { return false; }
        }
        property bool airplaneMode: false
        property bool focusIndicatorShown: false
        property bool airplaneIndicatorShown: false
        function syncFocusIndicator() {
            if (focusMode) {
                focusHide.stop();
                focusIndicatorShown = true;
                focusIndicator.opacity = 0;
                focusMoon.scale = 0.42;
                focusPop.restart();
            } else {
                focusPop.stop();
                focusHide.restart();
            }
        }
        onFocusModeChanged: Qt.callLater(syncFocusIndicator)
        function syncAirplaneIndicator() {
            if (airplaneMode) {
                airplaneHide.stop();
                airplaneIndicatorShown = true;
                airplaneIndicator.opacity = 0;
                airplaneGlyph.scale = 0.42;
                airplaneGlyph.flightY = 20;
                airplanePop.restart();
            } else {
                airplanePop.stop();
                airplaneHide.restart();
            }
        }
        onAirplaneModeChanged: Qt.callLater(syncAirplaneIndicator)

        // ---- hide while an app is fullscreen (F11, a video, a game ...) ----
        // Use the window's actual fullscreen state. Hyprland's workspace fullscreen
        // flag also covers the F3 maximized mode, which should leave the notch visible.
        readonly property bool windowFullscreen: {
            const t = ToplevelManager.activeToplevel;
            if (!t || t.fullscreen !== true)
                return false;
            const s = t.screens;    // with several monitors only this one counts
            if (!s || s.length === 0 || !screen)
                return true;
            for (let i = 0; i < s.length; i++) {
                if (s[i].name === screen.name)
                    return true;
            }
            return false;
        }
        readonly property bool hideForFullscreen: hideOnFullscreen && windowFullscreen
        onHideForFullscreenChanged: {
            if (hideForFullscreen) {
                openDelay.stop();
                expanded = false;
            }
        }

        readonly property bool cameraInUse: captureActive("Video/Source", "Stream/Input/Video")
        readonly property bool microphoneInUse: captureActive("Audio/Source", "Stream/Input/Audio")
        property bool screenRecording: false
        readonly property bool privacyActive: cameraInUse || microphoneInUse || screenRecording

        // MacShell writes this PID file while its wf-recorder process is active.
        Process {
            id: recorderStateProbe
            command: ["sh", "-c",
                "p=$(cat \"${XDG_RUNTIME_DIR:-/tmp}/macbar-recorder.pid\" 2>/dev/null); "
                + "if [ -n \"$p\" ] && [ \"$(cat \"/proc/$p/comm\" 2>/dev/null)\" = wf-recorder ]; then echo active; else echo inactive; fi; "
                + "wifi=$(nmcli radio wifi 2>/dev/null); "
                + "bt=$(timeout 2 bluetoothctl show 2>/dev/null | sed -n 's/^[[:space:]]*Powered:[[:space:]]*//p' | head -n1); "
                + "if [ \"$wifi\" != enabled ] && [ \"$bt\" != yes ]; then echo airplane; else echo normal; fi"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var states = text.split("\n");
                    win.screenRecording = (states[0] || "").trim() === "active";
                    win.airplaneMode = (states[1] || "").trim() === "airplane";
                }
            }
        }
        Process {
            id: lyricsFetch
            command: ["curl", "--silent", "--show-error", "--max-time", "12"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const body = text.trim();
                    if (!body) {
                        win.lyricsStatus = "Lyrics unavailable right now";
                        return;
                    }
                    try {
                        const results = JSON.parse(body);
                        if (!Array.isArray(results) || results.length === 0) {
                            win.lyricsStatus = "Lyrics not found";
                            return;
                        }
                        const normalize = value => String(value || "").trim().toLowerCase();
                        const title = normalize(win.player?.trackTitle);
                        const artist = normalize(win.player?.trackArtist);
                        const match = results.find(item => normalize(item.trackName) === title
                                                           && normalize(item.artistName) === artist)
                                   || results.find(item => normalize(item.trackName) === title);
                        if (!match) {
                            win.lyricsStatus = "Lyrics not found";
                            return;
                        }
                        const synced = win.parseSyncedLyrics(match.syncedLyrics || "");
                        const plain = String(match.plainLyrics || "").trim();
                        if (synced.length > 0) {
                            win.lyricsLines = synced;
                            win.lyricsTimed = true;
                            win.lyricsText = "";
                            win.lyricsStatus = "";
                        } else if (plain) {
                            win.lyricsLines = [];
                            win.lyricsTimed = false;
                            win.lyricsText = plain;
                            win.lyricsStatus = "";
                        } else {
                            win.lyricsLines = [];
                            win.lyricsTimed = false;
                            win.lyricsText = "";
                            win.lyricsStatus = match.instrumental ? "Instrumental track" : "Lyrics not found";
                        }
                    } catch (e) {
                        win.lyricsStatus = "Lyrics unavailable right now";
                    }
                }
            }
        }
        Timer {
            interval: 500
            repeat: true
            running: win.hasPlayer
            triggeredOnStart: true
            property string observedTrackKey: ""
            onTriggered: {
                const now = Date.now();
                if (win.player.positionSupported)
                    win.lyricFallbackPosition = win.player.position;
                else if (win.isPlaying)
                    win.lyricFallbackPosition += Math.max(0, (now - win.lyricFallbackTick) / 1000);
                win.lyricFallbackTick = now;

                const key = win.hasPlayer
                    ? win.playerKey + "|" + (win.player.trackTitle || "") + "|" + (win.player.trackArtist || "")
                    : "";
                if (key && key !== observedTrackKey) {
                    observedTrackKey = key;
                    win.lyricFallbackPosition = win.player.positionSupported ? win.player.position : 0;
                    win.lyricFallbackTick = now;
                    if (win.lyricsVisible && key !== win.lyricsRequestKey)
                        win.requestLyrics();
                }
            }
        }
        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: if (!recorderStateProbe.running) recorderStateProbe.running = true
        }

        function captureActive(sourceType, streamType) {
            const links = Pipewire.linkGroups.values;
            for (let i = 0; i < links.length; i++) {
                const link = links[i];
                const sourceClass = link.source?.properties?.["media.class"];
                const targetClass = link.target?.properties?.["media.class"];
                if (link.state === PwLinkState.Active
                        && link.source && link.target
                        && sourceClass === sourceType
                        && targetClass === streamType)
                    return true;
            }
            return false;
        }

        // ---- which media player to show ----
        // Tap the app name in the notch to pick one by hand (kept until that app quits
        // or a different app starts playing). Otherwise: the one that is playing, else
        // the last one shown, else a paused one that has a track loaded, else the first.
        property var pinned: null
        property var pinPlaying: []        // apps that were already playing when the pick was made
        property var lastPlayer: null
        readonly property int playerCount: Mpris.players.values.length
        readonly property var player: {
            const list = Mpris.players.values;
            if (list.length === 0)
                return null;
            if (list.indexOf(pinned) >= 0)
                return pinned;
            for (let i = 0; i < list.length; i++) {
                if (list[i].playbackState === MprisPlaybackState.Playing)
                    return list[i];
            }
            if (list.indexOf(lastPlayer) >= 0)
                return lastPlayer;
            for (let j = 0; j < list.length; j++) {
                if (list[j].playbackState === MprisPlaybackState.Paused && list[j].trackTitle !== "")
                    return list[j];
            }
            return list[0];
        }

        // Remembered a moment later (not inside the binding) to avoid a binding loop.
        function rememberPlayer() {
            lastPlayer = player;
        }
        onPlayerChanged: {
            Qt.callLater(rememberPlayer);
            softLoop = false;
        }

        function playingNow() {
            return Mpris.players.values.filter(p => p.playbackState === MprisPlaybackState.Playing);
        }

        function nextPlayer() {
            const list = Mpris.players.values;
            if (list.length < 2)
                return;
            pinned = list[(list.indexOf(player) + 1) % list.length];
            pinPlaying = playingNow();
        }

        // Runs while a pick is active: drops it when that app quits, or when a
        // different app starts playing, so the notch follows what you are hearing.
        function checkPin() {
            if (pinned === null)
                return;
            if (Mpris.players.values.indexOf(pinned) < 0) {
                pinned = null;
                return;
            }
            const now = playingNow();
            for (let i = 0; i < now.length; i++) {
                if (now[i] !== pinned && pinPlaying.indexOf(now[i]) < 0) {
                    pinned = null;
                    return;
                }
            }
            pinPlaying = now;
        }

        readonly property bool hasPlayer: player !== null
        readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
        readonly property bool canLoop: hasPlayer && player.loopSupported && player.canControl
        readonly property bool canBar: hasPlayer && player.lengthSupported && player.length > 0
        property bool lyricsVisible: false
        property string lyricsText: ""
        property string lyricsStatus: ""
        property string lyricsRequestKey: ""
        property var lyricsLines: []
        property bool lyricsTimed: false
        property double lyricFallbackPosition: 0
        property double lyricFallbackTick: Date.now()
        readonly property real playbackPosition: hasPlayer && player.positionSupported
            ? player.position : lyricFallbackPosition
        readonly property int activeLyricIndex: {
            if (!lyricsTimed || lyricsLines.length === 0)
                return -1;
            let active = -1;
            for (let i = 0; i < lyricsLines.length; i++) {
                if (lyricsLines[i].time <= playbackPosition + 0.08)
                    active = i;
                else
                    break;
            }
            return active;
        }

        function parseSyncedLyrics(value) {
            const parsed = [];
            const rows = String(value || "").split(/\r?\n/);
            const stampPattern = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;
            for (let i = 0; i < rows.length; i++) {
                const line = rows[i];
                const stamps = line.match(stampPattern) || [];
                if (stamps.length === 0)
                    continue;
                const lyric = line.replace(stampPattern, "").trim();
                if (!lyric)
                    continue;
                for (let j = 0; j < stamps.length; j++) {
                    const parts = stamps[j].match(/\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/);
                    if (!parts)
                        continue;
                    const fraction = parts[3] ? Number("0." + parts[3]) : 0;
                    parsed.push({
                        time: Number(parts[1]) * 60 + Number(parts[2]) + fraction,
                        text: lyric
                    });
                }
            }
            parsed.sort((a, b) => a.time - b.time);
            return parsed;
        }

        function stripLyricsTimestamps(value) {
            return String(value || "").replace(/\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]/g, "").trim();
        }

        function requestLyrics() {
            if (!hasPlayer) {
                lyricsText = "";
                lyricsStatus = "Start a track to find lyrics";
                return;
            }
            if (lyricsFetch.running)
                lyricsFetch.running = false;

            lyricsText = "";
            lyricsLines = [];
            lyricsTimed = false;
            lyricsStatus = "Searching lyrics…";
            lyricsRequestKey = playerKey + "|" + (player.trackTitle || "") + "|" + (player.trackArtist || "");
            const url = "https://lrclib.net/api/search?track_name="
                      + encodeURIComponent(player.trackTitle || "")
                      + "&artist_name=" + encodeURIComponent(player.trackArtist || "");
            lyricsFetch.command = ["curl", "--silent", "--show-error", "--max-time", "12",
                                   "-H", "X-User-Agent: MacShellIsland/1.0 (Quickshell 0.3.0)", url];
            lyricsFetch.running = true;
        }

        function toggleLyrics() {
            lyricsVisible = !lyricsVisible;
            if (lyricsVisible)
                requestLyrics();
            else if (lyricsFetch.running)
                lyricsFetch.running = false;
        }

        // SimpMusic's Linux media interface only handles play/pause, next, previous and
        // stop. It still says it can seek and loop, but ignores both, so for it those
        // buttons are drawn faded (they are left clickable in case a newer version adds them).
        readonly property string playerKey: {
            if (!hasPlayer)
                return "";
            return ((player.identity || "") + " " + (player.desktopEntry || "") + " " + (player.dbusName || "")).toLowerCase();
        }
        readonly property bool onlyBasicControls: playerKey.indexOf("simpmusic") >= 0

        // "Loop song" for players that have no loop switch of their own (Chromium and
        // Electron apps such as Rambox): the notch jumps back to the start just before
        // the song ends. Players with a real loop switch use that instead.
        property bool softLoop: false
        property double lastSoftSeek: 0
        readonly property bool softLoopOk: hasPlayer && !player.loopSupported && player.canControl && canBar && player.positionSupported
        readonly property bool canLoopSong: canLoop || softLoopOk
        readonly property bool loopSongOn: hasPlayer && (player.loopSupported ? player.loopState === MprisLoopState.Track : softLoop)
        readonly property bool loopPlaylistOn: hasPlayer && player.loopSupported
            && player.loopState === MprisLoopState.Playlist
        readonly property bool loopModeOn: loopSongOn || loopPlaylistOn
        readonly property bool canCycleLoopMode: canLoopSong || canLoop
        readonly property string loopButtonIcon: loopSongOn && !loopPlaylistOn ? "repeat1" : "repeat"

        function toggleSongLoop() {
            if (canLoop)
                toggleLoop(MprisLoopState.Track);
            else if (softLoopOk)
                softLoop = !softLoop;
        }

        function cycleLoopMode() {
            if (loopPlaylistOn) {
                toggleLoop(MprisLoopState.Playlist);
            } else if (loopSongOn) {
                if (canLoop)
                    toggleLoop(MprisLoopState.Playlist);
                else
                    softLoop = false;
            } else {
                toggleSongLoop();
            }
        }

        function softLoopTick() {
            if (!softLoop || !softLoopOk || !isPlaying)
                return;
            const p = player;
            p.positionChanged();
            if (p.length > 3 && p.length - p.position < 1.0 && Date.now() - lastSoftSeek > 2500) {
                lastSoftSeek = Date.now();
                jump(-p.position);
            }
        }

        // App name shown under the artist, plus the switch hint when several players exist.
        readonly property string sourceText: {
            if (!hasPlayer)
                return "";
            const name = player.identity || player.desktopEntry || "Media player";
            if (playerCount < 2)
                return name;
            return name + "  (" + (Mpris.players.values.indexOf(player) + 1) + "/" + playerCount + ")  tap to switch";
        }

        // Same loop button pressed twice turns looping off again.
        function toggleLoop(mode) {
            if (!hasPlayer)
                return;
            player.loopState = player.loopState === mode ? MprisLoopState.None : mode;
        }

        // Raw MPRIS call over D-Bus. Used when an app reports a capability as
        // missing but still handles the call (some apps get these flags wrong).
        function dbusCall(method, arg) {
            if (!hasPlayer)
                return;
            let dest = player.dbusName;
            if (dest.indexOf("org.mpris.MediaPlayer2.") !== 0)
                dest = "org.mpris.MediaPlayer2." + dest;
            const cmd = ["dbus-send", "--session", "--type=method_call",
                         "--dest=" + dest, "/org/mpris/MediaPlayer2",
                         "org.mpris.MediaPlayer2.Player." + method];
            if (arg !== undefined)
                cmd.push(arg);
            Quickshell.execDetached(cmd);
        }

        function togglePlay() {
            if (!hasPlayer)
                return;
            if (isPlaying && player.canPause)
                player.pause();
            else if (!isPlaying && player.canPlay)
                player.play();
            else
                dbusCall("PlayPause");
        }

        function goNext() {
            if (!hasPlayer)
                return;
            if (player.canGoNext)
                player.next();
            else
                dbusCall("Next");
        }

        function goPrevious() {
            if (!hasPlayer)
                return;
            if (player.canGoPrevious)
                player.previous();
            else
                dbusCall("Previous");
        }

        // Jump by `seconds` (negative = back). Quickshell's seek() takes seconds; the raw
        // D-Bus Seek (used when the app says it can't seek) takes microseconds.
        function jump(seconds) {
            if (!hasPlayer)
                return;
            if (player.canSeek)
                player.seek(seconds);
            else
                dbusCall("Seek", "int64:" + Math.round(seconds * 1000000));
        }

        // Some players give the cover as a plain file path instead of a URL.
        function artSource(url) {
            if (!url)
                return "";
            return url.charAt(0) === "/" ? "file://" + url : url;
        }

        // Read only a tiny colour sample from the cover; the cover itself is never
        // drawn into the player background.
        readonly property string currentArtSource: hasPlayer ? artSource(player.trackArtUrl) : ""
        property color sampledMediaColor: "transparent"
        property color mediaAccent: "#55555d"
        Behavior on mediaAccent { ColorAnimation { duration: 520; easing.type: Easing.OutCubic } }
        onSampledMediaColorChanged:
            mediaAccent = sampledMediaColor.a > 0 ? sampledMediaColor : "#55555d"
        onCurrentArtSourceChanged: albumSampler.load(currentArtSource)

        Canvas {
            id: albumSampler
            width: 24
            height: 24
            opacity: 0
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Immediate
            property string loaded: ""

            function load(url) {
                if (loaded !== "") {
                    unloadImage(loaded);
                    loaded = "";
                }
                if (!url) {
                    win.sampledMediaColor = "transparent";
                    return;
                }
                loaded = url;
                loadImage(url);
            }

            onImageLoaded: requestPaint()
            onPaint: {
                if (loaded === "" || !isImageLoaded(loaded))
                    return;
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(loaded, 0, 0, width, height);
                const data = ctx.getImageData(0, 0, width, height).data;
                let r = 0, g = 0, b = 0, weight = 0;
                for (let i = 0; i < data.length; i += 4) {
                    const red = data[i] / 255;
                    const green = data[i + 1] / 255;
                    const blue = data[i + 2] / 255;
                    const maximum = Math.max(red, green, blue);
                    const minimum = Math.min(red, green, blue);
                    const saturation = maximum > 0 ? (maximum - minimum) / maximum : 0;
                    const sampleWeight = saturation * saturation * (0.25 + maximum) + 0.002;
                    r += red * sampleWeight;
                    g += green * sampleWeight;
                    b += blue * sampleWeight;
                    weight += sampleWeight;
                }
                if (weight <= 0)
                    return;
                const sample = Qt.rgba(r / weight, g / weight, b / weight, 1);
                if (sample.hsvSaturation < 0.16) {
                    win.sampledMediaColor = "#55555d";
                    return;
                }
                const saturation = Math.max(0.38, sample.hsvSaturation);
                const value = Math.max(0.42, Math.min(0.88, sample.hsvValue));
                win.sampledMediaColor = Qt.hsva(sample.hsvHue < 0 ? 0 : sample.hsvHue,
                                                Math.min(1, saturation), value, 1);
            }
        }
        Component.onCompleted: albumSampler.load(currentArtSource)

        // Seconds -> "m:ss"
        function fmt(s) {
            if (!(s > 0))
                return "0:00";
            const m = Math.floor(s / 60);
            const r = Math.floor(s % 60);
            return m + ":" + (r < 10 ? "0" : "") + r;
        }

        // Anchored to the top edge only, so it is centered horizontally.
        anchors.top: true
        implicitWidth: openW
        implicitHeight: contentH
        color: "transparent"

        // Gone while a window is fullscreen, back as soon as it isn't.
        visible: !hideForFullscreen

        // Sit at the very top edge, reserve no space, don't push windows down.
        exclusionMode: ExclusionMode.Ignore

        // Overlay: always above the bar. Fullscreen apps are handled by `visible` above,
        // because an Overlay surface would otherwise stay on top of them.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "island"

        // Only the notch is clickable; every other click falls through to the bar.
        mask: Region { item: pill }

        Rectangle {
            id: pill
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: win.expanded ? win.openW : win.collapsedW
            height: win.expanded ? win.contentH : win.barH
            color: "black"
            clip: true
            border.width: 0

            // Notch shape: flat top, rounded bottom.
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: win.expanded ? 28 : 16
            bottomRightRadius: bottomLeftRadius

            // Album-colour fade under the media controls. Only colour is sampled;
            // no album art image or blur is used here.
            Rectangle {
                id: albumToneWash
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.58
                bottomLeftRadius: pill.bottomLeftRadius
                bottomRightRadius: pill.bottomRightRadius
                visible: win.hasPlayer && win.expanded
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(win.mediaAccent.r, win.mediaAccent.g, win.mediaAccent.b, 0) }
                    GradientStop { position: 0.42; color: Qt.rgba(win.mediaAccent.r * 0.22, win.mediaAccent.g * 0.22, win.mediaAccent.b * 0.22, 0.24) }
                    GradientStop { position: 1.0; color: Qt.rgba(win.mediaAccent.r * 0.58, win.mediaAccent.g * 0.58, win.mediaAccent.b * 0.58, 0.84) }
                }
            }

            Behavior on width  { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: win.lyricsVisible ? 480 : 340; easing.type: Easing.OutCubic } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            // The notch widens first, then enabled mode glyphs animate into place.
            SequentialAnimation {
                id: focusPop
                PauseAnimation { duration: 330 }
                ParallelAnimation {
                    NumberAnimation {
                        target: focusIndicator
                        property: "opacity"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: focusMoon
                            property: "scale"
                            to: 1.18
                            duration: 230
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: focusMoon
                            property: "scale"
                            to: 1
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            SequentialAnimation {
                id: airplanePop
                PauseAnimation { duration: 80 }
                ParallelAnimation {
                    NumberAnimation { target: airplaneIndicator; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: airplaneGlyph; property: "flightY"; to: -5; duration: 230; easing.type: Easing.OutCubic }
                            NumberAnimation { target: airplaneGlyph; property: "scale"; to: 1.14; duration: 230; easing.type: Easing.OutCubic }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: airplaneGlyph; property: "flightY"; to: 0; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { target: airplaneGlyph; property: "scale"; to: 1; duration: 150; easing.type: Easing.OutBack }
                        }
                    }
                }
            }
            SequentialAnimation {
                id: focusHide
                NumberAnimation {
                    target: focusIndicator
                    property: "opacity"
                    to: 0
                    duration: 140
                    easing.type: Easing.InCubic
                }
                ScriptAction { script: { win.focusIndicatorShown = false; focusMoon.scale = 0.42; } }
            }
            SequentialAnimation {
                id: airplaneHide
                ParallelAnimation {
                    NumberAnimation { target: airplaneIndicator; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                    NumberAnimation { target: airplaneGlyph; property: "flightY"; to: -24; duration: 230; easing.type: Easing.InCubic }
                    NumberAnimation { target: airplaneGlyph; property: "scale"; to: 0.58; duration: 230; easing.type: Easing.InCubic }
                }
                ScriptAction {
                    script: {
                        win.airplaneIndicatorShown = false;
                        airplaneGlyph.scale = 0.42;
                        airplaneGlyph.flightY = 20;
                    }
                }
            }

            // Expand after a short hover so passing the pointer over it doesn't pop it open.
            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hover.hovered) {
                        openDelay.restart();
                    } else {
                        openDelay.stop();
                        win.expanded = false;
                    }
                }
            }

            Timer {
                id: openDelay
                interval: 180
                onTriggered: win.expanded = true
            }

            // Players only report their position when asked; poll while open.
            Timer {
                interval: 250
                repeat: true
                triggeredOnStart: true
                running: win.hasPlayer && (win.expanded || win.isPlaying)
                onTriggered: win.player.positionChanged()
            }

            // A manual player pick is dropped when a different app starts playing.
            Timer {
                interval: 700
                repeat: true
                running: win.pinned !== null
                onTriggered: win.checkPin()
            }

            // "Loop song" fallback for players without a loop switch (see softLoopTick).
            Timer {
                interval: 300
                repeat: true
                running: win.softLoop && win.softLoopOk && win.isPlaying
                onTriggered: win.softLoopTick()
            }

            // Top row: Airplane Mode and Focus | workspaces | spacer | music bars | privacy.
            Row {
                id: topRow
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: win.barH
                spacing: 6

                Row {
                    id: airplaneIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.airplaneIndicatorShown
                    opacity: 0
                    spacing: 6

                    Glyph {
                        id: airplaneGlyph
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "airplane"
                        size: 15
                        scale: 0.42
                        property real flightY: 20
                        transform: Translate { y: airplaneGlyph.flightY }
                        tint: "#0a84ff"
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 14
                        color: "#303034"
                    }
                }

                Row {
                    id: focusIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.focusIndicatorShown
                    opacity: 0
                    spacing: 6

                    Glyph {
                        id: focusMoon
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "moon"
                        size: 15
                        scale: 0.42
                        tint: "#bf5af2"
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 14
                        color: "#303034"
                    }
                }

                Rectangle {
                    id: miniAlbumArt
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.hasPlayer
                    width: 22
                    height: 22
                    radius: 6
                    color: "#171719"
                    clip: true
                    border.color: "#303034"
                    border.width: 1

                    Glyph {
                        anchors.centerIn: parent
                        visible: miniCover.status !== Image.Ready
                        kind: "note"
                        size: 14
                        tint: "#8e8e93"
                    }

                    Image {
                        id: miniCover
                        anchors.fill: parent
                        source: win.hasPlayer ? win.artSource(win.player.trackArtUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                }

                Item {
                    id: albumWorkspaceSpacer
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.hasPlayer
                    implicitWidth: 12
                    implicitHeight: 22
                    width: 12
                    height: 22

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 14
                        radius: 1
                        color: "#6e6e73"
                    }
                }

                Item {
                    id: workspacePicker
                    readonly property int buttonWidth: 24
                    readonly property int buttonHeight: 22
                    readonly property int buttonSpacing: 6
                    implicitWidth: width
                    implicitHeight: height
                    width: win.workspaceIds.length * buttonWidth
                           + Math.max(0, win.workspaceIds.length - 1) * buttonSpacing
                    height: parent.height

                    Rectangle {
                        id: activeWorkspacePill
                        x: win.activeWorkspaceIndex * (workspacePicker.buttonWidth + workspacePicker.buttonSpacing)
                        y: (parent.height - height) / 2
                        width: workspacePicker.buttonWidth
                        height: workspacePicker.buttonHeight
                        radius: height / 2
                        visible: win.activeWorkspaceIndex >= 0
                        color: "#f5f5f7"
                        border.color: "#ffffff"
                        border.width: 1

                        Behavior on x {
                            SpringAnimation {
                                spring: 3.4
                                damping: 0.32
                                mass: 0.58
                                epsilon: 0.18
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        spacing: workspacePicker.buttonSpacing

                        Repeater {
                            model: win.workspaceIds

                            Rectangle {
                                id: btn
                                required property int modelData
                                property var ws: Hyprland.workspaces.values.find(w => w.id === modelData)
                                property bool isActive: Hyprland.focusedWorkspace?.id === modelData

                                anchors.verticalCenter: parent.verticalCenter
                                width: workspacePicker.buttonWidth
                                height: workspacePicker.buttonHeight
                                radius: height / 2
                                color: area.containsMouse && !isActive ? "#242426" : "transparent"
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: btn.modelData
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: btn.isActive ? "#000000" : (btn.ws ? "#d1d1d6" : "#636366")
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (btn.ws) {
                                            btn.ws.activate();
                                        } else if (Hyprland.usingLua) {
                                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + btn.modelData + " })");
                                        } else {
                                            Hyprland.dispatch("workspace " + btn.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: workspaceMusicSpacer
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 12
                    implicitHeight: 22
                    width: 12
                    height: 22

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 14
                        radius: 1
                        color: "#6e6e73"
                    }
                }

                Item {
                    id: musicBars
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 2
                    property bool playing: win.isPlaying
                    implicitWidth: 27
                    implicitHeight: 18
                    width: 27
                    height: 18

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        spacing: 3

                        Repeater {
                            model: 4

                            Rectangle {
                                id: visualBar
                                required property int index
                                readonly property real midpoint: [8, 8, 7, 8][index]
                                property real level: midpoint
                                width: 3
                                height: musicBars.playing ? level : 3
                                anchors.verticalCenter: parent.verticalCenter
                                radius: width / 2
                                color: Qt.lighter(win.mediaAccent, 1.35)
                                Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.OutCubic } }

                                SequentialAnimation {
                                    running: musicBars.playing
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        target: visualBar
                                        property: "level"
                                        from: visualBar.midpoint
                                        to: [14, 11, 14, 10][visualBar.index]
                                        duration: 210 + visualBar.index * 35
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        target: visualBar
                                        property: "level"
                                        to: [3, 4, 3, 4][visualBar.index]
                                        duration: 230 + visualBar.index * 30
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        target: visualBar
                                        property: "level"
                                        to: visualBar.midpoint
                                        duration: 180
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.privacyActive
                    width: 1
                    height: 14
                    color: "#303034"
                }

                Rectangle {
                    id: privacyIndicators
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.privacyActive
                    opacity: win.privacyActive ? 1 : 0
                    readonly property int dotSize: 7
                    readonly property int dotGap: 4
                    readonly property int sidePadding: 6
                    readonly property int activeDotCount: (win.cameraInUse ? 1 : 0)
                                                           + (win.microphoneInUse ? 1 : 0)
                                                           + (win.screenRecording ? 1 : 0)
                    width: sidePadding * 2 + activeDotCount * dotSize
                           + Math.max(0, activeDotCount - 1) * dotGap
                    height: 18
                    radius: 9
                    color: "#151517"
                    border.color: "#303034"
                    border.width: 1
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    Row {
                        anchors.centerIn: parent
                        spacing: privacyIndicators.dotGap

                        Rectangle {
                            visible: win.cameraInUse
                            opacity: visible ? 1 : 0
                            scale: visible ? 1 : 0.42
                            width: privacyIndicators.dotSize
                            height: width
                            radius: width / 2
                            color: "#30d158"
                            border.color: "#080808"
                            border.width: 1
                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                        }

                        Rectangle {
                            visible: win.microphoneInUse
                            opacity: visible ? 1 : 0
                            scale: visible ? 1 : 0.42
                            width: privacyIndicators.dotSize
                            height: width
                            radius: width / 2
                            color: "#ff9f0a"
                            border.color: "#080808"
                            border.width: 1
                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                        }

                        Rectangle {
                            visible: win.screenRecording
                            opacity: visible ? 1 : 0
                            scale: visible ? 1 : 0.42
                            width: privacyIndicators.dotSize
                            height: width
                            radius: width / 2
                            color: "#ff3b30"
                            border.color: "#080808"
                            border.width: 1
                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                        }
                    }
                }
            }

            // Date, visible only while expanded.
            Text {
                id: dateLabel
                anchors.top: topRow.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: "#8e8e93"
                font.pixelSize: 12
                opacity: win.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            // Media player. Laid out for the final width and revealed by the
            // notch growing (clip), so nothing reflows during the animation.
            Item {
                id: media
                y: win.expanded ? 58 : 72
                anchors.horizontalCenter: parent.horizontalCenter
                width: win.openW - 32
                height: win.contentH - 58 - 12
                enabled: win.expanded
                opacity: win.expanded ? 1 : 0
                scale: win.expanded ? 1 : 0.97
                transformOrigin: Item.Top
                Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

                // Cover art (a note icon when the player gives none).
                Rectangle {
                    id: art
                    visible: !win.lyricsVisible
                    width: 54
                    height: 54
                    color: "#1c1c1e"
                    radius: 12
                    clip: true
                    border.color: "#303034"
                    border.width: 1

                    Glyph {
                        anchors.centerIn: parent
                        opacity: cover.status === Image.Ready ? 0 : 1
                        kind: "note"
                        size: 26
                        tint: "#636366"
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: win.hasPlayer ? win.artSource(win.player.trackArtUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        scale: status === Image.Ready ? 1 : 0.94
                        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }

                // Title, artist, and which app this is (tap to switch when several are open).
                Column {
                    id: trackDetails
                    visible: !win.lyricsVisible
                    anchors.left: art.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: art.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: win.hasPlayer ? (win.player.trackTitle || "Unknown title") : "Nothing playing"
                        color: "#f5f5f7"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: win.hasPlayer ? (win.player.trackArtist || "Unknown artist") : "Start music in any player app"
                        color: "#a1a1a6"
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: win.hasPlayer
                        text: win.sourceText
                        color: win.playerCount > 1 ? "#4da3ff" : "#636366"
                        font.pixelSize: 11

                        MouseArea {
                            anchors.fill: parent
                            enabled: win.playerCount > 1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.nextPlayer()
                        }
                    }
                }

                Item {
                    id: lyricsPane
                    width: parent.width
                    height: win.lyricsVisible ? media.height - 78 : 58
                    clip: true
                    visible: win.lyricsVisible || opacity > 0.01
                    enabled: win.lyricsVisible
                    opacity: win.lyricsVisible ? 1 : 0
                    scale: win.lyricsVisible ? 1 : 0.985
                    transformOrigin: Item.Center
                    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

                    Flickable {
                        id: lyricsScroll
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        clip: true
                        visible: !win.lyricsTimed && win.lyricsText !== ""
                        contentWidth: width
                        contentHeight: lyricText.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: lyricText
                            width: lyricsScroll.width
                            text: win.lyricsText
                            color: "#ffffff"
                            font.pixelSize: 18
                            lineHeight: 1.12
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }

                    ListView {
                        id: syncedLyricsList
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        clip: true
                        visible: win.lyricsTimed && win.lyricsLines.length > 0
                        model: win.lyricsLines
                        currentIndex: win.activeLyricIndex
                        spacing: 10
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: height * 0.38
                        preferredHighlightEnd: height * 0.62
                        Behavior on contentY { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0)
                                positionViewAtIndex(currentIndex, ListView.Center);
                        }

                        delegate: Text {
                            required property var modelData
                            required property int index
                            width: syncedLyricsList.width
                            text: modelData.text
                            color: win.activeLyricIndex === index ? "#ffffff" : "#d1d1d6"
                            opacity: win.activeLyricIndex === index ? 1 : 0.72
                            font.pixelSize: win.activeLyricIndex === index ? 20 : 18
                            font.bold: win.activeLyricIndex === index
                            scale: win.activeLyricIndex === index ? 1.015 : 1
                            lineHeight: 1.08
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        anchors.fill: parent
                        visible: win.lyricsText === "" && !win.lyricsTimed
                        text: win.lyricsStatus
                        color: "#a1a1a6"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }

                // Elapsed time, progress bar (click to seek), total time.
                Item {
                    id: prog
                    y: win.lyricsVisible ? media.height - 70 : 64
                    width: parent.width
                    height: 16
                    Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                    readonly property real len: win.hasPlayer && win.player.lengthSupported ? win.player.length : 0
                    readonly property real pos: win.hasPlayer ? win.player.position : 0
                    readonly property real ratio: len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0

                    Text {
                        id: tNow
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        text: win.fmt(prog.pos)
                        color: "#a1a1a6"
                        font.pixelSize: 11
                    }

                    Text {
                        id: tEnd
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        horizontalAlignment: Text.AlignRight
                        text: win.fmt(prog.len)
                        color: "#a1a1a6"
                        font.pixelSize: 11
                    }

                    Rectangle {
                        id: bar
                        anchors.left: tNow.right
                        anchors.right: tEnd.left
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        height: seekArea.containsMouse ? 6 : 4
                        radius: 2
                        color: "#3a3a3c"
                        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: progressFill
                            width: bar.width * prog.ratio
                            height: bar.height
                            radius: 2
                            color: "white"
                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        id: seekArea
                        x: bar.x
                        width: bar.width
                        height: parent.height
                        enabled: win.canBar && !win.onlyBasicControls
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            win.jump(mouse.x / width * prog.len - prog.pos);
                        }
                    }
                }

                // Controls: loop | previous | -10s | play/pause | +10s | next | lyrics
                Row {
                    id: mediaControls
                    y: win.lyricsVisible ? media.height - 46 : 88
                    height: 46
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    scale: win.expanded ? 1 : 0.96
                    opacity: win.expanded ? 1 : 0
                    Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    CtlButton {
                        icon: win.loopButtonIcon
                        highlighted: win.loopModeOn
                        usable: win.canCycleLoopMode
                        dim: win.onlyBasicControls
                        onActivated: win.cycleLoopMode()
                    }

                    CtlButton {
                        icon: "prev"
                        usable: win.hasPlayer
                        dim: win.hasPlayer && !win.player.canGoPrevious
                        onActivated: win.goPrevious()
                    }

                    CtlButton {
                        icon: "back"
                        badge: String(win.skip)
                        iconSize: 24
                        usable: win.hasPlayer
                        dim: win.hasPlayer && (win.onlyBasicControls || !win.player.canSeek)
                        onActivated: win.jump(-win.skip)
                    }

                    CtlButton {
                        primary: true
                        icon: win.isPlaying ? "pause" : "play"
                        usable: win.hasPlayer
                        dim: win.hasPlayer && !(win.isPlaying ? win.player.canPause : win.player.canPlay)
                        onActivated: win.togglePlay()
                    }

                    CtlButton {
                        icon: "fwd"
                        badge: String(win.skip)
                        iconSize: 24
                        usable: win.hasPlayer
                        dim: win.hasPlayer && (win.onlyBasicControls || !win.player.canSeek)
                        onActivated: win.jump(win.skip)
                    }

                    CtlButton {
                        icon: "next"
                        usable: win.hasPlayer
                        dim: win.hasPlayer && !win.player.canGoNext
                        onActivated: win.goNext()
                    }

                    CtlButton {
                        icon: "lyrics"
                        highlighted: win.lyricsVisible
                        usable: win.hasPlayer
                        onActivated: win.toggleLyrics()
                    }
                }
            }

        }
    }
}
