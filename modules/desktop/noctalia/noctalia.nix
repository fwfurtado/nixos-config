{ inputs, ... }:
{
    imports = [
        inputs.noctalia.nixosModules.default
    ];

    program.noctalia = {
            enable = true;

            recommendedServices.enable = true;

            systemd.enable = true;
    };
}
