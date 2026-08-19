--[[
    potassium-ui
    A Potassium-styled UI library for Roblox exploits
    https://github.com/potassium-ui
]]

local Library = {}
Library.__index = Library
Library.Toggles = {}
Library.Options = {}
Library.Unloaded = false

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
    RedColor = Color3.fromRGB(240, 106, 99),
    Font = Enum.Font.Code,
}

local CORNER_RADIUS = UDim.new(0, 4)
local PILL_RADIUS = UDim.new(0, 10)

local function Tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function Create(class, props)
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
    return Create("UICorner", { CornerRadius = radius or CORNER_RADIUS, Parent = parent })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", { Color = color or Library.Scheme.OutlineColor, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end

local function AddPadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    })
end

local function AddListLayout(parent, padding, direction)
    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 4),
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent,
    })
    return layout
end

local function GetTextBounds(text, font, size)
    local temp = Create("TextLabel", { Text = text, Font = font or Library.Scheme.Font, TextSize = size or 13, Visible = false, Parent = game:GetService("CoreGui") })
    local bounds = temp.TextBounds
    temp:Destroy()
    return bounds
end

local Mouse = Players.LocalPlayer:GetMouse()

-- ==================== NOTIFICATION ====================
local Notifications = {}

function Library:Notify(info)
    if type(info) == "string" then
        info = { Title = "Notification", Description = info, Time = 3 }
    end
    info.Time = info.Time or 3

    local notifHolder = Create("Frame", {
        Size = UDim2.new(0, 280, 0, 60),
        Position = UDim2.new(1, -290, 1, 0),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Library.Scheme.MainColor,
        BorderSizePixel = 0,
        Parent = Library.NotifContainer,
    })
    AddCorner(notifHolder)
    AddStroke(notifHolder, Library.Scheme.OutlineColor)

    Create("Frame", {
        Size = UDim2.new(0, 3, 1),
        BackgroundColor3 = Library.Scheme.AccentColor,
        BorderSizePixel = 0,
        Parent = notifHolder,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 12, 0, 10),
        BackgroundTransparency = 1,
        Text = info.Title or "Notification",
        TextColor3 = Library.Scheme.WhiteColor,
        Font = Library.Scheme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notifHolder,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.new(0, 12, 0, 30),
        BackgroundTransparency = 1,
        Text = info.Description or "",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Library.Scheme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notifHolder,
    })

    notifHolder.Position = UDim2.new(1, 10, 1, -70 - (#Notifications * 65))
    Tween(notifHolder, { Position = UDim2.new(1, -290, 1, -70 - (#Notifications * 65)) }, 0.3)

    table.insert(Notifications, notifHolder)

    task.delay(info.Time, function()
        Tween(notifHolder, { Position = UDim2.new(1, 10, 1, -70 - (#Notifications * 65)) }, 0.3)
        task.delay(0.3, function()
            notifHolder:Destroy()
            for i, v in ipairs(Notifications) do
                if v == notifHolder then
                    table.remove(Notifications, i)
                    break
                end
            end
            for i, v in ipairs(Notifications) do
                Tween(v, { Position = UDim2.new(1, -290, 1, -70 - ((i - 1) * 65)) }, 0.2)
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

    local screenGui = Create("ScreenGui", {
        Name = "PotassiumUI",
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = game:GetService("CoreGui"),
    })
    self.ScreenGui = screenGui

    local notifContainer = Create("Frame", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    AddListLayout(notifContainer, 5)
    Library.NotifContainer = notifContainer

    local mainFrame = Create("Frame", {
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
    local titlebar = Create("Frame", {
        Name = "Titlebar",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Library.Scheme.BackgroundColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = titlebar,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library.Scheme.FontColor,
        Font = Library.Scheme.Font,
        TextSize = 13,
        Parent = titlebar,
    })

    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 46, 1, 0),
        Position = UDim2.new(1, -46, 0, 0),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Library.Scheme.Font,
        TextSize = 16,
        Parent = titlebar,
    })
    closeBtn.MouseButton1Click:Connect(function()
        Library:Unload()
    end)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Library.Scheme.AccentColor, TextColor3 = Color3.new(1, 1, 1) }, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundTransparency = 1, TextColor3 = Library.Scheme.MutedColor }, 0.1)
    end)

    local minBtn = Create("TextButton", {
        Size = UDim2.new(0, 46, 1, 0),
        Position = UDim2.new(1, -92, 0, 0),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = Library.Scheme.MutedColor,
        Font = Library.Scheme.Font,
        TextSize = 14,
        Parent = titlebar,
    })
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, { BackgroundTransparency = 1 }, 0.1)
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
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 220, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Library.Scheme.SidebarColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self.Sidebar = sidebar

    -- Sidebar scroll
    local sidebarScroll = Create("ScrollingFrame", {
        Name = "SidebarScroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.Scheme.OutlineColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    AddPadding(sidebarScroll, 4, 4, 0, 0)
    local sidebarLayout = AddListLayout(sidebarScroll, 0)
    self.SidebarScroll = sidebarScroll
    self.SidebarLayout = sidebarLayout

    -- Content area
    local content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -220, 1, -35),
        Position = UDim2.new(0, 220, 0, 35),
        BackgroundColor3 = Library.Scheme.MainColor,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    self.Content = content

    -- Content scroll
    local contentScroll = Create("ScrollingFrame", {
        Name = "ContentScroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Library.Scheme.OutlineColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = content,
    })
    AddPadding(contentScroll, 12, 12, 12, 12)
    AddListLayout(contentScroll, 8)
    self.ContentScroll = contentScroll

    -- Footer
    if self.Footer ~= "" then
        local footer = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.new(0, 0, 1, -24),
            BackgroundColor3 = Library.Scheme.BackgroundColor,
            BorderSizePixel = 0,
            Parent = mainFrame,
        })
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Library.Scheme.OutlineColor,
            BorderSizePixel = 0,
            Parent = footer,
        })
        Create("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = self.Footer,
            TextColor3 = Library.Scheme.MutedColor,
            Font = Library.Scheme.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = footer,
        })
    end

    return self
end

-- ==================== SIDEBAR ====================
function Library:Sidebar(title)
    local sidebarHeader = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Library.Scheme.SidebarColor,
        BorderSizePixel = 0,
        LayoutOrder = 0,
        Parent = self.SidebarScroll,
    })
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Library.Scheme.OutlineColor,
        BorderSizePixel = 0,
        Parent = sidebarHeader,
    })

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Explorer",
        TextColor3 = Library.Scheme.FontColor,
        Font = Library.Scheme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebarHeader,
    })

    local sidebar = {}
    sidebar.Sections = {}
    sidebar.ScrollFrame = self.SidebarScroll
    sidebar.Layout = self.SidebarLayout
    sidebar.OrderCounter = 1

    function sidebar:Section(sectionTitle)
        local sectionOrder = sidebar.OrderCounter
        sidebar.OrderCounter = sidebar.OrderCounter + 1

        local sectionHeader = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = sectionOrder,
            Parent = sidebar.ScrollFrame,
        })

        local chevron = Create("TextLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 10, 0.5, -7),
            BackgroundTransparency = 1,
            Text = "▶",
            TextColor3 = Library.Scheme.MutedColor,
            Font = Library.Scheme.Font,
            TextSize = 8,
            Parent = sectionHeader,
        })

        Create("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            Text = sectionTitle or "SECTION",
            TextColor3 = Library.Scheme.MutedColor,
            Font = Library.Scheme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sectionHeader,
        })

        local sectionContent = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = sectionOrder + 0.5,
            Visible = false,
            Parent = sidebar.ScrollFrame,
        })
        AddListLayout(sectionContent, 0)
        local contentOrderCounter = 1

        local expanded = false
        sectionHeader.MouseButton1Click:Connect(function()
            expanded = not expanded
            sectionContent.Visible = expanded
            Tween(chevron, { Rotation = expanded and 90 or 0 }, 0.15)
        end)
        sectionHeader.MouseEnter:Connect(function()
            Tween(sectionHeader, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
        end)
        sectionHeader.MouseLeave:Connect(function()
            Tween(sectionHeader, { BackgroundTransparency = 1 }, 0.1)
        end)

        local section = {}
        section.Header = sectionHeader
        section.Content = sectionContent

        function section:Tab(tabTitle, icon)
            local tabOrder = contentOrderCounter
            contentOrderCounter = contentOrderCounter + 1

            local tabItem = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = tabOrder,
                Parent = sectionContent,
            })

            local accentBar = Create("Frame", {
                Size = UDim2.new(0, 2, 0, 14),
                Position = UDim2.new(0, 22, 0.5, -7),
                BackgroundColor3 = Library.Scheme.AccentColor,
                BorderSizePixel = 0,
                Visible = false,
                Parent = tabItem,
            })

            local tabLabel = Create("TextLabel", {
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 32, 0, 0),
                BackgroundTransparency = 1,
                Text = tabTitle,
                TextColor3 = Library.Scheme.MutedColor,
                Font = Library.Scheme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tabItem,
            })

            local page = Create("Frame", {
                Name = tabTitle .. "_Page",
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
                Parent = self.ContentScroll,
            })
            AddListLayout(page, 8)
            self.Pages[tabTitle] = page

            local active = false
            tabItem.MouseButton1Click:Connect(function()
                for name, p in pairs(self.Pages) do
                    p.Visible = false
                end
                page.Visible = true

                for _, child in ipairs(sidebar.ScrollFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        for _, subChild in ipairs(child:GetChildren()) do
                            if subChild.Name == "AccentBar" then
                                subChild.Visible = false
                            end
                        end
                    end
                end
                for _, child in ipairs(sectionContent:GetChildren()) do
                    if child:IsA("TextButton") then
                        for _, subChild in ipairs(child:GetChildren()) do
                            if subChild.Name == "AccentBar" then
                                subChild.Visible = false
                            end
                        end
                    end
                end
                accentBar.Visible = true
                Tween(tabLabel, { TextColor3 = Library.Scheme.WhiteColor }, 0.1)
                self.ActiveTab = tabTitle
            end)
            tabItem.MouseEnter:Connect(function()
                if not active then
                    Tween(tabLabel, { TextColor3 = Library.Scheme.FontColor }, 0.1)
                end
            end)
            tabItem.MouseLeave:Connect(function()
                if not active then
                    Tween(tabLabel, { TextColor3 = Library.Scheme.MutedColor }, 0.1)
                end
            end)

            local tab = {}
            tab.Page = page
            tab.Elements = {}
            tab.OrderCounter = 1

            function tab:AddToggle(idx, info)
                if type(idx) == "string" and type(info) == "table" then
                    -- standard
                elseif type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Toggle" .. math.random(100000))
                end
                info = info or {}
                local toggleOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local toggleFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = toggleOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleFrame,
                })

                local track = Create("Frame", {
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = Library.Scheme.HoverColor,
                    BorderSizePixel = 0,
                    Parent = toggleFrame,
                })
                AddCorner(track, PILL_RADIUS)

                local thumb = Create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Library.Scheme.MutedColor,
                    BorderSizePixel = 0,
                    Parent = track,
                })
                AddCorner(thumb, PILL_RADIUS)

                local toggleBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = toggleFrame,
                })

                local value = info.Default or false
                local function updateVisual()
                    if value then
                        Tween(track, { BackgroundColor3 = Library.Scheme.AccentColor }, 0.15)
                        Tween(thumb, { Position = UDim.new(1, -18, 0.5, -8), BackgroundColor3 = Library.Scheme.WhiteColor }, 0.15)
                    else
                        Tween(track, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.15)
                        Tween(thumb, { Position = UDim.new(0, 2, 0.5, -8), BackgroundColor3 = Library.Scheme.MutedColor }, 0.15)
                    end
                end
                updateVisual()

                local toggleObj = {
                    Value = value,
                    Type = "Toggle",
                }

                function toggleObj:OnChanged(func)
                    toggleObj._changed = func
                end

                function toggleObj:SetValue(v)
                    toggleObj.Value = v
                    updateVisual()
                    if toggleObj._changed then toggleObj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                toggleBtn.MouseButton1Click:Connect(function()
                    toggleObj:SetValue(not toggleObj.Value)
                end)

                Library.Toggles[idx] = toggleObj
                Library.Options[idx] = toggleObj
                tab.Elements[idx] = toggleObj
                return toggleObj
            end

            function tab:AddButton(info, func)
                if type(info) == "string" then
                    func = info
                    info = { Text = info }
                end
                info = info or {}
                local btnOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local btn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Library.Scheme.HoverColor,
                    BorderSizePixel = 0,
                    Text = info.Text or "Button",
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    LayoutOrder = btnOrder,
                    Parent = page,
                })
                AddCorner(btn)

                btn.MouseEnter:Connect(function()
                    Tween(btn, { BackgroundColor3 = Library.Scheme.OutlineColor }, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, { BackgroundColor3 = Library.Scheme.HoverColor }, 0.1)
                end)
                btn.MouseButton1Click:Connect(function()
                    if func then func() end
                    if info.Func then info.Func() end
                end)
            end

            function tab:AddSlider(idx, info)
                if type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Slider" .. math.random(100000))
                end
                info = info or {}
                local sliderOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local min = info.Min or 0
                local max = info.Max or 100
                local default = info.Default or min
                local rounding = info.Rounding or 0
                local suffix = info.Suffix or ""
                local prefix = info.Prefix or ""

                local sliderFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    LayoutOrder = sliderOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, -60, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sliderFrame,
                })

                local valueLabel = Create("TextLabel", {
                    Size = UDim2.new(0, 60, 0, 16),
                    Position = UDim2.new(1, -60, 0, 0),
                    BackgroundTransparency = 1,
                    Text = prefix .. tostring(default) .. suffix,
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Library.Scheme.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = sliderFrame,
                })

                local trackBg = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Parent = sliderFrame,
                })
                AddCorner(trackBg, PILL_RADIUS)

                local fill = Create("Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Library.Scheme.AccentColor,
                    BorderSizePixel = 0,
                    Parent = trackBg,
                })
                AddCorner(fill, PILL_RADIUS)

                local thumb = Create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = Library.Scheme.WhiteColor,
                    BorderSizePixel = 0,
                    Parent = trackBg,
                })
                AddCorner(thumb, PILL_RADIUS)

                local sliderObj = { Value = default, Type = "Slider" }
                local dragging = false

                function sliderObj:OnChanged(func)
                    sliderObj._changed = func
                end

                function sliderObj:SetValue(v)
                    v = math.clamp(v, min, max)
                    v = math.floor(v * 10^rounding) / 10^rounding
                    sliderObj.Value = v
                    local pct = (v - min) / (max - min)
                    Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.1)
                    Tween(thumb, { Position = UDim2.new(pct, -7, 0.5, -7) }, 0.1)
                    valueLabel.Text = prefix .. tostring(v) .. suffix
                    if sliderObj._changed then sliderObj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                local function updateFromInput(inputX)
                    local absPos = trackBg.AbsolutePosition.X
                    local absSize = trackBg.AbsoluteSize.X
                    local pct = math.clamp((inputX - absPos) / absSize, 0, 1)
                    local val = min + (max - min) * pct
                    sliderObj:SetValue(val)
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

                sliderObj:SetValue(default)
                Library.Options[idx] = sliderObj
                tab.Elements[idx] = sliderObj
                return sliderObj
            end

            function tab:AddDropdown(idx, info)
                if type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Dropdown" .. math.random(100000))
                end
                info = info or {}
                local ddOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local values = info.Values or {}
                local default = info.Default or values[1]

                local ddFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 50),
                    BackgroundTransparency = 1,
                    LayoutOrder = ddOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ddFrame,
                })

                local ddBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = ddFrame,
                })
                AddCorner(ddBtn)

                local ddLabel = Create("TextLabel", {
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default or "Select..."),
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = ddBtn,
                })

                local arrow = Create("TextLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(1, -24, 0.5, -8),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Library.Scheme.Font,
                    TextSize = 10,
                    Parent = ddBtn,
                })

                local menu = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 10,
                    Parent = ddBtn,
                })
                AddCorner(menu)
                AddStroke(menu, Library.Scheme.OutlineColor)
                local menuLayout = AddListLayout(menu, 0)
                Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = menu })

                local ddObj = { Value = default, Type = "Dropdown" }
                local menuOpen = false

                function ddObj:OnChanged(func)
                    ddObj._changed = func
                end

                function ddObj:SetValue(v)
                    ddObj.Value = v
                    ddLabel.Text = tostring(v)
                    if ddObj._changed then ddObj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                function ddObj:SetValues(newValues)
                    values = newValues
                    for _, child in ipairs(menu:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, v in ipairs(values) do
                        local item = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundTransparency = 1,
                            Text = tostring(v),
                            TextColor3 = Library.Scheme.MutedColor,
                            Font = Library.Scheme.Font,
                            TextSize = 12,
                            ZIndex = 11,
                            Parent = menu,
                        })
                        item.MouseEnter:Connect(function()
                            Tween(item, { BackgroundColor3 = Library.Scheme.HoverColor, TextColor3 = Library.Scheme.WhiteColor }, 0.08)
                        end)
                        item.MouseLeave:Connect(function()
                            Tween(item, { BackgroundTransparency = 1, TextColor3 = Library.Scheme.MutedColor }, 0.08)
                        end)
                        item.MouseButton1Click:Connect(function()
                            ddObj:SetValue(v)
                            menuOpen = false
                            menu.Visible = false
                        end)
                    end
                end

                ddBtn.MouseButton1Click:Connect(function()
                    menuOpen = not menuOpen
                    menu.Visible = menuOpen
                    if menuOpen then
                        Tween(arrow, { Rotation = 180 }, 0.15)
                    else
                        Tween(arrow, { Rotation = 0 }, 0.15)
                    end
                end)

                ddObj:SetValues(values)
                Library.Options[idx] = ddObj
                tab.Elements[idx] = ddObj
                return ddObj
            end

            function tab:AddColorPicker(idx, info)
                if type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Color" .. math.random(100000))
                end
                info = info or {}
                local cpOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local default = info.Default or Color3.new(1, 1, 1)

                local cpFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = cpOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, -44, 1, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = cpFrame,
                })

                local colorBtn = Create("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -28, 0.5, -10),
                    BackgroundColor3 = default,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = cpFrame,
                })
                AddCorner(colorBtn, UDim.new(0, 4))
                AddStroke(colorBtn, Library.Scheme.OutlineColor)

                local cpObj = { Value = default, Type = "ColorPicker" }
                local pickerOpen = false

                local pickerFrame = Create("Frame", {
                    Size = UDim2.new(0, 200, 0, 180),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 20,
                    Parent = page,
                })
                AddCorner(pickerFrame)
                AddStroke(pickerFrame, Library.Scheme.OutlineColor)

                local sat = Create("Frame", {
                    Size = UDim2.new(1, -16, 0, 120),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 21,
                    Parent = pickerFrame,
                })
                AddCorner(sat)

                local gradient = Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                    }),
                    Rotation = 0,
                    ZIndex = 21,
                    Parent = sat,
                })
                local satOverlay = Create("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 22,
                    Parent = sat,
                })
                local satGrad = Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Rotation = 90,
                    ZIndex = 22,
                    Parent = satOverlay,
                })

                local hue = Create("Frame", {
                    Size = UDim2.new(1, -16, 0, 12),
                    Position = UDim2.new(0, 8, 0, 134),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 21,
                    Parent = pickerFrame,
                })
                AddCorner(hue, UDim.new(0, 3))
                local hueGrad = Create("UIGradient", {
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

                local hueSlider = Create("Frame", {
                    Size = UDim2.new(0, 4, 1, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 22,
                    Parent = hue,
                })
                AddCorner(hueSlider, UDim.new(0, 2))
                AddStroke(hueSlider, Color3.new(0, 0, 0), 1)

                local h, s, v = Color3.toHSV(default)
                local currentH, currentS, currentV = h, s, v

                function cpObj:OnChanged(func)
                    cpObj._changed = func
                end

                function cpObj:SetValue(c)
                    cpObj.Value = c
                    colorBtn.BackgroundColor3 = c
                    local ch, cs, cv = Color3.toHSV(c)
                    currentH, currentS, currentV = ch, cs, cv
                    if cpObj._changed then cpObj._changed(c) end
                    if info.Callback then info.Callback(c) end
                end

                local satDragging = false
                local hueDragging = false

                local function updateSat(input)
                    local pos = Vector2.new(
                        math.clamp(input.Position.X - sat.AbsolutePosition.X, 0, sat.AbsoluteSize.X),
                        math.clamp(input.Position.Y - sat.AbsolutePosition.Y, 0, sat.AbsoluteSize.Y)
                    )
                    currentS = pos.X / sat.AbsoluteSize.X
                    currentV = 1 - (pos.Y / sat.AbsoluteSize.Y)
                    cpObj:SetValue(Color3.fromHSV(currentH, currentS, currentV))
                end

                local function updateHue(input)
                    local pos = math.clamp((input.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                    currentH = pos
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(currentH, 0, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(currentH, 1, 1)),
                    })
                    cpObj:SetValue(Color3.fromHSV(currentH, currentS, currentV))
                end

                sat.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        satDragging = true
                        updateSat(input)
                    end
                end)
                hue.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                        updateHue(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if satDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSat(input)
                    end
                    if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateHue(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        satDragging = false
                        hueDragging = false
                    end
                end)

                colorBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    pickerFrame.Visible = pickerOpen
                    if pickerOpen then
                        pickerFrame.Position = UDim2.new(0, colorBtn.AbsolutePosition.X - page.AbsolutePosition.X, 0, colorBtn.AbsolutePosition.Y - page.AbsolutePosition.Y + 36)
                    end
                end)

                Library.Options[idx] = cpObj
                tab.Elements[idx] = cpObj
                return cpObj
            end

            function tab:AddKeybind(idx, info)
                if type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Keybind" .. math.random(100000))
                end
                info = info or {}
                local kbOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local kbFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    LayoutOrder = kbOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, -100, 1, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = kbFrame,
                })

                local keyBtn = Create("TextButton", {
                    Size = UDim2.new(0, 80, 0, 24),
                    Position = UDim2.new(1, -80, 0.5, -12),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = info.Default or "None",
                    TextColor3 = Library.Scheme.MutedColor,
                    Font = Library.Scheme.Font,
                    TextSize = 12,
                    Parent = kbFrame,
                })
                AddCorner(keyBtn)

                local kbObj = { Value = info.Default, Type = "Keybind", Mode = info.Mode or "Toggle" }
                local listening = false

                function kbObj:OnChanged(func)
                    kbObj._changed = func
                end

                function kbObj:SetValue(v)
                    kbObj.Value = v
                    keyBtn.Text = tostring(v)
                    if kbObj._changed then kbObj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                keyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    keyBtn.Text = "..."
                    keyBtn.BackgroundColor3 = Library.Scheme.AccentColor

                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            kbObj:SetValue(input.KeyCode.Name)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            kbObj:SetValue("MB1")
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            kbObj:SetValue("MB2")
                        end
                        listening = false
                        keyBtn.BackgroundColor3 = Library.Scheme.DarkColor
                        conn:Disconnect()
                    end)
                end)

                Library.Options[idx] = kbObj
                tab.Elements[idx] = kbObj
                return kbObj
            end

            function tab:AddInput(idx, info)
                if type(idx) == "table" then
                    info = idx
                    idx = info.Index or info.Idx or ("Input" .. math.random(100000))
                end
                info = info or {}
                local inputOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local inputFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 50),
                    BackgroundTransparency = 1,
                    LayoutOrder = inputOrder,
                    Parent = page,
                })

                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = info.Text or idx,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = inputFrame,
                })

                local inputBox = Create("TextBox", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = Library.Scheme.DarkColor,
                    BorderSizePixel = 0,
                    Text = info.Default or "",
                    PlaceholderText = info.Placeholder or "",
                    PlaceholderColor3 = Library.Scheme.MutedColor,
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 12,
                    ClearTextOnFocus = info.ClearTextOnFocus ~= false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = inputFrame,
                })
                AddCorner(inputBox)
                AddPadding(inputBox, 0, 0, 8, 8)

                local inputObj = { Value = info.Default or "", Type = "Input" }

                function inputObj:OnChanged(func)
                    inputObj._changed = func
                end

                function inputObj:SetValue(v)
                    inputObj.Value = v
                    inputBox.Text = v
                    if inputObj._changed then inputObj._changed(v) end
                    if info.Callback then info.Callback(v) end
                end

                inputBox.FocusLost:Connect(function()
                    inputObj.Value = inputBox.Text
                    if inputObj._changed then inputObj._changed(inputObj.Value) end
                    if info.Callback then info.Callback(inputObj.Value) end
                end)

                Library.Options[idx] = inputObj
                tab.Elements[idx] = inputObj
                return inputObj
            end

            function tab:AddLabel(text)
                local labelOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local label = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = text or "",
                    TextColor3 = Library.Scheme.FontColor,
                    Font = Library.Scheme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = labelOrder,
                    Parent = page,
                })

                return label
            end

            function tab:AddDivider()
                local divOrder = tab.OrderCounter
                tab.OrderCounter = tab.OrderCounter + 1

                local divider = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                    BorderSizePixel = 0,
                    LayoutOrder = divOrder,
                    Parent = page,
                })

                return divider
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

-- ==================== UPDATE COLORS ====================
function Library:UpdateColors()
    if self and self.MainFrame then
        self.MainFrame.BackgroundColor3 = Library.Scheme.MainColor
    end
end

return Library
