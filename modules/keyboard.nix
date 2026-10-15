{ ... }:
{
    services.xserver.xkb = {
        layout = "us";
        variant = "mac";
        model = "pc105";
        options = "lv3:ralt_switch";
    };

    console.useXkbConfig = true;
}
