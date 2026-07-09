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

      cacheDir = "\${XDG_CACHE_HOME:-$HOME/.cache}/shrimpternet";
      collectionDir = "${cacheDir}/collection";
      blogListFile = "${cacheDir}/blog.txt";

      helpText = ''
        ========= Shrimpternet =========
        Available commands:
          run    - Runs the Shrimpternet
          update - Crawls the Internet and updates Shrimpternet
        ================================
      '';

      runBinary = pkgs.runCommandCC "shrimp-run-bin" {} ''
        mkdir -p $out/bin
        cd "${./server}"
        $CC *.c -O2 -o $out/bin/shrimp-run
      '';

      runCommand = pkgs.writeShellApplication {
        name = "shrimp-run";
        runtimeInputs = [runBinary];
        text = ''shrimp-run "${collectionDir}"'';
      };

      updateCommand = pkgs.writeShellApplication {
        name = "shrimp-update";
        runtimeInputs = [pkgs.httrack];
        text = ''
          httrack -%L "${blogListFile}" \
            -O "${collectionDir}" \
            -%u0 -N0 -C1 -v \
            --max-rate=10000000 \
            --sockets=8 \
            --keep-alive
        '';
      };

      shrimp = {blogs ? []}:
        pkgs.writeShellApplication {
          name = "shrimp";
          runtimeInputs = [runCommand updateCommand];
          text = ''
            mkdir -p "${cacheDir}"
            mkdir -p "${collectionDir}"

            if [ ! -f "${blogListFile}" ]; then
              cat << EOF > "${blogListFile}"
              ${builtins.concatStringsSep "\n" blogs}
            EOF
            fi

            if [ $# -lt 1 ]; then
              exec "${updateCommand}/bin/shrimp-update" && "${runCommand}/bin/shrimp-run"
            fi

            SUBCOMMAND="$1"
            shift

            case "$SUBCOMMAND" in
              run)
                exec "${runCommand}/bin/shrimp-run"
                ;;
              update)
                exec "${updateCommand}/bin/shrimp-update"
                ;;
              help)
                echo "${helpText}"
                ;;
              *)
                echo "Unknown subcommand: $SUBCOMMAND" >&2
                echo ""
                echo "${helpText}"
                exit 1
                ;;
            esac
          '';
        };
    in {
      default = pkgs.callPackage shrimp {};
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
      shrimp = self.packages.${system}.default.override {inherit blogs;};
    in {
      default = pkgs.mkShell {
        packages =
          [shrimp]
          ++ (with pkgs; [
            alejandra
            statix
            deadnix
            nil
            nixd
          ]);

        shellHook = ''
          export VSCODE_PROFILE="${profile}";
          shrimp help
        '';
      };
    });
  };
}
