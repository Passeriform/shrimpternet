{pkgs}: let
  cwalk = pkgs.fetchFromGitHub {
    owner = "likle";
    repo = "cwalk";
    rev = "v1.2.9";
    sha256 = "sha256-alNhKXDbtYA8jyUo6RvJuouS3tzYSgN+BNBykfgqX/k=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "shrimp";
    version = pkgs.lib.fileContents ../VERSION;

    src = ./..;
    nativeBuildInputs = [pkgs.makeWrapper];
    strictDeps = true;

    doCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;

    buildPhase = ''
      mkdir -p server/bin

      cp -r ${cwalk}/include/* server/include/
      cp -r ${cwalk}/src/* server/src/

      $CC -O2 -Wall -Wextra -fsanitize=address,undefined \
        -Iserver/include \
        $(find server/src -name '*.c') \
        -o server/bin/serve
    '';

    checkPhase = ''
      $CC -g -Wall -Wextra -fsanitize=address,undefined \
        -Iserver/include \
        $(find server/src -name '*.c' -not -name 'main.c') \
        server/tests/test.c \
        -o run_tests

      ./run_tests
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/assets

      # Server
      cp server/bin/serve $out/bin/
      cp -r server/assets $out/share/

      # Scripts
      for script in scripts/*.sh; do
        install -Dm755 -t $out/libexec/ $script
      done
    '';

    postFixup = let
      binPath = pkgs.lib.makeBinPath [
        "$out"
        pkgs.pup
        pkgs.wget2
        pkgs.yt-dlp
      ];
    in ''
      for script in $out/libexec/*; do
        name=$(basename "$script" .sh)
        makeWrapper "$script" $out/bin/$name \
          --prefix PATH : ${binPath}
      done
    '';
  }
