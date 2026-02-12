{
  description = "Custom build of st-flexipatch with Home Manager module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # 1. Overlay agar user bisa mengganti pkgs.st dengan versi ini
      overlays.default = (final: prev: {
        st-flexipatch = prev.st.overrideAttrs (oldAttrs: {
          src = self; # Mengambil source code dari repo ini sendiri
          # Tambahkan buildInputs jika flexipatch butuh lib extra (misal: harfbuzz)
          buildInputs = oldAttrs.buildInputs ++ [ final.harfbuzz ];
        });
      });

      # 2. Home Manager Module
      homeManagerModules.default = { pkgs, config, lib, ... }: {
        options.programs.st-flexipatch.enable = lib.mkEnableOption "st-flexipatch terminal";
        config = lib.mkIf config.programs.st-flexipatch.enable {
          nixpkgs.overlays = [ self.overlays.default ];
          home.packages = [ pkgs.st-flexipatch ];
        };
      };

      # 3. Paket default agar bisa di-run langsung via 'nix run'
      packages = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ({ st, ... }: st.overrideAttrs (old: { src = self; })) {};
      });
    };
}
