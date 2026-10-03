{ pkgs, ... }:

{
  programs.fish.enable = true;

  users.mutableUsers = false;

  users.users.fernando = {
    isNormalUser = true;
    hashedPassword = "$6$nixostest$zYbTXkKr2RshAid5K9nha9HemsMiAZnclMsbtCPGfzFsKPft/A2x9aHI3iQhpcvSa5fx/OAmbXWmKavkxrRI1.";

    shell = pkgs.fish;

    extraGroups = [
        "wheel"
        "networkmanager"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
