inputs:
let
  inherit (inputs) self;
  inherit (inputs.nixpkgs-lib) lib;

  fileWrappers =
    modulesPath:
    import ./file-wrappers.nix {
      inherit lib modulesPath;
    };

  importTree =
    modulesPath:
    let
      wrap = (fileWrappers modulesPath).wrap;
    in
    (inputs.import-tree.map wrap) modulesPath;

  modules = importTree ./modules;

  mkFlake =
    {
      inputs ? { },
      specialArgs ? { },
      settings,
    }@args:
    let
      defaultSettings = rec {
        rootPath = settings.rootPath;
        modulesPath = rootPath + "/modules";
        overlaysPath = rootPath + "/overlays";
        packagesPath = rootPath + "/packages";
        debug = false;
      };
      settings = defaultSettings // args.settings;
    in
    self.inputs.flake-parts.lib.mkFlake
      {
        inputs = self.inputs // inputs;
        specialArgs = specialArgs // {
          inherit settings;
        };
      }
      {
        imports = [
          modules
          (importTree settings.modulesPath)
        ];
      };
in
{
  inherit
    modules
    fileWrappers
    importTree
    mkFlake
    ;
}
