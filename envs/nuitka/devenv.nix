{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    python312Packages.python
    python312Packages.nuitka
  ];
}
