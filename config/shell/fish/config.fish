#!/usr/bin/env fish
# ghOSt fish configuration.

set fish_greeting ""

command -q starship; and starship init fish | source
command -q zoxide; and zoxide init fish | source

fish_add_path -g $HOME/.local/bin

abbr -a -g gp git push
abbr -a -g gc git commit -asm
abbr -a -g gst git status

alias conf="hx ~/.config"
alias hyprconf="hx ~/.config/hypr"
alias ff="fastfetch"
