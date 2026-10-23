{ lib, pkgs, ... }:
{
  # nixpkgs pins an outdated source hash for omp 18.11.0; pin the current tag commit.
  nixpkgs.overlays = [
    (final: prev: {
      omp = prev.omp.overrideAttrs (_: {
        src = final.fetchFromGitHub {
          owner = "can1357";
          repo = "oh-my-pi";
          rev = "c2cb79e4c227aa4b22c4ccb933ff72fd88bceba4";
          hash = "sha256-pIAoAc3vE8nfVacsY+IEGcQVFCfMvVrK5qPcxi7NTho=";
        };
      });
    })
  ];

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
      [ "1password" "1password-cli" "databricks-cli" "google-chrome" "slack" "obsidian" "tern-stencil" ];

  programs.nix-ld.enable = true;
}
