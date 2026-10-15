set arquivo $argv[1]
if test -z "$arquivo"
    echo "Erro: Forneça um nome para o arquivo. Exemplo: rec-session aula1.txt"
    return 1
end
script -q -c "fish --init-command 'function fish_prompt; echo \"> \"; end'" $arquivo
if test -f $arquivo
    set -l temp_file (mktemp)
    sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g" $arquivo >$temp_file
    mv $temp_file $arquivo
    echo "Sessão gravada e limpa com sucesso em: $arquivo"
end
