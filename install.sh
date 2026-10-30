#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target_dir="$config_home/quickshell/island"
target_file="$target_dir/shell.qml"
bin_dir="${HOME}/.local/bin"
checker_source="$repo_dir/scripts/island-start"
checker_file="$bin_dir/island-start"

if [[ ! -f "$repo_dir/shell.qml" ]]; then
    printf 'Error: shell.qml is missing from %s\n' "$repo_dir" >&2
    exit 1
fi
if [[ ! -f "$checker_source" ]]; then
    printf 'Error: island-start is missing from %s\n' "$checker_source" >&2
    exit 1
fi

mkdir -p "$target_dir" "$bin_dir"
if [[ -f "$target_file" ]]; then
    backup_file="$target_file.backup.$(date +%Y%m%d-%H%M%S)"
    cp -- "$target_file" "$backup_file"
    printf 'Saved existing config to %s\n' "$backup_file"
fi
if [[ -f "$checker_file" ]]; then
    backup_file="$checker_file.backup.$(date +%Y%m%d-%H%M%S)"
    cp -- "$checker_file" "$backup_file"
    printf 'Saved existing checker to %s\n' "$backup_file"
fi

install -m 0644 -- "$repo_dir/shell.qml" "$target_file"
install -m 0755 -- "$checker_source" "$checker_file"
printf 'Installed notch config to %s\n' "$target_file"
printf 'Installed layer checker to %s\n' "$checker_file"

if ! command -v qs >/dev/null 2>&1; then
    printf 'Quickshell was not found. Install it from your distro before starting the notch.\n' >&2
else
    printf 'Start the notch and its checker now with: sh "%s"\n' "$checker_file"
fi
printf 'Add the checker to your existing Hyprland startup hook; see README.md.\n'
