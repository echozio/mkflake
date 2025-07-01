# mkFlake

## Usage
```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    mkFlake.url = "github:echozio/mkflake";
  };

  outputs =
    inputs:
    inputs.mkFlake inputs (
      {
        system,
        nixpkgs,
        pkgs,
        lib,
        ...
      }:
      {
        # use imports for modular flake outputs
        imports = [
          # ./packages.nix
        ];

        # specify what systems to target
        systems = [ "x86_64-linux" ];

        # lib can be extended modularly
        lib.fooBar = s: "foo ${s} bar";
        lib.fooBars = builtins.map lib.fooBar;
        lib.fooBarLines = lib.flip lib.pipe [
          lib.fooBars
          lib.concatLines
        ];

        # attributes under ${system} are mapped to <attribute>.${system}
        # in the final output
        ${system} = {
          # pkgs only works within ${system}
          packages.default = pkgs.writeShellScriptBin "test" ''
            echo ${
              lib.escapeShellArg (
                lib.fooBarLines [
                  "hello"
                  "world"
                ]
              )
            };
          '';
          formatter = pkgs.nixfmt-tree;
        };

        # outside ${system}, system is null
        foo = system; # == null

        # you can still create system-specific outputs as usual
        packages."x86_64-linux".hello =
          nixpkgs.legacyPackages."x86_64-linux".hello;

        # the top-level options _module, systems, output, lib and
        # ${system} (the values of the system option) are not included
        # in the ouputs by default as they are used internally, but can
        # be specified directly on the outputs option to override
        outputs.lib = lib;
      }
    );
}
```
