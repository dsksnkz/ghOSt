#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

# Anything other than a plain run in a terminal keeps the scriptable behaviour.
if [ $# -gt 0 ] || [ ! -t 0 ] || [ ! -t 1 ]; then
    command -v python3 >/dev/null || { printf 'Missing dependency: python\n' >&2; exit 1; }
    exec python3 scripts/install.py "$@"
fi

dim=$'\033[2m' bold=$'\033[1m' reset=$'\033[0m'
clear
cat <<'BANNER'

         __   ____  ______
   ___ _/ /  / __ \/ __/ /_
  / _ `/ _ \/ /_/ /\ \/ __/
  \_, /_//_/\____/___/\__/
 /___/

BANNER

read -r -p "  Install ghOSt? [y/N] " answer
case "$answer" in [yY]*) ;; *) printf '\n  Nothing was changed.\n\n'; exit 0 ;; esac
printf '\n'

# Asked here so the password prompt never lands on the progress bar.
sudo -v
if ! command -v python3 >/dev/null; then
    sudo pacman -S --needed --noconfirm python >/dev/null
fi

status=0
python3 scripts/install.py --activate --progress || status=$?
if [ "$status" -ne 0 ]; then
    exit "$status"
fi

printf '\n'
read -r -p "  Reboot now? [y/N] " answer
case "$answer" in
    [yY]*) systemctl reboot ;;
    *) printf '\n  %sghOSt is ready. Reboot when you like.%s\n\n' "$bold" "$reset" ;;
esac
