if status is-interactive
    # Commands to run in interactive sessions can go here
    source "$HOME/.cargo/env.fish"
end

set -g fish_greeting

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

abbr --add ls ls -la
abbr --add syu sudo pacman -Syu --needed --color=auto
abbr --add rns sudo pacman -Rns
abbr --add ss sudo pacman -Ss
#abbr --add cleanup sudo pacman -Rns $(sudo pacman -Qdtq)
abbr --add stream --set-cursor "streamlink https://www.twitch.tv/% best"
abbr --add vpn-up sudo wg-quick up kiwi_vpn
abbr --add vpn-down sudo wg-quick down kiwi_vpn
abbr --add rotate ~/.config/hypr/hdmi-rotation.fish
abbr --add mkdir mkdir -p
abbr --add mnt udisksctl mount -b
abbr --add umnt udisksctl unmount -b
abbr --add mv mv -v
abbr --add cls clear
abbr --add zed zeditor
abbr --add pp paplay -d sink_soundboard
abbr --add claude bash -c \'claude\'
zoxide init fish | source
alias vw-backup='cp ~/homestack/vaultwarden/data/db.sqlite3 ~/backups/vaultwarden/db-(date +%F_%H%M).sqlite3; and find ~/backups/vaultwarden -name "db-*.sqlite3" -mtime +30 -delete; and echo "Backup done: db-"(date +%F_%H%M)".sqlite3"'
export LIBVIRT_DEFAULT_URI="qemu:///system"
if status is-interactive
    keychain --quiet id_ed25519
    set -gx SSH_AUTH_SOCK (grep -oP 'SSH_AUTH_SOCK=\K[^;]+' $HOME/.keychain/(uname -n)-sh)
    set -gx SSH_AGENT_PID (grep -oP 'SSH_AGENT_PID=\K[^;]+' $HOME/.keychain/(uname -n)-sh)
end
function loc
    locate -i "$argv" | grep -i --color=always "$argv"
end
abbr --add updb sudo updatedb --add-single-prunepath "/run/media/christopher/Windows/Program Files" --add-single-prunepath "/run/media/christopher/Windows/Program Files (x86)" --add-single-prunepath "/run/media/christopher/Windows/Users/Christopher/Epic Games" -v
