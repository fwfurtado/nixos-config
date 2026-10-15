# Import from the bare-metal host only. The VM and Ubuntu System Manager do not run this service.
{ config, lib, ... }:

{
  services.sing-box.enable = true;

  # The encrypted configuration uses this absolute DNS hosts path. Keep the
  # file encrypted at rest and link to the decrypted runtime secret, not a
  # copy in the Nix store.
  environment.etc."sing-box/hosts.mgmt".source = config.sops.secrets."sing-box-hosts".path;

  # The native NixOS module supplies the sing-box system user, state directory,
  # upstream TUN capabilities and network-online ordering. Override only its
  # config source: settings = {} would otherwise load /etc/sing-box/config.json.
  systemd.services.sing-box.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${lib.getExe config.services.sing-box.package} -D /var/lib/sing-box -c ${config.sops.secrets."sing-box-config".path} run"
  ];
}
