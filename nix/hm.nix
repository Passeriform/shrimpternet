{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.shrimp;
in {
  imports = [(import ./package.nix {inherit pkgs;})];

  options.programs.shrimp = {
    enable = lib.mkEnableOption "Shrimpternet";

    package = lib.mkOption {
      type = lib.types.package;
      default = shrimp;
      description = "Package to install for Shrimpternet";
    };

    blogs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of blogs to fry";
    };

    youtubePlaylists = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of youtube playlists and videos to fry";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."shrimpternet/youtube".text = builtins.concatStringsSep "\n" cfg.youtubePlaylists;
    xdg.configFile."shrimpternet/blogs".text = builtins.concatStringsSep "\n" cfg.blogs;

    xdg.cacheFile."shrimpternet/blogs/.keep".text = "";
    xdg.cacheFile."shrimpternet/youtube/.keep".text = "";
    xdg.cacheFile."shrimpternet/meta.json".text = "{}";
  };
}
