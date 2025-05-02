{
  pkgs,
  ...
}:

{
  system.extraDependencies = with pkgs; [
    clang
    libcxx
    clangStdenv

    gcc
    glibc
    gccStdenv

    meson
    ninja

    clang-tools
  ];
}
