{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    luajit
    luajitPackages.luafilesystem
  ];
}
