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

      configDir = "\${XDG_CONFIG_HOME:-$HOME/.config}/shrimpternet";
      cacheDir = "\${XDG_CACHE_HOME:-$HOME/.cache}/shrimpternet";
      blogsDir = "${cacheDir}/blogs";
      blogsSourceFile = "${configDir}/blogs.txt";
      metaFile = "${cacheDir}/meta.json";

      helpText = ''
        ========= Shrimpternet =========
        Available commands:
          run    - Runs the Shrimpternet
          update - Crawls the Internet and updates Shrimpternet
        ================================
      '';

      webAssets = pkgs.stdenv.mkDerivation {
        name = "shrimp-web-assets";
        src = builtins.path {
          path = ./web;
          name = "shrimp-web-source";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./* $out/
        '';
      };

      runBinary =
        pkgs.runCommandCC "shrimp-run-bin" {
          src = ./server;
        } ''
          mkdir -p $out/bin
          cd "${./server}"
          $CC $src/*.c -O2 -o $out/bin/shrimp-run
        '';

      runCommand = pkgs.writeShellApplication {
        name = "shrimp-run";
        runtimeInputs = [runBinary];
        text = ''shrimp-run "${cacheDir}" "${webAssets}"'';
      };

      updateCommand = pkgs.writeShellApplication {
        name = "shrimp-update";
        text = ''
          ${pkgs.httrack}/bin/httrack -%L "${blogsSourceFile}" \
            -O "${blogsDir}" \
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
            mkdir -p "${configDir}"
            mkdir -p "${cacheDir}"
            mkdir -p "${blogsDir}"

            if [ ! -f "${blogsSourceFile}" ]; then
              echo "${builtins.concatStringsSep "\n" blogs}" > "${blogsSourceFile}"
            fi

            if [ ! -f "${metaFile}" ]; then
              echo "{}" > "${metaFile}"
            fi

            # shellcheck disable=SC2016
            find "${blogsDir}" -mindepth 2 -maxdepth 2 -name index.html | while read -r file; do
              slug=$(basename "$(dirname "$file")")
              href=blogs/"$slug"/

              sed -E '/<base [^>]*>/d; s|(<head>)|\1\n    '"<base href=\"/$href\">"'|i' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

              title=$(${pkgs.pup}/bin/pup 'title text{}' < "$file" 2>/dev/null)
              description=$(${pkgs.pup}/bin/pup 'meta[name="description"] attr{content}' < "$file" 2>/dev/null)
              image=blogs/$(${pkgs.pup}/bin/pup 'head link[rel~="icon"], head link[rel~="shortcut icon"] attr{href}' < "$file" 2>/dev/null)

              ${pkgs.jq}/bin/jq -n \
                --arg slug "$slug" \
                --arg title "$title" \
                --arg description "$description" \
                --arg image "$image" \
                --arg href "$href" \
                '{slug: $slug, title: $title, description: $description, image: $image, href: $href}'
            done | ${pkgs.jq}/bin/jq --null-input --rawfile orig "${metaFile}" '
              ($orig | fromjson | .blogs // []) + [inputs]
              | { blogs: (INDEX(.[]; .slug) | [ .[] ]) }
            ' > "${metaFile}.tmp" && mv "${metaFile}.tmp" "${metaFile}"

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
