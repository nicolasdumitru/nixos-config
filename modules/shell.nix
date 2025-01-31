{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    nushell
    fish
    starship
  ];
}
