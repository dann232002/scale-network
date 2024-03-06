{ config, pkgs, lib, ... }:
{


  # ZFS uniq system ID
  # to generate: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "6333bc40";

  networking = {
    # use systemd.networkd
    useNetworkd = true;
    useDHCP = false;

    # Needed for supporting nat
    firewall = {
      enable = true;
      extraCommands = lib.mkMerge [ (lib.mkAfter ''
        iptables -w -t nat -A nixos-nat-post -s 10.0.3.0/24 -o eno1 -j MASQUERADE
      '') ];
    };
    # Set this to control sysctl: net.ipv4.ip_forward and net.ipv6.conf.all.forwarding
    # instead in systemd.network via IPForward on any interface
    # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html#IPForward=
    nat.enable = true;
  };

  systemd.network = {
    enable = true;
    netdevs.virbr0.netdevConfig = {
      Kind = "bridge";
      Name = "virbr0";
    };

    networks = {
      "1-virbr0" = {
        matchConfig.Name = "virbr0";
        enable = true;
        #networkConfig.DHCP = "yes";
        address = [ "10.0.3.1/24" "10.0.3.20/24" "2001:470:f026:103::20/64" ];
        #gateway = [ "10.0.3.1" ];
        #[Route]
        #Gateway=192.168.0.10
        #Destination=10.0.0.0/8
        #GatewayOnlink=yes
      };
      "20-microvm-eth0" = {
        matchConfig.Name = "vm-*";
        networkConfig.Bridge = "virbr0";
      };
      "10-lan-eno2" = {
        matchConfig.Name = "eno2";
        networkConfig.Bridge = "virbr0";
      };
      # Keep this for troubleshooting
      "10-lan" = {
        matchConfig.Name = "eno1";
        enable = true;
        networkConfig = {
          DHCP = "yes";
          IPMasquerade = "both";
        };
      };
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    tio
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
