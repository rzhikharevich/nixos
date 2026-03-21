final: prev: {
  toggleUserUnit =
    unit:
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
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      picosvg = python-prev.picosvg.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
    })
  ];
}
