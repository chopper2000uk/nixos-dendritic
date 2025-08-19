{ default, ... }:
let
  modules = default.modules.nixos;

  getModule = path: default.getAttr modules path;
  getModules = prefix_or_paths: default.getModules "nixos." prefix_or_paths;
  getRole = role: getModule ("roles/" + role);
  getRoles = roles: getModules "roles/" roles;
  getFeature = features: getModule ("features/" + features);
  getFeatures = features: getModules "features/" features;

  # aliases
  withModules = getModules;
  withRoles = getRoles;
  withFeatures = getFeatures;

  perModule = fn: builtins.map fn withModules;
  perRole = fn: builtins.map fn withRoles;
  perFeature = fn: builtins.map fn withFeatures;

in
{
  _module.args.nixos = {
    inherit
      modules
      getModule
      getModules
      getRole
      getRoles
      getFeature
      getFeatures
      withModules
      withRoles
      withFeatures
      perModule
      perRole
      perFeature
      ;
  };
}
