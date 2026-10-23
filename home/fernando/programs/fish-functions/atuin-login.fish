if test -e $HOME/.local/share/atuin/session
    echo "atuin: sessão já existe em ~/.local/share/atuin/session"
    return 0
end

atuin login \
    -u (op read 'op://development/Atuin/username') \
    -p (op read 'op://development/Atuin/pass') \
    -k (op read 'op://development/Atuin/key')
