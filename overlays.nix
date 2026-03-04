final: prev: {
  prerenderIcon = { name ? "prerendered-icon.png", src, size ? 64 }:
    prev.runCommand name { nativeBuildInputs = [ prev.librsvg ]; } ''
      rsvg-convert -w ${builtins.toString size} -h ${builtins.toString size} \
        ${src} \
        -o $out
    '';
  writePython3Script = name: source:
    prev.writers.writePython3Bin name { flakeIgnore = [ "E265" "E501" ]; } source;
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
