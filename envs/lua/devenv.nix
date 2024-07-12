{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = with pkgs; [
    lua54Packages.lua
    lua54Packages.luafilesystem
    stylua
  ];
}
