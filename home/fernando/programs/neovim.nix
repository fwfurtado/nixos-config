{ config, lib, pkgs, ... }:
let
  packLock = "${./neovim/nvim-pack-lock.json}";
  lockPath = "${config.xdg.configHome}/nvim/nvim-pack-lock.json";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # This is application code rather than serializable preferences; keep Lua as
    # Lua while Home Manager owns installation and runtime dependencies.
    initLua = builtins.readFile ./neovim/init.lua;

    extraPackages = with pkgs; [
      ripgrep
      gopls
      rust-analyzer
      zls
      lua-language-server
      basedpyright
      ruff
    ];
  };

  # vim.pack.add writes the lock on first install. A Home Manager symlink into
  # the immutable store prevents that, so keep the managed copy writable.
  home.activation.neovimPackLock = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ -L ${lib.escapeShellArg lockPath} ]]; then
      case "$(${pkgs.coreutils}/bin/readlink ${lib.escapeShellArg lockPath})" in
        /nix/store/*) ;;
        *)
          echo "Refusing to replace a user-managed Neovim lockfile symlink" >&2
          exit 1
          ;;
      esac
    fi
    if [[ -L ${lib.escapeShellArg lockPath} ]] || ! ${pkgs.diffutils}/bin/cmp -s ${lib.escapeShellArg (toString packLock)} ${lib.escapeShellArg lockPath} || [[ ! -w ${lib.escapeShellArg lockPath} ]]; then
      run ${pkgs.coreutils}/bin/install -d ${lib.escapeShellArg "${config.xdg.configHome}/nvim"}
      run ${pkgs.coreutils}/bin/cp --remove-destination ${lib.escapeShellArg (toString packLock)} ${lib.escapeShellArg lockPath}
      run ${pkgs.coreutils}/bin/chmod 0644 ${lib.escapeShellArg lockPath}
    fi
  '';
}
