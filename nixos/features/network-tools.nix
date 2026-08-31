{ pkgs, ... }:

{
  programs.mininet.enable = true;
  programs.wireshark = {
    enable = true;
    usbmon.enable = true;
    dumpcap.enable = true;
  };
  users.users.nick.extraGroups = [ "wireshark" ];

  environment.systemPackages = with pkgs; [
    wireshark
    netcat-gnu
    cachix
  ];
}
