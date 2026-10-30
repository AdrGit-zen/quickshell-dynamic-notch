#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target_dir="$config_home/quickshell/island"
target_file="$target_dir/shell.qml"
bin_dir="$HOME/.local/bin"
unit_dir="$config_home/systemd/user"

checker_source="$repo_dir/scripts/island-start"
hourly_source="$repo_dir/scripts/island-hourly-reset"
checker_unit_source="$repo_dir/systemd/island-checker.service"
hourly_service_source="$repo_dir/systemd/island-hourly-reset.service"
hourly_timer_source="$repo_dir/systemd/island-hourly-reset.timer"

for source in "$repo_dir/shell.qml" "$checker_source" "$hourly_source" "$checker_unit_source" "$hourly_service_source" "$hourly_timer_source"; do
    if [[ ! -f "$source" ]]; then
        printf 'Error: required install file is missing: %s\n' "$source" >&2
        exit 1
    fi
done

checker_file="$bin_dir/island-start"
hourly_file="$bin_dir/island-hourly-reset"
checker_unit="$unit_dir/island-checker.service"
hourly_service="$unit_dir/island-hourly-reset.service"
hourly_timer="$unit_dir/island-hourly-reset.timer"

mkdir -p "$target_dir" "$bin_dir" "$unit_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
backup_if_exists() {
    if [[ -f "$1" ]]; then
        cp -- "$1" "$1.backup.$stamp"
        printf 'Saved existing file to %s.backup.%s\n' "$1" "$stamp"
    fi
}

backup_if_exists "$target_file"
backup_if_exists "$checker_file"
backup_if_exists "$hourly_file"
backup_if_exists "$checker_unit"
backup_if_exists "$hourly_service"
backup_if_exists "$hourly_timer"

install -m 0644 -- "$repo_dir/shell.qml" "$target_file"
install -m 0755 -- "$checker_source" "$checker_file"
install -m 0755 -- "$hourly_source" "$hourly_file"
install -m 0644 -- "$checker_unit_source" "$checker_unit"
install -m 0644 -- "$hourly_service_source" "$hourly_service"
install -m 0644 -- "$hourly_timer_source" "$hourly_timer"

printf 'Installed notch config to %s\n' "$target_file"
printf 'Installed Island checker and systemd user units.\n'

if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user daemon-reload; then
        if systemctl --user enable --now island-hourly-reset.timer; then
            printf 'Enabled the hourly Island recovery timer.\n'
        else
            printf 'Could not enable the hourly timer in this session; run: systemctl --user enable --now island-hourly-reset.timer\n' >&2
        fi
    else
        printf 'Could not reload the user systemd manager; run: systemctl --user daemon-reload\n' >&2
    fi
fi

printf 'In your Hyprland startup hook, import the session environment and start island-checker.service; see README.md.\n'
