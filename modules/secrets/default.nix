{ inputs, ... }:

{
    imports = [
        inputs.sops-nix.nixosModues.sops
    ];

    sops = {
        defaultSopsFile = ../../../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        agent.keyFile = "/var/lib/sops-nix/key.txt";
    };

    sops.secrets.example = {};
}
