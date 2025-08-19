{ config, lib, ... }:
let
  modules = config.flake.modules;

  getAttr = set: path: lib.attrsets.getAttrFromPath (lib.strings.splitString "." path) set;
  getAttrs =
    set: prefix: paths:
    builtins.map (path: getAttr set (prefix + path)) paths;
  getAttrs' =
    set: prefix: prefix_or_paths:
    if builtins.isString prefix_or_paths then
      getAttrs' set (prefix + prefix_or_paths)
    else
      getAttrs set prefix prefix_or_paths;

  getModule = path: getAttr modules path;
  getModules =
    prefix_or_paths:
    if builtins.isString prefix_or_paths then
      getAttrs' modules prefix_or_paths
    else
      getAttrs' modules "" prefix_or_paths;

  # alias
  withModules = getModules;

  perModule = fn: builtins.map fn withModules;

in
{
  _module.args.default = {
    inherit
      modules
      getAttr
      getAttrs
      getAttrs'
      getModule
      getModules
      withModules
      perModule
      ;
  };
}
