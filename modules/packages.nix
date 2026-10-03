{ pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
      chezmoi
      fish
      git
      neovim
      ripgrep
      fd

      starship
      zoxide
      direnv
      atuin
      bat
      sd
      fzf
      atuin
      yazi
    ];
}
