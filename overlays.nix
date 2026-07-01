{ inputs }:

final: prev:
{
  revisor = inputs.revisor.packages.${prev.stdenv.hostPlatform.system}.default;

  claude-code =
    (import inputs.nixpkgs-master {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (prev) config;
    }).claude-code;

  toggleUserUnit =
    unit:
    if prev.stdenv.isDarwin then
      prev.writeShellScript "toggle-${unit}" ''
        uid=$(/usr/bin/id -u)
        label=${unit}
        if /bin/launchctl print "gui/$uid/$label" 2>/dev/null | /usr/bin/grep -q "state = running"; then
          /bin/launchctl kill SIGTERM "gui/$uid/$label"
        else
          /bin/launchctl kickstart "gui/$uid/$label"
        fi
      ''
    else
      prev.writeShellScript "toggle-${unit}" ''
        if ${prev.systemd}/bin/systemctl --user is-active --quiet ${unit}; then
          ${prev.systemd}/bin/systemctl --user stop ${unit}
        else
          ${prev.systemd}/bin/systemctl --user start ${unit}
        fi
      '';

  prerenderIcon =
    {
      name ? "prerendered-icon.png",
      src,
      size ? 64,
    }:
    prev.runCommand name { nativeBuildInputs = [ prev.librsvg ]; } ''
      rsvg-convert -w ${builtins.toString size} -h ${builtins.toString size} \
        ${src} \
        -o $out
    '';
  colloidIcons = prev.colloid-icon-theme.override { colorVariants = [ "grey" ]; };
  mkColloidIcon =
    name: path:
    final.prerenderIcon {
      name = "${name}.png";
      src = "${final.colloidIcons}/share/icons/Colloid-Grey-Dark/${path}";
    };
  writePython3Script =
    name: opts: source:
    prev.writers.writePython3Bin name (
      {
        flakeIgnore = [
          "E265"
          "E501"
        ];
      }
      // opts
    ) source;
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      afdko = python-prev.afdko.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
      picosvg = python-prev.picosvg.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
      ws4py = python-prev.ws4py.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
    })
  ];
  lgtv-remote = prev.python3Packages.buildPythonApplication {
    pname = "lgtv-remote";
    version = "0.3";
    src = prev.fetchFromGitHub {
      owner = "klattimer";
      repo = "LGWebOSRemote";
      rev = "83b5e8be047fb900400184bc351de14634395563";
      hash = "sha256-b2rPvf8OpKvg5au9XJ+Zo6377AM3y3jbnRnsQ1P4AtA=";
    };
    pyproject = true;
    build-system = [ prev.python3Packages.setuptools ];
    dependencies = with prev.python3Packages; [
      wakeonlan
      ws4py
      requests
      getmac
    ];
  };
}
// prev.lib.optionalAttrs prev.stdenv.isDarwin {
  darwin_exec = inputs.darwin_exec.packages.${prev.stdenv.hostPlatform.system}.default;
  darwin_darkmode = inputs.darwin_darkmode.packages.${prev.stdenv.hostPlatform.system}.default;
  rvctl = prev.writeShellScriptBin "rvctl" ''
    exec ${final.revisor}/bin/rvctl -s "$HOME/.local/state/revisor/control.sock" "$@"
  '';
  inherit (prev.callPackages ./packages/vmnet.nix { }) vmnet-broker vmnet-helper;
}
// prev.lib.optionalAttrs prev.stdenv.isLinux {
  roland = prev.rustPlatform.buildRustPackage {
    pname = "roland";
    version = "0.1.0";
    src = prev.fetchFromGitHub {
      owner = "oknozor";
      repo = "roland";
      rev = "78351b998528bd335947fb59ea3e10c331c33331";
      hash = "sha256-wQCxgd2UavxWHKY4C3dZG/pRrLxSTDRajVgsO2E9GQM=";
    };
    cargoPatches = [ ./patches/roland.patch ];
    cargoHash = "sha256-CWIlkNi6PSiXLEi1gc3uzIWYpQURQadoMqp+eFvt5Ew=";
    doCheck = false;
    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [
      prev.libinput
      prev.udev
    ];
  };
  wvkbd = prev.wvkbd.overrideAttrs {
    makeFlags = [ "LAYOUT=deskintl" ];
    patches = [
      ./patches/wvkbd-no-fn-row.patch
      ./patches/wvkbd-add-cyrillic-layer.patch
    ];
    meta.mainProgram = "wvkbd-deskintl";
  };
}
