{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "zroot/local/root";
      fsType = "zfs";
    };

  # Originally was by-uuid but changed to by-label to make agnostic
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    {
      device = "zroot/local/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zroot/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "zroot/safe/persist";
      fsType = "zfs";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    efiSupport = true;
    device = "nodev";
    mirroredBoots =
      [
        {
          devices = [
            "/dev/disk/by-uuid/0001-B007"
          ];
          path = "/boot1";
        }
        {
          devices = [
            "/dev/disk/by-uuid/0002-B007"
          ];
          path = "/boot2";
        }
        {
          devices = [
            "/dev/disk/by-uuid/0003-B007"
          ];
          path = "/boot3";
        }
        {
          devices = [
            "/dev/disk/by-uuid/0004-B007"
          ];
          path = "/boot4";
        }
      ];
  };

  # ZFS uniq system ID
  networking.hostId = "74405d06";
}
