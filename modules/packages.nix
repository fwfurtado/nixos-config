{ pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
      chezmoi
      git
      neovim
      ghostty
      ripgrep
      fd
    ];
}
