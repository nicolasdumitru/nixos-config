{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        # Libraries
        numpy
        scipy
        pandas
        torchWithCuda
        matplotlib

        # Tooling
        python-lsp-server
      ]
    ))

    # Tooling
    pyright
    black
  ];
}
