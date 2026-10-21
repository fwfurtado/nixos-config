{ lib, stdenv, fetchurl, autoPatchelfHook, glibc, libxcb, libxkbcommon, vulkan-loader, libGL }:

stdenv.mkDerivation {
  pname = "tern-stencil";
  version = "0.9.5";

  src = fetchurl {
    url = "https://build.stencil.so/d/tern/20261019-233248-2863c37/Tern-0.9.5-linux-x86_64.tar.gz";
    hash = "sha256-ApOSXrYtSrfOLOuLx17Ox6xYNeh+awudb+vn0MgKzlI=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib glibc ];
  # The window backend loads these at runtime rather than via ELF NEEDED.
  runtimeDependencies = [ libxcb libxkbcommon vulkan-loader libGL ];

  installPhase = ''
    runHook preInstall
    install -Dm755 tern "$out/bin/tern"
    install -Dm644 ${./so.stencil.tern.desktop} "$out/share/applications/so.stencil.tern.desktop"
    substituteInPlace "$out/share/applications/so.stencil.tern.desktop" \
      --replace-fail "@TERN_EXEC@" "$out/bin/tern"
    runHook postInstall
  '';

  meta = {
    description = "Tern terminal workspace from Stencil";
    homepage = "https://stencil.so/tern";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tern";
  };
}
