{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    perl
    perl538Packages.PerlTidy
  ];
}
