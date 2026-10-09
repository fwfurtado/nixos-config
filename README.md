# NixOS e Home Manager com Tack

Configuração de NixOS para a VM de teste e o mini-PC bare-metal, mais Home Manager standalone para Linux e macOS. A instalação do mini-PC **não é automatizada**: os alvos de build nunca particionam, formatam ou montam discos.

## Fluxo

```text
NixOS: system.nix → hosts/vm                  (teste)
       minipc.nix → hosts/minipc              (disco próprio)
Linux/macOS: home.nix → Home Manager          (desktop Linux opcional)
Ubuntu/Fedora: standalone-system.nix → greetd (System Manager)
```

O projeto não contém `flake.nix`. Tack mantém os pins em `.tack/`; somente a avaliação do flake upstream do System Manager usa `builtins.getFlake`, no commit fixado pelo lock do Tack.

## Requisitos

- Nix com suporte a `nix-build` e `nix-instantiate`
- QEMU/KVM para executar a VM
- Tack 1.0.1 ou compatível para atualizar pins

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

- `system.nix` e `hosts/vm/`: sistema de teste com senha e console serial apenas para a VM
- `minipc.nix` e `hosts/minipc/`: host real, storage/UEFI, 1Password, sing-box
- `home.nix` e `home/fernando/`: Home Manager standalone e integrado ao NixOS; o nome de usuário é parametrizado por host
- `standalone-system.nix`: greetd e sessão Niri no Ubuntu/Fedora via System Manager
- `.tack/`: resolver, pins e lockfile; `nixpkgs` acompanha `nixos-unstable`
- `modules/`: módulos compartilhados; serviços exclusivos do mini-PC são importados pelo host

<<<<<<< HEAD
## Mini-PC: instalação direta a partir do Ubuntu

O Ubuntu usa a raiz e a ESP do Samsung SSD 980 PRO (serial `S76ENU0XA00371M`, `/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S76ENU0XA00371M`). **Somente** o WD_BLACK SN7100 (serial `254432804382`, `/dev/disk/by-id/nvme-WD_BLACK_SN7100_2TB_254432804382`) foi reparticionado; a partição anterior `models` foi apagada sem backup por escolha do proprietário. **Os números `/dev/nvme0n1` e `/dev/nvme1n1` inverteram após reiniciar:** nunca use esses números para identificar o disco a apagar. Confirme sempre modelo, serial, partições e montagens com `lsblk`, `findmnt` e `/dev/disk/by-id`. Não formate a ESP do Ubuntu.

O WD_BLACK contém três filesystems independentes por **rótulo**: `nixos-esp` (FAT32, 1 GiB, `/boot`), `nixos-root` (ext4, 200 GiB, `/`) e `nixos-home` (ext4, restante do disco, `/home`). Não há LUKS nem hibernação; zram fornece swap. Os rótulos correspondem a `hosts/minipc/default.nix`.

O firmware está com Secure Boot **desativado, sem apagar as chaves nem `dbx`**. A ESP do WD_BLACK contém `systemd-boot` para as gerações NixOS. Ela também recebeu rEFInd para um teste temporário de escolha entre NixOS e Ubuntu: o menu apareceu uma vez via `BootNext`, que é descartado após o boot. O Ubuntu continua como padrão do firmware; para entrar no NixOS, selecione o WD_BLACK no setup/boot menu. Não há plano de manter um menu dual-boot permanente, pois o dual boot é temporário e o destino terá um único disco. Os arquivos do rEFInd ainda são copiados por `boot.loader.systemd-boot.extraFiles`, sem tocar na ESP do Samsung. `boot.loader.efi.canTouchEfiVariables = false` impede que rebuilds alterem a prioridade do firmware. Reativar Secure Boot impediria o boot sem assinar os programas EFI e kernels.

Para **apenas construir** o sistema, sem criar filesystem nem instalar:

```bash
make minipc-build
```

O perfil de VM segue independente (`make build`); sua senha conhecida e seu `sudo` sem senha não são importados pelo host real. O host real desabilita o servidor SSH de entrada. A conta `fwfurtado` precisa de senha definida com `passwd` no sistema alvo antes do primeiro login; não há credencial em claro nem hash de teste configurado para ela.

### Instalação a partir do Ubuntu, sem USB

O [manual oficial](https://nixos.org/manual/nixos/stable/#sec-installing-from-other-distro) permite instalar diretamente a partir do Ubuntu. Depois de particionar e formatar **apenas o WD_BLACK confirmado**, monte os filesystems pelos rótulos. Use `/mnt/nixos`, porque `/mnt` já contém outros diretórios nesta máquina:

```bash
sudo mkdir -p /mnt/nixos
sudo mount /dev/disk/by-label/nixos-root /mnt/nixos
sudo mkdir -p /mnt/nixos/home /mnt/nixos/boot
sudo mount /dev/disk/by-label/nixos-home /mnt/nixos/home
sudo mount -o umask=0077 /dev/disk/by-label/nixos-esp /mnt/nixos/boot
```

Uma **chave age exclusiva do host já foi gerada**, adicionada a `.sops.yaml` e usada para cifrar os segredos. O arquivo privado está fora do Git, em `~/.local/state/nixos-config/minipc-age-key.txt` (0600). A chave foi salva no 1Password; a recuperação, a chave pública e a descriptografia de `secrets/sing-box-config.enc` foram testadas com `op run`. Provisionar a chave privada no destino antes de ativar os segredos:

```bash
sudo install -d -m 0700 /mnt/nixos/var/lib/sops-nix
sudo install -m 0600 ~/.local/state/nixos-config/minipc-age-key.txt /mnt/nixos/var/lib/sops-nix/key.txt
```

Compare a saída de `nixos-generate-config --root /mnt/nixos --show-hardware-config` com `hosts/minipc/default.nix`, sem importar definições duplicadas de filesystem. A configuração inclui os módulos detectados `thunderbolt` e `kvm-amd` e o microcódigo AMD. Construa a geração e instale exatamente essa geração com as ferramentas do mesmo `nixpkgs` pinado:

```bash
make minipc-build
tools=$(nix-build --no-out-link --option extra-experimental-features 'nix-command flakes' \
  ./minipc.nix -A pkgs.nixos-install-tools)
sudo env PATH="$tools/bin:$PATH" "$tools/bin/nixos-install" --root /mnt/nixos \
  --system "$(readlink -f result-minipc)" --no-channel-copy --no-root-password
sudo env PATH="$tools/bin:$PATH" "$tools/bin/nixos-enter" --root /mnt/nixos \
  -c '/nix/var/nix/profiles/system/sw/bin/passwd fwfurtado'
```

Defina a senha **interativamente no terminal local**, nunca no Git ou no chat. A instalação feita com `--no-root-password` depende da conta `fwfurtado` (grupo `wheel`) para administração. `nixos-install` gravou `EFI/BOOT/BOOTX64.EFI` e entradas de gerações em `loader/entries/` na ESP nova. O primeiro boot e login no NixOS funcionaram. O conteúdo de `~/projects/` e `~/Pictures/wallpapers/` foi copiado do Ubuntu para o `/home` do NixOS preservando arquivos já existentes; o Ubuntu continua como recuperação durante a migração.

O firmware mostrou o WD_BLACK inicialmente apenas como `UEFI OS` (Boot0004, fallback). A entrada direta `NixOS WD_BLACK` (Boot0001) apontou para `\EFI\systemd\systemd-bootx64.efi` e funcionou no teste via `BootNext`. A entrada rEFInd (Boot0005) também foi testada com `BootNext`: como esperado, apareceu uma vez e não substituiu a prioridade permanente do Ubuntu (Boot0002). Para alternar entre os sistemas nesta fase, use o seletor de disco do firmware; não é necessário alterar `BootOrder`.

### Desktop

NixOS e Linux standalone usam Niri e Noctalia. O NixOS instala sessão, portal e greeter no sistema; Home Manager configura Niri e Noctalia Shell. O agente Polkit nativo do Noctalia substitui `hyprpolkitagent`. A luz noturna nativa substitui `wl-gammarrelay`, com localização aproximada por IP via `noctalia.dev` ([política do serviço](https://noctalia.dev/privacy)). Confira no primeiro login: Niri, Noctalia, autenticação Polkit, bloqueio de tela, portal de screencast, saídas de vídeo e desbloqueio do 1Password.

A configuração Niri do NixOS replica teclado, mouse, layout, saídas `DP-1` (`5120x1440@119.999`) e `HDMI-A-1` (`5120x1440@59.977`) e os atalhos do ChezMoi. O primeiro login NixOS registrou `HDMI-A-1` com o modo solicitado; `DP-1` não estava conectado. Com o plugin `kenn/keybind-cheatsheet` instalado declarativamente, `Mod+Shift+Slash` abre novamente o mesmo cheatsheet do Ubuntu. As cores dinâmicas de `noctalia.kdl` ainda não são incluídas pelo Niri, pois o Home Manager valida `config.kdl` na store antes de o Noctalia gerar esse arquivo; as regras de janela do Noctalia no NixOS permanecem explícitas. As duas fontes não se atualizam automaticamente.

No mini-PC, `home/fernando/desktop/noctalia-settings.toml` declara o snapshot de `~/.local/state/noctalia/settings.toml` do Ubuntu, exceto a chave do Wallhaven. O Home Manager mantém as definições NixOS preexistentes de inatividade, luz noturna e lançamento de aplicativos como serviços systemd. `noctalia-plugins.nix` instala fontes pinadas dos cinco plugins, desativa atualizações automáticas dessas fontes e fornece Python com NumPy, ONNX Runtime e Pillow ao serviço Noctalia. O Wallpaper Depth ainda requer a instalação inicial do modelo de 99 MB pelo painel do plugin; os diretórios de wallpapers em `~/Pictures/wallpapers/` devem continuar presentes no NixOS. Alterações feitas pela UI em `~/.local/state/noctalia/settings.toml` têm precedência sobre os arquivos declarados.

No WD, o estado Noctalia anterior foi preservado em `~/.local/state/noctalia/settings.toml.pre-declarative`. Os overrides que escondiam a tela de bloqueio, templates e wallpapers declarados foram removidos de `settings.toml`; permanece `config_version = 15`. Isso é uma migração única da instalação, não uma limpeza automática a cada ativação.

O Home Manager instala Google Chrome (atalho `Mod+Shift+Return`), Zed, Slack e Obsidian; GitHub CLI, fzf, fd, mergiraf e ec já estavam declarados. Os módulos do host ativam o aplicativo e o CLI do 1Password. Beekeeper Studio não foi incluído: o pacote `beekeeper-studio-6.1.4` deste pin foi marcado pelo nixpkgs como inseguro devido ao Electron 39.8.10 fora de suporte, e o proprietário escolheu aguardar uma versão corrigida.

No mini-PC, `environment.systemPackages` fornece `bd` (Beads), `omp`, `docker`, `xh`, `make` e `kubectl`. O pacote `docker-client` inclui Docker Compose e Buildx; **não** ativa um daemon local nem concede ao usuário acesso ao socket Docker. Para executar contêineres localmente, a configuração do serviço e suas permissões precisam de uma decisão separada.

### Segredos e túnel SSH

A configuração e a tabela de hosts do sing-box ficam cifradas em `secrets/sing-box-{config,hosts}.enc`; sops-nix disponibiliza os arquivos somente ao usuário de sistema `sing-box` em `/run/secrets`. Como a instalação escolhida não usa LUKS, acesso físico ao disco ainda expõe a chave age local. Não versionar tokens de sessão nem exportá-los ao ambiente global do `systemd --user`

Após login e desbloqueio do 1Password, `vpn-proxy.service` usa `autossh` com o alias SSH `vpn-proxy` para abrir SOCKS em `127.0.0.1:1080`. A diretiva SSH `User` fica cifrada em `secrets/vpn-proxy-user.enc`: o alias inclui o arquivo decifrado por sops-nix somente em tempo de execução, sem registrar o usuário no módulo Nix ou nos argumentos do serviço. No NixOS, sops-nix o entrega ao usuário `fwfurtado` em `/run/secrets/vpn-proxy-user`; no Linux standalone, sops-nix do Home Manager o entrega em `$XDG_RUNTIME_DIR/secrets.d` e precisa da chave age em `~/.config/sops/age/keys.txt`. Exporte **somente a chave pública** da chave exclusiva do túnel no 1Password para `~/.ssh/vpn-proxy.pub`, autorize-a no Mac e confira a fingerprint SSH do Mac. Antes de o túnel funcionar, as rotas corporativas do `sing-box` que dependem desse SOCKS não estarão acessíveis. `active (running)` não comprova a conexão: teste o SOCKS e uma rota corporativa permitida.

O token Wallhaven está cifrado em `secrets/noctalia-wallhaven.enc` para o usuário e para o mini-PC. sops-nix entrega o TOML somente a `fwfurtado` em `/run/secrets/noctalia-wallhaven` (0400); um symlink gerado pelo Home Manager aponta para esse arquivo em `~/.config/noctalia/zz-wallhaven-secret.toml`. O valor não é interpolado em Nix nem copiado para a store.

### Home Manager standalone

No Ubuntu/Fedora, a sessão Niri de `standalone-system.nix` requer Home Manager desktop ativado para o usuário antes do switch do System Manager. A unidade `vpn-proxy.service` do Home Manager é opcional no standalone (`HOME_TAILNET_PROXY=true`). Antes de ativá-la no Ubuntu, pare/desative qualquer unidade já existente que ocupe a porta 1080, para evitar dois túneis concorrentes; não altere o serviço em execução apenas para fazer um build. O segredo de usuário precisa estar decifrável pela chave age local cadastrada como destinatária na `.sops.yaml`. Não executar `make system-switch` nem reiniciar o greeter como parte deste build. No macOS e no Linux CLI, o desktop continua opcional. Configurações de usuário migradas do ChezMoi saem daquele gestor por grupos, sem dupla posse do mesmo arquivo.

No macOS, o Home Manager escreve a configuração do Ghostty, mas o pacote Nix fixado não suporta Darwin; instale o aplicativo nativo separadamente. O perfil macOS não importa Niri nem serviços de Linux.

O Home Manager instala o lockfile editável do Neovim sem acessar a rede durante a ativação. O `vim.pack.add` baixa os plugins quando o Neovim é aberto pela primeira vez; atualizações posteriores são feitas no próprio editor, não no boot.
||||||| parent of 5decb96 (feat(nixos): add mini-PC desktop and services)
=======
## Mini-PC: instalação direta a partir do Ubuntu

O Ubuntu usa a raiz e a ESP do Samsung SSD 980 PRO (serial `S76ENU0XA00371M`, `/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S76ENU0XA00371M`). **Somente** o WD_BLACK SN7100 (serial `254432804382`, `/dev/disk/by-id/nvme-WD_BLACK_SN7100_2TB_254432804382`) foi reparticionado; a partição anterior `models` foi apagada sem backup por escolha do proprietário. **Os números `/dev/nvme0n1` e `/dev/nvme1n1` inverteram após reiniciar:** nunca use esses números para identificar o disco a apagar. Confirme sempre modelo, serial, partições e montagens com `lsblk`, `findmnt` e `/dev/disk/by-id`. Não formate a ESP do Ubuntu.

O WD_BLACK contém três filesystems independentes por **rótulo**: `nixos-esp` (FAT32, 1 GiB, `/boot`), `nixos-root` (ext4, 200 GiB, `/`) e `nixos-home` (ext4, restante do disco, `/home`). Não há LUKS nem hibernação; zram fornece swap. Os rótulos correspondem a `hosts/minipc/default.nix`.

O firmware está com Secure Boot **desativado, sem apagar as chaves nem `dbx`**. A ESP do WD_BLACK contém `systemd-boot` para as gerações NixOS. Ela também recebeu rEFInd para um teste temporário de escolha entre NixOS e Ubuntu: o menu apareceu uma vez via `BootNext`, que é descartado após o boot. O Ubuntu continua como padrão do firmware; para entrar no NixOS, selecione o WD_BLACK no setup/boot menu. Não há plano de manter um menu dual-boot permanente, pois o dual boot é temporário e o destino terá um único disco. Os arquivos do rEFInd ainda são copiados por `boot.loader.systemd-boot.extraFiles`, sem tocar na ESP do Samsung. `boot.loader.efi.canTouchEfiVariables = false` impede que rebuilds alterem a prioridade do firmware. Reativar Secure Boot impediria o boot sem assinar os programas EFI e kernels.

Para **apenas construir** o sistema, sem criar filesystem nem instalar:

```bash
make minipc-build
```

O perfil de VM segue independente (`make build`); sua senha conhecida e seu `sudo` sem senha não são importados pelo host real. O host real desabilita o servidor SSH de entrada. A conta `fwfurtado` precisa de senha definida com `passwd` no sistema alvo antes do primeiro login; não há credencial em claro nem hash de teste configurado para ela.

O mini-PC usa `America/Sao_Paulo` para exibir o horário local. O `systemd-timesyncd` permanece ativo para sincronizar automaticamente o relógio por NTP; `timedatectl status` mostra separadamente o fuso e o estado de sincronização.

### Instalação a partir do Ubuntu, sem USB

O [manual oficial](https://nixos.org/manual/nixos/stable/#sec-installing-from-other-distro) permite instalar diretamente a partir do Ubuntu. Depois de particionar e formatar **apenas o WD_BLACK confirmado**, monte os filesystems pelos rótulos. Use `/mnt/nixos`, porque `/mnt` já contém outros diretórios nesta máquina:

```bash
sudo mkdir -p /mnt/nixos
sudo mount /dev/disk/by-label/nixos-root /mnt/nixos
sudo mkdir -p /mnt/nixos/home /mnt/nixos/boot
sudo mount /dev/disk/by-label/nixos-home /mnt/nixos/home
sudo mount -o umask=0077 /dev/disk/by-label/nixos-esp /mnt/nixos/boot
```

Uma **chave age exclusiva do host já foi gerada**, adicionada a `.sops.yaml` e usada para cifrar os segredos. O arquivo privado está fora do Git, em `~/.local/state/nixos-config/minipc-age-key.txt` (0600). A chave foi salva no 1Password; a recuperação, a chave pública e a descriptografia de `secrets/sing-box-config.enc` foram testadas com `op run`. Provisionar a chave privada no destino antes de ativar os segredos:

```bash
sudo install -d -m 0700 /mnt/nixos/var/lib/sops-nix
sudo install -m 0600 ~/.local/state/nixos-config/minipc-age-key.txt /mnt/nixos/var/lib/sops-nix/key.txt
```

Compare a saída de `nixos-generate-config --root /mnt/nixos --show-hardware-config` com `hosts/minipc/default.nix`, sem importar definições duplicadas de filesystem. A configuração inclui os módulos detectados `thunderbolt` e `kvm-amd` e o microcódigo AMD. Construa a geração e instale exatamente essa geração com as ferramentas do mesmo `nixpkgs` pinado:

```bash
make minipc-build
tools=$(nix-build --no-out-link --option extra-experimental-features 'nix-command flakes' \
  ./minipc.nix -A pkgs.nixos-install-tools)
sudo env PATH="$tools/bin:$PATH" "$tools/bin/nixos-install" --root /mnt/nixos \
  --system "$(readlink -f result-minipc)" --no-channel-copy --no-root-password
sudo env PATH="$tools/bin:$PATH" "$tools/bin/nixos-enter" --root /mnt/nixos \
  -c '/nix/var/nix/profiles/system/sw/bin/passwd fwfurtado'
```

Defina a senha **interativamente no terminal local**, nunca no Git ou no chat. A instalação feita com `--no-root-password` depende da conta `fwfurtado` (grupo `wheel`) para administração. `nixos-install` gravou `EFI/BOOT/BOOTX64.EFI` e entradas de gerações em `loader/entries/` na ESP nova. O primeiro boot e login no NixOS funcionaram. O conteúdo de `~/projects/` e `~/Pictures/wallpapers/` foi copiado do Ubuntu para o `/home` do NixOS preservando arquivos já existentes; o Ubuntu continua como recuperação durante a migração.

O firmware mostrou o WD_BLACK inicialmente apenas como `UEFI OS` (Boot0004, fallback). A entrada direta `NixOS WD_BLACK` (Boot0001) apontou para `\EFI\systemd\systemd-bootx64.efi` e funcionou no teste via `BootNext`. A entrada rEFInd (Boot0005) também foi testada com `BootNext`: como esperado, apareceu uma vez e não substituiu a prioridade permanente do Ubuntu (Boot0002). Para alternar entre os sistemas nesta fase, use o seletor de disco do firmware; não é necessário alterar `BootOrder`.

### Desktop

NixOS e Linux standalone usam Niri e Noctalia. O NixOS instala sessão, portal e greeter no sistema; Home Manager configura Niri e Noctalia Shell. O agente Polkit nativo do Noctalia substitui `hyprpolkitagent`. A luz noturna nativa substitui `wl-gammarrelay`, com localização aproximada por IP via `noctalia.dev` ([política do serviço](https://noctalia.dev/privacy)). Confira no primeiro login: Niri, Noctalia, autenticação Polkit, bloqueio de tela, portal de screencast, saídas de vídeo e desbloqueio do 1Password.

`noctalia msg greeter-sync` copia a aparência para `/var/lib/noctalia-greeter/` mediante autorização Polkit. O serviço de usuário do Noctalia coloca `/run/wrappers/bin` antes do perfil do sistema no `PATH`, para usar o `pkexec` setuid do NixOS; o binário sem wrapper em `/run/current-system/sw/bin` falha com `pkexec must be setuid root`. A sincronização foi confirmada pelos arquivos `sync.toml` e wallpapers no estado do greeter, sem encerrar a sessão para testar a tela de login.

O Dell Thunderbolt 4 Dock usa `services.hardware.bolt` no mini-PC. O dock foi pareado com `boltctl enroll --policy=auto` após autorização explícita: `boltctl list` confirma `authorized` e `stored`, e a interface Ethernet do dock aparece como `eth0` (sem cabo conectado no teste). O domínio USB4 reporta `iommu_dma_protection=0`; a autorização persistente confia nesse dock sem proteção DMA declarada. Até agora o Niri só detecta o monitor em `HDMI-A-1`, portanto vídeo via dock ainda não foi comprovado.

O prompt Starship é gerado por `home/fernando/programs/starship.nix` via Home Manager integrado ao NixOS. Após corrigir seu `format`, reconstrua e ative a geração do mini-PC para atualizar `~/.config/starship.toml`; abrir um novo Fish recarrega o prompt. As quebras de linha do prompt são literais (`\n` no Nix), sem barra invertida antes de cada módulo.

No Wayland, o Ghostty (GTK 4.20+) precisa de um método de entrada para compor dead keys. Um drop-in de sua unidade systemd define `GTK_IM_MODULE=simple` apenas para o Ghostty; a mudança só alcança janelas novas após reiniciar a unidade, o que fecha as janelas atuais.

A configuração Niri do NixOS replica teclado, mouse, layout, saídas `DP-1` (`5120x1440@119.999`) e `HDMI-A-1` (`5120x1440@59.977`) e os atalhos do ChezMoi. O primeiro login NixOS registrou `HDMI-A-1` com o modo solicitado; `DP-1` não estava conectado. Com o plugin `kenn/keybind-cheatsheet` instalado declarativamente, `Mod+Shift+Slash` abre novamente o mesmo cheatsheet do Ubuntu. As cores dinâmicas de `noctalia.kdl` ainda não são incluídas pelo Niri, pois o Home Manager valida `config.kdl` na store antes de o Noctalia gerar esse arquivo; as regras de janela do Noctalia no NixOS permanecem explícitas. As duas fontes não se atualizam automaticamente.

No mini-PC, `home/fernando/desktop/noctalia-settings.toml` declara o snapshot de `~/.local/state/noctalia/settings.toml` do Ubuntu, exceto a chave do Wallhaven. O Home Manager mantém as definições NixOS preexistentes de inatividade, luz noturna e lançamento de aplicativos como serviços systemd. `noctalia-plugins.nix` instala fontes pinadas dos cinco plugins, desativa atualizações automáticas dessas fontes e fornece Python com NumPy, ONNX Runtime e Pillow ao serviço Noctalia. O Wallpaper Depth ainda requer a instalação inicial do modelo de 99 MB pelo painel do plugin; os diretórios de wallpapers em `~/Pictures/wallpapers/` devem continuar presentes no NixOS. Alterações feitas pela UI em `~/.local/state/noctalia/settings.toml` têm precedência sobre os arquivos declarados.

No WD, o estado Noctalia anterior foi preservado em `~/.local/state/noctalia/settings.toml.pre-declarative`. Os overrides que escondiam a tela de bloqueio, templates e wallpapers declarados foram removidos de `settings.toml`; permanece `config_version = 15`. Isso é uma migração única da instalação, não uma limpeza automática a cada ativação.

O Home Manager instala Google Chrome (atalho `Mod+Shift+Return`), Zed, Slack e Obsidian; GitHub CLI, fzf, fd, mergiraf e ec já estavam declarados. Os módulos do host ativam o aplicativo e o CLI do 1Password. Beekeeper Studio não foi incluído: o pacote `beekeeper-studio-6.1.4` deste pin foi marcado pelo nixpkgs como inseguro devido ao Electron 39.8.10 fora de suporte, e o proprietário escolheu aguardar uma versão corrigida.

No mini-PC, `environment.systemPackages` fornece `bd` (Beads), `omp`, `docker`, `xh`, `make` e `kubectl`. O pacote `docker-client` inclui Docker Compose e Buildx; **não** ativa um daemon local nem concede ao usuário acesso ao socket Docker. Para executar contêineres localmente, a configuração do serviço e suas permissões precisam de uma decisão separada.

### Segredos e túnel SSH

A configuração e a tabela de hosts do sing-box ficam cifradas em `secrets/sing-box-{config,hosts}.enc`; sops-nix disponibiliza os arquivos somente ao usuário de sistema `sing-box` em `/run/secrets`. Como a instalação escolhida não usa LUKS, acesso físico ao disco ainda expõe a chave age local. Não versionar tokens de sessão nem exportá-los ao ambiente global do `systemd --user`; **rotacione os tokens exibidos pela configuração antiga antes de migrá-los**.

Após login e desbloqueio do 1Password, `vpn-proxy.service` usa `autossh` com o alias SSH `vpn-proxy` para abrir SOCKS em `127.0.0.1:1080`. A diretiva SSH `User` fica cifrada em `secrets/vpn-proxy-user.enc`: o alias inclui o arquivo decifrado por sops-nix somente em tempo de execução, sem registrar o usuário no módulo Nix ou nos argumentos do serviço. No NixOS, sops-nix o entrega ao usuário `fwfurtado` em `/run/secrets/vpn-proxy-user`; no Linux standalone, sops-nix do Home Manager o entrega em `$XDG_RUNTIME_DIR/secrets.d` e precisa da chave age em `~/.config/sops/age/keys.txt`. Exporte **somente a chave pública** da chave exclusiva do túnel no 1Password para `~/.ssh/vpn-proxy.pub`, autorize-a no Mac e confira a fingerprint SSH do Mac. Antes de o túnel funcionar, as rotas corporativas do `sing-box` que dependem desse SOCKS não estarão acessíveis. `active (running)` não comprova a conexão: teste o SOCKS e uma rota corporativa permitida.

O token Wallhaven está cifrado em `secrets/noctalia-wallhaven.enc` para o usuário e para o mini-PC. sops-nix entrega o TOML somente a `fwfurtado` em `/run/secrets/noctalia-wallhaven` (0400); um symlink gerado pelo Home Manager aponta para esse arquivo em `~/.config/noctalia/zz-wallhaven-secret.toml`. O valor não é interpolado em Nix nem copiado para a store. O arquivo Ubuntu `~/.local/state/noctalia/settings.toml` continua contendo o token em texto claro; como o valor também foi exibido nesta conversa, rotacione-o no Wallhaven e recifre o segredo antes de tratá-lo como protegido.

### Home Manager standalone

No Ubuntu/Fedora, a sessão Niri de `standalone-system.nix` requer Home Manager desktop ativado para o usuário antes do switch do System Manager. A unidade `vpn-proxy.service` do Home Manager é opcional no standalone (`HOME_TAILNET_PROXY=true`). Antes de ativá-la no Ubuntu, pare/desative qualquer unidade já existente que ocupe a porta 1080, para evitar dois túneis concorrentes; não altere o serviço em execução apenas para fazer um build. O segredo de usuário precisa estar decifrável pela chave age local cadastrada como destinatária na `.sops.yaml`. Não executar `make system-switch` nem reiniciar o greeter como parte deste build. No macOS e no Linux CLI, o desktop continua opcional. Configurações de usuário migradas do ChezMoi saem daquele gestor por grupos, sem dupla posse do mesmo arquivo.

No macOS, o Home Manager escreve a configuração do Ghostty, mas o pacote Nix fixado não suporta Darwin; instale o aplicativo nativo separadamente. O perfil macOS não importa Niri nem serviços de Linux.

O Home Manager instala o lockfile editável do Neovim sem acessar a rede durante a ativação. O `vim.pack.add` baixa os plugins quando o Neovim é aberto pela primeira vez; atualizações posteriores são feitas no próprio editor, não no boot.
>>>>>>> 5decb96 (feat(nixos): add mini-PC desktop and services)

Os plugins públicos do `vim.pack.add` são buscados por HTTPS. A configuração Git não converte clones `https://github.com/` para SSH; apenas os pushes correspondentes usam `git@github.com:`. Assim, o primeiro início do Neovim não depende de chave SSH nem de `known_hosts` do GitHub.

O `nvim-treesitter` compila parsers na primeira abertura do editor. O ambiente do Neovim inclui `tree-sitter` CLI e `gcc` em `extraPackages`; eles não precisam estar no `PATH` global do shell.


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

No Linux e macOS, Home Manager gerencia a configuração de usuário migrada; os arquivos já assumidos por ele devem sair do ChezMoi em cada máquina para evitar conflito de ativação.
