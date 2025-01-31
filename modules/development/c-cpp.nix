{
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    gcc
    glibc

    clang
    libcxx

    gnumake
    cmake

    clang-tools
    bear

    gdb
  ];

}
