{ ... }:
{
    security.polkit.enable = true

    environment.systemPackages = pkgs; [
        hyprpolkitagent
    ];
}
