{ ... }:
{
  # The proxy domain rule-set and hosts table remain encrypted at rest.
  sops.secrets."sing-box-domains-proxy" = {
    sopsFile = ../../secrets/sing-box-domains-proxy.enc;
    format = "binary";
    owner = "sing-box";
    group = "sing-box";
    mode = "0400";
    restartUnits = [ "sing-box.service" ];
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
