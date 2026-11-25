{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    beads
    omp
    docker-client
    xh
    gnumake
    kubectl
    sops
    tcpdump
    bind.dnsutils
    bubblewrap
    glib.bin
    (callPackage ../../packages/tern-stencil.nix { })
  ];

  # uv installs Python wheels outside Nix; native extensions need libstdc++ at runtime.
  environment.sessionVariables.LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";

  # Keep the original package on PATH so its fish completion stays available.
  home-manager.users.fwfurtado.programs.fish.functions.omp = {
    description = "Run OMP with the NixOS CA bundle";
    body = ''
      set -lx SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
      command omp $argv
    '';
  };

  programs._1password-gui.enable = true;
  programs._1password.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg)
      [ "1password" "1password-cli" "databricks-cli" "google-chrome" "slack" "obsidian" "rtk" "tern-stencil" "v4l-utils" "obsbot-libdev" "chatgpt" ];

  programs.nix-ld.enable = true;
}
