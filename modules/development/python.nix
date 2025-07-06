{
  pkgs,
  ...
}:

{
  system.extraDependencies = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        # Libraries
        numpy
        scipy
        pandas
        torchWithCuda
        scikit-learn
        matplotlib

        # Tooling
        python-lsp-server
        jupyter
      ]
    ))

    # Tooling
    pyright
    black
  ];
}
