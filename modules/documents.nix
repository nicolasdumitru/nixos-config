{
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    kdePackages.okular

    texliveFull
    texlab
    rubber

    git

    pandoc

    # libreoffice
  ];
}
