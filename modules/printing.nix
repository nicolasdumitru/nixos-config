{
  driverPackages ? [ ],
}:

{
  lib,
  ...
}:

{
  services.printing = {
    enable = true;
    drivers = lib.mkAfter driverPackages;
  };
}
