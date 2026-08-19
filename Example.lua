--[[
    potassium-ui Example
    Load the library:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/potassium-ui/main/Library.lua"))()
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/potassium-ui/main/Library.lua"))()

-- Create the window
local Window = Library:CreateWindow({
    Title = "Potassium",
    Footer = "potassium-ui v1.0 | RightShift to toggle",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- Create sidebar (customizable header text)
local Sidebar = Window:Sidebar("Explorer")

-- Expandable section: Combat
local Combat = Sidebar:Section("COMBAT")

local AimbotTab = Combat:Tab("Aimbot")
local EspTab = Combat:Tab("ESP")
local MiscTab = Combat:Tab("Misc")

-- Aimbot tab
AimbotTab:AddToggle("SilentAim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(v)
        print("Silent Aim:", v)
    end,
})

AimbotTab:AddSlider("FOV", {
    Text = "FOV Size",
    Default = 90,
    Min = 0,
    Max = 360,
    Suffix = "°",
    Callback = function(v) print("FOV:", v) end,
})

AimbotTab:AddSlider("Smoothing", {
    Text = "Smoothing",
    Default = 50,
    Min = 0,
    Max = 100,
    Callback = function(v) print("Smoothing:", v) end,
})

AimbotTab:AddDropdown("HitPart", {
    Text = "Hit Part",
    Values = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head",
    Callback = function(v) print("Hit Part:", v) end,
})

AimbotTab:AddColorPicker("FOVColor", {
    Text = "FOV Circle Color",
    Default = Color3.fromRGB(240, 106, 99),
    Callback = function(v) print("FOV Color:", v) end,
})

AimbotTab:AddKeybind("AimKey", {
    Text = "Aim Key",
    Default = "MB2",
    Callback = function(v) print("Aim Key:", v) end,
})

AimbotTab:AddDivider()

AimbotTab:AddButton("Reset Aimbot", function()
    print("Aimbot reset!")
end)

-- ESP tab
EspTab:AddToggle("BoxESP", {
    Text = "Box ESP",
    Default = false,
    Callback = function(v) print("Box ESP:", v) end,
})

EspTag:AddToggle("NameESP", {
    Text = "Name ESP",
    Default = true,
    Callback = function(v) print("Name ESP:", v) end,
})

EspTab:AddToggle("HealthBar", {
    Text = "Health Bar",
    Default = false,
    Callback = function(v) print("Health Bar:", v) end,
})

EspTab:AddSlider("ESPDistance", {
    Text = "Max Distance",
    Default = 500,
    Min = 50,
    Max = 2000,
    Suffix = "m",
})

EspTab:AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = Color3.fromRGB(240, 106, 99),
})

-- Misc tab
MiscTab:AddToggle("AutoReload", {
    Text = "Auto Reload",
    Default = false,
})

MiscTab:AddToggle("NoRecoil", {
    Text = "No Recoil",
    Default = false,
})

MiscTab:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 100,
})

MiscTab:AddInput("ScriptBox", {
    Text = "Execute Script",
    Placeholder = "Paste script here...",
    Callback = function(v) print("Script:", v) end,
})

MiscTab:AddButton("Execute", function()
    print("Executed!")
end)

-- Expandable section: Settings
local Settings = Sidebar:Section("SETTINGS")

local MenuTab = Settings:Tab("Menu")

MenuTab:AddToggle("ShowKeybind", {
    Text = "Show Keybinds",
    Default = true,
})

MenuTab:AddSlider("MenuOpacity", {
    Text = "Menu Opacity",
    Default = 100,
    Min = 10,
    Max = 100,
    Suffix = "%",
})

MenuTab:AddButton("Unload", function()
    Library:Unload()
end)

-- Auto-expand the Combat section and show Aimbot tab on load
Library:Notify({
    Title = "potassium-ui",
    Description = "Loaded successfully. RightShift to toggle menu.",
    Time = 4,
})
