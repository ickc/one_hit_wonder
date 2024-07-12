{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    typescript
    nodejs
    nodePackages.prettier
  ];
}
