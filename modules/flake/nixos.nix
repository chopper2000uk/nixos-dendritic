{
  inputs,
  lib,
  config,
  withSystem,
  settings,
  ...
}:
let
  _config = config;
in
{
  options.configurations.nixos =
    let
      nixosConfigModule =
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            platform = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
            };
            host = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            users = lib.mkOption {
              type = with lib.types; attrsOf (listOf str);
            };
            roles = lib.mkOption {
              type = with lib.types; listOf str;
            };
          };
        };
    in
    lib.mkOption {
      type = with lib.types; attrsOf (submodule nixosConfigModule);
    };

  config.flake.nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
    _name: hostConfig:

    inputs.nixpkgs.lib.nixosSystem {

      # make flake-parts arguments available to nixos modules
      specialArgs =
        {
          inherit
            inputs
            hostConfig
            withSystem
            settings
            _config
            ;
        }
        // config._module.args.default
        // config._module.args.nixos;

      modules = [
        config.flake.modules.nixos.default
      ];
    }
  );
}
