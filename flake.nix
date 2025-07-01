{
  outputs = _: {
    __functor =
      _:
      inputs@{
        self ? inputs.self,
        nixpkgs ? inputs.nixpkgs,
        lib ? nixpkgs.lib,
        ...
      }:
      module:
      let
        extendedLib = (eval null).config.lib;
        eval =
          system:
          lib.evalModules {
            specialArgs = {
              inherit
                inputs
                system
                self
                nixpkgs
                ;
              lib = extendedLib;
            };
            modules = [
              module
              (
                { config, ... }:
                {
                  options = {
                    systems = lib.mkOption {
                      type = with lib.types; listOf str;
                      default = [ ];
                    };
                    outputs = lib.mkOption {
                      type = with lib.types; lazyAttrsOf anything;
                    };
                    ${system} = lib.mkOption {
                      type = with lib.types; lazyAttrsOf anything;
                      default = { };
                    };
                    lib = lib.mkOption {
                      type = with lib.types; lazyAttrsOf anything;
                    };
                  };
                  config = {
                    inherit lib;
                    _module = {
                      args.pkgs = lib.mkDefault nixpkgs.legacyPackages.${system};
                      freeformType = with lib.types; lazyAttrsOf anything;
                    };
                    outputs =
                      let
                        commonOutputs =
                          let
                            exclude = [
                              "_module"
                              "systems"
                              "outputs"
                              "lib"
                            ] ++ config.systems;
                          in
                          lib.removeAttrs config exclude;
                        systemOutputs = lib.pipe config.systems [
                          (map outputsForSystem)
                          (map lib.mkMerge)
                          lib.flatten
                        ];
                        outputsForSystem =
                          system:
                          lib.mapAttrsToList (output: value: { ${output}.${system} = value; }) (eval system).config.${system};
                        outputs = [ commonOutputs ] ++ systemOutputs;
                      in
                      lib.mkMerge outputs;
                  };
                }
              )
            ];
          };
      in
      (eval null).config.outputs;
  };
}
