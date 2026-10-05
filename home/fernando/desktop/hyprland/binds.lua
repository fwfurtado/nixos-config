local term = "ghostty +new-window"
local browser = "google-chrome"
local launcher = "fuzzel"

hl.bind("SUPER+Return", hl.dsp.exec_cmd(term), { description = "Open terminal" })
hl.bind("SUPER+CTRL+grave", hl.dsp.global("com.mitchellh.ghostty:CTRL+LOGO+grave"), { description = "Toggle Ghostty quick terminal" })
hl.bind("SUPER+SHIFT+Return", hl.dsp.exec_cmd(browser), { description = "Open browser" })
hl.bind("SUPER+E", hl.dsp.exec_cmd("nautilus"), { description = "Open file manager" })
hl.bind("SUPER+space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "Open launcher" })
hl.bind("SUPER+V", hl.dsp.exec_cmd("cliphist list | " .. launcher .. " --dmenu | cliphist decode | wl-copy"), { description = "Clipboard history" })

for _, direction in ipairs({ "left", "down", "up", "right" }) do
    hl.bind("SUPER+" .. direction, hl.dsp.focus({ direction = direction }), { description = "Focus window " .. direction })
    hl.bind("SUPER+SHIFT+" .. direction, hl.dsp.window.move({ direction = direction }), { description = "Move window " .. direction })
end

hl.bind("SUPER+M", hl.dsp.layout("focusmaster"), { description = "Focus master window" })
hl.bind("SUPER+SHIFT+M", hl.dsp.layout("swapwithmaster"), { description = "Swap with master" })
hl.bind("SUPER+Tab", hl.dsp.layout("cyclenext"), { description = "Next in stack" })
hl.bind("SUPER+SHIFT+Tab", hl.dsp.layout("cycleprev"), { description = "Previous in stack" })
hl.bind("SUPER+comma", hl.dsp.layout("addmaster"), { description = "Add master slot" })
hl.bind("SUPER+period", hl.dsp.layout("removemaster"), { description = "Remove master slot" })

hl.bind("SUPER+mouse:272", hl.dsp.window.drag(), { description = "Drag window" })
hl.bind("SUPER+mouse:273", hl.dsp.window.resize(), { description = "Resize with mouse" })
hl.bind("SUPER+Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER+CTRL+F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Fullscreen" })
hl.bind("SUPER+CTRL+M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Maximize (respect gaps)" })
hl.bind("SUPER+CTRL+space", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("SUPER+CTRL+P", hl.dsp.window.pin({ action = "toggle" }), { description = "Pin window" })
hl.bind("SUPER+SHIFT+R", hl.dsp.exec_cmd("hyprctl --batch \"dispatch layoutmsg mfact exact $mfact ; dispatch layoutmsg orientationcenter\""), { description = "Reset layout" })

hl.bind("SUPER+R", hl.dsp.submap("resize"), { description = "Enter resize mode" })
hl.define_submap("resize", function()
    hl.bind("left", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true, description = "Narrow window" })
    hl.bind("right", hl.dsp.window.resize({ x = 80, y = 0, relative = true }), { repeating = true, description = "Widen window" })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true, description = "Shrink height" })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true, description = "Grow height" })
    hl.bind("Escape", hl.dsp.submap("reset"), { description = "Leave resize mode" })
    hl.bind("Return", hl.dsp.submap("reset"), { description = "Leave resize mode" })
end)

local function move_windows_current_workspace(target)
    local current = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not current then return end
    for _, window in pairs(hl.get_windows({ workspace = current })) do
        hl.dispatch(hl.dsp.window.move({ window = window, workspace = target, follow = false }))
    end
    hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
end

for workspace = 1, 9 do
    hl.bind("SUPER+" .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }), { description = "Go to workspace " .. workspace })
    hl.bind("SUPER+SHIFT+" .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }), { description = "Send window to workspace " .. workspace })
    local target = workspace
    hl.bind("SUPER+CTRL+SHIFT+" .. target, function() move_windows_current_workspace(target) end, { description = "Send workspace to " .. target })
end

hl.bind("SUPER+bracketleft", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous existing workspace" })
hl.bind("SUPER+bracketright", hl.dsp.focus({ workspace = "e+1" }), { description = "Next existing workspace" })
hl.bind("SUPER+grave", hl.dsp.focus({ workspace = "previous" }), { description = "Back to last workspace" })
hl.bind("SUPER+S", hl.dsp.workspace.toggle_special("scratch"), { description = "Toggle scratchpad" })
hl.bind("SUPER+SHIFT+S", hl.dsp.window.move({ workspace = "special:scratch", follow = true }), { description = "Send window to scratchpad" })

hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | swappy -f -"), { description = "Region to editor" })
hl.bind("SHIFT+Print", hl.dsp.exec_cmd("grim - | wl-copy"), { description = "Screen to clipboard" })
hl.bind("SUPER+Print", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | wl-copy"), { description = "Region to clipboard" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, description = "Mute output" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, description = "Mute microphone" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, description = "Brightness down" })

hl.bind("SUPER+ALT+L", hl.dsp.exec_cmd("hyprlock"), { description = "Lock screen" })
hl.bind("SUPER+ALT+R", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload Hyprland" })
hl.bind("SUPER+ALT+Q", hl.dsp.exit(), { description = "Exit session" })
hl.bind("SUPER+SHIFT+slash", hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"), { description = "Show keybindings" })
hl.bind("SUPER+C", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center calendar"), { description = "Show calendar" })
hl.bind("SUPER+SHIFT+C", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center system"), { description = "Show system monitor" })
