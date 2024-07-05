{
  description = "Flake with multiple programming languages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # The set of systems to provide outputs for
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # A function that provides a system-specific Nixpkgs for the desired systems
      forAllSystems =
        f: nixpkgs.lib.genAttrs allSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      packages = forAllSystems (
        { pkgs }:
        {
          # Define environments for each programming language package
          gcc14 = pkgs.mkShell { buildInputs = [ pkgs.gcc14 ]; };

          ghc = pkgs.mkShell { buildInputs = [ pkgs.haskell.compiler.ghc ]; };

          go = pkgs.mkShell { buildInputs = [ pkgs.go ]; };

          julia-bin = pkgs.mkShell { buildInputs = [ pkgs.julia-bin ]; };

          lua54 = pkgs.mkShell { buildInputs = [ pkgs.lua54Packages.lua ]; };

          nodejs_22 = pkgs.mkShell { buildInputs = [ pkgs.nodejs_22 ]; };

          rustup = pkgs.mkShell { buildInputs = [ pkgs.rustup ]; };

          typescript = pkgs.mkShell {
            buildInputs = [
              pkgs.nodejs_22
              pkgs.nodePackages.typescript
            ];
          };
        }
      );
    };
}
