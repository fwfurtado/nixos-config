{ config, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SYSTEMD_EDITOR = "nvim";

    DOTNET_ROOT = "${home}/.dotnet";
    GOPATH = "${home}/go";

    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    OMP_PROFILE = "mimi";
    LS_TREE_IGNORE = "cache|log|logs|node_modules|vendor";
  };

  home.sessionPath = [
    "${home}/.local/bin"
    "${home}/bin"
    "${home}/.cargo/bin"
    "${home}/go/bin"
    "${home}/.krew/bin"
    "${home}/.pulumi/bin"
    "${home}/.opencode/bin"
    "${home}/.lmstudio/bin"
    "${home}/.toolhive/bin"
    "${home}/.dotnet"
    "${home}/.dotnet/tools"
    "${home}/.local/share/mise/shims"
  ];
}
