{
  pkgs,
  ...
}:

{
  system.extraDependencies = with pkgs; [
    clang
    clangStdenv
    libcxx

    clang-tools

    gcc
    gccStdenv
    glibc

    gnumake
  ];
}
