{ lib, stdenv, fetchurl, autoPatchelfHook, glibc, libxcb, libxkbcommon, vulkan-loader, libGL }:

stdenv.mkDerivation {
  pname = "tern-stencil";
  version = "0.8.3";

  src = fetchurl {
    url = "https://build.stencil.so/d/tern/20261012-142610-e2b8656/Tern-0.8.3-linux-x86_64.tar.gz";
    hash = "sha256-vMICgHolxxhYVhofV+A95F+94ZE4STAuNKLwo2xs/nk=";
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
