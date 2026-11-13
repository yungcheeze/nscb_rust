{
  description = "nscb_rust: NSC_Builder's core Switch content workflows, in Rust";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: {
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.nscb;
      nscb = pkgs.rustPlatform.buildRustPackage {
        pname = "nscb";
        version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
        src = pkgs.lib.cleanSource ./.;
        cargoLock.lockFile = ./Cargo.lock;
        # zstd-sys links the system libzstd through pkg-config.
        nativeBuildInputs = [pkgs.pkg-config];
        buildInputs = [pkgs.zstd];
        meta = {
          description = "Merge, convert (NSP <-> XCI), compress and verify Nintendo Switch content";
          homepage = "https://github.com/cxfcxf/nscb_rust";
          mainProgram = "nscb";
        };
      };
    });

    overlays.default = final: _prev: {
      nscb = self.packages.${final.stdenv.hostPlatform.system}.nscb;
    };

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${pkgs.stdenv.hostPlatform.system}.nscb];
        packages = [pkgs.rust-analyzer pkgs.clippy pkgs.rustfmt];
      };
    });
  };
}
