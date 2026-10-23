{ pkgs, ... }:
{
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
}
