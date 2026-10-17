{
  description = "A template for Rust projects using cargo-generate.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-z = {
      url = "https://flakehub.com/f/ejpcmac/git-z/*";
      inputs.nixpkgs.follows = "nixpkgs";
      # NOTE: Use the latest rust-overlay, compatible with the latest nixpkgs.
      inputs.rust-overlay.follows = "rust-overlay";
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

          # NOTE: nixpkgs builds cargo-generate without its default features,
          # disabling Git support, which we want back.
          cargo-generate = pkgs.cargo-generate.overrideAttrs {
            cargoBuildNoDefaultFeatures = false;
            doCheck = false;
          };
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
              inotify-tools
              rsync
            ];
          };
        };
    };
}
