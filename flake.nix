{
  description = "Custom build of st-flexipatch with NixOS and Home Manager modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # 1. Overlay: Tetap sama, untuk menambah 'st-flexipatch' ke dalam pkgs
      overlays.default = (final: prev: {
        st-flexipatch = prev.st.overrideAttrs (oldAttrs: {
          src = self;
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ 
            final.pkg-config 
            final.gnumake 
          ];
          buildInputs = (oldAttrs.buildInputs or []) ++ [
            final.imlib2
            final.freetype
            final.harfbuzz
            final.libX11
            final.libXft
            final.libXrender
            final.libXcursor
            final.fontconfig
          ];
          installFlags = [ "PREFIX=$(out)" ];
        });
      });

      # 2. NixOS Module
      nixosModules.default = { pkgs, config, lib, ... }: {
        options.programs.st-flexipatch.enable = lib.mkEnableOption "st-flexipatch terminal";
        config = lib.mkIf config.programs.st-flexipatch.enable {
          nixpkgs.overlays = [ self.overlays.default ];
          environment.systemPackages = [ pkgs.st-flexipatch ];
        };
      };

      # 3. Home Manager Module
      homeManagerModules.default = { pkgs, config, lib, ... }: {
        options.programs.st-flexipatch.enable = lib.mkEnableOption "st-flexipatch terminal";
        config = lib.mkIf config.programs.st-flexipatch.enable {
          nixpkgs.overlays = [ self.overlays.default ];
          home.packages = [ pkgs.st-flexipatch ];
        };
      };

      # 4. Perbaikan Packages: Langsung ambil derivasinya, bukan set-nya
      packages = forAllSystems (system: 
        let 
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in {
          # Sekarang 'default' adalah paket st-flexipatch itu sendiri
          default = pkgs.st-flexipatch; 
          st-flexipatch = pkgs.st-flexipatch;
        }
      );
    };
}
