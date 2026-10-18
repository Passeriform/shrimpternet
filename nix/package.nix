{pkgs}:
pkgs.stdenv.mkDerivation {
  pname = "shrimp";
  version = pkgs.lib.fileContents ../VERSION;

  src = ./..;
  nativeBuildInputs = [pkgs.makeWrapper];
  dontBuild = true;
  strictDeps = true;

  doCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;

  checkPhase = ''
    $CC -g -Wall -Wextra -fsanitize=address,undefined \
      -Iserver \
      server/utility/*.c \
      server/tests/test.c \
      -o run_tests

    ./run_tests
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/assets

    # Server
    $CC -O2 -Wall -Wextra \
      -Iserver \
      server/utility/*.c \
      server/main.c \
      -o serve
    cp serve $out/bin/
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
