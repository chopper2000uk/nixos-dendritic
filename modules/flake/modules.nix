{ lib, moduleLocation, ... }:
let
  inherit (lib) mapAttrs mkOption types;
  inherit (lib.strings) escapeNixIdentifier;

  addInfo =
    class: moduleName:
    let
      keyPrefix = "${toString moduleLocation}#modules";
      key = keyPrefix + ".${escapeNixIdentifier class}.${escapeNixIdentifier moduleName}";
    in
    if class == "generic" then
      module: module
    else
      module: {
        inherit key;
        _class = class;
        _file = key;
        imports = [
          module

          # import perModule
          {
            imports = [
              {
                _modulesManifest = [ moduleName ];
              }
            ];
          }

          # import once via key
          {
            key = keyPrefix;
            imports = [
              {
                options._modulesManifest = lib.mkOption {
                  type = with lib.types; listOf str;
                };
              }
            ];
          }
        ];
      };
in
{
  options = {
    flake.modules = mkOption {
      type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
      apply = mapAttrs (k: mapAttrs (addInfo k));
    };
  };
}
