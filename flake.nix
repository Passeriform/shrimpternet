{
  description = "Dev shell for Shrimpternet";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    profile = "elixir";
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs;
        [
          alejandra
          statix
          deadnix
          nil
          nixd
        ]
        ++ (with pkgs.beam29Packages; [
          elixir
          elixir-ls
        ]);

      shellHook = ''
        export VSCODE_PROFILE="${profile}";
      '';
    };
  };
}
