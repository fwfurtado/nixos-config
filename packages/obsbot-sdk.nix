{ lib, stdenv, requireFile, autoPatchelfHook }:
stdenv.mkDerivation {
  pname = "obsbot-libdev";
  version = "2.1.0_8";
  src = requireFile {
    name = "obsbot-libdev-2.1.0_8-linux-x86_64.tar.gz";
    hash = "sha256-q7jGPbpyTNz1oPiroRHaRtJ0UuFmEptnxuV8Ed7iTho=";
    message = ''
      Import the locally downloaded OBSBOT Linux SDK before building the mini-PC:
        nix-store --add-fixed sha256 /path/to/obsbot-libdev-2.1.0_8-linux-x86_64.tar.gz
      The archive contains include/ and linux/x86_64-release/libdev.so.1.0.0.
      The vendor SDK is not redistributed in this repository.
    '';
  };
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 linux/x86_64-release/libdev.so.1.0.0 "$out/lib/libdev.so.1.0.0"
    ln -s libdev.so.1.0.0 "$out/lib/libdev.so"
    install -Dm644 include/dev/dev.hpp "$out/include/dev/dev.hpp"
    install -Dm644 include/dev/devs.hpp "$out/include/dev/devs.hpp"
    install -Dm644 include/util/comm.hpp "$out/include/util/comm.hpp"
    runHook postInstall
  '';

  meta = {
    description = "Locally supplied proprietary OBSBOT Linux device SDK";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
  };
}
