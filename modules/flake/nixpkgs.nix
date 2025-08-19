{
  inputs,
  lib,
  withSystem,
  settings,
  ...
}:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = (
        import inputs.nixpkgs {
          inherit system;
          overlays =
            lib.pipe inputs.import-tree [
              (i: i.map (path: import path))
              (i: i.addPath settings.overlaysPath)
              (i: i.withLib lib)
              (i: i.files)
            ]
            ++ [ inputs.self.overlays.default ];
        }
      );

      pkgsDirectory = settings.packagesPath;
    };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      {
        local = config.packages;
      }
    );
}
