# Packages a Python script as an executable. The script is linted at build time
# with flake8, set up the way black documents for code it formats: 88 columns,
# and without the two checks that contradict its style.
{ lib, pkgs }:

{
  name,
  src,
  # Programs the script runs, put first on its PATH.
  runtimeInputs ? [ ],
}:

let
  lint = pkgs.writeShellScript "${name}-lint" ''
    exec ${pkgs.python3Packages.flake8}/bin/flake8 --show-source \
      --max-line-length=88 --extend-ignore=E203,E701 "$1"
  '';
in
pkgs.writers.makeScriptWriter {
  interpreter = lib.getExe pkgs.python3;
  check = lint;
  makeWrapperArgs = lib.optionals (runtimeInputs != [ ]) [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath runtimeInputs)
  ];
} "/bin/${name}" (builtins.readFile src)
