{ inputs, ... }:

{
    imports = [
        inputs.sops-nix.nixosModules.sops
        ./machine.nix
        ./user.nix
    ];

    sops = {
        # defaultSopsFile = ../../../secrets/secrets.yaml;
        # defaultSopsFormat = "yaml";

        age.keyFile = "/var/lib/sops-nix/key.txt";
    };

}
