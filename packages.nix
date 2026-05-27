{
  pkgs,
  config,
  isLinux,
}:
let
  linuxOnly = pkg: if isLinux then pkg else null;
  darwinOnly = pkg: if !isLinux then pkg else null;
in
builtins.filter (pkg: pkg != null) (
  with pkgs;
  [
    age
    (darwinOnly blueutil)
    (darwinOnly lgtv-remote)
    clang
    clang-tools
    claude-code
    cmake
    codex
    fastfetch
    file
    (linuxOnly flow-control)
    gcc
    gh
    git
    gnumake
    hcloud
    (linuxOnly hdparm)
    htop
    (linuxOnly hwloc)
    (linuxOnly iw)
    jq
    nano
    ncdu
    (linuxOnly net-tools)
    ninja
    nixfmt
    nvd
    (linuxOnly pciutils)
#    (darwinOnly pipx)
    (linuxOnly powerstat)
    (linuxOnly powertop)
    pstree
    pv
    ripgrep
    (darwinOnly rvctl)
    (darwinOnly skhd)
    (linuxOnly strace)
    tmux
    (linuxOnly usbutils)
    (linuxOnly wirelesstools)
    xxd
    (darwinOnly yabai)

    config.rzhikharevich.rustToolchain

    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        ptpython
      ]
    ))
  ]
)
