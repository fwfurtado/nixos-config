{ pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
      chezmoi
      fish
      git
      neovim
      ripgrep
      fd
    ];
}
