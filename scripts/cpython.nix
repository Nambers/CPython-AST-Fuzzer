{ py_ver_str ? "3.11.9" }:
let
  pkgs = import <nixpkgs> { 
    overlays = [
      (self: super: {
        ccacheWrapper = super.ccacheWrapper.override {
          extraConfig = ''
            export CCACHE_COMPRESS=1
            export CCACHE_DIR="/nix/var/cache/ccache"
            export CCACHE_UMASK=007
            if [ ! -d "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' does not exist"
              echo "Please create it with:"
              echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
              echo "  sudo chown root:nixbld '$CCACHE_DIR'"
              echo "====="
              exit 1
            fi
            if [ ! -w "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
              echo "Please verify its access permissions"
              echo "====="
              exit 1
            fi
          '';
        };
      })
    ];
  };
in
pkgs.mkShell {
  stdenv= pkgs.ccacheStdenv;
  packages = [
    pkgs.cmake
    pkgs.clang_18
    pkgs.llvm_18
    pkgs.lld_18
    pkgs.llvmPackages_18.compiler-rt-libc
    pkgs.ccache
  ];
  shellHook = ''
    export ASAN_OPTIONS='detect_leaks=0';
    export CC="${pkgs.clang_18}/bin/clang";
    export CXX="${pkgs.clang_18}/bin/clang++";
    export CLANG_BIN="${pkgs.clang_18}/bin/clang";
    export LIBCLANG_RT_PATH="${pkgs.llvmPackages_18.compiler-rt-libc}/lib/linux";
  '';
}
