# Use this file with nix-shell or similar tools; see https://nixos.org/
with import <nixpkgs> {};

mkShell {
  buildInputs = [
    pkgconfig
    ocl-icd
    opencl-headers
    SDL2
    SDL2_ttf
    (python3.withPackages (ppkgs: with ppkgs; [ setuptools numpy pygame pyopencl opencv4 ]))
  ];
}
