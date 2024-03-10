{
  description = "A template for Rust projects using cargo-generate.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-z = {
      url = "github:ejpcmac/git-z";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];
      systems = [ "x86_64-linux" ];

      perSystem = { inputs', ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
          git-z = inputs'.git-z.packages.git-z;
        in
        {
          devshells.default = {
            name = "rust-template";

            motd = ''

              {202}🔨 Welcome to the rust-template devshell!{reset}
            '';

            packages = with pkgs; [
              # Tools
              cargo-generate
              git-z
            ];
          };
        };
    };
}
