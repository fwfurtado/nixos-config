{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    beads
    omp
    docker-client
    xh
    gnumake
    kubectl
    glib.bin
    (callPackage ../../packages/tern-stencil.nix { })
  ];

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
      [ "1password" "1password-cli" "databricks-cli" "google-chrome" "slack" "obsidian" "rtk" "tern-stencil" "v4l-utils" "gitbutler" "but" "obsbot-libdev" ];

  programs.nix-ld.enable = true;
}
