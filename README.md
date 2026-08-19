# potassium-ui

A Potassium-styled UI library for Roblox exploits. Single file, loadstring-friendly.

## Features

- Dark theme matching the Potassium code editor
- Sidebar with customizable header and expandable sections
- Tab system driven by sidebar navigation
- Full element set: Toggle, Button, Slider, Dropdown, ColorPicker, Keybind, Input, Label, Divider
- Notifications
- Toggle keybind to show/hide menu
- Draggable titlebar with minimize and close

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/potassium-ui/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "My Script",
    Footer = "v1.0",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Sidebar = Window:Sidebar("Explorer")
local Combat = Sidebar:Section("COMBAT")

local AimbotTab = Combat:Tab("Aimbot")
AimbotTab:AddToggle("SilentAim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(v) print(v) end,
})
```

## API

### Window

```lua
local Window = Library:CreateWindow({
    Title = "Title",
    Footer = "Footer text",
    ToggleKey = Enum.KeyCode.RightShift,
})
```

### Sidebar

```lua
local Sidebar = Window:Sidebar("Explorer") -- customizable header
```

### Section (expandable)

```lua
local Section = Sidebar:Section("SECTION NAME")
```

### Tab (clickable sidebar item)

```lua
local Tab = Section:Tab("Tab Name")
```

### Elements

```lua
-- Toggle
Tab:AddToggle("idx", { Text = "Label", Default = false, Callback = function(v) end })

-- Button
Tab:AddButton("Click me", function() end)
Tab:AddButton({ Text = "Click me" }, function() end)

-- Slider
Tab:AddSlider("idx", { Text = "Label", Default = 50, Min = 0, Max = 100, Suffix = "%" })

-- Dropdown
Tab:AddDropdown("idx", { Text = "Label", Values = {"A","B","C"}, Default = "A" })

-- Color Picker
Tab:AddColorPicker("idx", { Text = "Label", Default = Color3.new(1,0,0) })

-- Keybind
Tab:AddKeybind("idx", { Text = "Label", Default = "MB2" })

-- Input
Tab:AddInput("idx", { Text = "Label", Placeholder = "Type..." })

-- Label
Tab:AddLabel("Text")

-- Divider
Tab:AddDivider()
```

### Notifications

```lua
Library:Notify({ Title = "Title", Description = "Message", Time = 3 })
Library:Notify("Simple message")
```

### Options / Toggles

```lua
Library.Options.idx:SetValue(newValue)
Library.Toggles.idx:SetValue(true)
```

## Colors

All colors are in `Library.Scheme` and can be changed at runtime:

| Key | Default |
|-----|---------|
| BackgroundColor | `#171719` |
| MainColor | `#1C1C1F` |
| SidebarColor | `#161618` |
| OutlineColor | `#252528` |
| FontColor | `#9A9AA3` |
| MutedColor | `#6D6D76` |
| AccentColor | `#F06A63` |
| HoverColor | `#353538` |
| DarkColor | `#101012` |
| WhiteColor | `#D6D6D8` |

## License

MIT
