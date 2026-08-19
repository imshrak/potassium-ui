--[[
    potassium-ui
    A Potassium-styled UI library for Roblox exploits
    https://github.com/imshrak/potassium-ui
]]

local Library = {}
Library.__index = Library
Library.Toggles = {}
Library.Options = {}
Library.Unloaded = false

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

Library.Scheme = {
    BackgroundColor = Color3.fromRGB(23, 23, 25),
    MainColor = Color3.fromRGB(28, 28, 31),
    SidebarColor = Color3.fromRGB(22, 22, 24),
    OutlineColor = Color3.fromRGB(37, 37, 40),
    FontColor = Color3.fromRGB(154, 154, 163),
    MutedColor = Color3.fromRGB(109, 109, 118),
    AccentColor = Color3.fromRGB(240, 106, 99),
    HoverColor = Color3.fromRGB(53, 53, 56),
    DarkColor = Color3.fromRGB(16, 16, 18),
    WhiteColor = Color3.fromRGB(214, 214, 216),
}

local CORNER_RADIUS = UDim.new(0, 4)
local PILL_RADIUS = UDim.new(0, 10)

local function MakeTween(instance, props, duration)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function Make(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function AddCorner(parent, radius)
    return Make("UICorner", { CornerRadius = radius or CORNER_RADIUS, Parent = parent })
end

local function AddStroke(parent, color, thickness)
    return Make("UIStroke", {
        Color = color or Library.Scheme.OutlineColor,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function AddPadding(parent, top, bottom, left, right)
    return Make("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    })
end

local function AddListLayout(parent, padding)
    return Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 4),
        Parent = parent,
    })
end

-- ==================== NOTIFICATIONS ====================
local Notifications = {}
local NotifContainer = nil

function Library:Notify(info)
    if not NotifContainer then return end
    if type(info) == "string" then
        info = { Title = "Notification", Description = info, Time = 3 }
    end
    info.Time = info.Time or 3

    local holder = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Library.Scheme.MainColor,
        BorderSizePixel = 0,
        Parent = NotifContainer,
    })
    AddCorner(holder)
    AddStroke(holder, Library.Scheme.OutlineColor)

    Make("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Library.Scheme.AccentColor,
        BorderSizePixel = 0,
        Parent = holder,
    })

    Make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = info.Title or "Notification",
        TextColor3 = Library.Scheme.WhiteColor,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    Make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1,
        Text = info.Description or "",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = holder,
    })

    table.insert(Notifications, holder)

    task.delay(info.Time, function()
        MakeTween(holder, { BackgroundTransparency = 1 }, 0.3)
        task.delay(0.3, function()
            holder:Destroy()
            for i, v in ipairs(Notifications) do
                if v == holder then
                    table.remove(Notifications, i)
                    break
                end
            end
        end)
    end)
end

-- ==================== WINDOW ====================
function Library:CreateWindow(info)
    info = info or {}
    local self = setmetatable({}, Library)
    self.Title = info.Title or "potassium"
    self.Footer = info.Footer or ""
    self.ToggleKey = info.ToggleKey or Enum.KeyCode.RightShift
    self.Toggled = true
    self.Dragging = false
    self.DragOffset = Vector2.new(0, 0)
    self.ActiveTab = nil
    self.Pages = {}

    local screenGui = Make("ScreenGui", {
        Name = "PotassiumUI",
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = (syn and syn.protect_gui and (function() local g = Make("ScreenGui", {Parent = game:GetService("CoreGui")}); syn.protect_gui(g); return g end)()) or game:GetService("CoreGui"),
    })
    self.ScreenGui = screenGui

    NotifContainer = Make("Frame", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    AddListLayout(NotifContainer, 6)

    local mainFrame = Make("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 580, 0, 400),
        Position = UDim2.new(0.5, -290, 0.5, -200),
        BackgroundColor3 = Library.Scheme.MainColor,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    AddCorner(mainFrame, UDim.new(0, 6))
    AddStroke(mainFrame, Library.Scheme.OutlineColor)
    self.MainFrame = mainFrame

    -- Titlebar
    local titlebar = Make("Frame", {
        Name = "Titlebar",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Library.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = titlebar,
    })

    Make("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library.Scheme.FontColor,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titlebar,
    })

    local closeBtn = Make("TextButton", {
        Size = UDim2.new(0, 46, 1, 0),
        Position = UDim2.new(1, -46, 0, 0),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = titlebar,
    })
    closeBtn.MouseButton1Click:Connect(function()
        Library:Unload()
    end)
    closeBtn.MouseEnter:Connect(function()
        MakeTween(closeBtn, { BackgroundColor3 = Library.Scheme.AccentColor, TextColor3 = Color3.new(1, 1, 1) }, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        MakeTween(closeBtn, { BackgroundTransparency = 1, TextColor3 = Library.Scheme.MutedColor }, 0.1)
    end)

    local minBtn = Make("TextButton", {
        Size = UDim2.new(0, 46, 1, 0),
        Position = UDim2.new(1, -92, 0, 0),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = titlebar,
    })
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        task.delay(0.1, function()
            local restore = Make("TextButton", {
                Size = UDim2.new(0, 200, 0, 30),
                Position = UDim2.new(0.5, -100, 0.5, -15),
                BackgroundColor3 = Library.Scheme.BackgroundColor,
                BorderSizePixel = 0,
                Text = self.Title .. "  (RightShift to show)",
                TextColor3 = Library.Scheme.FontColor,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Parent = screenGui,
            })
            AddCorner(restore, UDim.new(0, 4))
            AddStroke(restore, Library.Scheme.OutlineColor)
            restore.MouseButton1Click:Connect(function()
                mainFrame.Visible = true
                restore:Destroy()
            end)
        end)
    end)
    minBtn.MouseEnter:Connect(function()
        MakeTween(minBtn, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
    end)
    minBtn.MouseLeave:Connect(function()
        MakeTween(minBtn, { BackgroundTransparency = 1 }, 0.1)
    end)

    -- Dragging
    titlebar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self.DragOffset = Vector2.new(input.Position.X, input.Position.Y) - mainFrame.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = Vector2.new(input.Position.X, input.Position.Y) - self.DragOffset
            mainFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = false
        end
    end)

    -- Toggle keybind
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self.Toggled = not self.Toggled
            mainFrame.Visible = self.Toggled
        end
    end)

    -- Sidebar
    local sidebar = Make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 220, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Library.Scheme.SidebarColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Make("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    local sidebarScroll = Make("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = sidebar,
    })
    AddPadding(sidebarScroll, 4, 4, 0, 0)
    AddListLayout(sidebarScroll, 0)
    self.SidebarScroll = sidebarScroll

    -- Content area
    local content = Make("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -220, 1, -35),
        Position = UDim2.new(0, 220, 0, 35),
        BackgroundColor3 = Library.Scheme.MainColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })

    local contentScroll = Make("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = content,
    })
    AddPadding(contentScroll, 12, 12, 12, 12)
    AddListLayout(contentScroll, 6)
    self.ContentScroll = contentScroll

    -- Footer
    if self.Footer ~= "" then
        local footer = Make("Frame", {
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 1, -22),
            BackgroundColor3 = Library.Scheme.BackgroundColor,
            BorderSizePixel = 0,
            Parent = mainFrame,
        })
        Make("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Library.Scheme.OutlineColor,
            BorderSizePixel = 0,
            Parent = footer,
        })
        Make("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = self.Footer,
            TextColor3 = Library.Scheme.MutedColor,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = footer,
        })
    end

    return self
end

-- ==================== SIDEBAR ====================
function Library:Sidebar(title)
    local header = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Library.Scheme.SidebarColor,
        BorderSizePixel = 0,
        LayoutOrder = 0,
        Parent = self.SidebarScroll,
    })
    Make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = header,
    })
    Make("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Explorer",
        TextColor3 = Library.Scheme.FontColor,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local sidebar = {}
    sidebar.Sections = {}
    sidebar.OrderCounter = 1

    function sidebar:Section(sectionTitle)
        local order = sidebar.OrderCounter
        sidebar.OrderCounter = sidebar.OrderCounter + 1

        local sectionBtn = Make("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = order,
            Parent = self.SidebarScroll,
        })

        local chevron = Make("TextLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 10, 0.5, -7),
            BackgroundTransparency = 1,
            Text = ">",
            TextColor3 = Library.Scheme.MutedColor,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Parent = sectionBtn,
        })

        Make("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            Text = sectionTitle or "SECTION",
            TextColor3 = Library.Scheme.MutedColor,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sectionBtn,
        })

        local sectionContent = Make("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order + 0.5,
            Visible = false,
            Parent = self.SidebarScroll,
        })
        AddListLayout(sectionContent, 0)

        local expanded = false
        sectionBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            sectionContent.Visible = expanded
            chevron.Text = expanded and "v" or ">"
        end)
        sectionBtn.MouseEnter:Connect(function()
            MakeTween(sectionBtn, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
        end)
        sectionBtn.MouseLeave:Connect(function()
            MakeTween(sectionBtn, { BackgroundTransparency = 1 }, 0.1)
        end)

        local section = {}
        local contentOrder = 1

        function section:Tab(tabTitle)
            local tabOrder = contentOrder
            contentOrder = contentOrder + 1

            local tabItem = Make("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = tabOrder,
                Parent = sectionContent,
            })

            local accentBar = Make("Frame", {
                Size = UDim2.new(0, 2, 0, 14),
                Position = UDim2.new(0, 22, 0.5, -7),
                BackgroundColor3 = Library.Scheme.AccentColor,
                BorderSizePixel = 0,
                Visible = false,
                Name = "AccentBar",
                Parent = tabItem,
            })

            local tabLabel = Make("TextLabel", {
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 32, 0, 0),
                BackgroundTransparency = 1,
                Text = tabTitle,
                TextColor3 = Library.Scheme.MutedColor,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tabItem,
            })

            local page = Make("Frame", {
                Name = tabTitle .. "_Page",
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
                Parent = self.ContentScroll,
            })
            AddListLayout(page, 6)
            self.Pages[tabTitle] = page

            tabItem.MouseButton1Click:Connect(function()
                for _, p in pairs(self.Pages) do
                    p.Visible = false
                end
                page.Visible = true

                for _, child in ipairs(self.SidebarScroll:GetDescendants()) do
                    if child.Name == "AccentBar" then
                        child.Visible = false
                    end
                end
                accentBar.Visible = true
                MakeTween(tabLabel, { TextColor3 = Library.Scheme.WhiteColor }, 0.1)
                self.ActiveTab = tabTitle
            end)
            tabItem.MouseEnter:Connect(function()
                MakeTween(tabLabel, { TextColor3 = Library.Scheme.FontColor }, 0.1)
            end)
            tabItem.MouseLeave:Connect(function()
                if self.ActiveTab ~= tabTitle then
                    MakeTween(tabLabel, { TextColor3 = Library.Scheme.MutedColor }, 0.1)
                end
            end)

            local tab = {}
            tab.Page = page
            tab.OrderCounter = 1

            function tab:AddToggle(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local track = Make("Frame", {
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = Library.Scheme.HoverColor,
                    BorderSizePixel = 0,
                    Parent = frame,
                })
                AddCorner(track, PILL_RADIUS)

                local thumb = Make("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Library.Scheme.MutedColor,
                    BorderSizePixel = 0,
                    Parent = track,
                })
                AddCorner(thumb, PILL_RADIUS)

                local btn = Make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = frame,
                })

                local value = info.Default or false
                local function updateVisual()
                    if value then
                        MakeTween(track, { BackgroundColor3 = Library.Scheme.AccentColor }, 0.15)
                        MakeTween(thumb, { Position = UDim.new(1, -18, 0.5, -8), BackgroundColor3 = Library.Scheme.WhiteColor }, 0.15)
                    else
                        MakeTween(track, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.15)
                        MakeTween(thumb, { Position = UDim.new(0, 2, 0.5, -8), BackgroundColor3 = Library.Scheme.MutedColor }, 0.15)
                    end
                end
                updateVisual()

                local obj = { Value = value, Type = "Toggle" }
                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(v)
                    obj.Value = v
                    updateVisual()
                    if obj._changed then obj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                btn.MouseButton1Click:Connect(function()
                    obj:SetValue(not obj.Value)
                end)

                Library.Toggles[idx] = obj
                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddSlider(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local min = info.Min or 0
                local max = info.Max or 100
                local default = info.Default or min
                local rounding = info.Rounding or 0
                local suffix = info.Suffix or ""
                local prefix = info.Prefix or ""

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, -60, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local valueLabel = Make("TextLabel", {
                    Size = UDim2.new(0, 60, 0, 16),
                    Position = UDim2.new(1, -60, 0, 0),
                    BackgroundTransparency = 1,
                    Text = prefix .. tostring(default) .. suffix,
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Enum.Font.Code,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = frame,
                })

                local trackBg = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Parent = frame,
                })
                AddCorner(trackBg, PILL_RADIUS)

                local fill = Make("Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Library.Scheme.AccentColor,
                    BorderSizePixel = 0,
                    Parent = trackBg,
                })
                AddCorner(fill, PILL_RADIUS)

                local thumb = Make("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = Library.Scheme.WhiteColor,
                    BorderSizePixel = 0,
                    Parent = trackBg,
                })
                AddCorner(thumb, PILL_RADIUS)

                local obj = { Value = default, Type = "Slider" }
                local dragging = false

                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(v)
                    v = math.clamp(v, min, max)
                    v = math.floor(v * 10 ^ rounding) / 10 ^ rounding
                    obj.Value = v
                    local pct = (v - min) / (max - min)
                    MakeTween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.1)
                    MakeTween(thumb, { Position = UDim2.new(pct, -7, 0.5, -7) }, 0.1)
                    valueLabel.Text = prefix .. tostring(v) .. suffix
                    if obj._changed then obj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                local function updateFromInput(inputX)
                    local pct = math.clamp((inputX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                    obj:SetValue(min + (max - min) * pct)
                end

                trackBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        updateFromInput(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromInput(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                obj:SetValue(default)
                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddDropdown(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local values = info.Values or {}
                local default = info.Default or values[1]

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local ddBtn = Make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = frame,
                })
                AddCorner(ddBtn)

                local ddLabel = Make("TextLabel", {
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default or "Select..."),
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = ddBtn,
                })

                local arrow = Make("TextLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(1, -24, 0.5, -8),
                    BackgroundTransparency = 1,
                    Text = "v",
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    Parent = ddBtn,
                })

                local menuHolder = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 10,
                    Parent = frame,
                })
                local menuBg = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 10,
                    Parent = menuHolder,
                })
                AddCorner(menuBg)
                AddStroke(menuBg, Library.Scheme.OutlineColor)
                AddListLayout(menuBg, 0)
                AddPadding(menuBg, 4, 4, 0, 0)

                local obj = { Value = default, Type = "Dropdown" }
                local menuOpen = false

                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(v)
                    obj.Value = v
                    ddLabel.Text = tostring(v)
                    if obj._changed then obj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                function obj:SetValues(newValues)
                    values = newValues
                    for _, child in ipairs(menuBg:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, v in ipairs(values) do
                        local item = Make("TextButton", {
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundTransparency = 1,
                            Text = "  " .. tostring(v),
                            TextColor3 = Library.Scheme.MutedColor,
                            Font = Enum.Font.Gotham,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 11,
                            Parent = menuBg,
                        })
                        item.MouseEnter:Connect(function()
                            MakeTween(item, { BackgroundColor3 = Library.Scheme.HoverColor, TextColor3 = Library.Scheme.WhiteColor }, 0.08)
                        end)
                        item.MouseLeave:Connect(function()
                            MakeTween(item, { BackgroundTransparency = 1, TextColor3 = Library.Scheme.MutedColor }, 0.08)
                        end)
                        item.MouseButton1Click:Connect(function()
                            obj:SetValue(v)
                            menuOpen = false
                            menuHolder.Visible = false
                            MakeTween(arrow, { Rotation = 0 }, 0.15)
                        end)
                    end
                end

                ddBtn.MouseButton1Click:Connect(function()
                    menuOpen = not menuOpen
                    menuHolder.Visible = menuOpen
                    MakeTween(arrow, { Rotation = menuOpen and 180 or 0 }, 0.15)
                end)

                obj:SetValues(values)
                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddColorPicker(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local default = info.Default or Color3.new(1, 1, 1)

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, -44, 1, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local colorBtn = Make("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -28, 0.5, -10),
                    BackgroundColor3 = default,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = frame,
                })
                AddCorner(colorBtn, UDim.new(0, 4))
                AddStroke(colorBtn, Library.Scheme.OutlineColor)

                local pickerOpen = false
                local pickerFrame = Make("Frame", {
                    Size = UDim2.new(0, 190, 0, 170),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 20,
                    Parent = contentScroll,
                })
                AddCorner(pickerFrame)
                AddStroke(pickerFrame, Library.Scheme.OutlineColor)

                local sat = Make("Frame", {
                    Size = UDim2.new(1, -16, 0, 110),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 21,
                    Parent = pickerFrame,
                })
                AddCorner(sat)

                local satOverlay = Make("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 22,
                    Parent = sat,
                })
                Make("UIGradient", {
                    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Rotation = 90,
                    ZIndex = 22,
                    Parent = satOverlay,
                })

                local hue = Make("Frame", {
                    Size = UDim2.new(1, -16, 0, 12),
                    Position = UDim2.new(0, 8, 0, 126),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 21,
                    Parent = pickerFrame,
                })
                AddCorner(hue, UDim.new(0, 3))
                Make("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                    }),
                    ZIndex = 21,
                    Parent = hue,
                })

                local h, s, v = Color3.toHSV(default)
                local curH, curS, curV = h, s, v

                local obj = { Value = default, Type = "ColorPicker" }
                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(c)
                    obj.Value = c
                    colorBtn.BackgroundColor3 = c
                    curH, curS, curV = Color3.toHSV(c)
                    if obj._changed then obj._changed(c) end
                    if info.Callback then info.Callback(c) end
                end

                local satDrag, hueDrag = false, false
                local function updateSat(input)
                    local px = math.clamp(input.Position.X - sat.AbsolutePosition.X, 0, sat.AbsoluteSize.X)
                    local py = math.clamp(input.Position.Y - sat.AbsolutePosition.Y, 0, sat.AbsoluteSize.Y)
                    curS = px / sat.AbsoluteSize.X
                    curV = 1 - (py / sat.AbsoluteSize.Y)
                    obj:SetValue(Color3.fromHSV(curH, curS, curV))
                end
                local function updateHue(input)
                    curH = math.clamp((input.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                    obj:SetValue(Color3.fromHSV(curH, curS, curV))
                end

                sat.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then satDrag = true; updateSat(input) end
                end)
                hue.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true; updateHue(input) end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if satDrag and input.UserInputType == Enum.UserInputType.MouseMovement then updateSat(input) end
                    if hueDrag and input.UserInputType == Enum.UserInputType.MouseMovement then updateHue(input) end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then satDrag = false; hueDrag = false end
                end)

                colorBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    pickerFrame.Visible = pickerOpen
                end)

                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddKeybind(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, -100, 1, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local keyBtn = Make("TextButton", {
                    Size = UDim2.new(0, 80, 0, 24),
                    Position = UDim2.new(1, -80, 0.5, -12),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = info.Default or "None",
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Enum.Font.Code,
                    TextSize = 12,
                    Parent = frame,
                })
                AddCorner(keyBtn)

                local obj = { Value = info.Default, Type = "Keybind" }
                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(v)
                    obj.Value = v
                    keyBtn.Text = tostring(v)
                    if obj._changed then obj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                local listening = false
                keyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    keyBtn.Text = "..."
                    keyBtn.BackgroundColor3 = Library.Scheme.AccentColor

                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            obj:SetValue(input.KeyCode.Name)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            obj:SetValue("MB1")
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            obj:SetValue("MB2")
                        end
                        listening = false
                        keyBtn.BackgroundColor3 = Library.Scheme.DarkColor
                        conn:Disconnect()
                    end)
                end)

                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddInput(idx, info)
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local frame = Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundTransparency = 1,
                    LayoutOrder = order,
                    Parent = page,
                })

                Make("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })

                local inputBox = Make("TextBox", {
                    Size = UDim2.new(1, 0, 0, 28),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = info.Default or "",
                    PlaceholderText = info.Placeholder or "",
                    PlaceholderColor3 = Library.Scheme.MutedColor,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    ClearTextOnFocus = info.ClearTextOnFocus ~= false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                })
                AddCorner(inputBox)
                AddPadding(inputBox, 0, 0, 8, 8)

                local obj = { Value = info.Default or "", Type = "Input" }
                function obj:OnChanged(func) obj._changed = func end
                function obj:SetValue(v)
                    obj.Value = v
                    inputBox.Text = v
                    if obj._changed then obj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                inputBox.FocusLost:Connect(function()
                    obj.Value = inputBox.Text
                    if obj._changed then obj._changed(obj.Value) end
                    if info.Callback then info.Callback(obj.Value) end
                end)

                Library.Options[idx] = obj
                tab[idx] = obj
                return obj
            end

            function tab:AddLabel(text)
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1
                return Make("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = text or "",
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = order,
                    Parent = page,
                })
            end

            function tab:AddButton(info, func)
                if type(info) == "string" then
                    func = info
                    info = { Text = info }
                end
                info = info or {}
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local btn = Make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Library.Scheme.HoverColor,
                    BorderSizePixel = 0,
                    Text = info.Text or "Button",
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    LayoutOrder = order,
                    Parent = page,
                })
                AddCorner(btn)

                btn.MouseEnter:Connect(function()
                    MakeTween(btn, { BackgroundColor3 = Library.Scheme.OutlineColor }, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    MakeTween(btn, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
                end)
                btn.MouseButton1Click:Connect(function()
                    if func then func() end
                    if info.Func then info.Func() end
                end)
            end

            function tab:AddDivider()
                local order = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1
                return Make("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                    BorderSizePixel = 0,
                    LayoutOrder = order,
                    Parent = page,
                })
            end

            return tab
        end

        return section
    end

    return sidebar
end

-- ==================== UNLOAD ====================
function Library:Unload()
    Library.Unloaded = true
    if self and self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return Library
