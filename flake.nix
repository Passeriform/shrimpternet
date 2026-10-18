{
  description = "Shrimpternet";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = import ./nix/package.nix {inherit pkgs;};
    });

    homeModules = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = import ./nix/hm.nix {inherit pkgs;};
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      profile = "c";
      blogs = [
        "alexwlchan.net"
        "www.passeriform.com"
        "kyrie25.dev"
        "heitorpb.github.io"
      ];
      playlists = [
        "PLekO4IUwUsw_Abt1W7smz1vaiaB8bZCMo"
      ];
      DEBUG_HOME = ".home";
    in {
      default = pkgs.mkShell {
        packages =
          [self.packages.${system}.default]
          ++ (with pkgs; [
            alejandra
            statix
            deadnix
            nil
            nixd
          ]);

        shellHook = ''
          shopt -s expand_aliases

          alias reload="rm -rf .direnv && cd .. && cd shrimpternet"

          export VSCODE_PROFILE="${profile}";

          setup_shrimp() {
            export SHRIMP_HOME="${DEBUG_HOME}";

            mkdir -p "${DEBUG_HOME}/.config/shrimpternet"
            mkdir -p "${DEBUG_HOME}/.cache/shrimpternet/blogs"
            mkdir -p "${DEBUG_HOME}/.cache/shrimpternet/youtube"
            echo "{}" > "${DEBUG_HOME}/.cache/shrimpternet/meta.json"

            echo "${builtins.concatStringsSep "\n" blogs}" > "${DEBUG_HOME}/.config/shrimpternet/blogs"
            echo "${builtins.concatStringsSep "\n" playlists}" > "${DEBUG_HOME}/.config/shrimpternet/youtube"
          }

          setup_shrimp
          shrimp help
        '';
      };
    });
  };
}
