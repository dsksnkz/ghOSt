#!/usr/bin/env bash
# Show only actively playing MPRIS media, with a quiet monochrome idle state.
if ! command -v playerctl >/dev/null 2>&1; then
    printf 'Unavailable\n'
    exit 0
fi

while IFS= read -r player; do
    if [[ $(playerctl --player="$player" status 2>/dev/null) == Playing ]]; then
        title=$(playerctl --player="$player" metadata --format '{{title}}' 2>/dev/null)
        if [[ -n "$title" ]]; then
            printf '%s\n' "$title"
            exit 0
        fi
    fi
done < <(playerctl --list-all 2>/dev/null)

printf 'Not playing\n'
