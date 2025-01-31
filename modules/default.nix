{
  desktop = import ./desktop.nix;
  development = {
    default = import ./development;
    c-cpp = import ./development/c-cpp.nix;
    python = import ./development/python.nix;
  };
  documents = import ./documents.nix;
}
