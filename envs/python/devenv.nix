{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    python312Packages.autoflake
    python312Packages.black
    python312Packages.python
    python312Packages.isort
  ];
}
