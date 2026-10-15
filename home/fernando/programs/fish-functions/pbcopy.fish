if set -q WAYLAND_DISPLAY; and type -q wl-copy
    wl-copy
else if set -q DISPLAY; and type -q xsel
    xsel --clipboard --input
else if set -q DISPLAY; and type -q xclip
    xclip -selection clipboard
else
    echo "pbcopy: nenhum backend de clipboard disponível" >&2
    return 1
end
