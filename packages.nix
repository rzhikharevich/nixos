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
    (linuxOnly brightnessctl)
    clang
    claude-code
    cmake
    fastfetch
    file
    (linuxOnly flow-control)
    gcc
    gh
    git
    gnumake
    (linuxOnly hdparm)
    htop
    (linuxOnly hwloc)
    (linuxOnly iw)
    jq
    ncdu
    nixfmt
    nvd
    (linuxOnly pciutils)
    (linuxOnly powerstat)
    (linuxOnly powertop)
    pstree
    pv
    ripgrep
    (darwinOnly rvctl)
    (darwinOnly skhd)
    (linuxOnly strace)
    (linuxOnly telegram-desktop)
    tmux
    (linuxOnly pkgs.linuxPackages_latest.turbostat)
    (linuxOnly usbutils)
    (linuxOnly wirelesstools)
    (linuxOnly xwayland-satellite)
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
