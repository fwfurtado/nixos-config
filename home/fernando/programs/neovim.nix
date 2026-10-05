{ pkgs, ... }:
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

  xdg.configFile."nvim/nvim-pack-lock.json".source = ./neovim/nvim-pack-lock.json;
}
