{pkgs}: let
  binPath = pkgs.lib.makeBinPath [
    "$out"
    pkgs.pup
    pkgs.wget
    pkgs.yt-dlp
  ];
in
  pkgs.stdenv.mkDerivation {
    pname = "shrimp";
    version = pkgs.lib.fileContents ../VERSION;

    src = ./..;
    nativeBuildInputs = [pkgs.makeWrapper];
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/assets

      # Server
      $CC server/*.c -O2 -o serve
      cp serve $out/bin/
      cp -r server/assets $out/share/

      # Scripts
      for script in scripts/*.sh; do
        install -Dm755 -t $out/libexec/ $script
      done
    '';

    postFixup = ''
      for script in $out/libexec/*; do
        name=$(basename "$script" .sh)
        makeWrapper "$script" $out/bin/$name \
          --prefix PATH : ${binPath}
      done
    '';
  }
