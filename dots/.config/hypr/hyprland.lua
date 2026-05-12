-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

local function load_custom(module)
    local loaded = pcall(require, "custom/" .. module)
    if loaded then
        return
    end
    hl.exec_cmd("hyprctl keyword source \"$HOME/.config/hypr/custom/" .. module .. ".conf\"")
end

-- Environment variables --
require("hyprland/env")
load_custom("env")

-- Defaults --
require("hyprland/execs")
require("hyprland/general")
require("hyprland/rules")
require("hyprland/colors")
require("hyprland/keybinds")

-- Custom --
load_custom("execs")
load_custom("general")
load_custom("rules")
load_custom("keybinds")

-- nwg-displays support: re-add the files if it updates later
-- require("workspaces")
-- require("monitors")

-- Shell overrides --
require("hyprland/shellOverrides/main")
