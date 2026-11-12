# Import from the bare-metal host only. The VM and Ubuntu System Manager do not run this service.
{ config, ... }:

{
  services.sing-box = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./sing-box.json);
  };

  # The private hosts table remains outside the world-readable Nix store.
  environment.etc."sing-box/hosts.mgmt".source = config.sops.secrets."sing-box-hosts".path;
}
