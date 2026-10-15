set -l n 0
for d in ~/.pi/agent ~/.pi-work/agent
    test -d $d; or continue
    for f in (find $d -path '*sandbox-runtime*' -name 'apply-seccomp' 2>/dev/null)
        mv $f $f.disabled; and set n (math $n + 1)
    end
end
echo "pi-seccomp-off: $n binário(s) desabilitado(s)"
