{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, glibc, libxcb, libxkbcommon, vulkan-loader, libGL, webkitgtk_4_1, glib-networking }:

stdenv.mkDerivation {
  pname = "tern-stencil";
  version = "0.9.18";

  src = fetchurl {
    url = "https://build.stencil.so/d/tern/20261112-055729-6f1fa0f/Tern-0.9.18-linux-x86_64.tar.gz";
    hash = "sha256-In2LyiXCv8Yc/dSP+XANy9qoaA+d1d9aZ3mGGOYnANs=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ stdenv.cc.cc.lib glibc ];
  # The window backend and embedded browser load these via dlopen.
  runtimeDependencies = [ libxcb libxkbcommon vulkan-loader libGL webkitgtk_4_1 ];

  postFixup = ''
    wrapProgram "$out/bin/tern" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"
  '';

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
