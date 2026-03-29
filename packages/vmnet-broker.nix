{
  stdenv,
  fetchFromGitHub,
  darwin,
  apple-sdk_26,
}:

stdenv.mkDerivation {
  pname = "vmnet-broker";
  version = "0-unstable-2026-03-28";
  src = fetchFromGitHub {
    owner = "nirs";
    repo = "vmnet-broker";
    rev = "96a744daa587939fc9f5bb81411d5d8f09255db3";
    hash = "sha256-z3TMcnAj/M02Q8kjp0zUeqFpKR7Lbakq7tsQzMq4bq4=";
  };
  nativeBuildInputs = [ darwin.sigtool ];
  buildInputs = [ apple-sdk_26 ];
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
    codesign -f --entitlements ${../files/vmnet-entitlements.plist} -s - "$out/bin/vmnet-broker"
  '';
}
