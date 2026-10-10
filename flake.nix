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
        "https://alexwlchan.net/"
        "http://www.catb.org/esr"
        "https://www.passeriform.com/"
        "https://kyrie25.dev/"
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
            export SHRIMP_HOME=".home";

            mkdir -p ".home/.config/shrimpternet"
            mkdir -p ".home/.cache/shrimpternet/blogs"
            mkdir -p ".home/.cache/shrimpternet/youtube"
            echo "{}" > ".home/.cache/shrimpternet/meta.json"

            echo "${builtins.concatStringsSep "\n" blogs}" > ".home/.config/shrimpternet/blogs"
            echo "${builtins.concatStringsSep "\n" playlists}" > ".home/.config/shrimpternet/youtube"
          }

          setup_shrimp
          shrimp help
        '';
      };
    });
  };
}
