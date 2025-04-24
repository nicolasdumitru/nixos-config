{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        numpy
        scipy
        torchWithCuda
        matplotlib
      ]
    ))
    pyright
    black
  ];
}
