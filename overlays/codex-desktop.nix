{ inputs }:
final: _prev: {
  chatgpt = final.callPackage (inputs.nix-codex + "/package.nix") { };
}
