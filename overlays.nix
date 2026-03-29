final: prev:
{
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
      picosvg = python-prev.picosvg.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
    })
  ];
}
// prev.lib.optionalAttrs prev.stdenv.isDarwin {
  rvctl = prev.writeShellScriptBin "rvctl" ''
    exec ${final.revisor}/bin/rvctl -s "$HOME/.local/state/revisor/control.sock" "$@"
  '';
  vmnet-broker = prev.stdenv.mkDerivation {
    pname = "vmnet-broker";
    version = "0-unstable-2026-03-28";
    src = prev.fetchFromGitHub {
      owner = "nirs";
      repo = "vmnet-broker";
      rev = "96a744daa587939fc9f5bb81411d5d8f09255db3";
      hash = "sha256-z3TMcnAj/M02Q8kjp0zUeqFpKR7Lbakq7tsQzMq4bq4=";
    };
    nativeBuildInputs = [ prev.darwin.sigtool ];
    buildInputs = [ prev.apple-sdk_26 ];
    postPatch = ''
      mkdir -p include
      cat > include/version.h <<'EOF'
      #ifndef VERSION_H
      #define VERSION_H
      #define GIT_VERSION "0-unstable-2026-03-28"
      #define GIT_COMMIT "96a744d"
      #endif
      EOF
      substituteInPlace Makefile \
        --replace-fail 'codesign -f -v --entitlements entitlements.plist -s -' 'true #'
    '';
    preBuild = ''
      makeFlagsArray+=(
        "CFLAGS=-Wall -Wextra -O2 -Iinclude -mmacosx-version-min=26.0"
        "LDFLAGS=-framework CoreFoundation -framework vmnet -mmacosx-version-min=26.0"
      )
    '';
    buildFlags = [ "vmnet-broker" ];
    installPhase = ''
      mkdir -p $out/bin
      cp vmnet-broker $out/bin/
    '';
    postFixup = ''
      codesign -f --entitlements ${./files/vmnet-entitlements.plist} -s - "$out/bin/vmnet-broker"
    '';
  };
  vmnet-helper = prev.stdenv.mkDerivation {
    pname = "vmnet-helper";
    version = "0.10.0";
    src = prev.fetchFromGitHub {
      owner = "nirs";
      repo = "vmnet-helper";
      rev = "v0.10.0";
      hash = "sha256-sAwXbRVBVeQEG2nvtl/4djg6wUWMd8/vOMjzW2ZiqSM=";
    };
    nativeBuildInputs = [
      prev.meson
      prev.ninja
      prev.python3
      prev.darwin.sigtool
    ];
    buildInputs = [ prev.apple-sdk_26 ];
    postPatch = ''
      cat > gen-version <<'EOF'
      #!/usr/bin/env python3
      import sys
      output = sys.argv[1]
      with open(output, "w") as f:
          f.write('#define GIT_VERSION "v0.10.0"\n#define GIT_COMMIT  "release"\n')
      EOF
    '';
    postFixup = ''
      codesign -f --entitlements ${./files/vmnet-entitlements.plist} -s - "$out/bin/vmnet-helper"
    '';
  };
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
