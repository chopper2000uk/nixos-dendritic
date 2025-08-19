{ lib, modulesPath }:
let
  getFileArgValues = file: {
    currentFile = builtins.toString file;
    currentDir = builtins.dirOf file;
  };

  getModuleArgValues =
    file:
    let
      _matches = builtins.match ((builtins.toString modulesPath) + "/([^/]+)/?(.*)/(.+).nix") (
        builtins.toString file
      );
      _moduleDir = lib.lists.elemAt _matches 1;
      _moduleName = lib.lists.elemAt _matches 2;

      modulePath =
        if (_moduleDir == "") then
          if (!lib.strings.hasPrefix "-" _moduleName) then _moduleName else "default"
        else if (_moduleName == "default" || lib.strings.hasPrefix "-" _moduleName) then
          _moduleDir
        else if (lib.strings.hasPrefix "." _moduleName) then
          _moduleDir + _moduleName
        else
          _moduleDir + "/" + _moduleName;
    in
    {
      moduleClass = lib.lists.elemAt _matches 0;
      moduleName = builtins.baseNameOf modulePath;
      moduleDir = builtins.dirOf modulePath;
      inherit modulePath;
    };

  getNixosModuleArgValues =
    modules:
    let
      hasModule = module: builtins.any (m: builtins.match (module + "/.*") (m + "/") != null) modules;
      hasModules = modules: builtins.all hasModule modules;
      hasRole = role: hasModule ("roles/" + role);
      hasRoles = roles: builtins.all hasRole roles;
      hasFeature = feature: hasModule ("features/" + feature);
      hasFeatures = features: builtins.all hasFeature features;
    in
    {
      inherit
        hasModule
        hasModules
        hasRole
        hasRoles
        hasFeature
        hasFeatures
        ;
    };

  getNixosRoleModuleArgValues =
    moduleName: users:
    let
      roleUsers = lib.filterAttrs (_userName: roles: builtins.any (r: r == moduleName) roles) users;
      allUsers = builtins.attrNames roleUsers;
      perUser = fn: builtins.map fn allUsers;
    in
    {
      inherit allUsers perUser;
    };

  _wrap =
    {
      file,
      extraArgValues ? [ ],
    }:
    let
      fileContent = import file;
      wrapperArgs = fn: builtins.removeAttrs (lib.functionArgs fn) (builtins.attrNames extraArgValues);
      wrapperFn = fn: lib.setFunctionArgs (args: fn (args // extraArgValues)) (wrapperArgs fn);
    in
    if (lib.isFunction fileContent) then { imports = [ (wrapperFn fileContent) ]; } else fileContent;

  wrapFile =
    file:
    let
      isModule = lib.path.hasPrefix modulesPath file;
      extraArgValues = (getFileArgValues file) // lib.optionalAttrs isModule (getModuleArgValues file);
    in
    lib.setDefaultModuleLocation file (_wrap {
      inherit file extraArgValues;
    });

  wrapModule =
    file:
    let
      extraArgValues = (getFileArgValues file) // (getModuleArgValues file);
      inherit (extraArgValues) moduleClass modulePath;
    in
    lib.setDefaultModuleLocation file {
      flake.modules.${moduleClass}.${modulePath} = _wrap {
        inherit file extraArgValues;
      };
    };

  wrapNixosModule =
    file:
    let
      _extraArgValues = (getFileArgValues file) // (getModuleArgValues file);
      inherit (_extraArgValues) moduleClass modulePath;
    in
    lib.setDefaultModuleLocation file {
      flake.modules.${moduleClass}.${modulePath} =
        { config, ... }:
        let
          extraArgValues = _extraArgValues // (getNixosModuleArgValues config._modulesManifest);
        in
        _wrap {
          inherit extraArgValues file;
        };
    };

  wrapNixosRoleModule =
    file:
    let
      _extraArgValues = (getFileArgValues file) // (getModuleArgValues file);
      inherit (_extraArgValues) moduleClass modulePath moduleName;
    in
    lib.setDefaultModuleLocation file {
      flake.modules.${moduleClass}.${modulePath} =
        { config, hostConfig, ... }:
        let
          extraArgValues =
            _extraArgValues
            // (getNixosModuleArgValues config._modulesManifest)
            // (getNixosRoleModuleArgValues moduleName hostConfig.users);
        in
        _wrap {
          inherit extraArgValues file;
        };
    };

  wrap =
    file:
    let
      nixosModulePath = modulesPath + "/nixos";
      nixosRolesModulePath = nixosModulePath + "/roles";
    in
    if (lib.path.hasPrefix nixosRolesModulePath file) then
      wrapNixosRoleModule file
    else if (lib.path.hasPrefix nixosModulePath file) then
      wrapNixosModule file
    else
      wrapFile file;
in
{
  inherit
    wrap
    wrapFile
    wrapModule
    wrapNixosModule
    wrapNixosRoleModule
    ;
}
