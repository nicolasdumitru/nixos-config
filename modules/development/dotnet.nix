{
  pkgs,
  ...
}:

{
  # https://nix.dev/guides/faq#how-to-run-non-nix-executables
  programs.nix-ld.enable = true; # .NET needs this to work

  system.extraDependencies = with pkgs; [
    dotnetCorePackages.dotnet_9.sdk
    jetbrains.rider
  ];
}
