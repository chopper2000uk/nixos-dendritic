{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dendritic.url = "path:/home/colin/workspace/nixos-dendritic";
  };

  outputs =
    inputs:
    let
      settings = {
        rootPath = ./.;
      };
    in
    inputs.dendritic.mkFlake { inherit inputs settings; };
}
