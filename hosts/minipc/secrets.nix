{ ... }:
{
  # SOPS decrypts into /run/secrets; neither internal routes nor hosts data
  # enter the world-readable Nix store.
  sops.secrets."sing-box-config" = {
    sopsFile = ../../secrets/sing-box-config.enc;
    format = "binary";
    owner = "sing-box";
    group = "sing-box";
    mode = "0400";
  };
  sops.secrets."sing-box-hosts" = {
    sopsFile = ../../secrets/sing-box-hosts.enc;
    format = "binary";
    owner = "sing-box";
    group = "sing-box";
    mode = "0400";
  };
  sops.secrets."vpn-proxy-user" = {
    sopsFile = ../../secrets/vpn-proxy-user.enc;
    format = "binary";
    owner = "fwfurtado";
    group = "users";
    mode = "0400";
  };
  sops.secrets."noctalia-wallhaven" = {
    sopsFile = ../../secrets/noctalia-wallhaven.enc;
    format = "binary";
    owner = "fwfurtado";
    group = "users";
    mode = "0400";
  };
}
