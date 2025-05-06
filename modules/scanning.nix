{
  scanUsers ? [ ],
  driverPackages ? [ ],
}:

{
  config,
  pkgs,
  lib,
  ...
}:

{
  hardware.sane = {
    enable = true;
    extraBackends = driverPackages;
  };

  users.users = lib.mkMerge (
    map (user: {
      ${user} = {
        extraGroups = lib.mkAfter [
          "scanner"
          "lp"
        ];
      };
    }) scanUsers
  );

  environment.systemPackages = with pkgs; [
    simple-scan
  ];
}
