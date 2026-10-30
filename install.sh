#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target_dir="$config_home/quickshell/island"
target_file="$target_dir/shell.qml"

if [[ ! -f "$repo_dir/shell.qml" ]]; then
    printf 'Error: shell.qml is missing from %s\n' "$repo_dir" >&2
    exit 1
fi

mkdir -p "$target_dir"
if [[ -f "$target_file" ]]; then
    backup_file="$target_file.backup.$(date +%Y%m%d-%H%M%S)"
    cp -- "$target_file" "$backup_file"
    printf 'Saved existing config to %s\n' "$backup_file"
fi

install -m 0644 -- "$repo_dir/shell.qml" "$target_file"
printf 'Installed notch config to %s\n' "$target_file"

if ! command -v qs >/dev/null 2>&1; then
    printf 'Quickshell was not found. Install it from your distro, then run: qs -c island\n' >&2
else
    printf 'Start it now with: qs -c island\n'
fi
