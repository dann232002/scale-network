{ lib, pkgs, inputs, ... }:
let
  chomp = "503";
  prefix = "2001:470:f026:${chomp}";
  routerAddr = {
    ipv6 = "${prefix}::1";
    ipv4 = "10.128.3.1";
  };
in
{
  boot = {
    # For now copying from
    # https://github.com/NixOS/nixos-hardware/blob/master/pcengines/apu/default.nix
    # Initially for booting had to follow this: https://gist.github.com/tomfitzhenry/35389b0907d9c9172e5d790ca9e0d0dc
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty1"
    ];

    kernel.sysctl = {
      # if you use ipv4, this is all you need
      # especially for masq NAT
      "net.ipv4.conf.all.forwarding" = true;
      # since this is a router we need to set enable ipv6 forwarding or radvd will complain
      "net.ipv6.conf.all.forwarding" = true;
    };
  };



  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      extraCommands = lib.mkMerge [
        (lib.mkAfter ''
          iptables -w -t nat -A nixos-nat-post -s 10.128.3.0/24 -o enp1s0 -j MASQUERADE
        '')
      ];
    };

  };
  systemd.network = {
    enable = true;
    networks = {
      "01-enp1s0" = {
        name = "enp1s0";
        enable = true;
        networkConfig = {
          DHCP = "yes";
          IPMasquerade = "both";
        };
      };
      "01-enp2s0" = {
        name = "enp2s0";
        enable = true;
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = false;
        };
        address = [ "${routerAddr.ipv6}/64" "${routerAddr.ipv4}/24" ];
        ipv6AcceptRAConfig = {
          UseAutonomousPrefix = true;
        };
      };
    };
  };
  services.radvd.enable = true;
  services.radvd.config =
    ''
      interface eth1 {
        AdvSendAdvert on;
        # M Flag
        AdvManagedFlag on;
        # O Flag
        AdvOtherConfigFlag on;
        # ULA prefix (RFC 4193).
        prefix ${prefix}::/64 {
          AdvOnLink on;
        };
      };
    '';
}
