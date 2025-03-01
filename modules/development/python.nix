{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        numpy
        torchWithCuda
        matplotlib
      ]
    ))
    pyright
    black
  ];
}
