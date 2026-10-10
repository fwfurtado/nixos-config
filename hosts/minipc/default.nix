{ lib, pkgs, ... }:
{
  imports = [
    ../../modules
    ../../modules/services/system/sing-box.nix
  ];

  networking.hostName = "fw-minipc";
  time.timeZone = "America/Sao_Paulo";

  # Only WD_BLACK SN7100 (serial 254432804382) was repartitioned for NixOS.
  # NVMe numbers can swap across reboots; labels select this disk's filesystems,
  # never the Ubuntu ESP on Samsung SSD 980 PRO (serial S76ENU0XA00371M).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos-home";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos-esp";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-amd" ];
    loader.systemd-boot = {
      enable = true;
      # rEFInd chooses between the two ESPs; systemd-boot keeps NixOS generations.
      extraFiles = {
        "EFI/refind/refind_x64.efi" = "${pkgs.refind}/share/refind/refind_x64.efi";
        "EFI/refind/refind.conf" = ./refind.conf;
      };
    };
    loader.efi = {
      efiSysMountPoint = "/boot";
      # Install boot files on our ESP; manage UEFI entries separately from Ubuntu.
      canTouchEfiVariables = false;
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics.enable = true;
  };

  # Pair approved USB4/Thunderbolt docks; never auto-authorize unknown devices.
  services.hardware.bolt.enable = true;
  zramSwap.enable = true;

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

  # No copy of the VM's known password or passwordless wheel policy.
  users.users.fwfurtado = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    beads
    omp
    docker-client
    xh
    gnumake
    kubectl
  ];

  programs._1password-gui.enable = true;
  programs._1password.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg)
      [ "1password" "1password-cli" "google-chrome" "slack" "obsidian" ];

  # Only outgoing SSH is needed by the SOCKS tunnel; don't expose VM's
  # password-authenticated sshd on this host.
  services.openssh.enable = lib.mkForce false;
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];

  system.stateVersion = "26.05";
}
