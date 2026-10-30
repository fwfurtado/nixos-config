{ lib, stdenv, obsbotSdk ? null, controlsSource ? ./obsbot-controls.cpp }:
assert obsbotSdk != null || controlsSource != ./obsbot-controls.cpp;
stdenv.mkDerivation {
  pname = "tiny-virtual-camera";
  version = "1.1.0";
  src = ./.;

  buildInputs = lib.optional (obsbotSdk != null) obsbotSdk;
  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    $CC -std=c11 -O2 -Wall -Wextra -Werror -I"$src" -c "$src/tiny-virtual-camera.c" -o relay.o
    $CXX -std=c++17 -O2 -Wall -Wextra -Werror -I"$src" ${lib.optionalString (obsbotSdk != null) "-I${obsbotSdk}/include"} -c ${controlsSource} -o controls.o
    $CXX relay.o controls.o ${lib.optionalString (obsbotSdk != null) "-L${obsbotSdk}/lib -ldev -Wl,-rpath,${obsbotSdk}/lib"} -o tiny-virtual-camera
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 tiny-virtual-camera "$out/bin/tiny-virtual-camera"
    runHook postInstall
  '';

  meta = {
    description = "On-demand physical camera relay for a persistent v4l2loopback webcam";
    platforms = lib.platforms.linux;
    mainProgram = "tiny-virtual-camera";
  };
}
