{
  description = "Skupper Router";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        forAllSystems = nixpkgs.lib.genAttrs systems;
        nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
            qpid-proton = pkgs.callPackage ./qpid-proton.nix { };
            skupper-router = pkgs.callPackage ./skupper-router.nix {
              inherit (self.packages.${system}) qpid-proton;
            };
            default = self.packages.${system}.skupper-router;
        });
      devShells = forAllSystems (system:
              let
                pkgs = nixpkgsFor.${system};
                pythonEnv = pkgs.python3.withPackages (
                  ps: [
                    ps.cffi
                    self.packages.${system}.qpid-proton.py
                  ]
                );
              in {
                  default = pkgs.mkShell {
                    nativeBuildInputs = [
                      pkgs.cmake
                      pkgs.pkg-config
                    ];
                    buildInputs = [
                      pkgs.openssl
                      pkgs.cyrus_sasl
                      pkgs.libunwind
                      pkgs.libnghttp2
                      pythonEnv
                      self.packages.${system}.skupper-router
                    ];
                  };
              });
      };
}
