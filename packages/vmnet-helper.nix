{
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  python3,
  darwin,
  apple-sdk_26,
}:

stdenv.mkDerivation {
  pname = "vmnet-helper";
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "nirs";
    repo = "vmnet-helper";
    rev = "v0.10.0";
    hash = "sha256-sAwXbRVBVeQEG2nvtl/4djg6wUWMd8/vOMjzW2ZiqSM=";
  };
  nativeBuildInputs = [
    meson
    ninja
    python3
    darwin.sigtool
  ];
  buildInputs = [ apple-sdk_26 ];
  postPatch = ''
    cat > gen-version <<'SCRIPT'
    #!/bin/sh
    cat > "$1" <<'EOF'
    #define GIT_VERSION "v0.10.0"
    #define GIT_COMMIT  "release"
    EOF
    SCRIPT
  '';
  postFixup = ''
    codesign -f --entitlements ${../files/vmnet-entitlements.plist} -s - "$out/bin/vmnet-helper"
  '';
}
