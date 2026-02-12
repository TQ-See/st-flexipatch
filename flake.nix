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
      # 1. Overlay: Logika kompilasi otomatis ada di sini
      overlays.default = (final: prev: {
        st-flexipatch = prev.st.overrideAttrs (oldAttrs: {
          src = self;

          # Alat bantu saat kompilasi (compiler, pkg-config)
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ 
            final.pkg-config 
            final.gnumake 
          ];

          # Library yang dibutuhkan (Gabungan shell.nix + Harfbuzz)
          buildInputs = [
            final.imlib2
            final.freetype
            final.harfbuzz
            final.libX11
            final.libXft
            final.libXrender
            final.libXcursor
            final.fontconfig
          ];

          # Memaksa instalasi ke direktori Nix Store ($out)
          # Ini menggantikan PREFIX=$HOME/.local kamu dulu
          installFlags = [ "PREFIX=$(out)" ];
        });
      });

      # 2. NixOS Module: Untuk install system-wide (di configuration.nix)
      nixosModules.default = { pkgs, config, lib, ... }: {
        options.programs.st-flexipatch.enable = lib.mkEnableOption "st-flexipatch terminal";
        config = lib.mkIf config.programs.st-flexipatch.enable {
          nixpkgs.overlays = [ self.overlays.default ];
          environment.systemPackages = [ pkgs.st-flexipatch ];
        };
      };

      # 3. Home Manager Module: Untuk install per-user (di home.nix)
      homeManagerModules.default = { pkgs, config, lib, ... }: {
        options.programs.st-flexipatch.enable = lib.mkEnableOption "st-flexipatch terminal";
        config = lib.mkIf config.programs.st-flexipatch.enable {
          nixpkgs.overlays = [ self.overlays.default ];
          home.packages = [ pkgs.st-flexipatch ];
        };
      };

      # 4. Default Package: Agar bisa 'nix run github:TQ-See/st-flexipatch'
      packages = forAllSystems (system: 
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.callPackage ({ st, ... }: self.overlays.default pkgs pkgs) {};
        }
      );
    };
}
