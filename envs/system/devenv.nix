{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    hyperfine
    difftastic
    gnumake
    time
  ];
}
