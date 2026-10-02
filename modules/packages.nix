{ pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
      chezmoi
      git
      neovim
      ripgrep
      fd
    ];
}
