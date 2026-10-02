# NixOS VM com Tack

Configuração incremental para construir e executar uma VM NixOS com QEMU a partir de um host Ubuntu.

## Fluxo

```text
Ubuntu → Nix → Tack → system.nix → NixOS VM → SSH
```

O projeto não usa Flakes como arquitetura. O Tack mantém o pin de `nixpkgs` em `.tack/`, e `system.nix` é o entrypoint do sistema.

## Requisitos

- Nix com suporte a `nix-build` e `nix-instantiate`
- QEMU/KVM disponível no host
- Tack 1.0.1 ou compatível

O Tack pode ser instalado sem adicionar um `flake.nix` ao projeto:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  profile install github:manic-systems/tack
```

Se o binário não estiver no `PATH`, use:

```bash
export PATH="$HOME/.nix-profile/bin:$PATH"
```

## Estrutura

- `system.nix`: entrypoint do sistema NixOS
- `.tack/`: resolver, pins e lockfile do Tack
- `hosts/vm/default.nix`: composição específica da VM
- `modules/`: módulos reutilizáveis de base, usuários, pacotes e rede
- `services/`: espaço reservado para serviços de usuário futuros

O pin atual de `nixpkgs` aponta para `nixos-unstable` e é materializado em `.tack/pins.lock.json`.

## Build

```bash
make build
```

O resultado esperado é:

```text
./result/bin/run-nixos-test-vm
```

Para forçar uma avaliação/build novo:

```bash
make rebuild
```

O Makefile habilita temporariamente `nix-command flakes` nos comandos de build porque o resolver gerado pelo Tack usa `builtins.fetchTree`. Isso não cria nem requer `flake.nix` ou `flake.lock` no projeto.

## Executar a VM

Console serial interativo:

```bash
make vm-console
```

A VM usa:

- Hostname: `nixos-test`
- Memória: 4096 MiB
- CPUs: 4
- Console: `ttyS0`

Execução em background:

```bash
make vm-up
make vm-status
make vm-log
```

Encerrar ou reiniciar:

```bash
make vm-down
make vm-restart
```

O processo em background usa `.vm.pid` e grava a saída em `.vm.log`.

## SSH

O forwarding é declarado em NixOS:

```text
127.0.0.1:2222 → VM:22
```

Depois de iniciar a VM:

```bash
make ssh
```

O target SSH restringe autenticação a senha e evita o problema de muitas chaves no `ssh-agent`.

Usuário de teste:

```text
fernando
```

A configuração atual usa uma senha fixa apenas para o smoke test local da VM. Não reutilize essa credencial em uma máquina real.

## Pacotes verificados

A VM instala:

- Chezmoi
- Git
- Neovim
- Ghostty
- ripgrep (`rg`)
- fd

Validação manual dentro da VM:

```bash
command -v git
command -v chezmoi
command -v nvim
command -v rg
command -v fd
systemctl is-active sshd
```

## Limpeza

```bash
make clean
```

Remove o link de build, o PID file e o log local, encerrando antes uma VM em background.

O disco `nixos-test.qcow2` é gerado pelo launcher da VM e pode ser removido manualmente quando for necessário recriar o estado persistente:

```bash
make vm-down
rm -f nixos-test.qcow2
```

## Tack

Para inspecionar e validar os pins:

```bash
tack tree
tack verify
```

Para atualizar o pin de `nixpkgs` conforme o fluxo do Tack:

```bash
tack update
```

Dotfiles continuam sob responsabilidade do Chezmoi. Esta etapa não introduz Home Manager, Hjem nem migração de dotfiles.
