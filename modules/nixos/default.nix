{
  withSystem,
  hostConfig,
  getModules,
  ...
}:
let
  hostModules = getModules "hosts/" [ hostConfig.host ];
  rolesModules = getModules "roles/" hostConfig.roles;
  usersModules = getModules "users/" (builtins.attrNames hostConfig.users);
in
{
  imports =
    [
      (withSystem hostConfig.platform (
        { pkgs, ... }:
        {
          nixpkgs = {
            inherit (pkgs) config overlays;
            hostPlatform = hostConfig.platform;
          };
        }
      ))
    ]
    ++ hostModules
    ++ usersModules
    ++ rolesModules;
}
