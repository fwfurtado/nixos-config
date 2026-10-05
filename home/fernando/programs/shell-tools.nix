{ ... }:
{
  programs.bat.enable = true;
  programs.fd.enable = true;
  programs.ripgrep.enable = true;
  programs.eza.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.yazi = {
    enable = true;
    # A custom `y` function adds zoxide keyword lookup and cwd handoff.
    enableFishIntegration = false;
  };
}
