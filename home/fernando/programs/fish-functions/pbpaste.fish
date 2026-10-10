if set -q WAYLAND_DISPLAY; and type -q wl-paste
    wl-paste | string collect -N
else if set -q DISPLAY; and type -q xsel
    xsel --clipboard --output
else if set -q DISPLAY; and type -q xclip
    xclip -selection clipboard -o
else
    echo "pbpaste: nenhum backend de clipboard disponível" >&2
    return 1
end
