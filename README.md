# Nixos dendritic by convention

A variation of the Dendritic pattern, an attempting to reduce some of the boiler plate, by including some opinionated defaults and structure. Including a base nixpkgs configuration that supports packages via [pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts) and overlays. A module naming scheme that uses the filepaths to optionally group and name modules, and a structured layout of features and roles. Very much a prototype/work in progress, currently only supporting Nixos modules, so cross-cutting concerns aren't a consideration and much of the implementation could probably be done in a far better way. 

## What is the Dendritic pattern

Detailed documentation along with examples and discussions can be found at the following sites: 
  https://github.com/mightyiam/dendritic
  https://vic.github.io/dendrix/Dendritic.html  
  https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271/18

A brief overview would be that it's a 2 stage nix configuration pattern. In that all files are a flake-part modules, usually automatically imported via [import-tree](https://github.com/vic/import-tree). All of which are evaluate within the flake-parts scope, with some of the resulting output being attribute paths that are subsequently merged and passed into the nixos module build system as a second stage with a separate config scope. This allows the configuration built in the first stage to be accessible from other flake-part modules and to be used to generate the second stages configuration. There are a number advantages which are described in the previous links.

## Getting started 

Replace `{name}` where appropriate.

Copy the contents of the `template` directory.

Create `./modules/nixos/hosts/{machinename}.nix` and populate with the target machines configuration. If the module file grows too large break out into  either a feature `./modules/nixos/features/{featurename}.nix` and import:
```nix
{ withFeatures, ... }: {
  imports = withFeatures [
    "{featurename}"
  ];
}
``` 
or split the module `./modules/nixos/hosts/{machinename}.nix` to:
 - `./modules/nixos/hosts/{machinename}/default.nix`
 - `./modules/nixos/hosts/{machinename}/-{name}.nix`

Create `./modules/nixosConfigurations/{hostname}.nix` with
```nix
{ moduleName, ... }:
{
  configurations.nixos.${moduleName} = {
    host = {machinename};
    users = {
      {username} = [ ];
    };
    roles = [
      "base"
    ];
  };
}
```

Create `./modules/nixos/users/{username}.nix` with the users configuration. Again if module file grows too large break up as detailed for hosts.

Create `./modules/nixos/roles/base.nix` with the base role configuration. Role modules should be fairly thin, and should be split out to features or new roles, as opposed to splitting the module. They should also only depend/import roles that are the bare minimum for them to operate in isolation.

For an example look at https://github.com/chopper2000uk/nixos-dendritic-example


## project structure
```
├── modules
│   ├── nixos 
│   │   ├── features
│   │   ├── hosts
│   │   ├── roles
│   │   └── users
│   └── nixosConfiguration
├── overlays
├── packages
└── flake.nix
```

### flake.nix

#### settings

The default settings are as follows, with only `settings.rootPath = ./.;` required:

```nix
{
  rootPath = settings.rootPath;
  modulesPath = rootPath + "/modules";
  overlaysPath = rootPath + "/overlays";
  packagesPath = rootPath + "/packages";
  debug = false;
};
```

### modules

#### Optional arguments

All files that are under the `settings.modulesPath` are encapsulated in a function that makes a number of optional arguments available.

- currentFile = the filepath of the file.
- currentDir  = the directory of the file, the `dirOf currentFile`.  
- moduleName  = the name of the module, the `baseNameOf modulePath`.
- moduleDir   = the directory containing module, the `dirOf modulePath`.
- moduleClass = the first child directory of the `currentFile` under `settings.modulesPath`.
- modulePath  = the filepath after `moduleClass` without the '.nix' extension, unless the filename is `default.nix` or it starts with `-`, in which case it is that of its parent directory.


For example:

`./modules/nixos/roles/admin.nix`
```
 moduleClass = nixos
 modulePath  = roles/admin
 moduleName  = admin
 moduleDir   = roles
```

`./modules/nixos/features/terminal/apps/default.nix`
`./modules/nixos/features/terminal/apps/-git.nix`
```
 moduleClass = nixos
 modulePath  = features/terminal/apps
 moduleName  = apps
 moduleDir   = features/terminal
```

These can be used as argument to generate output, and don't need to be edited when moving files.

```nix
{ moduleName, ... }:
{
  configurations.nixos.${moduleName} = {
    ...
  };
}
```

### modules/nixosConfigurations

The nixosConfigurations binds the machine configuration `host`, the users and roles to a `hostname` for a nixosSystem.

```nix 
{
  configurations.nixos.${hostname} = {
    host = {machinename};    # host module name under `./modules/nixos/hosts`
    users = {
      {username} = [        # attributes of usernames that correspond to modules under `./modules/nixos/users`
         "base"             # list of roles that the username is passed to for additional configuration ie. extraGroups
      ];      
    };
    roles = [
      "base"                 # list of roles that correspond to modules under `./modules/nixos/roles`
    ];
  };
}
```

### modules/nixos

#### Naming scheme

Where flake-part modules usually consist of something like this:
```nix
{ lib, config, ... }:
{
  flake.modules.nixos."roles/base" = { config, ... }:
  {
    ...
  };
}

```

Which can be altered to use the module args with a filepath of `./modules/nixos/roles/base.nix`
```nix
{ lib, config, moduleClass, modulePath, ... }:
{
  flake.modules.${moduleClass}.${modulePath} = { config, ... }:
  {
    ...
  };
}

```

But for files under `./modules/nixos/` there is an additional automatic process that takes a `./modules/nixos/roles/base.nix`
```nix
{ config, ... }:
{
    ...  
}

```
And automatically wraps it assigning the contents to the property `flake.modules.${moduleClass}.${modulePath}`, whilst also making the flake-part arguments available to the nixos module. With the flake-parts `config` made available as `_config`. 


#### Module manifest

When each nixos flake module `flake.modules.nixos.` is imported as a nixos module for a nixosSystem, directly or indirectly imported from another module, its modulePath is added to that nixosSystems `config._modulesManifest` list. 

#### Optional arguments

All nixos modules additionally have the following optional arguments that make use of the `config._modulesManifest` to test if a module is included in the current configuration.

- hasModule   = true if the manifest contains the specified module. 
- hasModules  = true if the manifest contains the all the specified modules. 
- hasRole     = true if the manifest contains the specified role. 
- hasRoles    = true if the manifest contains the all the specified roles. 
- hasFeature  = true if the manifest contains the specified feature. 
- hasFeatures = true if the manifest contains the all the specified features. 

This can be used where one host imports a feature:
```nix 
{
  imports = withFeatures [ "hardware/amdgpu" ]; 
}
```

Another feature can conditionally extend the config based on its inclusion:
```nix
{ pkgs, lib, hasFeature, ... }:
{
  environment.systemPackages = with pkgs; [
    ...
  ] ++ lib.optional (hasFeature "hardware/amdgpu") pkgs.nvtopPackages.amd;
}
``` 

### modules/nixos/roles

#### Optional arguments

All nixos role modules under `./modules/nixos/roles` also get additional optional args on top of those provided for being a nixos module.
These are:
- allUsers = a list of users form the nixosCOnfiguration that have this role assigned to them.
- perUser  = maps allUsers to a provided function.

This allows the roles to handle things like the assignment of `users.extraGroups`.
For example with a `./modules/nixosConfiguration/test.nix`:
```nix
{ moduleName, ... }:
{
  configurations.nixos.${moduleName} = {
    host = ${moduleName};
    users = {
      testUser1 = [ "admin" ];
      testUser2 = [ ];
    };
    roles = [
      "base"
    ];
  };
}
```
The admin role can then create additional configuration just for those users:
`./modules/nixos/roles/admin.nix`
```nix
{ lib, withRoles, allUsers, perUser, ... }:
{
  imports = withRoles [ "base" ];

  users.users = lib.mergeAttrsList (
    perUser (userName: {
      ${userName}.extraGroups = [
        "wheel"
      ];
    })
  );

  nix.settings.trusted-users = allUsers;
}
```
