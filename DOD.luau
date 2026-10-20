--[[
                        _               _              
  _ __ __ _ _ __  _ __ | |_ ___ _______| |_ _   _  ___ 
 | '__/ _` | '_ \| '_ \| __/ _ \_  / _ \ __| | | |/ _ \
 | | | (_| | |_) | |_) | ||  __// /  __/ |_| |_| |  __/
 |_|  \__,_| .__/| .__/ \__\___/___\___|\__|\__, |\___|
           |_|   |_|                        |___/      

		   discord.gg/rapptezetyee
			t.me/HGithub


]]

local Library = {}
Library.__index = Library

-- Load Icons Library (Footagesus/Icons)
local IconsV2
pcall(function()
    IconsV2 = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
    IconsV2.SetIconsType("lucide")
end)

local function GetIcon(name)
    if IconsV2 then
        local ok, icon = pcall(function() return IconsV2.GetIcon(name) end)
        if ok and icon then return icon end
    end
    return "rbxassetid://6031075931" -- fallback: code icon
end

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats              = game:GetService("Stats")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local CoreGui            = game:GetService("CoreGui")
local Lighting           = game:GetService("Lighting")
local SoundService       = game:GetService("SoundService")
local LocalPlayer        = Players.LocalPlayer

local function getCam() return workspace.CurrentCamera end

local GuiSound = {
    Click     = { id = "rbxassetid://6895079853", pitch = 1.10, vol = 0.32 },
    ToggleOn  = { id = "rbxassetid://6895079853", pitch = 1.40, vol = 0.35 },
    ToggleOff = { id = "rbxassetid://6895079853", pitch = 0.88, vol = 0.28 },
    TabSwitch = { id = "rbxassetid://6895079853", pitch = 1.25, vol = 0.30 },
    Dropdown  = { id = "rbxassetid://6895079853", pitch = 1.00, vol = 0.30 },
    Notify    = { id = "rbxassetid://4590662766", pitch = 1.35, vol = 0.38 }
}

-- =========================================================
-- SHARED STATE / UTILITIES
-- =========================================================

local Fn = {}
local D  = {}

Fn.track = function(signal, callback, owner)
    if not owner or not owner._STATE or not owner._STATE.TrackedConns then
        error("[DoD UI] Tracked connections require a library owner.")
    end
    local conn = signal:Connect(callback)
    table.insert(owner._STATE.TrackedConns, conn)
    return conn
end

Fn.disconnectAll = function(owner)
    local connections = owner._STATE.TrackedConns
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
end

Fn.untrack = function(connection, owner)
    local connections = owner._STATE.TrackedConns
    local index = table.find(connections, connection)
    if index then table.remove(connections, index) end
    connection:Disconnect()
end

Fn.bindPressAnimation = function(guiObject)
    local scale = guiObject:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale", guiObject)
        scale.Scale = 1
    end
    local baseScale = scale.Scale
    local activeTween

    local function animate(factor)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(
            scale,
            TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = baseScale * factor}
        )
        activeTween:Play()
    end

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            animate(0.96)
        end
    end)
    guiObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            animate(1)
        end
    end)
    guiObject.MouseLeave:Connect(function()
        animate(1)
    end)
    return scale
end

Fn.accentTextColor = function(color)
    local function lin(c)
        if c <= 0.04045 then return c / 12.92 end
        return ((c + 0.055) / 1.055) ^ 2.4
    end
    local lum = 0.2126 * lin(color.R) + 0.7152 * lin(color.G) + 0.0722 * lin(color.B)
    return lum > 0.179 and Color3.fromRGB(20, 22, 28) or Color3.fromRGB(255, 255, 255)
end

-- =========================================================
-- THEMES (20 presets)
-- =========================================================

D.Themes = {
    Dark = {
        Accent = Color3.fromRGB(180, 180, 195),
        Accent2 = Color3.fromRGB(100, 100, 120),
        FocusOverlayColor = Color3.fromRGB(2, 2, 5),
        Bg = Color3.fromRGB(8, 8, 12),
        Bg2 = Color3.fromRGB(14, 14, 20),
        Card = Color3.fromRGB(20, 20, 28),
        Sidebar = Color3.fromRGB(10, 10, 15),
        Border = Color3.fromRGB(40, 40, 50),
        Text = Color3.fromRGB(220, 220, 230),
        TextDim = Color3.fromRGB(140, 140, 155),
        OverlayTransparency = 0.38,
    },
    Indigo = {
        Accent = Color3.fromRGB(99, 102, 241),
        Accent2 = Color3.fromRGB(139, 92, 246),
        OverlayColor = Color3.fromRGB(10, 9, 27),
        OverlayTransparency = 0.44,
    },
    Red = {
        Accent = Color3.fromRGB(248, 113, 113),
        Accent2 = Color3.fromRGB(239, 68, 68),
        OverlayColor = Color3.fromRGB(25, 8, 10),
        OverlayTransparency = 0.42,
    },
    Green = {
        Accent = Color3.fromRGB(52, 211, 153),
        Accent2 = Color3.fromRGB(16, 185, 129),
        OverlayColor = Color3.fromRGB(5, 22, 18),
        OverlayTransparency = 0.42,
    },
    Purple = {
        Accent = Color3.fromRGB(168, 85, 247),
        Accent2 = Color3.fromRGB(192, 38, 211),
        OverlayColor = Color3.fromRGB(15, 8, 24),
        OverlayTransparency = 0.44,
    },
    Orange = {
        Accent = Color3.fromRGB(251, 146, 60),
        Accent2 = Color3.fromRGB(249, 115, 22),
        OverlayColor = Color3.fromRGB(26, 14, 7),
        OverlayTransparency = 0.42,
    },
    Christmas = {
        Accent = Color3.fromRGB(220, 40, 40),
        Accent2 = Color3.fromRGB(30, 150, 70),
        FocusOverlayColor = Color3.fromRGB(20, 40, 25),
        Bg = Color3.fromRGB(18, 22, 20),
        Bg2 = Color3.fromRGB(25, 32, 28),
        Card = Color3.fromRGB(35, 45, 40),
        Sidebar = Color3.fromRGB(15, 20, 18),
        Border = Color3.fromRGB(80, 50, 50),
        Text = Color3.fromRGB(245, 245, 240),
        TextDim = Color3.fromRGB(200, 170, 170),
        GridColor = Color3.fromRGB(30, 150, 70),
        GridAltColor = Color3.fromRGB(220, 40, 40),
        OverlayTransparency = 0.4,
    },
    Ocean = {
        Accent = Color3.fromRGB(45, 170, 205),
        Accent2 = Color3.fromRGB(32, 112, 175),
        OverlayColor = Color3.fromRGB(5, 18, 28),
        OverlayTransparency = 0.42,
    },
    Rose = {
        Accent = Color3.fromRGB(244, 114, 182),
        Accent2 = Color3.fromRGB(219, 39, 119),
        OverlayColor = Color3.fromRGB(27, 8, 20),
        OverlayTransparency = 0.42,
    },
    Forest = {
        Accent = Color3.fromRGB(132, 184, 96),
        Accent2 = Color3.fromRGB(65, 135, 82),
        OverlayColor = Color3.fromRGB(12, 22, 10),
        OverlayTransparency = 0.42,
    },
    Sunset = {
        Accent = Color3.fromRGB(247, 135, 83),
        Accent2 = Color3.fromRGB(221, 83, 92),
        OverlayColor = Color3.fromRGB(27, 11, 10),
        OverlayTransparency = 0.42,
    },
    Arctic = {
        Accent = Color3.fromRGB(125, 211, 252),
        Accent2 = Color3.fromRGB(147, 197, 253),
        OverlayColor = Color3.fromRGB(8, 19, 30),
        OverlayTransparency = 0.46,
    },
    Gold = {
        Accent = Color3.fromRGB(234, 179, 8),
        Accent2 = Color3.fromRGB(202, 138, 4),
        OverlayColor = Color3.fromRGB(27, 20, 5),
        OverlayTransparency = 0.42,
    },
    Midnight = {
        Accent = Color3.fromRGB(90, 150, 255),
        Accent2 = Color3.fromRGB(50, 200, 255),
        FocusOverlayColor = Color3.fromRGB(5, 10, 30),
        Bg = Color3.fromRGB(8, 10, 22),
        Bg2 = Color3.fromRGB(14, 18, 35),
        Card = Color3.fromRGB(20, 26, 48),
        Sidebar = Color3.fromRGB(6, 8, 18),
        Border = Color3.fromRGB(40, 55, 90),
    },
    Cyberpunk = {
        Accent = Color3.fromRGB(255, 20, 150),
        Accent2 = Color3.fromRGB(0, 240, 255),
        FocusOverlayColor = Color3.fromRGB(30, 5, 40),
        Bg = Color3.fromRGB(15, 5, 25),
        Bg2 = Color3.fromRGB(25, 10, 40),
        Card = Color3.fromRGB(35, 15, 55),
        Sidebar = Color3.fromRGB(12, 3, 20),
        Border = Color3.fromRGB(100, 30, 150),
    },
    Monochrome = {
        Accent = Color3.fromRGB(230, 230, 230),
        Accent2 = Color3.fromRGB(150, 150, 150),
        FocusOverlayColor = Color3.fromRGB(10, 10, 10),
        Bg = Color3.fromRGB(12, 12, 12),
        Bg2 = Color3.fromRGB(20, 20, 20),
        Card = Color3.fromRGB(30, 30, 30),
        Sidebar = Color3.fromRGB(8, 8, 8),
        Border = Color3.fromRGB(60, 60, 60),
    },
    Neon = {
        Accent = Color3.fromRGB(60, 255, 130),
        Accent2 = Color3.fromRGB(200, 255, 60),
        FocusOverlayColor = Color3.fromRGB(5, 30, 15),
        Bg = Color3.fromRGB(6, 15, 10),
        Bg2 = Color3.fromRGB(12, 25, 18),
        Card = Color3.fromRGB(20, 40, 28),
        Sidebar = Color3.fromRGB(4, 10, 6),
        Border = Color3.fromRGB(40, 100, 60),
    },
    BloodMoon = {
        Accent = Color3.fromRGB(200, 20, 40),
        Accent2 = Color3.fromRGB(255, 90, 20),
        FocusOverlayColor = Color3.fromRGB(40, 5, 10),
        Bg = Color3.fromRGB(15, 5, 8),
        Bg2 = Color3.fromRGB(25, 8, 12),
        Card = Color3.fromRGB(40, 12, 20),
        Sidebar = Color3.fromRGB(10, 3, 5),
        Border = Color3.fromRGB(80, 20, 30),
    },
    Ice = {
        Accent = Color3.fromRGB(180, 230, 255),
        Accent2 = Color3.fromRGB(100, 190, 255),
        FocusOverlayColor = Color3.fromRGB(10, 25, 45),
        Bg = Color3.fromRGB(12, 20, 30),
        Bg2 = Color3.fromRGB(20, 30, 45),
        Card = Color3.fromRGB(32, 48, 68),
        Sidebar = Color3.fromRGB(8, 15, 22),
        Border = Color3.fromRGB(60, 100, 140),
    },
    ["Demon of Darkness"] = {
        Accent = Color3.fromRGB(200, 20, 40),
        Accent2 = Color3.fromRGB(150, 24, 16),
        FocusOverlayColor = Color3.fromRGB(32, 3, 8),
        OverlayColor = Color3.fromRGB(24, 2, 6),
        OverlayTransparency = 0.34,
        Bg = Color3.fromRGB(5, 4, 6),
        Bg2 = Color3.fromRGB(13, 7, 9),
        Card = Color3.fromRGB(22, 10, 13),
        CardHover = Color3.fromRGB(34, 12, 17),
        Sidebar = Color3.fromRGB(8, 5, 7),
        Border = Color3.fromRGB(78, 18, 27),
        Text = Color3.fromRGB(244, 232, 234),
        TextDim = Color3.fromRGB(170, 133, 140),
    },
}

D.ThemeNames = {
    "Dark", "Indigo", "Red", "Green", "Purple", "Orange", "Christmas",
    "Ocean", "Rose", "Forest", "Sunset", "Arctic", "Gold", "Midnight", "Demon of Darkness",
    "Cyberpunk", "Monochrome", "Neon", "BloodMoon", "Ice",
}

D.Colors = {
    Accent    = Color3.fromRGB(180, 180, 195),
    Accent2   = Color3.fromRGB(100, 100, 120),
    Bg        = Color3.fromRGB(8, 8, 12),
    Bg2       = Color3.fromRGB(14, 14, 20),
    Card      = Color3.fromRGB(20, 20, 28),
    CardHover = Color3.fromRGB(30, 30, 40),
    Text      = Color3.fromRGB(220, 220, 230),
    TextDim   = Color3.fromRGB(140, 140, 155),
    Sidebar   = Color3.fromRGB(10, 10, 15),
    Border    = Color3.fromRGB(40, 40, 50),
    Green     = Color3.fromRGB(52, 211, 153),
    Red       = Color3.fromRGB(248, 113, 113),
}

D.FocusOverlayTypes = {
    "None", "Grid", "Dots", "Diagonal", "Crosshatch", "Radial",
    "Scanlines", "Bricks", "Concentric", "Stars", "Plus", "Zigzag",
    "Matrix", "Waves"
}
D.WeatherTypes = {
    "Snow", "Rain", "Leaves", "Stars", "Bubbles",
    "Petals", "Embers", "Fireflies", "Mist", "Aurora",
}

-- =========================================================
-- WEATHER PRESETS
-- =========================================================

local WEATHER_PRESETS = {
    Snow = {
        count = 80, minSize = 1.5, maxSize = 4.5,
        color = Color3.fromRGB(255, 255, 255),
        transMin = 40, transMax = 60,
        speedMin = 10, speedMax = 18,
        driftMin = -5, driftMax = 5,
        shape = "Circle", sway = 0.012,
        rotationMin = -12, rotationMax = 12, zIndex = 1,
    },
    Rain = {
        count = 50, minSize = 2, maxSize = 3,
        color = Color3.fromRGB(150, 200, 255),
        transMin = 40, transMax = 70,
        speedMin = 80, speedMax = 120,
        driftMin = -2, driftMax = 2,
        shape = "Line", rotationMin = -8, rotationMax = 8, zIndex = 1,
    },
    Leaves = {
        count = 20, minSize = 6, maxSize = 12,
        colors = { Color3.fromRGB(205,112,52), Color3.fromRGB(185,75,42), Color3.fromRGB(222,165,65) },
        transMin = 20, transMax = 50,
        speedMin = 8, speedMax = 15,
        driftMin = -10, driftMax = 10,
        shape = "Leaf", sway = 0.035,
        rotationMin = -90, rotationMax = 90,
        rotationSpeedMin = -55, rotationSpeedMax = 55, zIndex = 1,
    },
    Stars = {
        count = 40, minSize = 2, maxSize = 4,
        color = Color3.fromRGB(255, 240, 150),
        transMin = 10, transMax = 40,
        speedMin = 0, speedMax = 0.5,
        driftMin = -0.5, driftMax = 0.5,
        shape = "Circle", zIndex = 1, twinkle = true,
    },
    Bubbles = {
        count = 25, minSize = 4, maxSize = 10,
        color = Color3.fromRGB(150, 220, 255),
        transMin = 30, transMax = 60,
        speedMin = -10, speedMax = -20,
        driftMin = -4, driftMax = 4,
        shape = "Circle", sway = 0.012, zIndex = 1,
    },
    Petals = {
        count = 36, minSize = 4, maxSize = 8,
        colors = { Color3.fromRGB(255,176,198), Color3.fromRGB(255,220,230), Color3.fromRGB(245,145,177) },
        transMin = 22, transMax = 48,
        speedMin = 7, speedMax = 16,
        driftMin = -12, driftMax = 12,
        shape = "Leaf", sway = 0.03,
        rotationMin = -180, rotationMax = 180,
        rotationSpeedMin = -70, rotationSpeedMax = 70, zIndex = 1,
    },
    Embers = {
        count = 42, minSize = 2, maxSize = 5,
        colors = { Color3.fromRGB(255,92,36), Color3.fromRGB(255,156,45), Color3.fromRGB(255,214,92) },
        transMin = 18, transMax = 48,
        speedMin = -28, speedMax = -10,
        driftMin = -9, driftMax = 9,
        shape = "Glow", sway = 0.012, twinkle = true,
        rotationSpeedMin = -25, rotationSpeedMax = 25, zIndex = 1,
    },
    Fireflies = {
        count = 24, minSize = 3, maxSize = 7,
        colors = { Color3.fromRGB(182,255,128), Color3.fromRGB(255,230,112), Color3.fromRGB(128,240,190) },
        transMin = 30, transMax = 65,
        speedMin = -3, speedMax = 3,
        driftMin = -5, driftMax = 5,
        shape = "Glow", sway = 0.02, twinkle = true, zIndex = 1,
    },
    Mist = {
        count = 8, minSize = 90, maxSize = 190,
        colors = { Color3.fromRGB(168,198,210), Color3.fromRGB(196,184,214), Color3.fromRGB(152,202,190) },
        transMin = 82, transMax = 92,
        speedMin = -1.5, speedMax = 1.5,
        driftMin = 1, driftMax = 4,
        shape = "Mist", sway = 0.025, zIndex = 1,
    },
    Aurora = {
        count = 5, minSize = 0.18, maxSize = 0.38,
        colors = { Color3.fromRGB(70,235,190), Color3.fromRGB(100,160,255), Color3.fromRGB(190,115,240) },
        transMin = 84, transMax = 92,
        speedMin = -1, speedMax = 1,
        driftMin = 1, driftMax = 3,
        shape = "Aurora", sway = 0.035,
        rotationMin = -8, rotationMax = 8, zIndex = 1,
    },
}

local function randomFloat(minV, maxV)
    if minV > maxV then minV, maxV = maxV, minV end
    return minV + (maxV - minV) * math.random()
end

-- =========================================================
-- SUB-TAB MODULE
-- =========================================================

local SubTabModule = {}
SubTabModule.__index = SubTabModule

local SUBTAB_DEFAULT_THEME = {
    PillBg       = Color3.fromRGB(34, 34, 44),
    LeftAccent   = Color3.fromRGB(160, 160, 185),
    TextActive   = Color3.fromRGB(255, 255, 255),
    TextInactive = Color3.fromRGB(130, 130, 145),
    FontActive   = Enum.Font.GothamBold,
    FontInactive = Enum.Font.GothamMedium,
}

function SubTabModule.new(config)
    local self = setmetatable({}, SubTabModule)
    self.Parent = config.Parent
    self.Owner = config.Owner
    self.Data = config.Data or {}
    self.OnChanged = config.OnChanged or function() end
    self.Theme = config.Theme or SUBTAB_DEFAULT_THEME
    self.CurrentMainCategory = nil
    self.ActiveSubIndices = {}
    self.Groups = {}
    self.TabWidth = config.TabWidth or 96
    self.TabHeight = config.TabHeight or 28
    self.Padding = config.Padding or 6
    self:_init()
    return self
end

function SubTabModule:_init()
    self.Wrapper = Instance.new("Frame", self.Parent)
    self.Wrapper.Name = "SubTabWrapper"
    self.Wrapper.Size = UDim2.new(1, 0, 1, 0)
    self.Wrapper.BackgroundTransparency = 1
    for mainCategory, subList in pairs(self.Data) do
        self:_createSubGroup(mainCategory, subList)
    end
end

function SubTabModule:_createSubGroup(mainCategory, subList)
    local group = Instance.new("CanvasGroup", self.Wrapper)
    group.Name = "SubGroup_" .. tostring(mainCategory)
    group.Size = UDim2.new(1, 0, 1, 0)
    group.BackgroundTransparency = 1
    group.GroupTransparency = 1
    group.Visible = false

    local indicator = Instance.new("Frame", group)
    indicator.Name = "SlidingIndicator"
    indicator.Size = UDim2.new(0, self.TabWidth, 0, self.TabHeight)
    indicator.Position = UDim2.new(0, 0, 0.5, -self.TabHeight / 2)
    indicator.BackgroundColor3 = self.Theme.PillBg
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 1
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 6)

    local accentLine = Instance.new("Frame", indicator)
    accentLine.Name = "LeftAccentBar"
    accentLine.Size = UDim2.new(0, 3, 0, 12)
    accentLine.Position = UDim2.new(0, 6, 0.5, -6)
    accentLine.BackgroundColor3 = self.Theme.LeftAccent
    accentLine.BorderSizePixel = 0
    Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)

    local subElements = {}
    self.ActiveSubIndices[mainCategory] = 1

    for i, subName in ipairs(subList) do
        local btn = Instance.new("TextButton", group)
        btn.Name = "SubBtn_" .. tostring(subName)
        btn.Size = UDim2.new(0, self.TabWidth, 0, self.TabHeight)
        btn.Position = UDim2.new(0, (i - 1) * (self.TabWidth + self.Padding), 0.5, -self.TabHeight / 2)
        btn.BackgroundTransparency = 1
        btn.Text = tostring(subName)
        btn.TextColor3 = (i == 1) and self.Theme.TextActive or self.Theme.TextInactive
        btn.Font = (i == 1) and self.Theme.FontActive or self.Theme.FontInactive
        btn.TextSize = 12
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.AutoButtonColor = false
        btn.ZIndex = 2
        subElements[i] = btn
        Fn.bindPressAnimation(btn)

        btn.MouseEnter:Connect(function()
            if self.ActiveSubIndices[mainCategory] ~= i then
                TweenService:Create(btn, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(200, 200, 215)}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.ActiveSubIndices[mainCategory] ~= i then
                TweenService:Create(btn, TweenInfo.new(0.18), {TextColor3 = self.Theme.TextInactive}):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            local currentActiveIdx = self.ActiveSubIndices[mainCategory]
            if currentActiveIdx == i then return end
            if self.Owner then self.Owner:PlaySound("TabSwitch") end
            local prevBtn = subElements[currentActiveIdx]
            self.ActiveSubIndices[mainCategory] = i
            local targetX = (i - 1) * (self.TabWidth + self.Padding)
            TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, targetX, 0.5, -self.TabHeight / 2)
            }):Play()
            if prevBtn then
                TweenService:Create(prevBtn, TweenInfo.new(0.18), {TextColor3 = self.Theme.TextInactive}):Play()
                prevBtn.Font = self.Theme.FontInactive
            end
            TweenService:Create(btn, TweenInfo.new(0.18), {TextColor3 = self.Theme.TextActive}):Play()
            btn.Font = self.Theme.FontActive
            self.OnChanged(mainCategory, subName)
        end)
    end

    self.Groups[mainCategory] = {
        Group = group,
        Indicator = indicator,
        Buttons = subElements,
    }
end

function SubTabModule:SwitchCategory(newCategory)
    if self.CurrentMainCategory == newCategory then return end
    if not self.Groups[newCategory] then return end
    local oldCategory = self.CurrentMainCategory
    self.CurrentMainCategory = newCategory
    if oldCategory and self.Groups[oldCategory] then
        local oldGroup = self.Groups[oldCategory].Group
        TweenService:Create(oldGroup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            GroupTransparency = 1
        }):Play()
        task.delay(0.15, function() oldGroup.Visible = false end)
    end
    local newGroupData = self.Groups[newCategory]
    local newGroup = newGroupData.Group
    newGroup.Visible = true
    newGroup.GroupTransparency = 1
    TweenService:Create(newGroup, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        GroupTransparency = 0
    }):Play()
    local activeSubIdx = self.ActiveSubIndices[newCategory] or 1
    local activeSubName = self.Data[newCategory] and self.Data[newCategory][activeSubIdx]
    if activeSubName then self.OnChanged(newCategory, activeSubName) end
end

function SubTabModule:SetActiveSub(category, subName)
    local group = self.Groups[category]
    if not group then return end
    for i, btn in ipairs(group.Buttons) do
        if btn.Text == tostring(subName) then
            local prev = self.ActiveSubIndices[category]
            if prev == i then return end
            self.ActiveSubIndices[category] = i
            if group.Buttons[prev] then
                TweenService:Create(group.Buttons[prev], TweenInfo.new(0.18), {
                    TextColor3 = self.Theme.TextInactive
                }):Play()
                group.Buttons[prev].Font = self.Theme.FontInactive
            end
            TweenService:Create(btn, TweenInfo.new(0.18), {
                TextColor3 = self.Theme.TextActive
            }):Play()
            btn.Font = self.Theme.FontActive
            TweenService:Create(group.Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, (i - 1) * (self.TabWidth + self.Padding), 0.5, -self.TabHeight / 2)
            }):Play()
            return
        end
    end
end

function SubTabModule:Resize(tabWidth, padding)
    if tabWidth <= 0 then return end
    self.TabWidth = tabWidth
    if padding then self.Padding = padding end
    for category, groupData in pairs(self.Groups) do
        groupData.Indicator.Size = UDim2.new(0, tabWidth, 0, self.TabHeight)
        for index, button in ipairs(groupData.Buttons) do
            button.Size = UDim2.new(0, tabWidth, 0, self.TabHeight)
            button.Position = UDim2.new(0, (index - 1) * (tabWidth + self.Padding), 0.5, -self.TabHeight / 2)
        end
        local activeIndex = self.ActiveSubIndices[category] or 1
        groupData.Indicator.Position = UDim2.new(
            0, (activeIndex - 1) * (tabWidth + self.Padding), 0.5, -self.TabHeight / 2
        )
    end
end

function SubTabModule:RefreshTheme(newTheme)
    if newTheme then self.Theme = newTheme end
    for cat, groupData in pairs(self.Groups) do
        groupData.Indicator.BackgroundColor3 = self.Theme.PillBg
        local accent = groupData.Indicator:FindFirstChild("LeftAccentBar")
        if accent then accent.BackgroundColor3 = self.Theme.LeftAccent end
        for i, btn in ipairs(groupData.Buttons) do
            if self.ActiveSubIndices[cat] == i then
                btn.TextColor3 = self.Theme.TextActive
                btn.Font = self.Theme.FontActive
            else
                btn.TextColor3 = self.Theme.TextInactive
                btn.Font = self.Theme.FontInactive
            end
        end
    end
end

function SubTabModule:Destroy()
    if self.Wrapper then
        self.Wrapper:Destroy()
        self.Wrapper = nil
    end
    table.clear(self.Groups)
    table.clear(self.ActiveSubIndices)
    self.CurrentMainCategory = nil
end

-- =========================================================
-- LIBRARY CONSTRUCTOR
-- =========================================================

function Library.new(opts)
    if opts == nil then opts = {}
    elseif type(opts) ~= "table" then
        error("[DoD UI] Library.new expects an options table.")
    end
    local self = setmetatable({}, Library)

    self.Title       = opts.Title or "Demon of Darkness UI"
    self.Version     = opts.Version or "v1.2"
    self.Author      = opts.Author or "@DemonOfDarkness"
    self.ThemeName   = opts.Theme or "Demon of Darkness"
    self.TabPosition = opts.TabPosition or "Top"
    self.TabWidth    = opts.TabWidth or 130
    self.ToggleKey   = opts.ToggleKey or Enum.KeyCode.RightShift
    self._TitleIconName = (type(opts.TitleIcon) == "string" and opts.TitleIcon ~= "")
        and opts.TitleIcon or "hexagon"
        
    self._Sounds = {}
    for name, data in pairs(GuiSound) do
        local s = Instance.new("Sound")
        s.Name = "DoD_Sound_" .. name
        s.SoundId = data.id
        s.PlaybackSpeed = data.pitch
        s.Volume = data.vol
        s.Parent = SoundService
        self._Sounds[name] = s
    end
    self.CategoryAlign = opts.CategoryAlign or "Center"
    if self.CategoryAlign ~= "Center" and self.CategoryAlign ~= "Left" and self.CategoryAlign ~= "Right" then
        self.CategoryAlign = "Center"
    end
    if typeof(self.ToggleKey) ~= "EnumItem" or self.ToggleKey.EnumType ~= Enum.KeyCode then
        error("[DoD UI] ToggleKey must be an Enum.KeyCode.")
    end
    if type(self.TabWidth) ~= "number" or self.TabWidth <= 0
        or self.TabWidth ~= self.TabWidth or self.TabWidth == math.huge then
        error("[DoD UI] TabWidth must be a positive number.")
    end
    if opts.Size ~= nil and typeof(opts.Size) ~= "UDim2" then
        error("[DoD UI] Size must be a UDim2 value.")
    end
    if opts.Acrylic ~= nil and type(opts.Acrylic) ~= "boolean" then
        error("[DoD UI] Acrylic must be a boolean.")
    end
    self.WindowSize = opts.Size or UDim2.fromOffset(750, 500)
    self.Acrylic = opts.Acrylic ~= false
    if opts.AcrylicBlur == nil then
        self.AcrylicBlurIntensity = 8
    else
        self.AcrylicBlurIntensity = opts.AcrylicBlur
    end
    if type(self.AcrylicBlurIntensity) ~= "number" or self.AcrylicBlurIntensity < 0
        or self.AcrylicBlurIntensity > 24 or self.AcrylicBlurIntensity ~= self.AcrylicBlurIntensity then
        error("[DoD UI] AcrylicBlur must be a number between 0 and 24.")
    end
    if self.TabPosition ~= "Top" and self.TabPosition ~= "Side" and self.TabPosition ~= "Bottom" then
        error('[DoD UI] TabPosition must be "Top", "Side", or "Bottom".')
    end

    self._UI = {}
    self._Colors = table.clone(D.Colors)
    if opts.FocusOverlay ~= nil and type(opts.FocusOverlay) ~= "boolean" then
        error("[DoD UI] FocusOverlay must be a boolean.")
    end
    if opts.FocusOverlayType ~= nil and not table.find(D.FocusOverlayTypes, opts.FocusOverlayType) then
        error("[DoD UI] FocusOverlayType must be a supported overlay type.")
    end
    if opts.Weather ~= nil and type(opts.Weather) ~= "table" then
        error("[DoD UI] Weather must be a table.")
    end
    if opts.Weather then
        if opts.Weather.Enabled ~= nil and type(opts.Weather.Enabled) ~= "boolean" then
            error("[DoD UI] Weather.Enabled must be a boolean.")
        end
        if opts.Weather.Type ~= nil and not table.find(D.WeatherTypes, opts.Weather.Type) then
            error("[DoD UI] Weather.Type must be a supported weather type.")
        end
        local intensity = opts.Weather.Intensity
        if intensity ~= nil and (type(intensity) ~= "number" or intensity < 0
            or intensity > 100 or intensity ~= intensity) then
            error("[DoD UI] Weather.Intensity must be a number between 0 and 100.")
        end
    end
    self._STATE = {
        ContentPages        = {},
        CategoryTabs        = {},
        TabColumns          = {}, -- Stores LeftCol, RightCol for each tab
        TabTopContainers    = {}, -- Stores Top container for each tab
        SearchSections      = {},
        SearchBodies        = {},
        SearchTopLevel      = {},
        SearchQuery         = "",
        PageSectionCounts   = {},
        TabCategories       = {},
        ThemeRefreshers     = {},
        activeDropdownPopups = {},
        activeKeybindListeners = {},
        KeybindOverlayRows = {},
        activeNotifs        = {},
        NotifQueue          = {},
        NotifActive         = 0,
        NotifMax            = 3,
        SavedScrollPositions = {},
        GuiVisible          = true,
        AnimatingGui        = false,
        GuiTween            = nil,
        TrackedConns        = {},
        Destroyed           = false,
        ActiveCategory      = nil,
        ActiveTab           = nil,
        WeatherEnabled      = false,
        WeatherType         = (opts.Weather and opts.Weather.Type) or "Snow",
        WeatherIntensity    = (opts.Weather and opts.Weather.Intensity) or 65,
        FocusOverlayEnabled = opts.FocusOverlay ~= false,
        FocusOverlayType    = opts.FocusOverlayType or "Grid",
        notifParts          = {},
        SnowParticles       = {},
        SnowConnection      = nil,
        WeatherClock        = 0,
        AccordionExpanded   = {},
        ConfigRegistry      = {},
        ConfigCounter       = {},
        ConfigAutoSave      = nil,
    }

    self:_initNotifications()
    self:_initMainGui()
    self:_initKeybindOverlay()
    self:_initTitleBar()
    self:_initTrafficLights()
    self:_initSidebar()
    self:_initSearchBar()
    self:_initContentArea()
    self:_applyNavigationLayout()
    self:_initFocusOverlay()
    self:_initMobileToggle()
    self:_initDrag()
    self:_initShadowSync()
    self:_initTooltip()
    self:_bindToggleKey()

    self:SetTheme(self.ThemeName, true)
    if self.Acrylic then
        self:_updateAcrylicBlur()
    end
    if opts.Weather and opts.Weather.Enabled then
        self:SetWeather(true, self._STATE.WeatherType, self._STATE.WeatherIntensity)
    end

    Fn.track(self._UI.MainContainer:GetPropertyChangedSignal("AbsoluteSize"), function()
        self:_applyNavigationLayout()
    end, self)

    return self
end

-- =========================================================
-- THEME APPLY
-- =========================================================

function Library:_applyThemeColors(themeName)
    local theme = D.Themes[themeName] or D.Themes.Dark
    local base = D.Themes.Dark
    self._Colors.Accent = theme.Accent or base.Accent
    self._Colors.Accent2 = theme.Accent2 or base.Accent2
    if self._AccentOverride then
        self._Colors.Accent = self._AccentOverride
        self._Colors.Accent2 = self._AccentOverride:Lerp(Color3.new(1, 1, 1), 0.25)
    end
    self._Colors.Bg = theme.Bg or base.Bg
    self._Colors.Bg2 = theme.Bg2 or base.Bg2
    self._Colors.Card = theme.Card or base.Card
    self._Colors.CardHover = theme.CardHover or theme.Card or base.CardHover or base.Card
    self._Colors.Sidebar = theme.Sidebar or base.Sidebar
    self._Colors.Border = theme.Border or base.Border
    self._Colors.Text = theme.Text or (theme.Bg and Fn.accentTextColor(theme.Bg)) or base.Text
    self._Colors.TextDim = theme.TextDim or base.TextDim
    return theme
end

function Library:SetTheme(themeName, silent)
    if self:_isDead() then return end
    local actualName = (type(themeName) == "string" and D.Themes[themeName]) and themeName or "Dark"
    local theme = self:_applyThemeColors(actualName)
    self.ThemeName = actualName

    local UI = self._UI
    local ok, err = pcall(function()
        if UI.MainContainer then
            UI.MainContainer.BackgroundColor3 = self._Colors.Bg
            UI.MainContainer.BackgroundTransparency = self.Acrylic and 0.32 or 0.1
        end
        if UI.AcrylicTexture then UI.AcrylicTexture.BackgroundColor3 = self._Colors.Accent2 end
        if UI.AcrylicGradient then
            UI.AcrylicGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.48, self._Colors.Accent2),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
            })
        end
        if UI.TitleBar then UI.TitleBar.BackgroundColor3 = self._Colors.Bg2 end
        if UI.CategoryBar then
            UI.CategoryBar.BackgroundColor3 = self.TabPosition == "Bottom" and self._Colors.Card or self._Colors.Sidebar
        end
        if UI.CategoryBarStroke then UI.CategoryBarStroke.Color = self._Colors.Border end
        if UI.Sidebar then UI.Sidebar.BackgroundColor3 = self._Colors.Sidebar end
        if UI.TabBarDivider then UI.TabBarDivider.BackgroundColor3 = self._Colors.Border end
        if UI.TitleLabel then UI.TitleLabel.TextColor3 = self._Colors.Text end
        if UI.TitleDiscord then UI.TitleDiscord.TextColor3 = self._Colors.TextDim end
        if UI.TitleLogoBadge then
            UI.TitleLogoBadge.BackgroundColor3 = self._Colors.Accent
            if UI.TitleLogoGradient then
                UI.TitleLogoGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, self._Colors.Accent),
                    ColorSequenceKeypoint.new(1, self._Colors.Accent2),
                })
            end
            if UI.TitleLogoStroke then UI.TitleLogoStroke.Color = self._Colors.Accent end
            if UI.TitleLogoIcon then UI.TitleLogoIcon.ImageColor3 = Fn.accentTextColor(self._Colors.Accent) end
        end
        if UI.TitleVersionBadge then
            UI.TitleVersionBadge.TextColor3 = self._Colors.TextDim
        end
        if UI.MainStroke then UI.MainStroke.Color = self._Colors.Border end
        if UI.TitleGradient then
            UI.TitleGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, self._Colors.Accent),
                ColorSequenceKeypoint.new(1, self._Colors.Accent2),
            })
        end
        if UI.SearchBar then UI.SearchBar.BackgroundColor3 = self._Colors.Card end
        if UI.SearchBarStroke then UI.SearchBarStroke.Color = self._Colors.Border end
        if UI.SearchInput then
            UI.SearchInput.TextColor3 = self._Colors.Text
            UI.SearchInput.PlaceholderColor3 = self._Colors.TextDim
        end
        if UI.SearchIcon then UI.SearchIcon.ImageColor3 = self._Colors.TextDim end
        if UI.MobileToggle then
            UI.MobileToggle.BackgroundColor3 = self._Colors.Card
            UI.MobileToggle.TextColor3 = self._Colors.Text
        end
        if UI.MobileToggleStroke then UI.MobileToggleStroke.Color = self._Colors.Accent end
        if UI.KeybindOverlay then
            UI.KeybindOverlay.BackgroundColor3 = self._Colors.Bg2
        end
        if UI.KeybindOverlayStroke then UI.KeybindOverlayStroke.Color = self._Colors.Border end
        if UI.KeybindOverlayList then UI.KeybindOverlayList.ScrollBarImageColor3 = self._Colors.Accent end
        if UI.KeybindOverlayEmpty then UI.KeybindOverlayEmpty.TextColor3 = self._Colors.TextDim end
        if UI.KeybindOverlayToggle then
            UI.KeybindOverlayToggle.BackgroundColor3 = self._Colors.Card
        end
        if UI.KeybindOverlayToggleStroke then UI.KeybindOverlayToggleStroke.Color = self._Colors.Accent end
        if UI.KeybindOverlayToggleIcon then UI.KeybindOverlayToggleIcon.ImageColor3 = self._Colors.Accent end
        if UI.KeybindOverlayToggleText then UI.KeybindOverlayToggleText.TextColor3 = self._Colors.Accent end
    end)
    if not ok then
        warn("[DoD UI] Theme UI refresh failed: " .. tostring(err))
    end

    for index, fn in ipairs(self._STATE.ThemeRefreshers) do
        local refreshed, refreshError = pcall(fn)
        if not refreshed then
            warn("[DoD UI] Theme refresher " .. index .. " failed: " .. tostring(refreshError))
        end
    end

    for frame, parts in pairs(self._STATE.notifParts) do
        if frame and frame.Parent then
            frame.BackgroundColor3 = self._Colors.Bg2
            if parts.stroke and parts.stroke.Parent then parts.stroke.Color = self._Colors.Accent end
            if parts.accentBar and parts.accentBar.Parent then parts.accentBar.BackgroundColor3 = self._Colors.Accent end
            if parts.progressBar and parts.progressBar.Parent then parts.progressBar.BackgroundColor3 = self._Colors.Accent end
            if parts.titleLabel and parts.titleLabel.Parent then parts.titleLabel.TextColor3 = self._Colors.Text end
            if parts.textLabel and parts.textLabel.Parent then parts.textLabel.TextColor3 = self._Colors.TextDim end
        end
    end

    if self._STATE.SubTabBar then
        self._STATE.SubTabBar:RefreshTheme({
            PillBg       = self._Colors.Card,
            LeftAccent   = self._Colors.Accent,
            TextActive   = Color3.fromRGB(255, 255, 255),
            TextInactive = self._Colors.TextDim,
            FontActive   = Enum.Font.GothamBold,
            FontInactive = Enum.Font.GothamMedium,
        })
    end

    if self._UI.FocusOverlay then
        self:_updateFocusOverlay(theme)
    end

    if not silent then
        self:Notify("THEME", "Applied: " .. actualName)
    end
end

function Library:SetAccentColor(color)
    if self:_isDead() then return end
    if typeof(color) ~= "Color3" then
        error("[DoD UI] SetAccentColor expects a Color3 value.")
    end
    self._AccentOverride = color
    self:SetTheme(self.ThemeName, true)
end

function Library:SetAcrylic(enabled, blurIntensity)
    if self:_isDead() then return end
    if type(enabled) ~= "boolean" then
        error("[DoD UI] SetAcrylic expects a boolean enabled value.")
    end
    if blurIntensity ~= nil then self:SetAcrylicIntensity(blurIntensity) end
    self.Acrylic = enabled

    local UI = self._UI
    if UI.MainContainer then
        UI.MainContainer.BackgroundTransparency = enabled and 0.32 or 0.1
    end
    if UI.AcrylicTexture then
        UI.AcrylicTexture.Visible = enabled
        UI.AcrylicTexture.BackgroundTransparency = enabled and 0.94 or 1
    end
    if UI.AcrylicSheen then
        UI.AcrylicSheen.Visible = enabled
        UI.AcrylicSheen.BackgroundTransparency = enabled and 0.72 or 1
    end
    self:_updateAcrylicBlur()
end

function Library:SetAcrylicIntensity(intensity)
    if self:_isDead() then return end
    if type(intensity) ~= "number" or intensity < 0 or intensity > 24
        or intensity ~= intensity then
        error("[DoD UI] Acrylic intensity must be a number between 0 and 24.")
    end
    self.AcrylicBlurIntensity = intensity
    self:_updateAcrylicBlur()
end

function Library:_registerThemeRefresher(fn)
    table.insert(self._STATE.ThemeRefreshers, fn)
end

function Library:_getConfigId(controlType, label)
    if type(label) ~= "string" then label = tostring(label or "") end
    local key = tostring(controlType) .. ":" .. label
    local counter = self._STATE.ConfigCounter
    counter[key] = (counter[key] or 0) + 1
    local n = counter[key]
    if n > 1 then return key .. "#" .. n end
    return key
end

function Library:_registerConfigState(id, getter, setter)
    if self:_isDead() then return id end
    self._STATE.ConfigRegistry[id] = { get = getter, set = setter }
    return id
end

function Library:_triggerAutoSave()
    if self:_isDead() then return end
    local auto = self._STATE.ConfigAutoSave
    if not auto or not auto.name then return end
    if self._autoSavePending then return end
    self._autoSavePending = true
    task.delay(0.6, function()
        self._autoSavePending = false
        if not self:_isDead() then
            self:SaveConfig(auto.name, true)
        end
    end)
end

-- =========================================================
-- NOTIFICATIONS
-- =========================================================

function Library:_initNotifications()
    local gui = Instance.new("ScreenGui")
    gui.Name = "DoD_UI_Notifications"
    gui.Parent = CoreGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 2000
    self._UI.NotifGui = gui
end

function Library:_updateNotifPositions()
    for index, frame in ipairs(self._STATE.activeNotifs) do
        local targetY = 15 + ((index - 1) * 65)
        TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -275, 0, targetY)}
        ):Play()
    end
end

function Library:ExportConfig()
    if self:_isDead() then return {} end
    local out = { _version = self.Version, _theme = self.ThemeName, _controls = {} }
    for id, entry in pairs(self._STATE.ConfigRegistry or {}) do
        local ok, val = pcall(entry.get)
        if ok and val ~= nil then
            out._controls[id] = val
        end
    end
    return out
end

function Library:ImportConfig(config, silent)
    if self:_isDead() then return end
    if type(config) ~= "table" then return end
    if config._theme and D.Themes[config._theme] then
        self:SetTheme(config._theme, true)
    end
    local applied, total = 0, 0
    for id, val in pairs(config._controls or {}) do
        total = total + 1
        local entry = self._STATE.ConfigRegistry and self._STATE.ConfigRegistry[id]
        if entry and entry.set then
            local ok = pcall(entry.set, val, true)
            if ok then applied = applied + 1 end
        end
    end
    if not silent then
        self:Notify("CONFIG", "Imported " .. applied .. "/" .. total .. " settings", "success")
    end
end

function Library:SaveConfig(name, silent)
    if self:_isDead() then return end
    if type(name) ~= "string" or name == "" then return end
    local data = self:ExportConfig()
    local ok, json = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if not ok or type(json) ~= "string" then
        if not silent then self:Notify("CONFIG", "JSON encode failed", "error") end
        return
    end
    local path = "DoD_UI_" .. name .. ".json"
    local saved = false
    pcall(function()
        if writefile and type(writefile) == "function" then
            writefile(path, json)
            saved = true
        end
    end)
    if not saved then
        local g = (getgenv and getgenv()) or _G
        g.__DoDConfigs = g.__DoDConfigs or {}
        g.__DoDConfigs[name] = json
        saved = true
    end
    if saved and not silent then
        self:Notify("CONFIG", "Saved: " .. name, "success")
    end
end

function Library:LoadConfig(name, silent)
    if self:_isDead() then return end
    if type(name) ~= "string" or name == "" then return end
    local path = "DoD_UI_" .. name .. ".json"
    local json = nil
    pcall(function()
        if isfile and type(isfile) == "function" and readfile and type(readfile) == "function" then
            if isfile(path) then json = readfile(path) end
        end
    end)
    if not json then
        local g = (getgenv and getgenv()) or _G
        if g.__DoDConfigs and g.__DoDConfigs[name] then
            json = g.__DoDConfigs[name]
        end
    end
    if type(json) ~= "string" then
        if not silent then self:Notify("CONFIG", "Not found: " .. name, "warning") end
        return
    end
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(json)
    end)
    if not ok or type(data) ~= "table" then
        if not silent then self:Notify("CONFIG", "Decode failed", "error") end
        return
    end
    self:ImportConfig(data, silent)
end

function Library:EnableAutoSave(name)
    if self:_isDead() then return end
    if type(name) ~= "string" or name == "" then return end
    self._STATE.ConfigAutoSave = { name = name }
    self:SaveConfig(name, true)
end

function Library:DisableAutoSave()
    if self:_isDead() then return end
    self._STATE.ConfigAutoSave = nil
end

function Library:Notify(title, text, notifyType)
    local STATE = self._STATE
    if STATE.Destroyed then return end
    self:PlaySound("Notify")
    title = tostring(title or "")
    text = tostring(text or "")
    notifyType = tostring(notifyType or "info")
    
    if STATE.NotifActive >= STATE.NotifMax then
        table.insert(STATE.NotifQueue, { title = title, text = text, nType = notifyType })
        return
    end
    STATE.NotifActive = STATE.NotifActive + 1

    task.spawn(function()
        if STATE.Destroyed or not self._UI.NotifGui or not self._UI.NotifGui.Parent then
            STATE.NotifActive = math.max(0, STATE.NotifActive - 1)
            return
        end
        local palette = self._Colors or {}
        local accent = palette.Accent or Color3.fromRGB(180, 180, 195)
        
        local iconId = GetIcon("info")
        local color = accent
        
        if notifyType == "success" then
            color = Color3.fromRGB(52, 211, 153)
            iconId = GetIcon("check-circle")
        elseif notifyType == "error" then
            color = Color3.fromRGB(248, 113, 113)
            iconId = GetIcon("x-circle")
        elseif notifyType == "warning" then
            color = Color3.fromRGB(251, 191, 36)
            iconId = GetIcon("alert-triangle")
        end

        local frame = Instance.new("Frame", self._UI.NotifGui)
        frame.Size = UDim2.new(0, 280, 0, 56)
        frame.Position = UDim2.new(1, -295, 0, -70)
        frame.BackgroundColor3 = palette.Bg2 or Color3.fromRGB(14, 14, 20)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        local frameStroke = Instance.new("UIStroke", frame)
        frameStroke.Color = color
        frameStroke.Thickness = 1
        frameStroke.Transparency = 0.4

        local icon = Instance.new("ImageLabel", frame)
        icon.Size = UDim2.fromOffset(16, 16)
        icon.Position = UDim2.new(0, 12, 0, 10)
        icon.BackgroundTransparency = 1
        icon.Image = iconId
        icon.ImageColor3 = color

        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.Size = UDim2.new(1, -40, 0, 20)
        titleLabel.Position = UDim2.new(0, 36, 0, 7)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = palette.Text or Color3.fromRGB(220, 220, 230)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 13
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local textLabel = Instance.new("TextLabel", frame)
        textLabel.Size = UDim2.new(1, -40, 0, 18)
        textLabel.Position = UDim2.new(0, 36, 0, 28)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = palette.TextDim or Color3.fromRGB(140, 140, 155)
        textLabel.Font = Enum.Font.GothamMedium
        textLabel.TextSize = 11
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local progressBar = Instance.new("Frame", frame)
        progressBar.Size = UDim2.new(1, -4, 0, 2)
        progressBar.Position = UDim2.new(0, 4, 1, -2)
        progressBar.BackgroundColor3 = color
        progressBar.BorderSizePixel = 0

        local accentBar = Instance.new("Frame", frame)
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 3, 1, -8)
        accentBar.Position = UDim2.new(0, 4, 0, 4)
        accentBar.BackgroundColor3 = color
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 2
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

        STATE.notifParts[frame] = {
            stroke = frameStroke,
            accentBar = accentBar,
            progressBar = progressBar,
            titleLabel = titleLabel,
            textLabel = textLabel,
        }

        table.insert(STATE.activeNotifs, frame)
        self:_updateNotifPositions()
        TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 0.1}):Play()

        TweenService:Create(
            progressBar,
            TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 2)}
        ):Play()

        task.wait(2.5)

        local index = table.find(STATE.activeNotifs, frame)
        if index then table.remove(STATE.activeNotifs, index) end
        if STATE.Destroyed or not frame.Parent then
            STATE.notifParts[frame] = nil
            if frame.Parent then frame:Destroy() end
            STATE.NotifActive = math.max(0, STATE.NotifActive - 1)
            return
        end
        self:_updateNotifPositions()

        TweenService:Create(titleLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(textLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(icon, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
        TweenService:Create(frameStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()

        local out = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 15, 0, frame.Position.Y.Offset), BackgroundTransparency = 1}
        )
        out:Play()
        out.Completed:Wait()
        STATE.notifParts[frame] = nil
        if frame.Parent then frame:Destroy() end
        STATE.NotifActive = math.max(0, STATE.NotifActive - 1)
        local nxt = table.remove(STATE.NotifQueue, 1)
        if nxt and not STATE.Destroyed then self:Notify(nxt.title, nxt.text, nxt.nType) end
    end)
end

-- =========================================================
-- MAIN GUI
-- =========================================================

function Library:_initMainGui()
    local UI = self._UI
    UI.MainGui = Instance.new("ScreenGui")
    UI.MainGui.Name = "DoD_UI_Main"
    UI.MainGui.Parent = CoreGui
    UI.MainGui.ResetOnSpawn = false
    UI.MainGui.IgnoreGuiInset = true
    UI.MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.MainGui.DisplayOrder = 1000

    UI.FocusOverlay = Instance.new("Frame", UI.MainGui)
    UI.FocusOverlay.Name = "FocusOverlay"
    UI.FocusOverlay.Size = UDim2.fromScale(1, 1)
    UI.FocusOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    UI.FocusOverlay.BackgroundTransparency = 1
    UI.FocusOverlay.BorderSizePixel = 0
    UI.FocusOverlay.ZIndex = 0
    UI.FocusOverlay.Visible = false
    UI.FocusOverlay.Active = false

    UI.GridPattern = Instance.new("Frame", UI.FocusOverlay)
    UI.GridPattern.Size = UDim2.fromScale(1, 1)
    UI.GridPattern.BackgroundTransparency = 1
    UI.GridPattern.ZIndex = 0

    UI.ParticleBG = Instance.new("Frame", UI.MainGui)
    UI.ParticleBG.Name = "ParticleBG"
    UI.ParticleBG.Size = UDim2.fromScale(1, 1)
    UI.ParticleBG.BackgroundTransparency = 1
    UI.ParticleBG.BorderSizePixel = 0
    UI.ParticleBG.ZIndex = 5
    UI.ParticleBG.ClipsDescendants = true
    UI.ParticleBG.Visible = false
    
    local particles = {}
    for i = 1, 25 do
        local p = Instance.new("Frame", UI.ParticleBG)
        p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
        p.Position = UDim2.fromScale(math.random(), math.random())
        p.BackgroundColor3 = self._Colors.Accent
        p.BackgroundTransparency = math.random(30, 80) / 100
        p.BorderSizePixel = 0
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
        table.insert(particles, {
            obj = p,
            speedX = (math.random() - 0.5) * 0.005,
            speedY = -math.random(1, 3) / 1000
        })
    end
    
    self._particleBGConn = RunService.RenderStepped:Connect(function(dt)
        if not UI.ParticleBG.Visible then return end
        for _, data in ipairs(particles) do
            local pos = data.obj.Position
            local nx = pos.X.Scale + data.speedX * dt * 10
            local ny = pos.Y.Scale + data.speedY * dt * 10
            if nx < 0 then nx = 1 elseif nx > 1 then nx = 0 end
            if ny < 0 then ny = 1 elseif ny > 1 then ny = 0 end
            data.obj.Position = UDim2.fromScale(nx, ny)
        end
    end)

    UI.SnowLayer = Instance.new("Frame", UI.MainGui)
    UI.SnowLayer.Name = "SnowLayer"
    UI.SnowLayer.Size = UDim2.fromScale(1, 1)
    UI.SnowLayer.BackgroundTransparency = 1
    UI.SnowLayer.BorderSizePixel = 0
    UI.SnowLayer.ZIndex = 4
    UI.SnowLayer.Visible = false

    UI.GuiBlur = Lighting:FindFirstChild("DoD_UI_Blur") or Instance.new("BlurEffect")
    UI.GuiBlur.Name = "DoD_UI_Blur"
    UI.GuiBlur.Size = 0
    UI.GuiBlur.Parent = Lighting

    local MC = Instance.new("Frame", UI.MainGui)
    UI.MainContainer = MC
    MC.Size = self.WindowSize
    MC.Position = UDim2.new(0.5, 0, 0.5, 0)
    MC.AnchorPoint = Vector2.new(0.5, 0.5)
    MC.BackgroundColor3 = self._Colors.Bg
    MC.BackgroundTransparency = self.Acrylic and 0.32 or 0.1
    MC.BorderSizePixel = 0
    MC.ClipsDescendants = true
    MC.ZIndex = 10
    Instance.new("UICorner", MC).CornerRadius = UDim.new(0, 14)

    UI.MainSizeConstraint = Instance.new("UISizeConstraint", MC)

    local function updateSizeLimit()
        local camera = getCam()
        if not camera then return end
        local viewport = camera.ViewportSize
        UI.MainSizeConstraint.MaxSize = Vector2.new(
            math.max(1, viewport.X * 0.96),
            math.max(1, viewport.Y * 0.92)
        )
        UI.MainSizeConstraint.MinSize = Vector2.new(
            math.min(280, UI.MainSizeConstraint.MaxSize.X),
            math.min(240, UI.MainSizeConstraint.MaxSize.Y)
        )
    end
    updateSizeLimit()
    local camera = getCam()
    if camera then
        Fn.track(camera:GetPropertyChangedSignal("ViewportSize"), updateSizeLimit, self)
    end

    UI.AcrylicTexture = Instance.new("Frame", MC)
    UI.AcrylicTexture.Name = "AcrylicTexture"
    UI.AcrylicTexture.Size = UDim2.fromScale(1, 1)
    UI.AcrylicTexture.BackgroundColor3 = self._Colors.Accent2
    UI.AcrylicTexture.BackgroundTransparency = self.Acrylic and 0.94 or 1
    UI.AcrylicTexture.BorderSizePixel = 0
    UI.AcrylicTexture.Active = false
    UI.AcrylicTexture.Visible = self.Acrylic
    Instance.new("UICorner", UI.AcrylicTexture).CornerRadius = UDim.new(0, 14)

    UI.AcrylicGradient = Instance.new("UIGradient", UI.AcrylicTexture)
    UI.AcrylicGradient.Rotation = 35
    UI.AcrylicGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.48, self._Colors.Accent2),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    UI.AcrylicGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0.5),
    })

    UI.AcrylicSheen = Instance.new("Frame", MC)
    UI.AcrylicSheen.Name = "AcrylicSheen"
    UI.AcrylicSheen.Size = UDim2.new(1, -2, 0, 1)
    UI.AcrylicSheen.Position = UDim2.new(0, 1, 0, 1)
    UI.AcrylicSheen.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.AcrylicSheen.BackgroundTransparency = self.Acrylic and 0.72 or 1
    UI.AcrylicSheen.BorderSizePixel = 0
    UI.AcrylicSheen.Visible = self.Acrylic

    UI.MainScale = Instance.new("UIScale", MC)
    UI.MainScale.Scale = 1

    UI.MainStroke = Instance.new("UIStroke", MC)
    UI.MainStroke.Color = self._Colors.Border
    UI.MainStroke.Thickness = 1.5

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeButton"
    minBtn.Parent = UI.MainGui
    minBtn.Size = UDim2.fromOffset(120, 32)
    minBtn.Position = UDim2.new(0.5, 0, 0, -40)
    minBtn.AnchorPoint = Vector2.new(0.5, 0)
    minBtn.BackgroundColor3 = self._Colors.Bg2
    minBtn.BackgroundTransparency = 0.1
    minBtn.AutoButtonColor = false
    minBtn.Visible = false
    minBtn.ZIndex = 500
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)
    
    local minStroke = Instance.new("UIStroke", minBtn)
    minStroke.Color = self._Colors.Accent
    minStroke.Thickness = 1.5
    minStroke.Transparency = 0.5
    
    local minIcon = Instance.new("ImageLabel")
    minIcon.Size = UDim2.fromOffset(16, 16)
    minIcon.Position = UDim2.new(0, 12, 0.5, -8)
    minIcon.BackgroundTransparency = 1
    minIcon.Image = GetIcon("panel-top")
    minIcon.ImageColor3 = self._Colors.Accent
    
    local minText = Instance.new("TextLabel")
    minText.Size = UDim2.new(1, -34, 1, 0)
    minText.Position = UDim2.new(0, 34, 0, 0)
    minText.BackgroundTransparency = 1
    minText.Text = "OPEN UI"
    minText.TextColor3 = self._Colors.Accent
    minText.Font = Enum.Font.GothamBold
    minText.TextSize = 11
    
    UI.MinimizeButton = minBtn
    UI.MinimizeButtonStroke = minStroke
    UI.MinimizeButtonIcon = minIcon
    
    Fn.bindPressAnimation(minBtn)
    
    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        TweenService:Create(minStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(minStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    end)
    
    minBtn.MouseButton1Click:Connect(function()
        self:PlaySound("Click")
        minBtn.Visible = false
        self:Toggle()
    end)
    
    self:_registerThemeRefresher(function()
        minBtn.BackgroundColor3 = self._Colors.Bg2
        minStroke.Color = self._Colors.Accent
        minIcon.ImageColor3 = self._Colors.Accent
        minText.TextColor3 = self._Colors.Accent
    end)

    self._shadowLayers = {}
end

function Library:_initShadowSync()
    self._shadowLayers = {}
end

function Library:_initKeybindOverlay()
    local UI = self._UI
    local overlay = Instance.new("Frame", UI.MainGui)
    overlay.Name = "KeybindOverlay"
    overlay.Size = UDim2.fromOffset(290, 300)
    overlay.AnchorPoint = Vector2.new(1, 1)
    overlay.Position = UDim2.new(1, -18, 1, -58)
    overlay.BackgroundColor3 = self._Colors.Bg2
    overlay.BackgroundTransparency = 0.08
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.ZIndex = 250
    overlay.ClipsDescendants = true
    Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", overlay)
    stroke.Color = self._Colors.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    local heading = Instance.new("TextLabel", overlay)
    heading.Name = "Heading"
    heading.Size = UDim2.new(1, -60, 0, 18)
    heading.Position = UDim2.new(0, 16, 0, 12)
    heading.BackgroundTransparency = 1
    heading.Text = "KEYBINDS"
    heading.TextColor3 = self._Colors.Text
    heading.Font = Enum.Font.GothamBold
    heading.TextSize = 12
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.ZIndex = 251

    local subtitle = Instance.new("TextLabel", overlay)
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -60, 0, 14)
    subtitle.Position = UDim2.new(0, 16, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "No active keybinds"
    subtitle.TextColor3 = self._Colors.TextDim
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 10
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 251

    local closeButton = Instance.new("TextButton", overlay)
    closeButton.Name = "Close"
    closeButton.Size = UDim2.fromOffset(24, 24)
    closeButton.Position = UDim2.new(1, -34, 0, 16)
    closeButton.BackgroundColor3 = self._Colors.Card
    closeButton.BackgroundTransparency = 0.4
    closeButton.Text = ""
    closeButton.AutoButtonColor = false
    closeButton.ZIndex = 252
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

    local closeIcon = Instance.new("ImageLabel", closeButton)
    closeIcon.Size = UDim2.fromOffset(12, 12)
    closeIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = GetIcon("x")
    closeIcon.ImageColor3 = self._Colors.TextDim
    closeIcon.ZIndex = 253

    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(closeIcon, TweenInfo.new(0.15), {ImageColor3 = self._Colors.Text}):Play()
    end)
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
        TweenService:Create(closeIcon, TweenInfo.new(0.15), {ImageColor3 = self._Colors.TextDim}):Play()
    end)

    local divider = Instance.new("Frame", overlay)
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, -32, 0, 1)
    divider.Position = UDim2.new(0, 16, 0, 52)
    divider.BackgroundColor3 = self._Colors.Border
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0
    divider.ZIndex = 251

    local list = Instance.new("ScrollingFrame", overlay)
    list.Name = "KeybindList"
    list.Size = UDim2.new(1, -20, 1, -64)
    list.Position = UDim2.new(0, 10, 0, 56)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = self._Colors.Accent
    list.ScrollBarImageTransparency = 0.3
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.ZIndex = 251
    local layout = Instance.new("UIListLayout", list)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    local listPad = Instance.new("UIPadding", list)
    listPad.PaddingTop = UDim.new(0, 2)
    listPad.PaddingBottom = UDim.new(0, 8)

    local emptyMessage = Instance.new("Frame", list)
    emptyMessage.Name = "EmptyMessage"
    emptyMessage.LayoutOrder = 0
    emptyMessage.Size = UDim2.new(1, -8, 0, 80)
    emptyMessage.BackgroundTransparency = 1
    emptyMessage.ZIndex = 252

    local emptyIcon = Instance.new("ImageLabel", emptyMessage)
    emptyIcon.Size = UDim2.fromOffset(28, 28)
    emptyIcon.Position = UDim2.new(0.5, -14, 0, 12)
    emptyIcon.BackgroundTransparency = 1
    emptyIcon.Image = GetIcon("keyboard")
    emptyIcon.ImageColor3 = self._Colors.TextDim
    emptyIcon.ImageTransparency = 0.4
    emptyIcon.ZIndex = 252

    local emptyText = Instance.new("TextLabel", emptyMessage)
    emptyText.Size = UDim2.new(1, -16, 0, 14)
    emptyText.Position = UDim2.new(0, 8, 0, 48)
    emptyText.BackgroundTransparency = 1
    emptyText.Text = "No keybinds assigned yet"
    emptyText.TextColor3 = self._Colors.TextDim
    emptyText.Font = Enum.Font.GothamMedium
    emptyText.TextSize = 10
    emptyText.TextXAlignment = Enum.TextXAlignment.Center
    emptyText.ZIndex = 252

    local toggle = Instance.new("TextButton", UI.MainGui)
    toggle.Name = "KeybindOverlayToggle"
    toggle.Size = UDim2.fromOffset(110, 34)
    toggle.AnchorPoint = Vector2.new(1, 1)
    toggle.Position = UDim2.new(1, -18, 1, -18)
    toggle.BackgroundColor3 = self._Colors.Card
    toggle.BackgroundTransparency = 0.12
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.ZIndex = 253
    toggle.Visible = false
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local toggleStroke = Instance.new("UIStroke", toggle)
    toggleStroke.Color = self._Colors.Accent
    toggleStroke.Thickness = 1
    toggleStroke.Transparency = 0.4

    local toggleIcon = Instance.new("ImageLabel", toggle)
    toggleIcon.Size = UDim2.fromOffset(14, 14)
    toggleIcon.Position = UDim2.new(0, 14, 0.5, -7)
    toggleIcon.BackgroundTransparency = 1
    toggleIcon.Image = GetIcon("keyboard")
    toggleIcon.ImageColor3 = self._Colors.Accent

    local toggleText = Instance.new("TextLabel", toggle)
    toggleText.Size = UDim2.new(1, -40, 1, 0)
    toggleText.Position = UDim2.new(0, 34, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = "KEYBINDS"
    toggleText.TextColor3 = self._Colors.Accent
    toggleText.Font = Enum.Font.GothamBold
    toggleText.TextSize = 10
    toggleText.TextXAlignment = Enum.TextXAlignment.Left

    Fn.bindPressAnimation(toggle)

    toggle.MouseEnter:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
    end)
    toggle.MouseLeave:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundTransparency = 0.12}):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
    end)

    toggle.MouseButton1Click:Connect(function()
        overlay.Visible = not overlay.Visible
    end)
    closeButton.MouseButton1Click:Connect(function()
        overlay.Visible = false
    end)

    UI.KeybindOverlay = overlay
    UI.KeybindOverlayList = list
    UI.KeybindOverlayEmpty = emptyMessage
    UI.KeybindOverlayToggle = toggle
    UI.KeybindOverlayStroke = stroke
    UI.KeybindOverlayToggleStroke = toggleStroke
    UI.KeybindOverlayToggleIcon = toggleIcon
    UI.KeybindOverlayToggleText = toggleText
    UI.KeybindOverlaySubtitle = subtitle
    UI.KeybindOverlayCloseIcon = closeIcon
    UI.KeybindOverlayDivider = divider
    UI.KeybindOverlayEmptyIcon = emptyIcon
    UI.KeybindOverlayEmptyText = emptyText

    self:_registerThemeRefresher(function()
        overlay.BackgroundColor3 = self._Colors.Bg2
        stroke.Color = self._Colors.Border
        heading.TextColor3 = self._Colors.Text
        subtitle.TextColor3 = self._Colors.TextDim
        emptyText.TextColor3 = self._Colors.TextDim
        emptyIcon.ImageColor3 = self._Colors.TextDim
        closeIcon.ImageColor3 = self._Colors.TextDim
        closeButton.BackgroundColor3 = self._Colors.Card
        divider.BackgroundColor3 = self._Colors.Border
        list.ScrollBarImageColor3 = self._Colors.Accent
        toggle.BackgroundColor3 = self._Colors.Card
        toggleStroke.Color = self._Colors.Accent
        toggleIcon.ImageColor3 = self._Colors.Accent
        toggleText.TextColor3 = self._Colors.Accent
        for _, row in pairs(self._STATE.KeybindOverlayRows) do
            if row.frame then row.frame.BackgroundColor3 = self._Colors.Card end
            if row.stroke then row.stroke.Color = self._Colors.Border end
            if row.iconBg then row.iconBg.BackgroundColor3 = self._Colors.Bg2 end
            if row.name then row.name.TextColor3 = self._Colors.Text end
            if row.key then
                row.key.BackgroundColor3 = self._Colors.Bg2
                row.key.TextColor3 = self._Colors.Accent
            end
            if row.icon then row.icon.ImageColor3 = self._Colors.Accent end
            if row.keyStroke then row.keyStroke.Color = self._Colors.Accent end
        end
    end)
end

function Library:_refreshKeybindOverlay()
    local UI = self._UI
    local list = UI.KeybindOverlayList
    if not list then return end
    local count = #self._STATE.activeKeybindListeners
    UI.KeybindOverlayEmpty.Visible = count == 0
    if UI.KeybindOverlaySubtitle then
        if count == 0 then
            UI.KeybindOverlaySubtitle.Text = "No active keybinds"
        elseif count == 1 then
            UI.KeybindOverlaySubtitle.Text = "1 active keybind"
        else
            UI.KeybindOverlaySubtitle.Text = tostring(count) .. " active keybinds"
        end
    end
    for index, listener in ipairs(self._STATE.activeKeybindListeners) do
        local row = self._STATE.KeybindOverlayRows[listener]
        if not row or not row.frame.Parent then
            local frame = Instance.new("Frame", list)
            frame.Name = "Keybind_" .. tostring(index)
            frame.LayoutOrder = index
            frame.Size = UDim2.new(1, -6, 0, 40)
            frame.BackgroundColor3 = self._Colors.Card
            frame.BackgroundTransparency = 0.35
            frame.BorderSizePixel = 0
            frame.ZIndex = 252
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

            local rowStroke = Instance.new("UIStroke", frame)
            rowStroke.Color = self._Colors.Border
            rowStroke.Thickness = 1
            rowStroke.Transparency = 0.6

            local iconBg = Instance.new("Frame", frame)
            iconBg.Size = UDim2.fromOffset(24, 24)
            iconBg.Position = UDim2.new(0, 10, 0.5, -12)
            iconBg.BackgroundColor3 = self._Colors.Bg2
            iconBg.BackgroundTransparency = 0.3
            iconBg.BorderSizePixel = 0
            iconBg.ZIndex = 253
            Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 6)

            local icon = Instance.new("ImageLabel", iconBg)
            icon.Size = UDim2.fromOffset(12, 12)
            icon.Position = UDim2.new(0.5, -6, 0.5, -6)
            icon.BackgroundTransparency = 1
            icon.Image = GetIcon("command")
            icon.ImageColor3 = self._Colors.Accent
            icon.ZIndex = 254

            local name = Instance.new("TextLabel", frame)
            name.Name = "Action"
            name.Size = UDim2.new(1, -120, 1, 0)
            name.Position = UDim2.new(0, 42, 0, 0)
            name.BackgroundTransparency = 1
            name.TextColor3 = self._Colors.Text
            name.Font = Enum.Font.GothamMedium
            name.TextSize = 12
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.ZIndex = 253

            local key = Instance.new("TextLabel", frame)
            key.Name = "Shortcut"
            key.Size = UDim2.new(0, 68, 0, 24)
            key.Position = UDim2.new(1, -78, 0.5, -12)
            key.BackgroundColor3 = self._Colors.Bg2
            key.BackgroundTransparency = 0.2
            key.BorderSizePixel = 0
            key.TextColor3 = self._Colors.Accent
            key.Font = Enum.Font.GothamBold
            key.TextSize = 10
            key.TextTruncate = Enum.TextTruncate.AtEnd
            key.ZIndex = 253
            Instance.new("UICorner", key).CornerRadius = UDim.new(0, 7)

            local keyStroke = Instance.new("UIStroke", key)
            keyStroke.Color = self._Colors.Accent
            keyStroke.Thickness = 1
            keyStroke.Transparency = 0.65

            row = {
                frame = frame,
                stroke = rowStroke,
                iconBg = iconBg,
                icon = icon,
                name = name,
                key = key,
                keyStroke = keyStroke,
            }
            self._STATE.KeybindOverlayRows[listener] = row
        end
        row.frame.LayoutOrder = index
        row.name.Text = listener.name
        row.key.Text = listener.keyName or "None"
    end
end

function Library:_initTooltip()
    local UI = self._UI
    local gui = Instance.new("ScreenGui")
    gui.Name = "DoD_UI_Tooltip"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    UI.TooltipGui = gui

    local frame = Instance.new("Frame", gui)
    frame.Name = "Tooltip"
    frame.BackgroundColor3 = self._Colors.Bg2
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromOffset(120, 28)
    frame.Visible = false
    frame.ZIndex = 100
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = self._Colors.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    local glow = Instance.new("Frame", frame)
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.BackgroundColor3 = self._Colors.Accent
    glow.BackgroundTransparency = 0.92
    glow.BorderSizePixel = 0
    glow.ZIndex = 100
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 8)

    local accentBar = Instance.new("Frame", frame)
    accentBar.Size = UDim2.new(0, 3, 1, -8)
    accentBar.Position = UDim2.new(0, 4, 0, 4)
    accentBar.BackgroundColor3 = self._Colors.Accent
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 102
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextColor3 = self._Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = ""
    label.ZIndex = 102

    UI.TooltipFrame = frame
    UI.TooltipLabel = label
    UI.TooltipStroke = stroke
    UI.TooltipAccent = accentBar
    UI.TooltipGlow = glow

    self:_registerThemeRefresher(function()
        if not frame.Parent then return end
        frame.BackgroundColor3 = self._Colors.Bg2
        stroke.Color = self._Colors.Accent
        accentBar.BackgroundColor3 = self._Colors.Accent
        glow.BackgroundColor3 = self._Colors.Accent
        label.TextColor3 = self._Colors.Text
    end)

    Fn.track(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_updateTooltipPosition(input.Position)
        end
    end, self)
end

function Library:_updateTooltipPosition(mousePos)
    local frame = self._UI.TooltipFrame
    if not frame or not frame.Visible then return end
    local cam = getCam()
    if not cam then return end
    local vp = cam.ViewportSize
    local fw = frame.AbsoluteSize.X
    local fh = frame.AbsoluteSize.Y
    if fw <= 0 then fw = 120 end
    if fh <= 0 then fh = 28 end
    local x = mousePos.X + 18
    local y = mousePos.Y + 22
    if x + fw > vp.X - 8 then x = mousePos.X - fw - 18 end
    if y + fh > vp.Y - 8 then y = mousePos.Y - fh - 14 end
    frame.Position = UDim2.fromOffset(math.max(4, x), math.max(4, y))
end

function Library:_bindTooltip(element, text)
    if not text or text == "" then return end
    element.MouseEnter:Connect(function()
        local frame = self._UI.TooltipFrame
        if not frame then return end
        local lbl = self._UI.TooltipLabel
        lbl.Text = tostring(text)
        local charCount = utf8.len(tostring(text)) or #tostring(text)
        local w = math.clamp(charCount * 7 + 32, 100, 320)
        frame.Size = UDim2.fromOffset(w, 28)
        frame.Visible = true
        frame.BackgroundTransparency = 1
        self._UI.TooltipStroke.Transparency = 1
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(self._UI.TooltipStroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
        local mouse = UserInputService:GetMouseLocation()
        self:_updateTooltipPosition(mouse)
    end)
    element.MouseLeave:Connect(function()
        local frame = self._UI.TooltipFrame
        if not frame then return end
        TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
        TweenService:Create(self._UI.TooltipStroke, TweenInfo.new(0.1), {Transparency = 1}):Play()
        task.delay(0.12, function()
            if frame and frame.BackgroundTransparency >= 0.9 then
                frame.Visible = false
            end
        end)
    end)
end

function Library:_bindToggleKey()
    Fn.track(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end, self)
end

function Library:SetVersion(text)
    if self:_isDead() then return end
    self.Version = tostring(text or "")
    if self._UI.TitleVersionBadge then
        self._UI.TitleVersionBadge.Text = self.Version
    end
end

function Library:SetToggleKey(key)
    if self:_isDead() then return end
    if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then
        error("[DoD UI] SetToggleKey expects an Enum.KeyCode.")
    end
    self.ToggleKey = key
    if self._UI.TitleToggleHint then
        self._UI.TitleToggleHint.Text = key.Name
    end
    self:Notify("KEYBIND", "Toggle GUI: " .. key.Name)
end

function Library:SetTitleIcon(iconName)
    if self:_isDead() then return end
    if type(iconName) ~= "string" or iconName == "" then
        error("[DoD UI] SetTitleIcon expects a non-empty icon name string.")
    end
    self._TitleIconName = iconName
    if self._UI.TitleLogoIcon then
        self._UI.TitleLogoIcon.Image = GetIcon(iconName)
    end
end

-- Removed _initProfileCard

function Library:CreateKeybindOverlay()
    if self:_isDead() then return end
    self:_refreshKeybindOverlay()
    self._UI.KeybindOverlayToggle.Visible = true
    return self._UI.KeybindOverlay
end

function Library:SetKeybindOverlayVisible(visible)
    if self:_isDead() then return end
    if type(visible) ~= "boolean" then
        error("[DoD UI] SetKeybindOverlayVisible expects a boolean value.")
    end
    self._UI.KeybindOverlay.Visible = visible
end

-- =========================================================
-- TITLE BAR
-- =========================================================

function Library:_initTitleBar()
    local UI = self._UI
    UI.TitleBar = Instance.new("Frame", UI.MainContainer)
    UI.TitleBar.Size = UDim2.new(1, 0, 0, 42)
    UI.TitleBar.BackgroundColor3 = self._Colors.Bg2
    UI.TitleBar.BorderSizePixel = 0
    Instance.new("UICorner", UI.TitleBar).CornerRadius = UDim.new(0, 14)

    UI.TitleGradient = Instance.new("UIGradient", UI.TitleBar)
    UI.TitleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, self._Colors.Accent),
        ColorSequenceKeypoint.new(1, self._Colors.Accent2),
    })
    UI.TitleGradient.Rotation = 90
    UI.TitleGradient.Transparency = NumberSequence.new(0.85)

    -- Modern Glass Logo
    local logoBadge = Instance.new("Frame", UI.TitleBar)
    logoBadge.Name = "TitleLogoBadge"
    logoBadge.Size = UDim2.fromOffset(24, 24)
    logoBadge.Position = UDim2.new(0, 12, 0.5, -12)
    logoBadge.BackgroundColor3 = Color3.new(1, 1, 1)
    logoBadge.BackgroundTransparency = 0.88
    logoBadge.BorderSizePixel = 0
    Instance.new("UICorner", logoBadge).CornerRadius = UDim.new(0, 8)

    local logoStroke = Instance.new("UIStroke", logoBadge)
    logoStroke.Color = Color3.new(1, 1, 1)
    logoStroke.Thickness = 1
    logoStroke.Transparency = 0.85

    local logoIcon = Instance.new("ImageLabel", logoBadge)
    logoIcon.Name = "Icon"
    logoIcon.Size = UDim2.fromOffset(14, 14)
    logoIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = GetIcon(self._TitleIconName)
    logoIcon.ImageColor3 = self._Colors.Accent
    logoIcon.ScaleType = Enum.ScaleType.Fit

    local logoScale = Instance.new("UIScale", logoBadge)
    logoScale.Scale = 1

    logoBadge.MouseEnter:Connect(function()
        TweenService:Create(logoScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.08}):Play()
        TweenService:Create(logoStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
    end)
    logoBadge.MouseLeave:Connect(function()
        TweenService:Create(logoScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(logoStroke, TweenInfo.new(0.15), {Transparency = 0.85}):Play()
    end)

    UI.TitleLogoBadge = logoBadge
    UI.TitleLogoStroke = logoStroke
    UI.TitleLogoIcon = logoIcon

    local mainTitle, subTitle = self.Title:match("^(.-)%s*|%s*(.+)$")
    if not mainTitle then
        mainTitle = self.Title
        subTitle = ""
    end

    UI.TitleLabel = Instance.new("TextLabel", UI.TitleBar)
    UI.TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    UI.TitleLabel.Position = UDim2.new(0, 46, 0, 0)
    UI.TitleLabel.BackgroundTransparency = 1
    UI.TitleLabel.Text = mainTitle
    UI.TitleLabel.TextColor3 = self._Colors.Text
    UI.TitleLabel.Font = Enum.Font.GothamBlack
    UI.TitleLabel.TextSize = 14
    UI.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    UI.TitleLabel.TextYAlignment = Enum.TextYAlignment.Center

    UI.TitleSubtitle = Instance.new("TextLabel", UI.TitleBar)
    UI.TitleSubtitle.Size = UDim2.new(0, 200, 1, 0)
    UI.TitleSubtitle.Position = UDim2.new(0, 46, 0, 0)
    UI.TitleSubtitle.BackgroundTransparency = 1
    UI.TitleSubtitle.Text = subTitle
    UI.TitleSubtitle.TextColor3 = self._Colors.TextDim
    UI.TitleSubtitle.Font = Enum.Font.GothamMedium
    UI.TitleSubtitle.TextSize = 12
    UI.TitleSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    UI.TitleSubtitle.TextYAlignment = Enum.TextYAlignment.Center

    -- Glass Pill Version
    UI.TitleVersionBadge = Instance.new("TextLabel", UI.TitleBar)
    UI.TitleVersionBadge.Size = UDim2.new(0, 0, 0, 18)
    UI.TitleVersionBadge.AutomaticSize = Enum.AutomaticSize.X
    UI.TitleVersionBadge.Position = UDim2.new(0, 170, 0.5, -9)
    UI.TitleVersionBadge.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.TitleVersionBadge.BackgroundTransparency = 0.92
    UI.TitleVersionBadge.Text = self.Version
    UI.TitleVersionBadge.TextColor3 = self._Colors.TextDim
    UI.TitleVersionBadge.Font = Enum.Font.RobotoMono
    UI.TitleVersionBadge.TextSize = 10
    UI.TitleVersionBadge.BorderSizePixel = 0
    Instance.new("UICorner", UI.TitleVersionBadge).CornerRadius = UDim.new(1, 0)

    local vStroke = Instance.new("UIStroke", UI.TitleVersionBadge)
    vStroke.Color = Color3.new(1, 1, 1)
    vStroke.Transparency = 0.88
    vStroke.Thickness = 1

    local vPad = Instance.new("UIPadding", UI.TitleVersionBadge)
    vPad.PaddingLeft = UDim.new(0, 8)
    vPad.PaddingRight = UDim.new(0, 8)

    UI.TitleDiscord = Instance.new("TextLabel", UI.TitleBar)
    UI.TitleDiscord.Size = UDim2.new(0, 0, 1, 0)
    UI.TitleDiscord.AutomaticSize = Enum.AutomaticSize.X
    UI.TitleDiscord.Position = UDim2.new(1, -230, 0, 0)
    UI.TitleDiscord.BackgroundTransparency = 1
    UI.TitleDiscord.Text = "<i>" .. self.Author .. "</i>"
    UI.TitleDiscord.RichText = true
    UI.TitleDiscord.TextColor3 = self._Colors.TextDim
    UI.TitleDiscord.Font = Enum.Font.GothamBold
    UI.TitleDiscord.TextSize = 12
    UI.TitleDiscord.TextXAlignment = Enum.TextXAlignment.Right

    -- Keybind Hint Box
    local hintBg = Instance.new("TextButton", UI.TitleBar)
    hintBg.Name = "TitleToggleHintBg"
    hintBg.Size = UDim2.new(0, 0, 0, 20)
    hintBg.AutomaticSize = Enum.AutomaticSize.X
    hintBg.Position = UDim2.new(1, -300, 0.5, -10)
    hintBg.BackgroundColor3 = self._Colors.Bg
    hintBg.BackgroundTransparency = 0.5
    hintBg.BorderSizePixel = 0
    hintBg.Text = ""
    hintBg.AutoButtonColor = false
    Instance.new("UICorner", hintBg).CornerRadius = UDim.new(0, 4)

    local hintStroke = Instance.new("UIStroke", hintBg)
    hintStroke.Color = self._Colors.Border
    hintStroke.Transparency = 0.5
    hintStroke.Thickness = 1

    local hintPad = Instance.new("UIPadding", hintBg)
    hintPad.PaddingLeft = UDim.new(0, 6)
    hintPad.PaddingRight = UDim.new(0, 6)

    UI.TitleToggleHint = Instance.new("TextLabel", hintBg)
    UI.TitleToggleHint.AutomaticSize = Enum.AutomaticSize.X
    UI.TitleToggleHint.Size = UDim2.new(0, 0, 1, 0)
    UI.TitleToggleHint.BackgroundTransparency = 1
    UI.TitleToggleHint.Text = self.ToggleKey.Name
    UI.TitleToggleHint.TextColor3 = self._Colors.TextDim
    UI.TitleToggleHint.Font = Enum.Font.GothamMedium
    UI.TitleToggleHint.TextSize = 10
    UI.TitleToggleHint.TextXAlignment = Enum.TextXAlignment.Center
    UI.TitleToggleHint.TextYAlignment = Enum.TextYAlignment.Center
    
    UI.TitleToggleHintBg = hintBg

    hintBg.MouseEnter:Connect(function()
        TweenService:Create(hintBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(hintStroke, TweenInfo.new(0.15), {Transparency = 0.2, Color = self._Colors.Accent}):Play()
    end)
    hintBg.MouseLeave:Connect(function()
        TweenService:Create(hintBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
        TweenService:Create(hintStroke, TweenInfo.new(0.15), {Transparency = 0.5, Color = self._Colors.Border}):Play()
    end)

    local isListening = false
    hintBg.MouseButton1Click:Connect(function()
        if isListening then return end
        isListening = true
        UI.TitleToggleHint.Text = "PRESS KEY..."
        UI.TitleToggleHint.TextColor3 = self._Colors.Accent
        
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self:SetToggleKey(input.KeyCode)
                UI.TitleToggleHint.TextColor3 = self._Colors.TextDim
                isListening = false
                conn:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                UI.TitleToggleHint.Text = self.ToggleKey.Name
                UI.TitleToggleHint.TextColor3 = self._Colors.TextDim
                isListening = false
                conn:Disconnect()
            end
        end)
    end)

    self:_registerThemeRefresher(function()
        if UI.TitleToggleHint then
            UI.TitleToggleHint.TextColor3 = self._Colors.TextDim
        end
        if hintStroke then
            hintStroke.Color = self._Colors.Border
        end
        if hintBg then
            hintBg.BackgroundColor3 = self._Colors.Bg
        end
        if UI.TitleSubtitle then
            UI.TitleSubtitle.TextColor3 = self._Colors.TextDim
        end
        if logoIcon then
            logoIcon.ImageColor3 = self._Colors.Accent
        end
    end)

    local function updateTitleLayout()
        local width = UI.MainContainer.AbsoluteSize.X
        if width <= 0 then width = 640 end
        
        local tlWidth = 76
        UI.TitleDiscord.Visible = width >= 560
        local authorW = 0
        if UI.TitleDiscord.Visible then
            authorW = UI.TitleDiscord.AbsoluteSize.X
            if authorW <= 0 then authorW = 50 end
            UI.TitleDiscord.Position = UDim2.new(1, -tlWidth - authorW, 0, 0)
        end

        local hintW = UI.TitleToggleHintBg.AbsoluteSize.X
        if hintW <= 0 then hintW = 40 end
        local hintOffset = tlWidth + (authorW > 0 and authorW + 12 or 0)
        UI.TitleToggleHintBg.Position = UDim2.new(1, -hintOffset - hintW, 0.5, -10)

        local maxTitleWidth = math.clamp(width - 420, 80, 300)
        
        local mainTextW = UI.TitleLabel.TextBounds.X
        if mainTextW <= 0 then
            mainTextW = #UI.TitleLabel.Text * 7.5
        end
        mainTextW = math.min(mainTextW, maxTitleWidth)
        UI.TitleLabel.Size = UDim2.new(0, mainTextW, 1, 0)
        
        local subTextW = 0
        if UI.TitleSubtitle.Text ~= "" then
            subTextW = UI.TitleSubtitle.TextBounds.X
            if subTextW <= 0 then subTextW = #UI.TitleSubtitle.Text * 6 end
            local maxSubWidth = math.max(10, maxTitleWidth - mainTextW - 8)
            subTextW = math.min(subTextW, maxSubWidth)
            UI.TitleSubtitle.Size = UDim2.new(0, subTextW, 1, 0)
            UI.TitleSubtitle.Position = UDim2.new(0, 46 + mainTextW + 8, 0, 0)
            UI.TitleSubtitle.Visible = true
        else
            UI.TitleSubtitle.Visible = false
        end

        local badgeW = UI.TitleVersionBadge.AbsoluteSize.X
        if badgeW <= 0 then badgeW = 40 end
        local badgeStart = 46 + mainTextW + (subTextW > 0 and subTextW + 12 or 10)
        local badgeEnd = badgeStart + badgeW

        local hintStart = width - hintOffset - hintW
        local canShowBadge = width >= 420 and (badgeEnd + 16) < hintStart

        UI.TitleVersionBadge.Visible = canShowBadge
        UI.TitleVersionBadge.Position = UDim2.new(0, badgeStart, 0.5, -9)
    end
    updateTitleLayout()
    task.defer(updateTitleLayout)
    task.delay(0.15, updateTitleLayout)
    Fn.track(UI.MainContainer:GetPropertyChangedSignal("AbsoluteSize"), updateTitleLayout, self)
    Fn.track(UI.TitleVersionBadge:GetPropertyChangedSignal("AbsoluteSize"), updateTitleLayout, self)
    Fn.track(UI.TitleToggleHintBg:GetPropertyChangedSignal("AbsoluteSize"), updateTitleLayout, self)
end

function Library:_initTrafficLights()
    local UI = self._UI
    local container = Instance.new("Frame", UI.TitleBar)
    container.Name = "TrafficLights"
    container.Size = UDim2.new(0, 62, 0, 14)
    container.Position = UDim2.new(1, -76, 0.5, -7)
    container.BackgroundTransparency = 1

    local baseColors = {
        Color3.fromRGB(255, 95, 86),
        Color3.fromRGB(255, 189, 46),
        Color3.fromRGB(39, 201, 63),
    }
    local hoverColors = {
        Color3.fromRGB(255, 130, 122),
        Color3.fromRGB(255, 205, 90),
        Color3.fromRGB(60, 220, 80),
    }
    UI.TrafficDots = {}
    for i = 1, 3 do
        local dot = Instance.new("TextButton", container)
        dot.Size = UDim2.new(0, 14, 0, 14)
        dot.Position = UDim2.new(0, (i - 1) * 18, 0, 0)
        dot.BackgroundColor3 = baseColors[i]
        dot.Text = ""
        dot.BorderSizePixel = 0
        dot.AutoButtonColor = false
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        Fn.bindPressAnimation(dot)
        dot.MouseEnter:Connect(function() dot.BackgroundColor3 = hoverColors[i] end)
        dot.MouseLeave:Connect(function() dot.BackgroundColor3 = baseColors[i] end)
        table.insert(UI.TrafficDots, dot)
    end

    UI.TrafficDots[1].MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    self._hudState    = "NORMAL"
    self._hudNormalSize = self.WindowSize
    self._hudNormalPos  = UDim2.new(0.5, 0, 0.5, 0)

    local hudTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function hideChildren(visible)
        for _, child in ipairs(UI.MainContainer:GetChildren()) do
            if child:IsA("GuiObject") and child ~= UI.TitleBar then
                if child == UI.AcrylicTexture or child == UI.AcrylicSheen then
                    child.Visible = visible and self.Acrylic
                else
                    child.Visible = visible
                end
            end
        end
        if UI.ParticleBG then
            UI.ParticleBG.Visible = visible and self._STATE.GuiVisible
        end
        if UI.SnowLayer then
            UI.SnowLayer.Visible = visible and self._STATE.GuiVisible and self._STATE.WeatherEnabled
        end
        if UI.MobileToggle then
            UI.MobileToggle.Visible = visible and UserInputService.TouchEnabled
        end
        if UI.KeybindOverlay and not visible then
            UI.KeybindOverlay.Visible = false
        end
        if UI.KeybindOverlayToggle then
            UI.KeybindOverlayToggle.Visible = visible and #self._STATE.activeKeybindListeners > 0
        end
        if self._STATE.ContentPages then
            for name, page in pairs(self._STATE.ContentPages) do
                if page then
                    page.Visible = visible and (name == self._STATE.ActiveTab)
                end
            end
        end
    end

    local function applyHudState(target)
        if self._hudState == target then return end
        local prev = self._hudState
        self._hudState = target

        if prev == "NORMAL" then
            self._hudNormalSize = UI.MainContainer.Size
            self._hudNormalPos  = UI.MainContainer.Position
        end

        if target == "MINIMIZED" then
            hideChildren(false)
            if UI.FocusOverlay then
                self._focusOverlayWasVisible = UI.FocusOverlay.Visible
                UI.FocusOverlay.Visible = false
            end
            local curr = UI.MainContainer.Size
            TweenService:Create(UI.MainContainer, hudTweenInfo, {
                Size = UDim2.new(curr.X.Scale, curr.X.Offset, 0, 42),
            }):Play()
        elseif target == "MAXIMIZED" then
            local camera = getCam()
            if not camera then return end
            local vp = camera.ViewportSize
            TweenService:Create(UI.MainContainer, hudTweenInfo, {
                Size = UDim2.new(0, math.max(1, vp.X - 40), 0, math.max(1, vp.Y - 40)),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            }):Play()
        else -- NORMAL
            local tw = TweenService:Create(UI.MainContainer, hudTweenInfo, {
                Size = self._hudNormalSize,
                Position = self._hudNormalPos,
            })
            tw.Completed:Connect(function()
                if self._hudState == "NORMAL" then
                    hideChildren(true)
                    if self._STATE.FocusOverlayEnabled and self._STATE.GuiVisible and UI.FocusOverlay then
                        UI.FocusOverlay.Visible = true
                    end
                end
            end)
            tw:Play()
        end
    end

    UI.TrafficDots[2].MouseButton1Click:Connect(function()
        if STATE.GuiVisible then
            self:Minimize()
        end
    end)

    UI.TrafficDots[3].MouseButton1Click:Connect(function()
        if self._hudState == "MAXIMIZED" then
            applyHudState("NORMAL")
        else
            applyHudState("MAXIMIZED")
        end
    end)
end

-- =========================================================
-- CATEGORY BAR + SUB-TAB HOST
-- =========================================================

function Library:_initSidebar()
    local UI = self._UI

    UI.CategoryBar = Instance.new("Frame", UI.MainContainer)
    UI.CategoryBar.Size = UDim2.new(1, -20, 0, 46)
    UI.CategoryBar.Position = UDim2.new(0, 10, 0, 42)
    UI.CategoryBar.BackgroundColor3 = self._Colors.Sidebar
    UI.CategoryBar.BackgroundTransparency = 0.35
    UI.CategoryBar.BorderSizePixel = 0
    UI.CategoryBar.ClipsDescendants = true
    Instance.new("UICorner", UI.CategoryBar).CornerRadius = UDim.new(0, 14)
    UI.CategoryBarStroke = Instance.new("UIStroke", UI.CategoryBar)
    UI.CategoryBarStroke.Color = self._Colors.Border
    UI.CategoryBarStroke.Thickness = 1
    UI.CategoryBarStroke.Transparency = 1

    UI.Sidebar = Instance.new("Frame", UI.MainContainer)
    UI.Sidebar.Size = UDim2.new(1, -20, 0, 30)
    UI.Sidebar.Position = UDim2.new(0, 10, 0, 94)
    UI.Sidebar.BackgroundColor3 = self._Colors.Sidebar
    UI.Sidebar.BackgroundTransparency = 1
    UI.Sidebar.BorderSizePixel = 0
    UI.Sidebar.ClipsDescendants = true
    Instance.new("UICorner", UI.Sidebar).CornerRadius = UDim.new(0, 10)

    UI.TabBarDivider = Instance.new("Frame", UI.MainContainer)
    UI.TabBarDivider.Size = UDim2.new(1, -20, 0, 1)
    UI.TabBarDivider.Position = UDim2.new(0, 10, 0, 124)
    UI.TabBarDivider.BackgroundColor3 = self._Colors.Border
    UI.TabBarDivider.BackgroundTransparency = 0.5
    UI.TabBarDivider.BorderSizePixel = 0

    local accordionScroll = Instance.new("ScrollingFrame", UI.CategoryBar)
    accordionScroll.Name = "AccordionScroll"
    accordionScroll.Position = UDim2.new(0, 6, 0, 56)
    accordionScroll.Size = UDim2.new(1, -12, 1, -114)
    accordionScroll.BackgroundTransparency = 1
    accordionScroll.BorderSizePixel = 0
    accordionScroll.ScrollBarThickness = 2
    accordionScroll.ScrollBarImageColor3 = self._Colors.Accent
    accordionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    accordionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    accordionScroll.Visible = false
    accordionScroll.ZIndex = 5

    local asLayout = Instance.new("UIListLayout", accordionScroll)
    asLayout.SortOrder = Enum.SortOrder.LayoutOrder
    asLayout.Padding = UDim.new(0, 4)

    local asPad = Instance.new("UIPadding", accordionScroll)
    asPad.PaddingTop = UDim.new(0, 4)
    asPad.PaddingBottom = UDim.new(0, 8)
    asPad.PaddingLeft = UDim.new(0, 4)
    asPad.PaddingRight = UDim.new(0, 4)

    UI.AccordionScroll = accordionScroll

    local miniProfile = Instance.new("Frame", UI.CategoryBar)
    miniProfile.Name = "SideProfileMini"
    miniProfile.Size = UDim2.new(1, -16, 0, 36)
    miniProfile.Position = UDim2.new(0, 8, 1, -44)
    miniProfile.BackgroundColor3 = self._Colors.Card
    miniProfile.BackgroundTransparency = 0.5
    miniProfile.BorderSizePixel = 0
    miniProfile.Visible = false
    miniProfile.ZIndex = 10
    Instance.new("UICorner", miniProfile).CornerRadius = UDim.new(0, 8)

    local spStroke = Instance.new("UIStroke", miniProfile)
    spStroke.Color = self._Colors.Border
    spStroke.Thickness = 1
    spStroke.Transparency = 0.5

    local spAvatar = Instance.new("ImageLabel", miniProfile)
    spAvatar.Name = "Avatar"
    spAvatar.Size = UDim2.fromOffset(22, 22)
    spAvatar.Position = UDim2.new(0, 8, 0.5, -11)
    spAvatar.BackgroundColor3 = self._Colors.Bg2
    spAvatar.BorderSizePixel = 0
    spAvatar.ZIndex = 11
    spAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150&filters=circular"
    Instance.new("UICorner", spAvatar).CornerRadius = UDim.new(1, 0)

    local spName = Instance.new("TextLabel", miniProfile)
    spName.Name = "Name"
    spName.Size = UDim2.new(1, -44, 1, 0)
    spName.Position = UDim2.new(0, 36, 0, 0)
    spName.BackgroundTransparency = 1
    spName.Text = LocalPlayer.Name
    spName.TextColor3 = self._Colors.Text
    spName.Font = Enum.Font.GothamBold
    spName.TextSize = 12
    spName.TextXAlignment = Enum.TextXAlignment.Left
    spName.TextTruncate = Enum.TextTruncate.AtEnd
    spName.ZIndex = 11

    UI.SideProfileMini = miniProfile
    UI.SideProfileAvatar = spAvatar
    UI.SideProfileName = spName
    UI.SideProfileStroke = spStroke

    self:_registerThemeRefresher(function()
        if not miniProfile.Parent then return end
        miniProfile.BackgroundColor3 = self._Colors.Card
        spStroke.Color = self._Colors.Border
        spName.TextColor3 = self._Colors.Text
        spAvatar.BackgroundColor3 = self._Colors.Bg2
        if accordionScroll and accordionScroll.Parent then
            accordionScroll.ScrollBarImageColor3 = self._Colors.Accent
        end
    end)
end

function Library:_applyNavigationLayout()
    local UI = self._UI
    if not (UI.CategoryBar and UI.Sidebar and UI.TabBarDivider) then return end
    local position = self.TabPosition
    local mainSize = UI.MainContainer.AbsoluteSize
    local mainW = mainSize.X
    local mainH = mainSize.Y
    local sideWidth = math.min(self.TabWidth + 20, math.max(120, mainW * 0.36))
    local hasSearch  = UI.SearchBar ~= nil
    local hasContent = UI.ContentArea ~= nil

    local BOTTOM_PADDING = 15

    if position == "Side" then
        if hasSearch and UI.SearchBar.Parent ~= UI.CategoryBar then
            UI.SearchBar.Parent = UI.CategoryBar
        end
        UI.CategoryBar.Size = UDim2.new(0, sideWidth, 1, -62)
        UI.CategoryBar.Position = UDim2.new(0, 10, 0, 50)
        UI.CategoryBar.BackgroundColor3 = self._Colors.Sidebar
        UI.CategoryBar.BackgroundTransparency = 0.35
        UI.CategoryBarStroke.Transparency = 0
        UI.CategoryBarStroke.Color = self._Colors.Border

        if hasSearch then
            UI.SearchBar.Size = UDim2.new(1, -16, 0, 32)
            UI.SearchBar.Position = UDim2.new(0, 8, 0, 8)
        end

        UI.Sidebar.Visible = false
        UI.TabBarDivider.Visible = false
        if UI.AccordionScroll then UI.AccordionScroll.Visible = true end
        if UI.SideProfileMini then UI.SideProfileMini.Visible = true end

        if hasContent then
            UI.ContentArea.Size = UDim2.new(1, -(sideWidth + 30), 1, -62)
            UI.ContentArea.Position = UDim2.new(0, sideWidth + 20, 0, 50)
        end
        if UI.BottomPill then UI.BottomPill.Visible = false end

    elseif position == "Bottom" then
        if hasSearch and UI.SearchBar.Parent ~= UI.MainContainer then
            UI.SearchBar.Parent = UI.MainContainer
        end
        UI.Sidebar.Visible = true
        UI.TabBarDivider.Visible = true
        if UI.AccordionScroll then UI.AccordionScroll.Visible = false end
        if UI.SideProfileMini then UI.SideProfileMini.Visible = false end
        if UI.BottomPill then UI.BottomPill.Visible = true end

        UI.CategoryBar.Size = UDim2.new(1, -20, 0, 56)
        UI.CategoryBar.Position = UDim2.new(0, 10, 1, -66)
        UI.CategoryBar.BackgroundColor3 = self._Colors.Card
        UI.CategoryBar.BackgroundTransparency = 0.05
        UI.CategoryBarStroke.Transparency = 0.2

        UI.Sidebar.Size = UDim2.new(1, -20, 0, 30)
        UI.Sidebar.Position = UDim2.new(0, 10, 0, 48)
        UI.TabBarDivider.Size = UDim2.new(1, -20, 0, 1)
        UI.TabBarDivider.Position = UDim2.new(0, 10, 0, 80)

        if hasSearch then
            UI.SearchBar.Size = UDim2.new(1, -30, 0, 28)
            UI.SearchBar.Position = UDim2.new(0, 15, 0, 86)
        end
        if hasContent then
            local contentTop = 119
            local bottomReserve = 56 + 10 + 10
            local contentH = math.max(120, mainH - contentTop - bottomReserve)
            UI.ContentArea.Size = UDim2.new(1, -30, 0, contentH)
            UI.ContentArea.Position = UDim2.new(0, 15, 0, contentTop)
        end

    else -- Top
        UI.CategoryBar.Size = UDim2.new(1, -20, 0, 46)
        UI.CategoryBar.Position = UDim2.new(0, 10, 0, 42)
        UI.CategoryBar.BackgroundColor3 = self._Colors.Sidebar
        UI.CategoryBar.BackgroundTransparency = 0.35
        UI.CategoryBarStroke.Transparency = 1

        UI.Sidebar.Size = UDim2.new(1, -20, 0, 30)
        UI.Sidebar.Position = UDim2.new(0, 10, 0, 94)
        UI.TabBarDivider.Size = UDim2.new(1, -20, 0, 1)
        UI.TabBarDivider.Position = UDim2.new(0, 10, 0, 124)

        if hasSearch then
            UI.SearchBar.Size = UDim2.new(1, -30, 0, 28)
            UI.SearchBar.Position = UDim2.new(0, 15, 0, 129)
        end
        if hasContent then
            local contentTop = 162
            local contentH = math.max(150, mainH - contentTop - BOTTOM_PADDING)
            UI.ContentArea.Size = UDim2.new(1, -30, 0, contentH)
            UI.ContentArea.Position = UDim2.new(0, 15, 0, contentTop)
        end
        if UI.BottomPill then UI.BottomPill.Visible = false end
    end

    self:_layoutCategoryButtons()
    self:_resizeSubTabs()
end

function Library:_toggleCategoryAccordion(categoryName)
    if self:_isDead() then return end
    local STATE = self._STATE
    local data = STATE.CategoryButtons and STATE.CategoryButtons[categoryName]
    if not data or not data.isAccordion then return end
    local current = STATE.AccordionExpanded[categoryName]
    self:_setAccordionState(categoryName, not current)
end

function Library:_setAccordionState(categoryName, expanded)
    if self:_isDead() then return end
    local STATE = self._STATE
    local data = STATE.CategoryButtons and STATE.CategoryButtons[categoryName]
    if not data or not data.isAccordion then return end
    STATE.AccordionExpanded[categoryName] = expanded
    if expanded then
        data.tabList.Visible = true
        local targetH = data.layout.AbsoluteContentSize.Y
        TweenService:Create(data.tabList, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetH)
        }):Play()
    else
        local tw = TweenService:Create(data.tabList, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0)
        })
        tw.Completed:Connect(function()
            if not STATE.AccordionExpanded[categoryName] then
                data.tabList.Visible = false
            end
        end)
        tw:Play()
    end
    if data.chevron then
        data.chevron.Image = GetIcon(expanded and "chevron-up" or "chevron-down")
    end
    if data.button and data.stroke then
        TweenService:Create(data.stroke, TweenInfo.new(0.18), {
            Transparency = expanded and 0.3 or 0.7,
            Color = expanded and self._Colors.Accent or self._Colors.Border,
        }):Play()
        TweenService:Create(data.button, TweenInfo.new(0.18), {
            BackgroundTransparency = expanded and 0.5 or 0.75,
        }):Play()
        if data.label then
            data.label.TextColor3 = expanded and self._Colors.Text or self._Colors.TextDim
            data.label.Font = expanded and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
        if data.icon then
            data.icon.ImageColor3 = expanded and self._Colors.Accent or self._Colors.TextDim
        end
        if data.chevron then
            data.chevron.ImageColor3 = expanded and self._Colors.Accent or self._Colors.TextDim
        end
    end
end

function Library:_resizeSubTabs()
    if self.TabPosition == "Side" then return end
    local subTabBar = self._STATE.SubTabBar
    local category = self._STATE.ActiveCategory
    if not subTabBar or not category then return end
    local tabs = self._STATE.CategoryTabs[category] or {}
    local tabCount = #tabs
    if tabCount == 0 then return end
    local availableWidth = self._UI.Sidebar.AbsoluteSize.X
    if availableWidth <= 0 then return end
    local gap = math.min(subTabBar.Padding, availableWidth / math.max(tabCount * 2 - 1, 1))
    local tabWidth = math.min(self.TabWidth, (availableWidth - gap * (tabCount - 1)) / tabCount)
    subTabBar:Resize(tabWidth, gap)
end

-- =========================================================
-- SEARCH BAR
-- =========================================================

function Library:_initSearchBar()
    local UI = self._UI
    UI.SearchBar = Instance.new("Frame", UI.MainContainer)
    UI.SearchBar.Size = UDim2.new(1, -30, 0, 28)
    UI.SearchBar.Position = UDim2.new(0, 15, 0, 129)
    UI.SearchBar.BackgroundColor3 = self._Colors.Card
    UI.SearchBar.BackgroundTransparency = 0.15
    UI.SearchBar.BorderSizePixel = 0
    Instance.new("UICorner", UI.SearchBar).CornerRadius = UDim.new(1, 0)

    UI.SearchBarStroke = Instance.new("UIStroke", UI.SearchBar)
    UI.SearchBarStroke.Color = self._Colors.Border
    UI.SearchBarStroke.Thickness = 1.1
    UI.SearchBarStroke.Transparency = 0.25

    UI.SearchIcon = Instance.new("ImageLabel", UI.SearchBar)
    UI.SearchIcon.Size = UDim2.new(0, 14, 0, 14)
    UI.SearchIcon.Position = UDim2.new(0, 14, 0.5, -7)
    UI.SearchIcon.BackgroundTransparency = 1
    UI.SearchIcon.Image = GetIcon("search")
    UI.SearchIcon.ImageColor3 = self._Colors.TextDim

    UI.SearchInput = Instance.new("TextBox", UI.SearchBar)
    UI.SearchInput.Size = UDim2.new(1, -50, 1, 0)
    UI.SearchInput.Position = UDim2.new(0, 36, 0, 0)
    UI.SearchInput.BackgroundTransparency = 1
    UI.SearchInput.Text = ""
    UI.SearchInput.PlaceholderText = "Search settings..."
    UI.SearchInput.PlaceholderColor3 = self._Colors.TextDim
    UI.SearchInput.TextColor3 = self._Colors.Text
    UI.SearchInput.Font = Enum.Font.GothamMedium
    UI.SearchInput.TextSize = 12
    UI.SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    UI.SearchInput.ClearTextOnFocus = false

    local clearBtn = Instance.new("TextButton", UI.SearchBar)
    clearBtn.Size = UDim2.fromOffset(16, 16)
    clearBtn.Position = UDim2.new(1, -26, 0.5, -8)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text = ""
    clearBtn.AutoButtonColor = false
    clearBtn.Visible = false
    
    local clearIcon = Instance.new("ImageLabel", clearBtn)
    clearIcon.Size = UDim2.fromScale(1, 1)
    clearIcon.BackgroundTransparency = 1
    clearIcon.Image = GetIcon("x")
    clearIcon.ImageColor3 = self._Colors.TextDim

    clearBtn.MouseButton1Click:Connect(function()
        UI.SearchInput.Text = ""
    end)

    UI.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self._STATE.SearchQuery = UI.SearchInput.Text
        clearBtn.Visible = #UI.SearchInput.Text > 0
        
        if self._searchDebounce then
            pcall(task.cancel, self._searchDebounce)
            self._searchDebounce = nil
        end
        self._searchDebounce = task.delay(0.15, function()
            self._searchDebounce = nil
            if not self:_isDead() then
                self:_applySearchFilter()
            end
        end)
    end)

    UI.SearchInput.Focused:Connect(function()
        TweenService:Create(UI.SearchBarStroke, TweenInfo.new(0.22), {
            Color = self._Colors.Accent, Transparency = 0.1
        }):Play()
    end)
    UI.SearchInput.FocusLost:Connect(function()
        TweenService:Create(UI.SearchBarStroke, TweenInfo.new(0.22), {
            Color = self._Colors.Border, Transparency = 0.25
        }):Play()
    end)
end

function Library:_applySearchFilter(tabName)
    local STATE = self._STATE
    tabName = tabName or STATE.ActiveTab
    if not tabName then return end

    local query = string.lower(STATE.SearchQuery or ""):match("^%s*(.-)%s*$")
    local searching = query ~= ""
    local totalMatches = 0

    for _, sectionData in ipairs(STATE.SearchSections[tabName] or {}) do
        if searching and not sectionData.searching then
            sectionData.expandedBeforeSearch = sectionData.expanded
        end

        local sectionMatches = searching and (
            string.find(string.lower(sectionData.title), query, 1, true) ~= nil
            or string.find(string.lower(sectionData.summary), query, 1, true) ~= nil
        )
        local anyControlMatches = false

        for _, control in ipairs(sectionData.controls) do
            local matches = not searching
                or sectionMatches
                or string.find(string.lower(control.searchText), query, 1, true) ~= nil
            control.instance.Visible = matches
            if matches then anyControlMatches = true end
        end

        local sectionMatchesResults = not searching or sectionMatches or anyControlMatches
        sectionData.section.Visible = sectionMatchesResults
        if searching and sectionMatchesResults then totalMatches = totalMatches + 1 end

        if searching then
            if sectionData.expanded ~= sectionMatchesResults then
                sectionData.setExpanded(sectionMatchesResults, false)
            end
        elseif sectionData.searching then
            if sectionData.expandedBeforeSearch ~= nil then
                sectionData.setExpanded(sectionData.expandedBeforeSearch, false)
                sectionData.expandedBeforeSearch = nil
            end
        end
        sectionData.searching = searching
    end

    local pool = STATE.SearchTopLevel and STATE.SearchTopLevel[tabName]
    if pool then
        for _, ctrl in ipairs(pool) do
            if ctrl.instance.Parent then
                local matches = not searching
                    or string.find(string.lower(ctrl.searchText), query, 1, true) ~= nil
                ctrl.instance.Visible = matches
                if searching and matches then totalMatches = totalMatches + 1 end
            end
        end
    end

    local page = STATE.ContentPages[tabName]
    if page then
        local emptyState = page:FindFirstChild("SearchEmptyState")
        if searching and totalMatches == 0 then
            if not emptyState then
                emptyState = Instance.new("Frame", page)
                emptyState.Name = "SearchEmptyState"
                emptyState.Size = UDim2.new(1, 0, 0, 100)
                emptyState.BackgroundTransparency = 1
                emptyState.LayoutOrder = 999
                local eIcon = Instance.new("ImageLabel", emptyState)
                eIcon.Size = UDim2.fromOffset(32, 32)
                eIcon.Position = UDim2.new(0.5, -16, 0, 10)
                eIcon.BackgroundTransparency = 1
                eIcon.Image = GetIcon("search")
                eIcon.ImageColor3 = self._Colors.TextDim
                local eText = Instance.new("TextLabel", emptyState)
                eText.Size = UDim2.new(1, 0, 0, 20)
                eText.Position = UDim2.new(0, 0, 0, 50)
                eText.BackgroundTransparency = 1
                eText.Text = "No results found for '" .. query .. "'"
                eText.TextColor3 = self._Colors.TextDim
                eText.Font = Enum.Font.GothamMedium
                eText.TextSize = 11
            end
            emptyState.Visible = true
        elseif emptyState then
            emptyState.Visible = false
        end
    end
end

function Library:_registerSearchControl(instance, searchText)
    local parent = instance.Parent
    local sectionData
    while parent do
        sectionData = self._STATE.SearchBodies[parent]
        if sectionData then break end
        parent = parent.Parent
    end

    if not sectionData then
        local tabName
        local p = instance.Parent
        while p do
            for name, page in pairs(self._STATE.ContentPages) do
                if page == p then tabName = name; break end
            end
            if tabName then break end
            p = p.Parent
        end
        if tabName then
            self._STATE.SearchTopLevel = self._STATE.SearchTopLevel or {}
            self._STATE.SearchTopLevel[tabName] = self._STATE.SearchTopLevel[tabName] or {}
            table.insert(self._STATE.SearchTopLevel[tabName], {
                instance = instance,
                searchText = tostring(searchText or ""),
            })
            self:_applySearchFilter(tabName)
        end
        return instance
    end

    table.insert(sectionData.controls, {
        instance = instance,
        searchText = tostring(searchText or ""),
    })
    self:_applySearchFilter(sectionData.tabName)
    return instance
end

-- =========================================================
-- CONTENT AREA (TRUE 2-COLUMN LAYOUT)
-- =========================================================

function Library:_initContentArea()
    local UI = self._UI
    UI.ContentArea = Instance.new("Frame", UI.MainContainer)
    UI.ContentArea.Size = UDim2.new(1, -30, 1, -177)
    UI.ContentArea.Position = UDim2.new(0, 15, 0, 162)
    UI.ContentArea.BackgroundTransparency = 1
    UI.ContentArea.ClipsDescendants = false
    UI.ContentArea.ZIndex = 3
end

-- =========================================================
-- FOCUS OVERLAY
-- =========================================================

function Library:_initFocusOverlay()
    self:_rebuildFocusPattern()
end

function Library:_rebuildFocusPattern()
    local UI = self._UI
    if not UI.GridPattern then return end
    for _, child in ipairs(UI.GridPattern:GetChildren()) do
        child:Destroy()
    end
    local patternType = self._STATE.FocusOverlayType or "Grid"
    if patternType == "None" then return end

    local theme = D.Themes[self.ThemeName] or D.Themes.Dark
    local accent = theme.GridColor or theme.Accent or self._Colors.Accent
    local altAccent = theme.GridAltColor or accent

    local function pickColor(index)
        if theme.GridAltColor and index % 2 == 0 then return altAccent end
        return accent
    end

    if patternType == "Grid" then
        for index = 1, 18 do
            local line = Instance.new("Frame", UI.GridPattern)
            line.BackgroundColor3 = pickColor(index)
            line.BackgroundTransparency = 0.88
            line.BorderSizePixel = 0
            if index % 2 == 0 then
                line.Size = UDim2.new(1, 0, 0, 2)
                line.Position = UDim2.new(0, 0, index / 20, 0)
            else
                line.Size = UDim2.new(0, 2, 1, 0)
                line.Position = UDim2.new(index / 20, 0, 0, 0)
            end
        end
    elseif patternType == "Dots" then
        for xi = 1, 14 do
            for yi = 1, 9 do
                local dot = Instance.new("Frame", UI.GridPattern)
                dot.Size = UDim2.fromOffset(3, 3)
                dot.Position = UDim2.new(xi / 15, 0, yi / 10, 0)
                dot.BackgroundColor3 = pickColor(xi + yi)
                dot.BackgroundTransparency = 0.7
                dot.BorderSizePixel = 0
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            end
        end
    elseif patternType == "Diagonal" then
        for index = 1, 14 do
            local line = Instance.new("Frame", UI.GridPattern)
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.Size = UDim2.new(1.6, 0, 0, 2)
            line.Position = UDim2.new(0.5, 0, index / 15, 0)
            line.Rotation = 45
            line.BackgroundColor3 = pickColor(index)
            line.BackgroundTransparency = 0.9
            line.BorderSizePixel = 0
        end
    elseif patternType == "Crosshatch" then
        for index = 1, 10 do
            for _, rot in ipairs({45, -45}) do
                local line = Instance.new("Frame", UI.GridPattern)
                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.Size = UDim2.new(1.6, 0, 0, 2)
                line.Position = UDim2.new(0.5, 0, index / 11, 0)
                line.Rotation = rot
                line.BackgroundColor3 = pickColor(index)
                line.BackgroundTransparency = 0.9
                line.BorderSizePixel = 0
            end
        end
    elseif patternType == "Radial" then
        for index = 1, 12 do
            local angle = (index / 12) * math.pi
            local line = Instance.new("Frame", UI.GridPattern)
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.Size = UDim2.new(1.4, 0, 0, 1)
            line.Position = UDim2.new(0.5, 0, 0.5, 0)
            line.Rotation = math.deg(angle)
            line.BackgroundColor3 = pickColor(index)
            line.BackgroundTransparency = 0.9
            line.BorderSizePixel = 0
        end
    elseif patternType == "Scanlines" then
        local count = 30
        for index = 1, count do
            local line = Instance.new("Frame", UI.GridPattern)
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, index / count, 0)
            line.BackgroundColor3 = pickColor(index)
            line.BackgroundTransparency = 0.88
            line.BorderSizePixel = 0
        end
    elseif patternType == "Bricks" then
        local rows, cols = 10, 8
        local rowH = 1 / rows
        for r = 1, rows do
            local hLine = Instance.new("Frame", UI.GridPattern)
            hLine.Size = UDim2.new(1, 0, 0, 1)
            hLine.Position = UDim2.new(0, 0, r * rowH, 0)
            hLine.BackgroundColor3 = pickColor(r)
            hLine.BackgroundTransparency = 0.88
            hLine.BorderSizePixel = 0
            local isOdd = (r % 2 == 1)
            local limit = isOdd and cols or (cols - 1)
            local offset = isOdd and 0 or (0.5 / cols)
            for c = 1, limit do
                local vLine = Instance.new("Frame", UI.GridPattern)
                vLine.Size = UDim2.new(0, 1, rowH, 0)
                vLine.Position = UDim2.new((c / cols) + offset, 0, (r - 1) * rowH, 0)
                vLine.BackgroundColor3 = pickColor(r + c)
                vLine.BackgroundTransparency = 0.88
                vLine.BorderSizePixel = 0
            end
        end
    elseif patternType == "Concentric" then
        local rings = 10
        for index = 1, rings do
            local ring = Instance.new("Frame", UI.GridPattern)
            ring.AnchorPoint = Vector2.new(0.5, 0.5)
            ring.Position = UDim2.new(0.5, 0, 0.5, 0)
            local scale = index / rings
            ring.Size = UDim2.new(scale, 0, scale, 0)
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            local stroke = Instance.new("UIStroke", ring)
            stroke.Color = pickColor(index)
            stroke.Thickness = 1
            stroke.Transparency = 0.88
            Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
        end
    elseif patternType == "Stars" then
        for index = 1, 60 do
            local dot = Instance.new("Frame", UI.GridPattern)
            local sz = math.random(1, 3)
            dot.Size = UDim2.fromOffset(sz, sz)
            dot.Position = UDim2.new(math.random(), 0, math.random(), 0)
            dot.BackgroundColor3 = pickColor(index)
            dot.BackgroundTransparency = math.random(30, 70) / 100
            dot.BorderSizePixel = 0
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        end
    elseif patternType == "Plus" then
        for xi = 1, 8 do
            for yi = 1, 6 do
                local plus = Instance.new("TextLabel", UI.GridPattern)
                plus.Size = UDim2.fromOffset(14, 14)
                plus.Position = UDim2.new(xi / 9, 0, yi / 7, 0)
                plus.BackgroundTransparency = 1
                plus.Text = "+"
                plus.TextColor3 = pickColor(xi + yi)
                plus.TextTransparency = 0.7
                plus.Font = Enum.Font.GothamBold
                plus.TextSize = 16
            end
        end
    elseif patternType == "Zigzag" then
        local rows, segments = 10, 14
        for r = 1, rows do
            local y = r / (rows + 1)
            for s = 1, segments do
                local seg = Instance.new("Frame", UI.GridPattern)
                seg.AnchorPoint = Vector2.new(0.5, 0.5)
                seg.Size = UDim2.new(0.1, 0, 0, 1)
                local x = s / (segments + 1)
                local dir = (s % 2 == 0) and 40 or -40
                seg.Position = UDim2.new(x, 0, y, 0)
                seg.Rotation = dir
                seg.BackgroundColor3 = pickColor(r + s)
                seg.BackgroundTransparency = 0.88
                seg.BorderSizePixel = 0
            end
        end
    elseif patternType == "Matrix" then
        for index = 1, 20 do
            local col = Instance.new("Frame", UI.GridPattern)
            col.Size = UDim2.new(0, 1, 1, 0)
            col.Position = UDim2.new(index / 21, 0, 0, 0)
            col.BackgroundColor3 = pickColor(index)
            col.BorderSizePixel = 0
            local grad = Instance.new("UIGradient", col)
            grad.Rotation = 90
            grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.85),
                NumberSequenceKeypoint.new(1, 1),
            })
        end
    elseif patternType == "Waves" then
        local waveCount = 4
        local points = 40
        for w = 1, waveCount do
            local baseY = w / (waveCount + 1)
            for p = 1, points do
                local seg = Instance.new("Frame", UI.GridPattern)
                seg.AnchorPoint = Vector2.new(0.5, 0.5)
                seg.Size = UDim2.new(0.04, 0, 0, 1)
                local x = p / (points + 1)
                local y = baseY + math.sin(x * math.pi * 6) * 0.04
                seg.Position = UDim2.new(x, 0, y, 0)
                seg.Rotation = math.cos(x * math.pi * 6) * 35
                seg.BackgroundColor3 = pickColor(w + p)
                seg.BackgroundTransparency = 0.88
                seg.BorderSizePixel = 0
            end
        end
    end
end

function Library:_updateFocusOverlay(theme)
    local UI = self._UI
    theme = theme or D.Themes[self.ThemeName] or D.Themes.Dark
    if not UI.FocusOverlay then return end

    UI.FocusOverlay.BackgroundColor3 = theme.FocusOverlayColor or theme.OverlayColor or self._Colors.Bg
    UI.FocusOverlay.BackgroundTransparency = self._STATE.FocusOverlayEnabled
        and (theme.OverlayTransparency or 0.45) or 1
    UI.FocusOverlay.Visible = self._STATE.FocusOverlayEnabled and self._STATE.GuiVisible

    self:_rebuildFocusPattern()
end

function Library:SetFocusOverlay(enabled, patternType)
    if self:_isDead() then return end
    if type(enabled) ~= "boolean" then
        error("[DoD UI] SetFocusOverlay expects a boolean enabled value.")
    end
    if patternType ~= nil and not table.find(D.FocusOverlayTypes, patternType) then
        error("[DoD UI] SetFocusOverlay received an unsupported pattern type.")
    end
    self._STATE.FocusOverlayEnabled = enabled
    if patternType ~= nil then
        self._STATE.FocusOverlayType = patternType
        self:_rebuildFocusPattern()
    end
    self:_updateFocusOverlay()
    self:_updateAcrylicBlur()
end

function Library:_updateAcrylicBlur()
    local blur = self._UI.GuiBlur
    if not blur then return end
    local state = self._STATE
    local blurSize = 0
    if state.GuiVisible then
        if self.Acrylic then blurSize = self.AcrylicBlurIntensity end
        if state.FocusOverlayEnabled then blurSize = math.max(blurSize, 12) end
    end
    blur.Size = blurSize
end

-- =========================================================
-- WEATHER ENGINE
-- =========================================================

function Library:SetWeather(enabled, weatherType, intensity)
    if self:_isDead() then return end
    if type(enabled) ~= "boolean" then
        error("[DoD UI] SetWeather expects a boolean enabled value.")
    end
    if weatherType ~= nil and not table.find(D.WeatherTypes, weatherType) then
        error("[DoD UI] SetWeather received an unsupported weather type.")
    end
    if intensity ~= nil and (type(intensity) ~= "number" or intensity < 0
        or intensity > 100 or intensity ~= intensity) then
        error("[DoD UI] Weather intensity must be a number between 0 and 100.")
    end
    local wasEnabled = self._STATE.WeatherEnabled
    local typeChanged = weatherType and weatherType ~= self._STATE.WeatherType
    self._STATE.WeatherEnabled = enabled
    if weatherType then self._STATE.WeatherType = weatherType end
    if intensity then self._STATE.WeatherIntensity = intensity end

    if enabled then
        if not wasEnabled or typeChanged or not self._STATE.SnowConnection then
            self:_createWeather(self._STATE.WeatherType)
        end
    else
        self:_stopWeather()
    end
end

function Library:_stopWeather()
    local STATE = self._STATE
    if STATE.SnowConnection then
        Fn.untrack(STATE.SnowConnection, self)
        STATE.SnowConnection = nil
    end
    for _, particle in ipairs(STATE.SnowParticles) do
        if particle.frame then particle.frame:Destroy() end
    end
    table.clear(STATE.SnowParticles)
    self._UI.SnowLayer.Visible = false
end

function Library:_createWeather(weatherType)
    self:_stopWeather()
    if not self._STATE.WeatherEnabled then return end

    local preset = WEATHER_PRESETS[weatherType]
    if not preset then return end

    local UI = self._UI
    local STATE = self._STATE

    UI.SnowLayer.Visible = STATE.GuiVisible
    local maxCount = math.max(1, math.floor(preset.count * 100 / 65 + 0.5))
    local colors = preset.colors or { preset.color or Color3.new(1, 1, 1) }

    for index = 1, maxCount do
        local size = randomFloat(preset.minSize, preset.maxSize)
        local frame = Instance.new("Frame", UI.SnowLayer)
        local baseTransparency = randomFloat(preset.transMin, preset.transMax) / 100
        local color = colors[math.random(1, #colors)]

        if preset.shape == "Aurora" then
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.Size = UDim2.new(size, 0, randomFloat(0.65, 1.1), 0)
            frame.Position = UDim2.fromScale(math.random(), randomFloat(0.35, 0.65))
            frame.BackgroundTransparency = baseTransparency
        elseif preset.shape == "Mist" then
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.Size = UDim2.fromOffset(size * 2.2, randomFloat(24, 54))
            frame.Position = UDim2.fromScale(math.random(), randomFloat(0.2, 0.9))
            frame.BackgroundTransparency = baseTransparency
        elseif preset.shape == "Line" then
            frame.Size = UDim2.fromOffset(size, size * 4)
            frame.BackgroundTransparency = baseTransparency
        elseif preset.shape == "Leaf" then
            frame.Size = UDim2.fromOffset(size * 1.5, size * 0.75)
            frame.BackgroundTransparency = baseTransparency
        else
            frame.Size = UDim2.fromOffset(size, size)
            frame.BackgroundTransparency = baseTransparency
        end

        if preset.shape ~= "Aurora" and preset.shape ~= "Mist" then
            frame.Position = UDim2.fromScale(math.random(), math.random())
        end
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.ZIndex = preset.zIndex + (math.random() < 0.35 and 1 or 0)

        if preset.shape == "Circle" or preset.shape == "Leaf" or preset.shape == "Glow" then
            Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
        end

        local gradient
        if preset.shape == "Mist" or preset.shape == "Aurora" then
            gradient = Instance.new("UIGradient", frame)
            gradient.Color = ColorSequence.new(color, colors[math.random(1, #colors)])
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.25, 0.35),
                NumberSequenceKeypoint.new(0.75, 0.35),
                NumberSequenceKeypoint.new(1, 1),
            })
            gradient.Rotation = preset.shape == "Aurora" and 90 or 0
        elseif preset.shape == "Glow" or weatherType == "Bubbles" then
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = color
            stroke.Thickness = 1
            stroke.Transparency = 0.35
        end

        local depth = randomFloat(0.65, 1.2)
        table.insert(STATE.SnowParticles, {
            frame = frame,
            x = frame.Position.X.Scale,
            y = frame.Position.Y.Scale,
            speed = randomFloat(preset.speedMin, preset.speedMax) / 100 * depth,
            drift = randomFloat(preset.driftMin, preset.driftMax) / 100 * depth,
            sway = (preset.sway or 0) * depth,
            phase = math.random() * math.pi * 2,
            frequency = randomFloat(0.7, 1.8),
            rotation = randomFloat(preset.rotationMin or 0, preset.rotationMax or 0),
            rotationSpeed = randomFloat(preset.rotationSpeedMin or 0, preset.rotationSpeedMax or 0),
            baseTransparency = baseTransparency,
            twinkle = preset.twinkle or false,
            twinkleSpeed = randomFloat(1.5, 4),
            color = color,
            gradient = gradient,
            index = index,
        })
    end

    STATE.WeatherClock = 0
    STATE.SnowConnection = Fn.track(RunService.RenderStepped, function(dt)
        if not STATE.WeatherEnabled then
            self:_stopWeather()
            return
        end
        UI.SnowLayer.Visible = STATE.GuiVisible
        if not STATE.GuiVisible then return end

        STATE.WeatherClock = STATE.WeatherClock + dt
        local currentIntensity = math.clamp(tonumber(STATE.WeatherIntensity) or 65, 0, 100)
        local activeCount = math.floor(#STATE.SnowParticles * currentIntensity / 100 + 0.5)
        local speedScale = 0.45 + currentIntensity / 100 * 0.9

        for _, particle in ipairs(STATE.SnowParticles) do
            local frame = particle.frame
            frame.Visible = particle.index <= activeCount
            if frame.Visible then
                particle.y = particle.y + particle.speed * speedScale * dt
                particle.x = particle.x + particle.drift * speedScale * dt

                if particle.speed > 0 then
                    if particle.y > 1.05 then particle.y = -0.05 end
                else
                    if particle.y < -0.05 then particle.y = 1.05 end
                end
                if particle.x > 1.05 then particle.x = -0.05 end
                if particle.x < -0.05 then particle.x = 1.05 end

                if particle.twinkle then
                    local pulse = (math.sin(STATE.WeatherClock * particle.twinkleSpeed + particle.phase) + 1) * 0.5
                    frame.BackgroundTransparency = math.clamp(particle.baseTransparency + (1 - pulse) * 0.24, 0, 0.98)
                end

                local swayOffset = math.sin(STATE.WeatherClock * particle.frequency + particle.phase) * particle.sway
                frame.Position = UDim2.fromScale(particle.x + swayOffset, particle.y)
                particle.rotation = particle.rotation + particle.rotationSpeed * dt
                frame.Rotation = particle.rotation
                if particle.gradient and weatherType == "Aurora" then
                    particle.gradient.Rotation = 75 + math.sin(STATE.WeatherClock * 0.22 + particle.phase) * 18
                end
            end
        end
    end, self)
end

-- =========================================================
-- MOBILE TOGGLE
-- =========================================================

function Library:_initMobileToggle()
    local UI = self._UI
    UI.MobileToggle = Instance.new("TextButton", UI.MainGui)
    UI.MobileToggle.Visible = UserInputService.TouchEnabled
    UI.MobileToggle.Text = "<i>Menu</i>"
    UI.MobileToggle.RichText = true
    UI.MobileToggle.Size = UDim2.new(0, 48, 0, 48)
    UI.MobileToggle.Position = UDim2.new(0, 16, 0.5, -24)
    UI.MobileToggle.BackgroundColor3 = self._Colors.Card
    UI.MobileToggle.TextColor3 = self._Colors.Text
    UI.MobileToggle.Font = Enum.Font.Gotham
    UI.MobileToggle.TextSize = 13
    UI.MobileToggle.AutoButtonColor = false
    UI.MobileToggle.BorderSizePixel = 0
    Instance.new("UICorner", UI.MobileToggle).CornerRadius = UDim.new(1, 0)

    UI.MobileToggleStroke = Instance.new("UIStroke", UI.MobileToggle)
    UI.MobileToggleStroke.Color = self._Colors.Accent
    UI.MobileToggleStroke.Thickness = 1.2
    UI.MobileToggleStroke.Transparency = 0.35

    Fn.bindPressAnimation(UI.MobileToggle)
    UI.MobileToggle.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

-- =========================================================
-- DRAG LOGIC
-- =========================================================

function Library:_initDrag()
    local UI = self._UI
    local dragging, dragStart, dragStartPos

    UI.TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            dragStartPos = UI.MainContainer.Position
        end
    end)

    Fn.track(UserInputService.InputChanged, function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local camera = getCam()
            if not camera then return end
            local vp = camera.ViewportSize
            local sz = UI.MainContainer.AbsoluteSize
            local delta = inp.Position - dragStart
            local scaleX = dragStartPos.X.Scale * vp.X
            local scaleY = dragStartPos.Y.Scale * vp.Y
            local absX = scaleX + dragStartPos.X.Offset + delta.X
            local absY = scaleY + dragStartPos.Y.Offset + delta.Y
            absX = math.clamp(absX, sz.X * 0.5 + 8, vp.X - sz.X * 0.5 - 8)
            absY = math.clamp(absY, sz.Y * 0.5 + 8, vp.Y - sz.Y * 0.5 - 8)
            UI.MainContainer.Position = UDim2.new(
                dragStartPos.X.Scale, absX - scaleX,
                dragStartPos.Y.Scale, absY - scaleY
            )
        end
    end, self)

    Fn.track(UserInputService.InputEnded, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end, self)
end

-- =========================================================
-- PUBLIC API: CREATE CATEGORY / TAB / SECTION
-- =========================================================

function Library:CreateCategory(categoryName, iconSpec)
    if self:_isDead() then return end
    if type(categoryName) ~= "string" or categoryName == "" then
        error("[DoD UI] CreateCategory requires a non-empty category name.")
    end
    if iconSpec ~= nil and type(iconSpec) ~= "string" then
        error("[DoD UI] CreateCategory iconSpec must be a string or nil.")
    end
    local UI = self._UI
    local STATE = self._STATE
    if STATE.CategoryButtons and STATE.CategoryButtons[categoryName] then
        error("[DoD UI] Category '" .. categoryName .. "' already exists.")
    end
    STATE.CategoryTabs[categoryName] = STATE.CategoryTabs[categoryName] or {}
    STATE.CategoryOrder = STATE.CategoryOrder or {}
    STATE.CategoryButtons = STATE.CategoryButtons or {}
    if not STATE.CategoryButtons[categoryName] then
        table.insert(STATE.CategoryOrder, categoryName)
    end

    if self.TabPosition == "Side" and UI.AccordionScroll then
        local group = Instance.new("Frame", UI.AccordionScroll)
        group.Name = "AccGroup_" .. categoryName
        group.LayoutOrder = #STATE.CategoryOrder
        group.Size = UDim2.new(1, 0, 0, 34)
        group.BackgroundTransparency = 1
        group.ClipsDescendants = true
        group.ZIndex = 5
        group.AutomaticSize = Enum.AutomaticSize.Y

        local groupLayout = Instance.new("UIListLayout", group)
        groupLayout.SortOrder = Enum.SortOrder.LayoutOrder
        groupLayout.Padding = UDim.new(0, 2)

        local header = Instance.new("TextButton", group)
        header.Name = "Header"
        header.LayoutOrder = 1
        header.Size = UDim2.new(1, 0, 0, 32)
        header.BackgroundColor3 = self._Colors.Card
        header.BackgroundTransparency = 0.75
        header.Text = ""
        header.AutoButtonColor = false
        header.ZIndex = 6
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

        local hStroke = Instance.new("UIStroke", header)
        hStroke.Color = self._Colors.Border
        hStroke.Thickness = 1
        hStroke.Transparency = 0.7

        local chevron = Instance.new("ImageLabel", header)
        chevron.Name = "Chevron"
        chevron.Size = UDim2.fromOffset(12, 12)
        chevron.Position = UDim2.new(0, 8, 0.5, -6)
        chevron.BackgroundTransparency = 1
        chevron.Image = GetIcon("chevron-down")
        chevron.ImageColor3 = self._Colors.TextDim
        chevron.ScaleType = Enum.ScaleType.Fit
        chevron.ZIndex = 7

        local iconImg = Instance.new("ImageLabel", header)
        iconImg.Size = UDim2.fromOffset(14, 14)
        iconImg.Position = UDim2.new(0, 26, 0.5, -7)
        iconImg.BackgroundTransparency = 1
        iconImg.ImageColor3 = self._Colors.TextDim
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 7
        if iconSpec then
            if string.sub(iconSpec, 1, 6) == "asset:" then
                iconImg.Image = "rbxassetid://" .. string.sub(iconSpec, 7)
            else
                iconImg.Image = GetIcon(iconSpec)
            end
        end

        local label = Instance.new("TextLabel", header)
        label.Size = UDim2.new(1, -48, 1, 0)
        label.Position = UDim2.new(0, 46, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = string.upper(categoryName)
        label.TextColor3 = self._Colors.TextDim
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 7

        local tabList = Instance.new("Frame", group)
        tabList.Name = "TabList"
        tabList.LayoutOrder = 2
        tabList.Size = UDim2.new(1, 0, 0, 0)
        tabList.BackgroundTransparency = 1
        tabList.ClipsDescendants = true
        tabList.Visible = false
        tabList.ZIndex = 5

        local tlLayout = Instance.new("UIListLayout", tabList)
        tlLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tlLayout.Padding = UDim.new(0, 3)

        local tlPad = Instance.new("UIPadding", tabList)
        tlPad.PaddingLeft = UDim.new(0, 20)
        tlPad.PaddingRight = UDim.new(0, 4)
        tlPad.PaddingTop = UDim.new(0, 4)
        tlPad.PaddingBottom = UDim.new(0, 6)

        STATE.CategoryButtons[categoryName] = {
            button = header,
            label = label,
            icon = iconImg,
            chevron = chevron,
            group = group,
            tabList = tabList,
            layout = tlLayout,
            stroke = hStroke,
            isAccordion = true,
        }

        header.MouseButton1Click:Connect(function()
            local current = STATE.AccordionExpanded[categoryName]
            local isActiveCat = (STATE.ActiveCategory == categoryName)
            
            if not current then
                local tabs = STATE.CategoryTabs[categoryName]
                local targetTab = nil
                if tabs and #tabs > 0 then
                    local savedIdx = STATE.ActiveSubIndices[categoryName]
                    targetTab = (savedIdx and tabs[savedIdx]) or tabs[1]
                end
                self:SetActiveCategory(categoryName, targetTab)
            elseif current and not isActiveCat then
                local tabs = STATE.CategoryTabs[categoryName]
                local targetTab = nil
                if tabs and #tabs > 0 then
                    local savedIdx = STATE.ActiveSubIndices[categoryName]
                    targetTab = (savedIdx and tabs[savedIdx]) or tabs[1]
                end
                self:SetActiveCategory(categoryName, targetTab)
            elseif current and isActiveCat then
                self:_setAccordionState(categoryName, false)
            end
        end)

        header.MouseEnter:Connect(function()
            TweenService:Create(hStroke, TweenInfo.new(0.15), {Transparency = 0.3, Color = self._Colors.Accent}):Play()
            TweenService:Create(header, TweenInfo.new(0.15), {BackgroundTransparency = 0.55}):Play()
        end)
        header.MouseLeave:Connect(function()
            local isActive = (self.TabPosition == "Side") and STATE.AccordionExpanded[categoryName] or (categoryName == STATE.ActiveCategory)
            TweenService:Create(hStroke, TweenInfo.new(0.15), {
                Transparency = isActive and 0.3 or 0.7,
                Color = isActive and self._Colors.Accent or self._Colors.Border,
            }):Play()
            TweenService:Create(header, TweenInfo.new(0.15), {BackgroundTransparency = isActive and 0.5 or 0.75}):Play()
        end)

        self:_registerThemeRefresher(function()
            if not header.Parent then return end
            header.BackgroundColor3 = self._Colors.Card
            local isActive = (self.TabPosition == "Side") and STATE.AccordionExpanded[categoryName] or (categoryName == STATE.ActiveCategory)
            hStroke.Color = isActive and self._Colors.Accent or self._Colors.Border
            label.TextColor3 = isActive and self._Colors.Text or self._Colors.TextDim
            iconImg.ImageColor3 = isActive and self._Colors.Accent or self._Colors.TextDim
            chevron.ImageColor3 = isActive and self._Colors.Accent or self._Colors.TextDim
        end)

        return header
    end

    local btn = Instance.new("TextButton", UI.CategoryBar)
    btn.Name = "CatBtn_" .. categoryName
    btn.Size = UDim2.new(0, 110, 0, 30)
    btn.BackgroundColor3 = self._Colors.Card
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Fn.bindPressAnimation(btn)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local iconImg = Instance.new("ImageLabel", btn)
    iconImg.Size = UDim2.new(0, 16, 0, 16)
    iconImg.Position = UDim2.new(0, 14, 0.5, -8)
    iconImg.BackgroundTransparency = 1
    iconImg.ImageColor3 = Color3.new(1, 1, 1)
    iconImg.ImageTransparency = 0.45
    iconImg.ScaleType = Enum.ScaleType.Fit
    if iconSpec then
        if string.sub(iconSpec, 1, 6) == "asset:" then
            iconImg.Image = "rbxassetid://" .. string.sub(iconSpec, 7)
        else
            iconImg.Image = GetIcon(iconSpec)
        end
    end

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1, -42, 1, 0)
    label.Position = UDim2.new(0, 36, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = categoryName
    label.TextColor3 = self._Colors.TextDim
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd

    btn.MouseButton1Click:Connect(function()
        self:SetActiveCategory(categoryName)
    end)

    STATE.CategoryButtons[categoryName] = { button = btn, label = label, icon = iconImg }
    self:_registerThemeRefresher(function()
        if not btn.Parent then return end
        btn.BackgroundColor3 = self._Colors.Card
        label.TextColor3 = categoryName == STATE.ActiveCategory
            and Color3.fromRGB(255, 255, 255) or self._Colors.TextDim
    end)

    self:_layoutCategoryButtons()
    return btn
end

function Library:_layoutCategoryButtons()
    local STATE = self._STATE
    local UI = self._UI
    if not STATE.CategoryButtons then return end
    if self.TabPosition == "Side" then return end
    local names = {}
    for _, name in ipairs(STATE.CategoryOrder or {}) do
        if STATE.CategoryButtons[name] then table.insert(names, name) end
    end
    if #names == 0 then
        if self.TabPosition == "Bottom" then
            UI.CategoryBar.Size = UDim2.new(1, -20, 0, 48)
            UI.CategoryBar.Position = UDim2.new(0, 10, 1, -58)
        end
        return
    end

    local gap, padding = 8, 8
    local availableWidth = UI.MainContainer.AbsoluteSize.X - 20
    if self.TabPosition == "Top" then
        availableWidth = UI.CategoryBar.AbsoluteSize.X
    end
    if availableWidth <= 0 then return end

    gap = math.min(gap, math.floor(availableWidth / math.max(#names * 2, 1)))
    padding = math.min(padding, math.floor((availableWidth - gap * math.max(#names - 1, 0)) / (#names * 2)))
    local gapsWidth = math.max(#names - 1, 0) * gap
    local buttonWidth = math.min(self.TabWidth, math.floor((availableWidth - padding * 2 - gapsWidth) / #names))
    buttonWidth = math.max(buttonWidth, 1)
    local dockWidth = math.min(availableWidth, #names * buttonWidth + gapsWidth + padding * 2)
    
    if self.TabPosition == "Bottom" then
        UI.CategoryBar.Size = UDim2.new(1, -20, 0, 56)
        UI.CategoryBar.Position = UDim2.new(0, 10, 1, -66)
    end

    local startX = padding
    if self.CategoryAlign == "Center" or self.TabPosition == "Bottom" then
        startX = math.floor((availableWidth - dockWidth) / 2) + padding
    elseif self.CategoryAlign == "Right" then
        startX = availableWidth - dockWidth + padding
    end
    for i, name in ipairs(names) do
        local data = STATE.CategoryButtons[name]
        data.button.Size = UDim2.new(0, buttonWidth, 0, self.TabPosition == "Bottom" and 36 or 30)
        data.button.Position = UDim2.new(0, startX + (i - 1) * (buttonWidth + gap), 0.5, self.TabPosition == "Bottom" and -18 or -15)
        data.label.Visible = buttonWidth >= 72
        data.icon.Position = UDim2.new(0, buttonWidth >= 72 and 10 or (buttonWidth - 16) / 2, 0.5, -8)
        data.label.Size = UDim2.new(1, -38, 1, 0)
    end

    if self.TabPosition == "Bottom" and UI.BottomPill then
        local activeData = STATE.CategoryButtons[STATE.ActiveCategory]
        if activeData and activeData.button then
            UI.BottomPill.Size = UDim2.new(0, buttonWidth, 0, 36)
            UI.BottomPill.Position = UDim2.new(0, activeData.button.Position.X.Offset, 0.5, -18)
        end
    end
end

function Library:SetActiveCategory(categoryName, preferredTab)
    if self:_isDead() then return end
    local STATE = self._STATE
    if not STATE.CategoryButtons or not STATE.CategoryButtons[categoryName] then return end
    if STATE.ActiveCategory == categoryName and STATE.SubTabBar then
        if preferredTab and STATE.ContentPages[preferredTab] then
            self:SwitchTab(preferredTab)
        end
        return
    end
    STATE.ActiveCategory = categoryName
    STATE.ActiveSubIndices = STATE.ActiveSubIndices or {}

    if self.TabPosition ~= "Side" then
        for name, data in pairs(STATE.CategoryButtons or {}) do
            local active = (name == categoryName)
            TweenService:Create(data.button, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                BackgroundTransparency = active and 0.55 or 1,
            }):Play()
            TweenService:Create(data.label, TweenInfo.new(0.22), {
                TextColor3 = active and Color3.fromRGB(255, 255, 255) or self._Colors.TextDim,
            }):Play()
            data.label.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
            TweenService:Create(data.icon, TweenInfo.new(0.22), {
                ImageTransparency = active and 0 or 0.45,
            }):Play()
        end
    end

    local tabs = STATE.CategoryTabs[categoryName]
    if not (tabs and #tabs > 0) then return end

    local targetIdx, targetName
    if preferredTab and STATE.ContentPages[preferredTab] then
        for idx, name in ipairs(tabs) do
            if name == preferredTab then
                targetIdx, targetName = idx, name
                break
            end
        end
    end
    if not targetName then
        local savedIdx = STATE.ActiveSubIndices[categoryName]
        if savedIdx and tabs[savedIdx] then
            targetIdx, targetName = savedIdx, tabs[savedIdx]
        else
            targetIdx, targetName = 1, tabs[1]
        end
    end

    if self.TabPosition == "Side" then
        if not STATE.AccordionExpanded[categoryName] then
            self:_setAccordionState(categoryName, true)
        end
        
        for _, catData in pairs(STATE.CategoryButtons) do
            if catData.isAccordion and catData.tabList then
                for _, otherSub in ipairs(catData.tabList:GetChildren()) do
                    if otherSub:IsA("TextButton") then
                        otherSub.BackgroundTransparency = 1
                        local lbl = otherSub:FindFirstChild("SubLabel")
                        if lbl then
                            lbl.TextColor3 = self._Colors.TextDim
                            lbl.Font = Enum.Font.GothamMedium
                        end
                        local ind = otherSub:FindFirstChild("AccentDot")
                        if ind then ind.Visible = false end
                    end
                end
            end
        end
        
        if targetName then
            STATE.ActiveSubIndices[categoryName] = targetIdx
            local catData = STATE.CategoryButtons[categoryName]
            if catData and catData.tabList then
                for _, child in ipairs(catData.tabList:GetChildren()) do
                    if child:IsA("TextButton") and child:GetAttribute("TabName") == targetName then
                        child.BackgroundTransparency = 0.4
                        local lbl = child:FindFirstChild("SubLabel")
                        if lbl then
                            lbl.TextColor3 = self._Colors.Text
                            lbl.Font = Enum.Font.GothamBold
                        end
                        local ind = child:FindFirstChild("AccentDot")
                        if ind then ind.Visible = true end
                        break
                    end
                end
            end
            if STATE.ContentPages[targetName] then
                self:SwitchTab(targetName)
            end
        end
        return
    end

    if STATE.SubTabBar and STATE.SubTabBar.Wrapper then
        local oldBar = STATE.SubTabBar
        local oldWrapper = oldBar.Wrapper
        oldBar.Wrapper = nil
        STATE.SubTabBar = nil
        if oldWrapper then
            for _, child in ipairs(oldWrapper:GetDescendants()) do
                if child:IsA("CanvasGroup") then
                    TweenService:Create(child, TweenInfo.new(0.15), {GroupTransparency = 1}):Play()
                elseif child:IsA("TextButton") or child:IsA("TextLabel") then
                    TweenService:Create(child, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
                end
            end
            task.delay(0.16, function()
                if oldWrapper and oldWrapper.Parent then oldWrapper:Destroy() end
            end)
        end
        oldBar:Destroy()
    end

    local suppress = false
    STATE.SubTabBar = SubTabModule.new({
        Parent = self._UI.Sidebar,
        Data = { [categoryName] = tabs },
        TabWidth = self.TabWidth, TabHeight = 28, Padding = 6,
        Theme = {
            PillBg = self._Colors.Card, LeftAccent = self._Colors.Accent,
            TextActive = Color3.fromRGB(255, 255, 255), TextInactive = self._Colors.TextDim,
            FontActive = Enum.Font.GothamBold, FontInactive = Enum.Font.GothamMedium,
        },
        Owner = self,
        OnChanged = function(_, subName)
            if suppress then return end
            for idx, name in ipairs(tabs) do
                if name == subName then
                    STATE.ActiveSubIndices[categoryName] = idx
                    break
                end
            end
            if STATE.ContentPages[subName] then
                self:SwitchTab(subName)
            end
        end,
    })
    self:_resizeSubTabs()
    suppress = true
    STATE.SubTabBar:SwitchCategory(categoryName)
    suppress = false

    if targetName then
        STATE.SubTabBar:SetActiveSub(categoryName, targetName)
        STATE.ActiveSubIndices[categoryName] = targetIdx
        if STATE.ContentPages[targetName] then
            self:SwitchTab(targetName)
        end
    end
end

function Library:SetTabBadge(categoryName, tabName, text, color)
    warn("[DoD UI] SetTabBadge is deprecated - badges removed in this version.")
    return
end

function Library:CreateTab(categoryName, tabName)
    if self:_isDead() then return end
    if type(tabName) ~= "string" or tabName == "" then
        error("[DoD UI] CreateTab requires a non-empty tab name.")
    end
    local UI = self._UI
    local STATE = self._STATE
    if not STATE.CategoryButtons or not STATE.CategoryButtons[categoryName] then
        error("[DoD UI] Category '" .. tostring(categoryName) .. "' belum dibuat. Panggil :CreateCategory dulu.")
    end
    if STATE.ContentPages[tabName] then
        error("[DoD UI] Tab '" .. tabName .. "' already exists.")
    end
    STATE.TabCategories[tabName] = categoryName
    STATE.CategoryTabs[categoryName] = STATE.CategoryTabs[categoryName] or {}
    table.insert(STATE.CategoryTabs[categoryName], tabName)

    local page = Instance.new("ScrollingFrame", UI.ContentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = self._Colors.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.VerticalScrollBarInset = Enum.ScrollBarInset.None
    page.HorizontalScrollBarInset = Enum.ScrollBarInset.None
    page.ElasticBehavior = Enum.ElasticBehavior.Never

    local pagePad = Instance.new("UIPadding", page)
    pagePad.PaddingTop = UDim.new(0, 6)
    pagePad.PaddingBottom = UDim.new(0, 12)
    pagePad.PaddingRight = UDim.new(0, 6)

    local pageList = Instance.new("UIListLayout", page)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, 10)

    -- Top container (full width) for banners
    local topContainer = Instance.new("Frame", page)
    topContainer.Name = "TopContainer"
    topContainer.LayoutOrder = 1
    topContainer.Size = UDim2.new(1, 0, 0, 0)
    topContainer.AutomaticSize = Enum.AutomaticSize.Y
    topContainer.BackgroundTransparency = 1
    local topLayout = Instance.new("UIListLayout", topContainer)
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.Padding = UDim.new(0, 10)

    -- Dual Columns Container
    local columnsContainer = Instance.new("Frame", page)
    columnsContainer.Name = "ColumnsContainer"
    columnsContainer.LayoutOrder = 2
    columnsContainer.Size = UDim2.new(1, 0, 0, 0)
    columnsContainer.BackgroundTransparency = 1
    columnsContainer.ClipsDescendants = false

    -- Left Column
    local leftCol = Instance.new("Frame", columnsContainer)
    leftCol.Name = "LeftColumn"
    leftCol.Size = UDim2.new(0.5, -5, 0, 0)
    leftCol.Position = UDim2.new(0, 0, 0, 0)
    leftCol.AutomaticSize = Enum.AutomaticSize.Y
    leftCol.BackgroundTransparency = 1
    leftCol.ClipsDescendants = false
    local leftLayout = Instance.new("UIListLayout", leftCol)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 10)

    -- Right Column
    local rightCol = Instance.new("Frame", columnsContainer)
    rightCol.Name = "RightColumn"
    rightCol.Size = UDim2.new(0.5, -5, 0, 0)
    rightCol.Position = UDim2.new(0.5, 5, 0, 0)
    rightCol.AutomaticSize = Enum.AutomaticSize.Y
    rightCol.BackgroundTransparency = 1
    rightCol.ClipsDescendants = false
    local rightLayout = Instance.new("UIListLayout", rightCol)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Padding = UDim.new(0, 10)

    -- Auto-scale height for columns container
    local function updateColumnsSize()
        local leftSize = leftLayout.AbsoluteContentSize.Y
        local rightSize = rightLayout.AbsoluteContentSize.Y
        local maxH = math.max(leftSize, rightSize)
        columnsContainer.Size = UDim2.new(1, 0, 0, maxH)
    end
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateColumnsSize)
    rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateColumnsSize)

    -- Save references
    STATE.ContentPages[tabName] = page
    STATE.TabTopContainers[tabName] = topContainer
    STATE.TabColumns[tabName] = { Left = leftCol, Right = rightCol, Container = columnsContainer }

    self:_registerThemeRefresher(function()
        if page.Parent then
            page.ScrollBarImageColor3 = self._Colors.Accent
        end
    end)
    page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if STATE.ActiveTab == tabName then
            STATE.SavedScrollPositions[tabName] = page.CanvasPosition
        end
    end)

    if self.TabPosition == "Side" then
        local catData = STATE.CategoryButtons[categoryName]
        if catData and catData.tabList then
            local tabCount = 0
            for _, c in ipairs(catData.tabList:GetChildren()) do
                if c:IsA("TextButton") then tabCount = tabCount + 1 end
            end
            local subBtn = Instance.new("TextButton", catData.tabList)
            subBtn.Name = "SubTab_" .. tabName
            subBtn.LayoutOrder = tabCount + 1
            subBtn.Size = UDim2.new(1, 0, 0, 26)
            subBtn.BackgroundColor3 = self._Colors.Card
            subBtn.BackgroundTransparency = 1
            subBtn.Text = ""
            subBtn.AutoButtonColor = false
            subBtn.ZIndex = 6
            subBtn:SetAttribute("TabName", tabName)
            Instance.new("UICorner", subBtn).CornerRadius = UDim.new(0, 6)

            local accentDot = Instance.new("Frame", subBtn)
            accentDot.Name = "AccentDot"
            accentDot.Size = UDim2.fromOffset(3, 12)
            accentDot.Position = UDim2.new(0, 2, 0.5, -6)
            accentDot.BackgroundColor3 = self._Colors.Accent
            accentDot.BorderSizePixel = 0
            accentDot.Visible = false
            accentDot.ZIndex = 7
            Instance.new("UICorner", accentDot).CornerRadius = UDim.new(1, 0)

            local subLabel = Instance.new("TextLabel", subBtn)
            subLabel.Name = "SubLabel"
            subLabel.Size = UDim2.new(1, -16, 1, 0)
            subLabel.Position = UDim2.new(0, 12, 0, 0)
            subLabel.BackgroundTransparency = 1
            subLabel.Text = tabName
            subLabel.TextColor3 = self._Colors.TextDim
            subLabel.Font = Enum.Font.GothamMedium
            subLabel.TextSize = 11
            subLabel.TextXAlignment = Enum.TextXAlignment.Left
            subLabel.TextTruncate = Enum.TextTruncate.AtEnd
            subLabel.ZIndex = 7

            subBtn.MouseEnter:Connect(function()
                if STATE.ActiveTab ~= tabName then
                    TweenService:Create(subBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
                    TweenService:Create(subLabel, TweenInfo.new(0.15), {TextColor3 = self._Colors.Text}):Play()
                end
            end)
            subBtn.MouseLeave:Connect(function()
                if STATE.ActiveTab ~= tabName then
                    TweenService:Create(subBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(subLabel, TweenInfo.new(0.15), {TextColor3 = self._Colors.TextDim}):Play()
                end
            end)

            subBtn.MouseButton1Click:Connect(function()
                self:SetActiveCategory(categoryName, tabName)
            end)

            self:_registerThemeRefresher(function()
                if not subBtn.Parent then return end
                subBtn.BackgroundColor3 = self._Colors.Card
                subLabel.TextColor3 = STATE.ActiveTab == tabName and self._Colors.Text or self._Colors.TextDim
                accentDot.BackgroundColor3 = self._Colors.Accent
            end)
        end
    end

    if STATE.ActiveCategory == nil or STATE.ActiveCategory == categoryName then
        self:SetActiveCategory(categoryName)
    end
    return page
end

function Library:SwitchTab(tabName)
    if self:_isDead() then return end
    local STATE = self._STATE
    local page = STATE.ContentPages[tabName]
    if not page then return end

    local ownerCat = STATE.TabCategories[tabName]
    if ownerCat and STATE.ActiveCategory ~= ownerCat then
        self:SetActiveCategory(ownerCat, tabName)
        return
    end

    if STATE.ActiveTab == tabName and page.Visible then
        return
    end

    self:PlaySound("TabSwitch")

    for _, p in pairs(STATE.ContentPages) do
        if p ~= page then p.Visible = false end
    end
    page.Visible = true
    STATE.ActiveTab = tabName

    local scale = page:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale", page)
    end
    scale.Scale = 0.94
    page.Position = UDim2.new(0, 25, 0, 0)
    page.BackgroundTransparency = 1

    TweenService:Create(scale,
        TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
    TweenService:Create(page,
        TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()

    local saved = STATE.SavedScrollPositions[tabName]
    if saved then
        task.defer(function()
            for _ = 1, 3 do
                task.wait(0.05)
                if page.Parent then page.CanvasPosition = saved end
            end
        end)
    end

    self:_applySearchFilter(tabName)
    if STATE.SubTabBar and ownerCat then
        pcall(function() STATE.SubTabBar:SetActiveSub(ownerCat, tabName) end)
    end
end

function Library:CreateSection(tabName, title, summary, defaultOpen, columnName)
    if self:_isDead() then return end
    if type(title) ~= "string" or title == "" then
        error("[DoD UI] CreateSection requires a non-empty title.")
    end
    if summary ~= nil and type(summary) ~= "string" then
        error("[DoD UI] CreateSection summary must be a string or nil.")
    end
    if columnName ~= nil and columnName ~= "Left" and columnName ~= "Right" then
        error("[DoD UI] CreateSection column must be 'Left' or 'Right'.")
    end
    columnName = columnName or "Left"

    local columns = self._STATE.TabColumns[tabName]
    if not columns then
        error("[DoD UI] Tab '" .. tostring(tabName) .. "' not found. Call :CreateTab first.")
    end
    local parentCol = columns[columnName]

    local sectionOrder = #parentCol:GetChildren() + 1
    local HEADER_HEIGHT = 50

    local section = Instance.new("Frame", parentCol)
    section.Name = (title:gsub("%W", "") or "") .. "Section"
    section.LayoutOrder = sectionOrder
    section.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    section.BackgroundColor3 = self._Colors.Card
    section.BackgroundTransparency = 0.15
    section.BorderSizePixel = 0
    section.ClipsDescendants = true
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 12) -- Softer corners

    local cardStroke = Instance.new("UIStroke", section)
    cardStroke.Color = self._Colors.Border
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.4

    local header = Instance.new("TextButton", section)
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    Fn.bindPressAnimation(header)

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -50, 0, 18)
    titleLabel.Position = UDim2.new(0, 16, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self._Colors.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local summaryLabel = Instance.new("TextLabel", header)
    summaryLabel.Size = UDim2.new(1, -50, 0, 14)
    summaryLabel.Position = UDim2.new(0, 16, 0, 28)
    summaryLabel.BackgroundTransparency = 1
    summaryLabel.Text = summary or ""
    summaryLabel.TextColor3 = self._Colors.TextDim
    summaryLabel.Font = Enum.Font.GothamMedium
    summaryLabel.TextSize = 10
    summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
    summaryLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local indicator = Instance.new("ImageLabel", header)
    indicator.Name = "ExpandIndicator"
    indicator.Size = UDim2.fromOffset(16, 16)
    indicator.AnchorPoint = Vector2.new(0.5, 0.5)
    indicator.Position = UDim2.new(1, -26, 0.5, 0)
    indicator.BackgroundTransparency = 1
    indicator.Image = GetIcon(defaultOpen and "arrow-up" or "arrow-down")
    indicator.ImageColor3 = defaultOpen and self._Colors.Accent or self._Colors.TextDim
    indicator.ScaleType = Enum.ScaleType.Fit

    local hoverBar = Instance.new("Frame", header)
    hoverBar.Name = "HoverBar"
    hoverBar.Size = UDim2.new(0, 0, 0, 22)
    hoverBar.Position = UDim2.new(0, 0, 0.5, -11)
    hoverBar.BackgroundColor3 = self._Colors.Accent
    hoverBar.BorderSizePixel = 0
    hoverBar.ZIndex = 5
    Instance.new("UICorner", hoverBar).CornerRadius = UDim.new(1, 0)

    local separator = Instance.new("Frame", section)
    separator.Size = UDim2.new(1, -32, 0, 1)
    separator.Position = UDim2.new(0, 16, 0, HEADER_HEIGHT)
    separator.BackgroundColor3 = self._Colors.Border
    separator.BackgroundTransparency = 1
    separator.BorderSizePixel = 0

    local body = Instance.new("Frame", section)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = false
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = false

    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding = UDim.new(0, 8)

    local bodyPad = Instance.new("UIPadding", body)
    bodyPad.PaddingLeft = UDim.new(0, 12)
    bodyPad.PaddingRight = UDim.new(0, 12)
    bodyPad.PaddingTop = UDim.new(0, 10)
    bodyPad.PaddingBottom = UDim.new(0, 14)

    local expanded = defaultOpen == true
    local currentTween
    local sectionData = {
        tabName = tabName,
        title = title,
        summary = summary or "",
        section = section,
        controls = {},
        expanded = expanded,
        searching = false,
    }
    self._STATE.SearchSections[tabName] = self._STATE.SearchSections[tabName] or {}
    table.insert(self._STATE.SearchSections[tabName], sectionData)
    self._STATE.SearchBodies[body] = sectionData

    local function updateHeight(animate)
        local innerH = bodyLayout.AbsoluteContentSize.Y
        local contentH = (innerH > 0) and (innerH + 24) or 24
        local targetH = expanded and (HEADER_HEIGHT + contentH) or HEADER_HEIGHT
        if currentTween then currentTween:Cancel() end
        if animate == false then
            section.Size = UDim2.new(1, 0, 0, targetH)
        else
            currentTween = TweenService:Create(section,
                TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 0, targetH)})
            currentTween:Play()
            if not expanded then
                local cap = currentTween
                cap.Completed:Connect(function()
                    if not expanded and body then body.Visible = false end
                end)
            end
        end
        TweenService:Create(separator, TweenInfo.new(0.2), {
            BackgroundTransparency = expanded and 0.6 or 1
        }):Play()
        indicator.Image = GetIcon(expanded and "arrow-up" or "arrow-down")
        TweenService:Create(indicator,
            TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageColor3 = expanded and self._Colors.Accent or self._Colors.TextDim,
            }):Play()
    end

    local function toggle(forceState)
        if forceState ~= nil then expanded = forceState
        else expanded = not expanded end
        sectionData.expanded = expanded
        if expanded then
            body.Visible = true
            task.defer(function() updateHeight(true) end)
        else
            updateHeight(true)
        end
    end

    sectionData.setExpanded = function(isExpanded)
        expanded = isExpanded
        sectionData.expanded = expanded
        body.Visible = expanded
        if expanded then
            task.defer(function() updateHeight(false) end)
        else
            updateHeight(false)
        end
    end

    bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded then updateHeight(true) end
    end)

    header.MouseEnter:Connect(function()
        TweenService:Create(section, TweenInfo.new(0.18),
            {BackgroundColor3 = self._Colors.CardHover, BackgroundTransparency = 0.05}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18),
            {Transparency = 0, Color = self._Colors.Accent, Thickness = 1.2}):Play()
        TweenService:Create(hoverBar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 3, 0, 22)}):Play()
        if not expanded then
            TweenService:Create(indicator, TweenInfo.new(0.18),
                {TextColor3 = self._Colors.Accent}):Play()
        end
    end)
    header.MouseLeave:Connect(function()
        TweenService:Create(section, TweenInfo.new(0.18),
            {BackgroundColor3 = self._Colors.Card, BackgroundTransparency = 0.15}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18),
            {Transparency = 0.4, Color = self._Colors.Border, Thickness = 1}):Play()
        TweenService:Create(hoverBar, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 22)}):Play()
        if not expanded then
            TweenService:Create(indicator, TweenInfo.new(0.18),
                {TextColor3 = self._Colors.TextDim}):Play()
        end
    end)

    local lastToggleTime = 0
    header.MouseButton1Up:Connect(function()
        local now = tick()
        if now - lastToggleTime < 0.18 then return end
        lastToggleTime = now
        toggle()
    end)

    if expanded then
        body.Visible = true
        task.spawn(function()
            task.wait(0.08)
            updateHeight(false)
        end)
    end

    self:_registerThemeRefresher(function()
        section.BackgroundColor3 = self._Colors.Card
        cardStroke.Color = self._Colors.Border
        titleLabel.TextColor3 = self._Colors.Text
        summaryLabel.TextColor3 = self._Colors.TextDim
        indicator.Image = GetIcon(expanded and "arrow-up" or "arrow-down")
        indicator.ImageColor3 = expanded and self._Colors.Accent or self._Colors.TextDim
        separator.BackgroundColor3 = self._Colors.Border
    end)

    self:_applySearchFilter(tabName)
    return body
end

-- Helper for backwards compatibility
function Library:CreateColumnSection(tabName, title, summary, defaultOpen)
    if self:_isDead() then return end
    local body = self:CreateSection(tabName, title, summary, defaultOpen)
    local row = Instance.new("Frame", body)
    row.Name = "Columns"
    row.LayoutOrder = 1
    row.Size = UDim2.new(1, 0, 0, 0)
    row.BackgroundTransparency = 1
    row.AutomaticSize = Enum.AutomaticSize.Y

    local function createColumn(name, xPosition)
        local column = Instance.new("Frame", row)
        column.Name = name
        column.Size = UDim2.new(0.5, -6, 0, 0)
        column.Position = UDim2.new(xPosition, xPosition == 0 and 0 or 6, 0, 0)
        column.BackgroundTransparency = 1
        column.AutomaticSize = Enum.AutomaticSize.Y
        local layout = Instance.new("UIListLayout", column)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        local padding = Instance.new("UIPadding", column)
        padding.PaddingLeft = UDim.new(0, 4)
        padding.PaddingRight = UDim.new(0, 4)
        padding.PaddingTop = UDim.new(0, 1)
        padding.PaddingBottom = UDim.new(0, 1)
        return column
    end

    local leftColumn = createColumn("LeftColumn", 0)
    local rightColumn = createColumn("RightColumn", 0.5)
    return leftColumn, rightColumn
end

function Library:CreateDashboardBanner(tabName)
    if self:_isDead() then return end
    local topContainer = self._STATE.TabTopContainers[tabName]
    if not topContainer then
        error("[DoD UI] Tab '" .. tostring(tabName) .. "' not found. Call :CreateTab first.")
    end

    local function GetGreeting()
        local h = tonumber(os.date("%H")) or 12
        if h >= 5 and h < 12 then return "Good Morning"
        elseif h >= 12 and h < 17 then return "Good Afternoon"
        elseif h >= 17 and h < 20 then return "Good Evening"
        else return "Good Night" end
    end

    local PlayerCard = Instance.new("Frame", topContainer)
    PlayerCard.Name = "PlayerGreetingCard"
    PlayerCard.LayoutOrder = #topContainer:GetChildren() + 1
    PlayerCard.Size = UDim2.new(1, 0, 0, 68)
    PlayerCard.BackgroundColor3 = self._Colors.Card
    PlayerCard.BorderSizePixel = 0
    Instance.new("UICorner", PlayerCard).CornerRadius = UDim.new(0, 12)
    local pcStroke = Instance.new("UIStroke", PlayerCard)
    pcStroke.Color = self._Colors.Border
    pcStroke.Thickness = 1

    local AvatarImg = Instance.new("ImageLabel", PlayerCard)
    AvatarImg.Size = UDim2.new(0, 46, 0, 46)
    AvatarImg.Position = UDim2.new(0, 12, 0.5, -23)
    AvatarImg.BackgroundTransparency = 1
    AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150&filters=circular"
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke", AvatarImg)
    avStroke.Color = self._Colors.Border
    avStroke.Thickness = 1

    local GreetLabel = Instance.new("TextLabel", PlayerCard)
    GreetLabel.Size = UDim2.new(0.5, -70, 0, 14)
    GreetLabel.Position = UDim2.new(0, 68, 0, 14)
    GreetLabel.BackgroundTransparency = 1
    GreetLabel.Font = Enum.Font.GothamMedium
    GreetLabel.TextSize = 10.5
    GreetLabel.TextColor3 = self._Colors.TextDim
    GreetLabel.TextXAlignment = Enum.TextXAlignment.Left
    GreetLabel.Text = GetGreeting()

    local NameLabel = Instance.new("TextLabel", PlayerCard)
    NameLabel.Size = UDim2.new(0.5, -70, 0, 22)
    NameLabel.Position = UDim2.new(0, 68, 0, 30)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 16
    NameLabel.TextColor3 = self._Colors.Text
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Text = LocalPlayer.DisplayName or LocalPlayer.Name

    local ClockLabel = Instance.new("TextLabel", PlayerCard)
    ClockLabel.Size = UDim2.new(0.5, 0, 0, 24)
    ClockLabel.Position = UDim2.new(0.5, -16, 0, 11)
    ClockLabel.BackgroundTransparency = 1
    ClockLabel.Font = Enum.Font.GothamBold
    ClockLabel.TextSize = 20
    ClockLabel.TextColor3 = self._Colors.Text
    ClockLabel.TextXAlignment = Enum.TextXAlignment.Right
    ClockLabel.Text = os.date("%H:%M:%S")

    local DateLabel = Instance.new("TextLabel", PlayerCard)
    DateLabel.Size = UDim2.new(0.45, 0, 0, 14)
    DateLabel.Position = UDim2.new(0.55, -16, 0, 38)
    DateLabel.BackgroundTransparency = 1
    DateLabel.Font = Enum.Font.GothamMedium
    DateLabel.TextSize = 10.5
    DateLabel.TextColor3 = self._Colors.TextDim
    DateLabel.TextXAlignment = Enum.TextXAlignment.Right
    DateLabel.Text = os.date("%d / %m / %Y")

    local placeName = "Roblox Experience"
    local creatorName = "Roblox Studio"
    local resolvedGameIcon = ""
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info then
            if info.Name and info.Name ~= "" then placeName = info.Name end
            if info.Creator and info.Creator.Name and info.Creator.Name ~= "" then creatorName = info.Creator.Name end
            if info.IconImageAssetId and tonumber(info.IconImageAssetId) and tonumber(info.IconImageAssetId) > 0 then
                resolvedGameIcon = "rbxassetid://" .. tostring(info.IconImageAssetId)
            end
        end
    end)
    if resolvedGameIcon == "" then
        local universeId = (game.GameId and tonumber(game.GameId) and tonumber(game.GameId) > 0) and game.GameId or nil
        if universeId then
            resolvedGameIcon = "rbxthumb://type=GameIcon&id=" .. tostring(universeId) .. "&w=150&h=150"
        else
            resolvedGameIcon = "rbxthumb://type=Asset&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
        end
    end

    local GameCard = Instance.new("Frame", topContainer)
    GameCard.Name = "GameServerCard"
    GameCard.LayoutOrder = #topContainer:GetChildren() + 1
    GameCard.Size = UDim2.new(1, 0, 0, 86)
    GameCard.BackgroundColor3 = self._Colors.Card
    GameCard.BorderSizePixel = 0
    Instance.new("UICorner", GameCard).CornerRadius = UDim.new(0, 14)
    local gcStroke = Instance.new("UIStroke", GameCard)
    gcStroke.Color = self._Colors.Border
    gcStroke.Thickness = 1

    local BannerImg = Instance.new("ImageLabel", GameCard)
    BannerImg.Name = "MapBanner"
    BannerImg.AnchorPoint = Vector2.new(1, 0)
    BannerImg.Position = UDim2.new(1, 0, 0, 0)
    BannerImg.Size = UDim2.new(0.65, 0, 1, 0)
    BannerImg.BackgroundTransparency = 1
    BannerImg.ScaleType = Enum.ScaleType.Crop
    BannerImg.Image = resolvedGameIcon
    BannerImg.ImageTransparency = 0.70
    BannerImg.ZIndex = 1
    Instance.new("UICorner", BannerImg).CornerRadius = UDim.new(0, 14)

    local bGrad = Instance.new("UIGradient", BannerImg)
    bGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 0.82),
        NumberSequenceKeypoint.new(1, 0.35)
    })

    local GameThumb = Instance.new("ImageLabel", GameCard)
    GameThumb.Size = UDim2.new(0, 60, 0, 60)
    GameThumb.Position = UDim2.new(0, 12, 0.5, -30)
    GameThumb.BackgroundColor3 = self._Colors.Bg2
    GameThumb.BackgroundTransparency = 0.1
    GameThumb.ScaleType = Enum.ScaleType.Fit
    GameThumb.Image = resolvedGameIcon
    GameThumb.ZIndex = 3
    Instance.new("UICorner", GameThumb).CornerRadius = UDim.new(0, 14)
    local gtStroke = Instance.new("UIStroke", GameThumb)
    gtStroke.Color = self._Colors.Border
    gtStroke.Thickness = 1

    local GameTitleLbl = Instance.new("TextLabel", GameCard)
    GameTitleLbl.Size = UDim2.new(1, -90, 0, 18)
    GameTitleLbl.Position = UDim2.new(0, 84, 0, 12)
    GameTitleLbl.BackgroundTransparency = 1
    GameTitleLbl.Font = Enum.Font.GothamBold
    GameTitleLbl.TextSize = 14
    GameTitleLbl.TextColor3 = self._Colors.Text
    GameTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    GameTitleLbl.Text = placeName
    GameTitleLbl.ZIndex = 3

    local GameSubLbl = Instance.new("TextLabel", GameCard)
    GameSubLbl.Size = UDim2.new(1, -90, 0, 14)
    GameSubLbl.Position = UDim2.new(0, 84, 0, 32)
    GameSubLbl.BackgroundTransparency = 1
    GameSubLbl.Font = Enum.Font.Gotham
    GameSubLbl.TextSize = 9.5
    GameSubLbl.TextColor3 = self._Colors.TextDim
    GameSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    GameSubLbl.Text = "by " .. ((creatorName and creatorName ~= "") and creatorName or "Roblox Creator")
    GameSubLbl.ZIndex = 3

    local PillsRow = Instance.new("Frame", GameCard)
    PillsRow.Size = UDim2.new(1, -90, 0, 22)
    PillsRow.Position = UDim2.new(0, 84, 0, 52)
    PillsRow.BackgroundTransparency = 1
    PillsRow.ZIndex = 3

    local prLayout = Instance.new("UIListLayout", PillsRow)
    prLayout.FillDirection = Enum.FillDirection.Horizontal
    prLayout.Padding = UDim.new(0, 6)

    local function MakePill(text, minW, col)
        local p = Instance.new("Frame", PillsRow)
        p.AutomaticSize = Enum.AutomaticSize.X
        p.Size = UDim2.new(0, minW or 60, 0, 20)
        p.BackgroundColor3 = self._Colors.Bg2
        p.BackgroundTransparency = 0.2
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
        local ps = Instance.new("UIStroke", p)
        ps.Color = self._Colors.Border
        ps.Thickness = 0.8

        local t = Instance.new("TextLabel", p)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 1, 0)
        t.Position = UDim2.new(0, 8, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold
        t.TextSize = 8.5
        t.TextColor3 = col or self._Colors.TextDim
        t.Text = text
        local pad = Instance.new("UIPadding", p)
        pad.PaddingRight = UDim.new(0, 8)
        return { Frame = p, Stroke = ps, Label = t }
    end

    local pillId = MakePill("ID " .. tostring(game.PlaceId), 90, self._Colors.TextDim)
    local pillPl = MakePill("Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers), 70, self._Colors.TextDim)
    local pillPing = MakePill("Ping 35 ms", 60, self._Colors.Accent)

    task.spawn(function()
        while task.wait(0.25) do
            if not PlayerCard or not PlayerCard.Parent then break end
            ClockLabel.Text = os.date("%H:%M:%S")
            DateLabel.Text = os.date("%d / %m / %Y")
            GreetLabel.Text = GetGreeting()
            pillPl.Label.Text = "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            pcall(function()
                local p = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                pillPing.Label.Text = "Ping " .. tostring(p) .. " ms"
            end)
        end
    end)

    self:_registerThemeRefresher(function()
        PlayerCard.BackgroundColor3 = self._Colors.Card
        pcStroke.Color = self._Colors.Border
        avStroke.Color = self._Colors.Border
        GreetLabel.TextColor3 = self._Colors.TextDim
        NameLabel.TextColor3 = self._Colors.Text
        ClockLabel.TextColor3 = self._Colors.Text
        DateLabel.TextColor3 = self._Colors.TextDim
        GameCard.BackgroundColor3 = self._Colors.Card
        gcStroke.Color = self._Colors.Border
        GameThumb.BackgroundColor3 = self._Colors.Bg2
        gtStroke.Color = self._Colors.Border
        GameTitleLbl.TextColor3 = self._Colors.Text
        GameSubLbl.TextColor3 = self._Colors.TextDim
        for _, pill in ipairs({pillId, pillPl, pillPing}) do
            pill.Frame.BackgroundColor3 = self._Colors.Bg2
            pill.Stroke.Color = self._Colors.Border
            if pill == pillPing then
                pill.Label.TextColor3 = self._Colors.Accent
            else
                pill.Label.TextColor3 = self._Colors.TextDim
            end
        end
    end)

    return GameCard
end

function Library:CreateThemeCustomizer(tabName)
    if self:_isDead() then return end
    local section = self:CreateSection(
        tabName,
        "Theme Customizer",
        "Adjust appearance and effects live",
        true
    )
    local themeIndex = table.find(D.ThemeNames, self.ThemeName) or 1
    self:AddDropdown(section, "Theme", D.ThemeNames, themeIndex, function(_, themeName)
        self._AccentOverride = nil
        self:SetTheme(themeName)
    end)
    self:AddColorPicker(section, "Accent color", self._Colors.Accent, function(color)
        self:SetAccentColor(color)
    end)
    self:AddDropdown(section, "Focus overlay pattern", D.FocusOverlayTypes,
        math.max(1, table.find(D.FocusOverlayTypes, self._STATE.FocusOverlayType) or 2),
        function(_, overlayType)
            self:SetFocusOverlay(self._STATE.FocusOverlayEnabled, overlayType)
        end
    )
    self:AddToggle(section, "Focus overlay", self._STATE.FocusOverlayEnabled, function(enabled)
        self:SetFocusOverlay(enabled, self._STATE.FocusOverlayType)
    end)
    self:AddToggle(section, "Acrylic blur", self.Acrylic, function(enabled)
        self:SetAcrylic(enabled)
    end)
    self:AddSlider(section, "Blur intensity", 0, 24, self.AcrylicBlurIntensity, 0, function(value)
        self:SetAcrylicIntensity(value)
    end)
    self:AddDropdown(section, "Weather effect", D.WeatherTypes,
        table.find(D.WeatherTypes, self._STATE.WeatherType) or 1,
        function(_, weatherType)
            self._STATE.WeatherType = weatherType
            if self._STATE.WeatherEnabled then
                self:SetWeather(true, weatherType, self._STATE.WeatherIntensity)
            end
        end
    )
    local weatherIntensity = math.clamp(tonumber(self._STATE.WeatherIntensity) or 65, 0, 100)
    self:AddSlider(section, "Weather intensity", 0, 100, weatherIntensity, 0, function(value)
        self:SetWeather(self._STATE.WeatherEnabled, self._STATE.WeatherType, value)
    end)
    self:AddToggle(section, "Weather effects", self._STATE.WeatherEnabled, function(enabled)
        self:SetWeather(enabled, self._STATE.WeatherType, self._STATE.WeatherIntensity)
    end)
    return section
end

-- =========================================================
-- CONTROLS
-- =========================================================

function Library:AddToggle(page, text, default, callback)
    if self:_isDead() then return end
    if default ~= nil and type(default) ~= "boolean" then
        error("[DoD UI] AddToggle default must be a boolean.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddToggle callback must be a function.")
    end
    callback = callback or function() end
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    holder.Active = true
    Fn.bindPressAnimation(holder)
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lab = Instance.new("TextLabel", holder)
    lab.Size = UDim2.new(1, -104, 1, 0)
    lab.Position = UDim2.new(0, 12, 0, 0)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = self._Colors.Text
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 12
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.TextTruncate = Enum.TextTruncate.AtEnd

    local switchBg = Instance.new("Frame", holder)
    switchBg.Size = UDim2.new(0, 36, 0, 20)
    switchBg.Position = UDim2.new(1, -50, 0.5, -10)
    switchBg.BackgroundColor3 = default and self._Colors.Accent or Color3.fromRGB(45, 45, 55)
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local switchStroke = Instance.new("UIStroke", switchBg)
    switchStroke.Color = default and self._Colors.Accent or self._Colors.Border
    switchStroke.Thickness = 1

    local knob = Instance.new("Frame", switchBg)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default

    local function updateVisual(animate)
        local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if animate then
            TweenService:Create(switchBg, tInfo, {BackgroundColor3 = state and self._Colors.Accent or Color3.fromRGB(45, 45, 55)}):Play()
            TweenService:Create(switchStroke, tInfo, {Color = state and self._Colors.Accent or self._Colors.Border}):Play()
            TweenService:Create(knob, tInfo, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        else
            switchBg.BackgroundColor3 = state and self._Colors.Accent or Color3.fromRGB(45, 45, 55)
            switchStroke.Color = state and self._Colors.Accent or self._Colors.Border
            knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        end
    end

    local lastToggle = 0
    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            local now = tick()
            if now - lastToggle < 0.15 then return end
            lastToggle = now
            state = not state
            self:PlaySound(state and "ToggleOn" or "ToggleOff")
            updateVisual(true)
            callback(state)
            self:_triggerAutoSave()
        end
    end)

    self:_registerConfigState(self:_getConfigId("toggle", text),
        function() return state end,
        function(v, silent)
            if type(v) ~= "boolean" then return end
            if state == v then return end
            state = v
            updateVisual(false)
            if not silent then
                callback(state)
                self:_triggerAutoSave()
            end
        end
    )

    holder.MouseEnter:Connect(function()
        if not state then
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = self._Colors.Accent:Lerp(Color3.new(1,1,1), 0.15)}):Play()
        end
    end)
    
    holder.MouseLeave:Connect(function()
        updateVisual(true)
    end)

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        lab.TextColor3 = self._Colors.Text
        updateVisual(false)
    end)
    self:_bindTooltip(holder, text)
    return self:_registerSearchControl(holder, text)
end

function Library:AddSlider(page, text, minVal, maxVal, default, decimals, callback)
    if self:_isDead() then return end
    if type(minVal) ~= "number" or type(maxVal) ~= "number" then
        error("[DoD UI] AddSlider minVal/maxVal harus number.")
    end
    if maxVal <= minVal then
        error("[DoD UI] AddSlider maxVal harus lebih besar dari minVal.")
    end
    if minVal ~= minVal or maxVal ~= maxVal or minVal == math.huge or maxVal == math.huge
        or minVal == -math.huge or maxVal == -math.huge then
        error("[DoD UI] AddSlider bounds must be finite numbers.")
    end
    if maxVal - minVal == math.huge then
        error("[DoD UI] AddSlider range is too large.")
    end
    if decimals == nil then decimals = 1 end
    if type(decimals) ~= "number" or decimals < 0 or decimals > 6 or decimals % 1 ~= 0 then
        error("[DoD UI] AddSlider decimals must be an integer between 0 and 6.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddSlider callback must be a function.")
    end
    if type(default) ~= "number" then default = minVal end
    if default ~= default or default == math.huge or default == -math.huge then
        error("[DoD UI] AddSlider default must be finite.")
    end
    default = math.clamp(default, minVal, maxVal)
    callback = callback or function() end

    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 58)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lab = Instance.new("TextLabel", holder)
    lab.Size = UDim2.new(1, -112, 0, 18)
    lab.Position = UDim2.new(0, 14, 0, 6)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = self._Colors.Text
    lab.Font = Enum.Font.GothamMedium
    lab.TextSize = 12
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.TextTruncate = Enum.TextTruncate.AtEnd

    local valBox = Instance.new("TextBox", holder)
    valBox.Name = "ValueBox"
    valBox.Size = UDim2.new(0, 80, 0, 24)
    valBox.Position = UDim2.new(1, -94, 0, 3)
    valBox.BackgroundColor3 = self._Colors.Bg2
    valBox.BackgroundTransparency = 0.5
    valBox.TextColor3 = self._Colors.Text
    valBox.Font = Enum.Font.GothamBold
    valBox.TextSize = 12
    valBox.Text = tostring(default)
    valBox.TextXAlignment = Enum.TextXAlignment.Center
    valBox.ClearTextOnFocus = false
    valBox.BorderSizePixel = 0
    Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 8)

    local valBoxPad = Instance.new("UIPadding", valBox)
    valBoxPad.PaddingLeft = UDim.new(0, 10)
    valBoxPad.PaddingRight = UDim.new(0, 10)

    local valBoxStroke = Instance.new("UIStroke", valBox)
    valBoxStroke.Color = self._Colors.Border
    valBoxStroke.Thickness = 1
    valBoxStroke.Transparency = 0.6

    local sliderBg = Instance.new("Frame", holder)
    sliderBg.Size = UDim2.new(1, -28, 0, 8)
    sliderBg.Position = UDim2.new(0, 14, 0, 36)
    sliderBg.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    sliderBg.BorderSizePixel = 0
    sliderBg.Active = true
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local sliderStroke = Instance.new("UIStroke", sliderBg)
    sliderStroke.Color = self._Colors.Border
    sliderStroke.Thickness = 1
    sliderStroke.Transparency = 0.5

    for i = 1, 3 do
        local tick = Instance.new("Frame", sliderBg)
        tick.Size = UDim2.new(0, 1, 0, 4)
        tick.Position = UDim2.new(i / 4, 0, 0.5, -2)
        tick.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
        tick.BackgroundTransparency = 0.4
        tick.BorderSizePixel = 0
        tick.ZIndex = 1
    end

    local fillGlow = Instance.new("Frame", sliderBg)
    fillGlow.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1.6, -0.3)
    fillGlow.Position = UDim2.new(0, 0, 0.5, -6.4)
    fillGlow.BackgroundColor3 = self._Colors.Accent
    fillGlow.BackgroundTransparency = 0.7
    fillGlow.BorderSizePixel = 0
    fillGlow.ZIndex = 1
    Instance.new("UICorner", fillGlow).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", sliderBg)
    fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = self._Colors.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 2
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new(self._Colors.Accent, self._Colors.Accent2 or self._Colors.Accent)
    fillGrad.Rotation = 0

    local knobHalo = Instance.new("Frame", sliderBg)
    knobHalo.Name = "KnobHalo"
    knobHalo.AnchorPoint = Vector2.new(0.5, 0.5)
    knobHalo.Size = UDim2.fromOffset(24, 24)
    knobHalo.Position = UDim2.new((default - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knobHalo.BackgroundColor3 = self._Colors.Accent
    knobHalo.BackgroundTransparency = 1
    knobHalo.BorderSizePixel = 0
    knobHalo.ZIndex = 2
    Instance.new("UICorner", knobHalo).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", sliderBg)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - minVal) / (maxVal - minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = self._Colors.Accent
    knobStroke.Thickness = 2
    knobStroke.Transparency = 0.2

    local knobScale = Instance.new("UIScale", knob)
    knobScale.Scale = 1

    local val = default
    local drag = false
    local editing = false
    local originalText = ""

    local function formatValue(v)
        if decimals == 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(decimals) .. "f", v)
    end

    local function applyValue(newVal, animate)
        newVal = math.clamp(newVal, minVal, maxVal)
        local mult = 10 ^ decimals
        if math.abs(newVal) <= math.huge / mult then
            if newVal >= 0 then
                newVal = math.floor(newVal * mult + 0.5) / mult
            else
                newVal = math.ceil(newVal * mult - 0.5) / mult
            end
        end
        val = newVal
        local rel = math.clamp((newVal - minVal) / (maxVal - minVal), 0, 1)
        if animate then
            TweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
            TweenService:Create(fillGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(rel, 0, 1.6, -0.3)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(rel, -8, 0.5, -8)}):Play()
            TweenService:Create(knobHalo, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(rel, 0, 0.5, 0)}):Play()
        else
            fill.Size = UDim2.new(rel, 0, 1, 0)
            fillGlow.Size = UDim2.new(rel, 0, 1.6, -0.3)
            knob.Position = UDim2.new(rel, -8, 0.5, -8)
            knobHalo.Position = UDim2.new(rel, 0, 0.5, 0)
        end
        if not editing then
            valBox.Text = formatValue(newVal)
        end
    end

    local function setFromPosition(position)
        local width = sliderBg.AbsoluteSize.X
        if width <= 0 then return end
        local rel = math.clamp((position.X - sliderBg.AbsolutePosition.X) / width, 0, 1)
        local newVal = minVal + (maxVal - minVal) * rel
        applyValue(newVal, false)
        callback(val)
        self:_triggerAutoSave()
    end

    valBox.Focused:Connect(function()
        editing = true
        originalText = valBox.Text
        TweenService:Create(valBoxStroke, TweenInfo.new(0.15), {Color = self._Colors.Accent, Transparency = 0}):Play()
        TweenService:Create(valBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
    end)

    valBox.MouseEnter:Connect(function()
        if not editing then
            TweenService:Create(valBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.35}):Play()
            TweenService:Create(valBoxStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
        end
    end)
    valBox.MouseLeave:Connect(function()
        if not editing then
            TweenService:Create(valBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(valBoxStroke, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
        end
    end)

    valBox.FocusLost:Connect(function(enterPressed)
        editing = false
        TweenService:Create(valBoxStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.6}):Play()
        TweenService:Create(valBox, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
        if valBox.Text == originalText then
            valBox.Text = formatValue(val)
            return
        end
        local parsed = tonumber(valBox.Text)
        if parsed and parsed == parsed and parsed ~= math.huge and parsed ~= -math.huge then
            applyValue(parsed, true)
            callback(val)
            self:_triggerAutoSave()
        else
            valBox.Text = formatValue(val)
        end
    end)

    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            TweenService:Create(knobScale, TweenInfo.new(0.1), {Scale = 1.2}):Play()
            TweenService:Create(knobStroke, TweenInfo.new(0.1), {Transparency = 0}):Play()
        end
    end)

    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            TweenService:Create(knobScale, TweenInfo.new(0.1), {Scale = 1.2}):Play()
            setFromPosition(inp.Position)
        end
    end)

    Fn.track(UserInputService.InputEnded, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if drag then
                TweenService:Create(knobScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                TweenService:Create(knobStroke, TweenInfo.new(0.15), {Transparency = 0.2}):Play()
            end
            drag = false
        end
    end, self)

    Fn.track(UserInputService.InputChanged, function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            setFromPosition(inp.Position)
        end
    end, self)

    self:_registerConfigState(self:_getConfigId("slider", text),
        function() return val end,
        function(v, silent)
            if type(v) ~= "number" or v ~= v then return end
            applyValue(v, false)
            if not silent then
                callback(val)
                self:_triggerAutoSave()
            end
        end
    )

    holder.MouseEnter:Connect(function()
        if not drag then
            TweenService:Create(knobScale, TweenInfo.new(0.15), {Scale = 1.1}):Play()
            TweenService:Create(knobHalo, TweenInfo.new(0.18), {BackgroundTransparency = 0.82}):Play()
        end
    end)
    holder.MouseLeave:Connect(function()
        if not drag then
            TweenService:Create(knobScale, TweenInfo.new(0.15), {Scale = 1}):Play()
            TweenService:Create(knobHalo, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end)

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        lab.TextColor3 = self._Colors.Text
        valBox.TextColor3 = self._Colors.Text
        valBox.BackgroundColor3 = self._Colors.Bg2
        valBoxStroke.Color = self._Colors.Border
        fill.BackgroundColor3 = self._Colors.Accent
        fillGlow.BackgroundColor3 = self._Colors.Accent
        knobStroke.Color = self._Colors.Accent
        knobHalo.BackgroundColor3 = self._Colors.Accent
        sliderStroke.Color = self._Colors.Border
        fillGrad.Color = ColorSequence.new(self._Colors.Accent, self._Colors.Accent2 or self._Colors.Accent)
    end)
    self:_bindTooltip(lab, text .. " [" .. tostring(minVal) .. " - " .. tostring(maxVal) .. "] — click value to type")
    return self:_registerSearchControl(holder, text .. " " .. tostring(minVal) .. " " .. tostring(maxVal))
end

function Library:AddDropdown(page, text, options, defaultIndex, callback)
    if self:_isDead() then return end
    if type(options) ~= "table" or #options == 0 then
        error("[DoD UI] AddDropdown options harus array non-empty.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddDropdown callback must be a function.")
    end
    if type(defaultIndex) ~= "number" or defaultIndex % 1 ~= 0
        or defaultIndex < 1 or defaultIndex > #options then
        defaultIndex = 1
    end
    callback = callback or function() end

    local STATE = self._STATE
    local UI = self._UI

    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local holderStroke = Instance.new("UIStroke", holder)
    holderStroke.Color = self._Colors.Border
    holderStroke.Thickness = 1
    holderStroke.Transparency = 0.5

    local label = Instance.new("TextLabel", holder)
    label.Size = UDim2.new(0.42, -20, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self._Colors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd

    local valueChip = Instance.new("TextButton", holder)
    valueChip.Size = UDim2.new(0.58, -14, 0, 30)
    valueChip.Position = UDim2.new(0.42, 4, 0.5, -15)
    valueChip.BackgroundColor3 = self._Colors.Bg2
    valueChip.BackgroundTransparency = 0.2
    valueChip.Text = ""
    valueChip.BorderSizePixel = 0
    valueChip.AutoButtonColor = false
    Fn.bindPressAnimation(valueChip)
    Instance.new("UICorner", valueChip).CornerRadius = UDim.new(0, 8)

    local chipStroke = Instance.new("UIStroke", valueChip)
    chipStroke.Color = self._Colors.Border
    chipStroke.Thickness = 1
    chipStroke.Transparency = 0.4

    valueChip.MouseEnter:Connect(function()
        TweenService:Create(chipStroke, TweenInfo.new(0.15), {Color = self._Colors.Accent, Transparency = 0.1}):Play()
        TweenService:Create(valueChip, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    valueChip.MouseLeave:Connect(function()
        TweenService:Create(chipStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.4}):Play()
        TweenService:Create(valueChip, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    end)

    local chipLabel = Instance.new("TextLabel", valueChip)
    chipLabel.Size = UDim2.new(1, -20, 1, 0)
    chipLabel.Position = UDim2.new(0, 12, 0, 0)
    chipLabel.BackgroundTransparency = 1
    chipLabel.Text = tostring(options[defaultIndex])
    chipLabel.TextColor3 = self._Colors.Text
    chipLabel.Font = Enum.Font.GothamBold
    chipLabel.TextSize = 11
    chipLabel.TextXAlignment = Enum.TextXAlignment.Left
    chipLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local currentIndex = defaultIndex
    local popup = Instance.new("Frame", UI.MainGui)
    popup.Name = "DropdownPopup"
    popup.BackgroundColor3 = self._Colors.Bg2
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 200
    popup.ClipsDescendants = true
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

    local popupStroke = Instance.new("UIStroke", popup)
    popupStroke.Color = self._Colors.Accent
    popupStroke.Thickness = 1
    popupStroke.Transparency = 0.3

    local popupSearch = Instance.new("Frame", popup)
    popupSearch.Size = UDim2.new(1, -10, 0, 24)
    popupSearch.Position = UDim2.new(0, 5, 0, 5)
    popupSearch.BackgroundColor3 = self._Colors.Card
    popupSearch.BackgroundTransparency = 0.5
    popupSearch.BorderSizePixel = 0
    popupSearch.ZIndex = 202
    Instance.new("UICorner", popupSearch).CornerRadius = UDim.new(0, 4)
    
    local searchBox = Instance.new("TextBox", popupSearch)
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search options..."
    searchBox.PlaceholderColor3 = self._Colors.TextDim
    searchBox.TextColor3 = self._Colors.Text
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 203

    local popupScroll = Instance.new("ScrollingFrame", popup)
    popupScroll.Size = UDim2.new(1, 0, 1, -34)
    popupScroll.Position = UDim2.new(0, 0, 0, 34)
    popupScroll.BackgroundTransparency = 1
    popupScroll.BorderSizePixel = 0
    popupScroll.ScrollBarThickness = 3
    popupScroll.ScrollBarImageColor3 = self._Colors.Accent
    popupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    popupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    popupScroll.ZIndex = 201

    local optionButtons = {}

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(searchBox.Text)
        for _, btn in ipairs(optionButtons) do
            local lbl = btn:FindFirstChildOfClass("TextLabel")
            if lbl then
                local txt = string.lower(lbl.Text)
                btn.Visible = (q == "" or string.find(txt, q, 1, true) ~= nil)
            end
        end
    end)

    local popupList = Instance.new("UIListLayout", popupScroll)
    popupList.SortOrder = Enum.SortOrder.LayoutOrder
    popupList.Padding = UDim.new(0, 2)

    local popupPad = Instance.new("UIPadding", popupScroll)
    popupPad.PaddingTop = UDim.new(0, 5)
    popupPad.PaddingBottom = UDim.new(0, 5)
    popupPad.PaddingLeft = UDim.new(0, 5)
    popupPad.PaddingRight = UDim.new(0, 5)

    local function refreshOptions()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        table.clear(optionButtons)
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", popupScroll)
            optBtn.Size = UDim2.new(1, 0, 0, 30)
            optBtn.BackgroundColor3 = self._Colors.Card
            optBtn.BackgroundTransparency = 1
            optBtn.Text = ""
            optBtn.BorderSizePixel = 0
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 202
            Fn.bindPressAnimation(optBtn)
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 5)

            local optLabel = Instance.new("TextLabel", optBtn)
            optLabel.Size = UDim2.new(1, -36, 1, 0)
            optLabel.Position = UDim2.new(0, 12, 0, 0)
            optLabel.BackgroundTransparency = 1
            optLabel.Text = tostring(opt)
            optLabel.TextColor3 = self._Colors.Text
            optLabel.Font = Enum.Font.GothamBold
            optLabel.TextSize = 12
            optLabel.TextXAlignment = Enum.TextXAlignment.Left

            local check = Instance.new("TextLabel", optBtn)
            check.Size = UDim2.new(0, 24, 1, 0)
            check.Position = UDim2.new(1, -28, 0, 0)
            check.BackgroundTransparency = 1
            check.Text = "✓"
            check.TextColor3 = self._Colors.Accent
            check.Font = Enum.Font.GothamBlack
            check.TextSize = 14
            check.Visible = (i == currentIndex)

            optBtn.MouseEnter:Connect(function() optBtn.BackgroundTransparency = 0.4 end)
            optBtn.MouseLeave:Connect(function() optBtn.BackgroundTransparency = 1 end)
            optBtn.MouseButton1Click:Connect(function()
                currentIndex = i
                chipLabel.Text = tostring(options[i])
                popup.Visible = false
                callback(i, options[i])
                self:_triggerAutoSave()
            end)
            table.insert(optionButtons, optBtn)
        end
    end

    self:_registerConfigState(self:_getConfigId("dropdown", text),
        function() return currentIndex end,
        function(v, silent)
            if type(v) ~= "number" or v < 1 or v > #options then return end
            if v == currentIndex then return end
            currentIndex = v
            chipLabel.Text = tostring(options[v])
            if not silent then
                callback(v, options[v])
                self:_triggerAutoSave()
            end
        end
    )

    local function updatePopupPosition()
        local camera = getCam()
        if not camera then return end
        local chipPos = valueChip.AbsolutePosition
        local chipSize = valueChip.AbsoluteSize
        local totalHeight = math.min(#options * 32 + 44, 260)
        local viewport = camera.ViewportSize
        local width = math.min(chipSize.X, math.max(1, viewport.X - 16))
        local x = math.clamp(chipPos.X, 8, math.max(8, viewport.X - width - 8))
        local y = chipPos.Y + chipSize.Y + 6
        if y + totalHeight > viewport.Y - 8 then
            y = chipPos.Y - totalHeight - 6
        end
        y = math.clamp(y, 8, math.max(8, viewport.Y - totalHeight - 8))
        popup.Size = UDim2.fromOffset(width, totalHeight)
        popup.Position = UDim2.fromOffset(x, y)
    end

    valueChip.MouseButton1Click:Connect(function()
        self:PlaySound("Dropdown")
        if popup.Visible then
            popup.Visible = false
        else
            for _, other in ipairs(STATE.activeDropdownPopups) do
                if other.popup ~= popup then other.close() end
            end
            refreshOptions()
            updatePopupPosition()
            popup.Visible = true
            local targetPos = popup.Position
            popup.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset + 4)
            TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos,
            }):Play()
        end
    end)

    table.insert(STATE.activeDropdownPopups, {
        popup = popup,
        close = function() popup.Visible = false end,
    })

    Fn.track(UserInputService.InputBegan, function(inp)
        if not popup.Visible then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = inp.Position
        local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
        local bp, bs = valueChip.AbsolutePosition, valueChip.AbsoluteSize
        local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
        local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
        if not inPopup and not inBtn then popup.Visible = false end
    end, self)

    task.spawn(function()
        while popup.Parent do
            if popup.Visible then updatePopupPosition() end
            task.wait(0.1)
        end
    end)

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        holderStroke.Color = self._Colors.Border
        label.TextColor3 = self._Colors.Text
        valueChip.BackgroundColor3 = self._Colors.Bg2
        chipStroke.Color = self._Colors.Border
        chipLabel.TextColor3 = self._Colors.Text
        popup.BackgroundColor3 = self._Colors.Bg2
        popupStroke.Color = self._Colors.Accent
        popupScroll.ScrollBarImageColor3 = self._Colors.Accent
        popupSearch.BackgroundColor3 = self._Colors.Card
        searchBox.TextColor3 = self._Colors.Text
        searchBox.PlaceholderColor3 = self._Colors.TextDim
        for _, btn in ipairs(optionButtons) do
            btn.BackgroundColor3 = self._Colors.Card
            for _, child in ipairs(btn:GetChildren()) do
                if child:IsA("TextLabel") then
                    if child.Size.X.Offset == 24 and child.Size.X.Scale == 0 then
                        child.TextColor3 = self._Colors.Accent
                    else
                        child.TextColor3 = self._Colors.Text
                    end
                end
            end
        end
    end)

    local searchableOptions = {}
    for _, option in ipairs(options) do
        table.insert(searchableOptions, tostring(option))
    end
    self:_bindTooltip(label, text .. " (" .. #options .. " options)")
    return self:_registerSearchControl(holder, text .. " " .. table.concat(searchableOptions, " "))
end

function Library:AddMultiDropdown(page, text, options, defaults, callback)
    if self:_isDead() then return end
    if type(options) ~= "table" or #options == 0 then
        error("[DoD UI] AddMultiDropdown options must be a non-empty array.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddMultiDropdown callback must be a function.")
    end
    callback = callback or function() end
    local selected = {}
    if type(defaults) == "table" then
        for _, idx in ipairs(defaults) do
            if type(idx) == "number" and idx >= 1 and idx <= #options then
                selected[idx] = true
            end
        end
    end

    local STATE = self._STATE
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local holderStroke = Instance.new("UIStroke", holder)
    holderStroke.Color = self._Colors.Border
    holderStroke.Thickness = 1
    holderStroke.Transparency = 0.5

    local label = Instance.new("TextLabel", holder)
    label.Size = UDim2.new(0.42, -20, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self._Colors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd

    local valueChip = Instance.new("TextButton", holder)
    valueChip.Size = UDim2.new(0.58, -14, 0, 30)
    valueChip.Position = UDim2.new(0.42, 4, 0.5, -15)
    valueChip.BackgroundColor3 = self._Colors.Bg2
    valueChip.BackgroundTransparency = 0.2
    valueChip.Text = ""
    valueChip.BorderSizePixel = 0
    valueChip.AutoButtonColor = false
    Fn.bindPressAnimation(valueChip)
    Instance.new("UICorner", valueChip).CornerRadius = UDim.new(0, 8)

    local chipStroke = Instance.new("UIStroke", valueChip)
    chipStroke.Color = self._Colors.Border
    chipStroke.Thickness = 1
    chipStroke.Transparency = 0.4

    local chipLabel = Instance.new("TextLabel", valueChip)
    chipLabel.Size = UDim2.new(1, -20, 1, 0)
    chipLabel.Position = UDim2.new(0, 12, 0, 0)
    chipLabel.BackgroundTransparency = 1
    chipLabel.TextColor3 = self._Colors.Text
    chipLabel.Font = Enum.Font.GothamBold
    chipLabel.TextSize = 11
    chipLabel.TextXAlignment = Enum.TextXAlignment.Left
    chipLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local function getSelectedIndices()
        local out = {}
        for i = 1, #options do
            if selected[i] then table.insert(out, i) end
        end
        return out
    end

    local function getSelectedValues()
        local out = {}
        for i = 1, #options do
            if selected[i] then table.insert(out, options[i]) end
        end
        return out
    end

    local function updateChipLabel()
        local indices = getSelectedIndices()
        if #indices == 0 then
            chipLabel.Text = "None"
            chipLabel.TextColor3 = self._Colors.TextDim
        elseif #indices == 1 then
            chipLabel.Text = tostring(options[indices[1]])
            chipLabel.TextColor3 = self._Colors.Text
        else
            chipLabel.Text = tostring(#indices) .. " selected"
            chipLabel.TextColor3 = self._Colors.Text
        end
    end
    updateChipLabel()

    local popup = Instance.new("Frame", self._UI.MainGui)
    popup.Name = "MultiDropdownPopup"
    popup.BackgroundColor3 = self._Colors.Bg2
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 200
    popup.ClipsDescendants = true
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

    local popupStroke = Instance.new("UIStroke", popup)
    popupStroke.Color = self._Colors.Accent
    popupStroke.Thickness = 1
    popupStroke.Transparency = 0.3

    local popupScroll = Instance.new("ScrollingFrame", popup)
    popupScroll.Size = UDim2.new(1, 0, 1, -10)
    popupScroll.Position = UDim2.new(0, 0, 0, 5)
    popupScroll.BackgroundTransparency = 1
    popupScroll.BorderSizePixel = 0
    popupScroll.ScrollBarThickness = 3
    popupScroll.ScrollBarImageColor3 = self._Colors.Accent
    popupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    popupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    popupScroll.ZIndex = 201

    local popupList = Instance.new("UIListLayout", popupScroll)
    popupList.SortOrder = Enum.SortOrder.LayoutOrder
    popupList.Padding = UDim.new(0, 2)

    local popupPad = Instance.new("UIPadding", popupScroll)
    popupPad.PaddingTop = UDim.new(0, 5)
    popupPad.PaddingBottom = UDim.new(0, 5)
    popupPad.PaddingLeft = UDim.new(0, 5)
    popupPad.PaddingRight = UDim.new(0, 5)

    local optionButtons = {}

    local function refreshOptions()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        table.clear(optionButtons)
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", popupScroll)
            optBtn.Size = UDim2.new(1, 0, 0, 30)
            optBtn.BackgroundColor3 = self._Colors.Card
            optBtn.BackgroundTransparency = 1
            optBtn.Text = ""
            optBtn.BorderSizePixel = 0
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 202
            Fn.bindPressAnimation(optBtn)
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 5)

            local box = Instance.new("Frame", optBtn)
            box.Size = UDim2.fromOffset(16, 16)
            box.Position = UDim2.new(0, 10, 0.5, -8)
            box.BackgroundColor3 = selected[i] and self._Colors.Accent or self._Colors.Bg
            box.BorderSizePixel = 0
            box.ZIndex = 203
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

            local boxStroke = Instance.new("UIStroke", box)
            boxStroke.Color = selected[i] and self._Colors.Accent or self._Colors.Border
            boxStroke.Thickness = 1

            local check = Instance.new("TextLabel", box)
            check.Size = UDim2.fromScale(1, 1)
            check.BackgroundTransparency = 1
            check.Text = "✓"
            check.TextColor3 = Fn.accentTextColor(self._Colors.Accent)
            check.Font = Enum.Font.GothamBlack
            check.TextSize = 11
            check.Visible = selected[i] and true or false
            check.ZIndex = 204

            local optLabel = Instance.new("TextLabel", optBtn)
            optLabel.Size = UDim2.new(1, -50, 1, 0)
            optLabel.Position = UDim2.new(0, 34, 0, 0)
            optLabel.BackgroundTransparency = 1
            optLabel.Text = tostring(opt)
            optLabel.TextColor3 = self._Colors.Text
            optLabel.Font = Enum.Font.GothamBold
            optLabel.TextSize = 12
            optLabel.TextXAlignment = Enum.TextXAlignment.Left
            optLabel.ZIndex = 203

            optBtn.MouseEnter:Connect(function() optBtn.BackgroundTransparency = 0.4 end)
            optBtn.MouseLeave:Connect(function() optBtn.BackgroundTransparency = 1 end)
            optBtn.MouseButton1Click:Connect(function()
                selected[i] = not selected[i] or nil
                box.BackgroundColor3 = selected[i] and self._Colors.Accent or self._Colors.Bg
                boxStroke.Color = selected[i] and self._Colors.Accent or self._Colors.Border
                check.Visible = selected[i] and true or false
                updateChipLabel()
                callback(getSelectedIndices(), getSelectedValues())
                self:_triggerAutoSave()
            end)
            table.insert(optionButtons, optBtn)
        end
    end

    local function updatePopupPosition()
        local camera = getCam()
        if not camera then return end
        local chipPos = valueChip.AbsolutePosition
        local chipSize = valueChip.AbsoluteSize
        local totalHeight = math.min(#options * 32 + 12, 260)
        local viewport = camera.ViewportSize
        local width = math.min(chipSize.X, math.max(1, viewport.X - 16))
        local x = math.clamp(chipPos.X, 8, math.max(8, viewport.X - width - 8))
        local y = chipPos.Y + chipSize.Y + 6
        if y + totalHeight > viewport.Y - 8 then
            y = chipPos.Y - totalHeight - 6
        end
        y = math.clamp(y, 8, math.max(8, viewport.Y - totalHeight - 8))
        popup.Size = UDim2.fromOffset(width, totalHeight)
        popup.Position = UDim2.fromOffset(x, y)
    end

    valueChip.MouseButton1Click:Connect(function()
        self:PlaySound("Dropdown")
        if popup.Visible then
            popup.Visible = false
        else
            for _, other in ipairs(STATE.activeDropdownPopups) do
                if other.popup ~= popup then other.close() end
            end
            refreshOptions()
            updatePopupPosition()
            popup.Visible = true
            local targetPos = popup.Position
            popup.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset + 4)
            TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos,
            }):Play()
        end
    end)

    table.insert(STATE.activeDropdownPopups, {
        popup = popup,
        close = function() popup.Visible = false end,
    })

    Fn.track(UserInputService.InputBegan, function(inp)
        if not popup.Visible then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = inp.Position
        local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
        local bp, bs = valueChip.AbsolutePosition, valueChip.AbsoluteSize
        local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
        local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
        if not inPopup and not inBtn then popup.Visible = false end
    end, self)

    task.spawn(function()
        while popup.Parent do
            if popup.Visible then updatePopupPosition() end
            task.wait(0.1)
        end
    end)

    self:_registerConfigState(self:_getConfigId("multi_dropdown", text),
        function() return getSelectedIndices() end,
        function(v, silent)
            if type(v) ~= "table" then return end
            table.clear(selected)
            for _, idx in ipairs(v) do
                if type(idx) == "number" and idx >= 1 and idx <= #options then
                    selected[idx] = true
                end
            end
            updateChipLabel()
            if not silent then
                callback(getSelectedIndices(), getSelectedValues())
                self:_triggerAutoSave()
            end
        end
    )

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        holderStroke.Color = self._Colors.Border
        label.TextColor3 = self._Colors.Text
        valueChip.BackgroundColor3 = self._Colors.Bg2
        chipStroke.Color = self._Colors.Border
        updateChipLabel()
        popup.BackgroundColor3 = self._Colors.Bg2
        popupStroke.Color = self._Colors.Accent
        popupScroll.ScrollBarImageColor3 = self._Colors.Accent
    end)

    local searchableOptions = {}
    for _, option in ipairs(options) do
        table.insert(searchableOptions, tostring(option))
    end
    self:_bindTooltip(label, text .. " (" .. #options .. " options)")
    return self:_registerSearchControl(holder, text .. " " .. table.concat(searchableOptions, " "))
end

function Library:AddKeybind(page, text, default, callback)
    if self:_isDead() then return end
    local function _normSpec(spec)
        if spec == nil then return nil, {} end
        if typeof(spec) == "EnumItem" and spec.EnumType == Enum.KeyCode then
            return spec, {}
        end
        if spec == "LClick" or spec == "RClick" then
            return spec, {}
        end
        if type(spec) == "table" then
            local mods = spec.Modifiers or spec.mods or {}
            if type(mods) ~= "table" then mods = {} end
            local key = spec.Key or spec.key
            if key == nil then return nil, {} end
            return key, mods
        end
        return nil, {}
    end
    local _initKey, _initMods = _normSpec(default)
    if default ~= nil and not (
        (typeof(default) == "EnumItem" and default.EnumType == Enum.KeyCode)
        or default == "LClick" or default == "RClick"
        or (type(default) == "table" and (default.Key ~= nil or default.key ~= nil))
    ) then
        error("[DoD UI] AddKeybind default must be Enum.KeyCode, LClick, RClick, table, or nil.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddKeybind callback must be a function.")
    end
    local STATE = self._STATE
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lab = Instance.new("TextLabel", holder)
    lab.Size = UDim2.new(1, -136, 1, 0)
    lab.Position = UDim2.new(0, 12, 0, 0)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = self._Colors.Text
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 13
    lab.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(0, 110, 0, 28)
    btn.Position = UDim2.new(1, -122, 0.5, -14)
    btn.BackgroundColor3 = self._Colors.Bg2
    btn.BackgroundTransparency = 0.2
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Fn.bindPressAnimation(btn)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new(self._Colors.Bg2, self._Colors.Bg)
    btnGrad.Rotation = 90

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = self._Colors.Border
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5

    local btnIcon = Instance.new("ImageLabel", btn)
    btnIcon.Size = UDim2.fromOffset(14, 14)
    btnIcon.Position = UDim2.new(0, 10, 0.5, -7)
    btnIcon.BackgroundTransparency = 1
    btnIcon.Image = GetIcon("keyboard")
    btnIcon.ImageColor3 = self._Colors.TextDim

    local btnText = Instance.new("TextLabel", btn)
    btnText.Size = UDim2.new(1, -34, 1, 0)
    btnText.Position = UDim2.new(0, 28, 0, 0)
    btnText.BackgroundTransparency = 1
    btnText.Text = "NONE"
    btnText.TextColor3 = self._Colors.Text
    btnText.Font = Enum.Font.GothamBold
    btnText.TextSize = 11
    btnText.TextXAlignment = Enum.TextXAlignment.Left

    local listener
    local function _formatKeyName(k)
        if typeof(k) == "EnumItem" then
            return string.upper(k.Name)
        elseif k == nil then
            return "NONE"
        else
            return string.upper(tostring(k))
        end
    end
    local function setLabel(k, mods)
        mods = mods or {}
        local baseName = _formatKeyName(k)
        local keyName = baseName
        if #mods > 0 then
            keyName = table.concat(mods, "+") .. "+" .. baseName
        end
        btnText.Text = keyName
        btnIcon.ImageColor3 = (k ~= nil) and self._Colors.Accent or self._Colors.TextDim
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.5}):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        if listener then
            listener.key = k
            listener.mods = mods
            listener.keyName = keyName
            self:_refreshKeybindOverlay()
        end
    end
    setLabel(_initKey, _initMods)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Accent, Transparency = 0.1}):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
    end)

    btn.MouseLeave:Connect(function()
        if listener and listener.active then return end
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.5}):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    end)

    listener = {
        active = false,
        btn = btn,
        btnText = btnText,
        btnStroke = btnStroke,
        btnIcon = btnIcon,
        callback = callback or function() end,
        name = tostring(text),
        key = _initKey,
        mods = _initMods,
        keyName = btnText.Text,
        setKey = setLabel,
    }
    table.insert(STATE.activeKeybindListeners, listener)
    if not STATE._overlayAutoShown then
        STATE._overlayAutoShown = true
        self._UI.KeybindOverlayToggle.Visible = true
    end
    self:_refreshKeybindOverlay()

    btn.MouseButton1Click:Connect(function()
        self:PlaySound("Click")
        if listener.active then
            listener.active = false
            btnText.Text = listener.keyName
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.5}):Play()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
            return
        end
        for _, l in ipairs(STATE.activeKeybindListeners) do 
            l.active = false
            if l.btnText then l.btnText.Text = l.keyName end
            if l.btnStroke then TweenService:Create(l.btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.5}):Play() end
        end
        listener.active = true
        btnText.Text = "PRESS A KEY..."
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = self._Colors.Accent, Transparency = 0}):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)

    if not STATE._kbListenerInstalled then
        STATE._kbListenerInstalled = true
        local function getMods()
            local m = {}
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                table.insert(m, "Ctrl")
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                table.insert(m, "Shift")
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                table.insert(m, "Alt")
            end
            return m
        end
        local function modsMatch(stored, current)
            stored = stored or {}
            current = current or {}
            if #stored ~= #current then return false end
            for _, v in ipairs(stored) do
                if not table.find(current, v) then return false end
            end
            return true
        end
        Fn.track(UserInputService.InputBegan, function(inp, proc)
            if proc then return end
            for _, l in ipairs(STATE.activeKeybindListeners) do
                local mp = inp.Position
                local bp, bs = l.btn.AbsolutePosition, l.btn.AbsoluteSize
                local onClickBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X
                    and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                if l.active then
                    if not onClickBtn then
                        l.active = false
                        local capturedMods = getMods()
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            l.setKey(inp.KeyCode, capturedMods)
                            l.callback(inp.KeyCode, capturedMods)
                        elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            l.setKey("LClick", capturedMods)
                            l.callback(Enum.UserInputType.MouseButton1, capturedMods)
                        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                            l.setKey("RClick", capturedMods)
                            l.callback(Enum.UserInputType.MouseButton2, capturedMods)
                        end
                    end
                elseif l.key ~= nil and not onClickBtn then
                    local currentMods = getMods()
                    local matched = false
                    local firedKey = nil
                    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == l.key then
                        matched = true
                        firedKey = l.key
                    elseif inp.UserInputType == Enum.UserInputType.MouseButton1 and l.key == "LClick" then
                        matched = true
                        firedKey = Enum.UserInputType.MouseButton1
                    elseif inp.UserInputType == Enum.UserInputType.MouseButton2 and l.key == "RClick" then
                        matched = true
                        firedKey = Enum.UserInputType.MouseButton2
                    end
                    if matched and modsMatch(l.mods, currentMods) then
                        l.callback(firedKey, l.mods)
                        self:_triggerAutoSave()
                    end
                end
            end
        end, self)
    end

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        lab.TextColor3 = self._Colors.Text
        btnGrad.Color = ColorSequence.new(self._Colors.Bg2, self._Colors.Bg)
        btnText.TextColor3 = self._Colors.Text
        if listener and listener.key ~= nil then
            btnIcon.ImageColor3 = self._Colors.Accent
        else
            btnIcon.ImageColor3 = self._Colors.TextDim
        end
    end)
    self:_bindTooltip(lab, text .. " — click to rebind")
    return self:_registerSearchControl(holder, text)
end

function Library:AddButton(page, text, callback)
    if self:_isDead() then return end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddButton callback must be a function.")
    end
    callback = callback or function() end
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, 4)
    btn.Text = text
    btn.BackgroundColor3 = self._Colors.Accent
    btn.BackgroundTransparency = 0.15
    btn.TextColor3 = Fn.accentTextColor(self._Colors.Accent)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Fn.bindPressAnimation(btn)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.15 end)
    btn.MouseButton1Click:Connect(function()
        self:PlaySound("Click")
        callback()
    end)

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        btn.BackgroundColor3 = self._Colors.Accent
        btn.TextColor3 = Fn.accentTextColor(self._Colors.Accent)
    end)
    self:_bindTooltip(holder, text .. " (click)")
    return self:_registerSearchControl(holder, text)
end

function Library:AddLabel(page, text)
    if self:_isDead() then return end
    local label = Instance.new("TextLabel", page)
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = self._Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true

    self:_registerThemeRefresher(function()
        label.TextColor3 = self._Colors.Text
    end)
    return self:_registerSearchControl(label, text)
end

function Library:AddParagraph(page, title, desc)
    if self:_isDead() then return end
    desc = desc or ""
    local holder = Instance.new("Frame", page)
    holder.Name = "Paragraph"
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

    local layout = Instance.new("UIListLayout", holder)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)

    local padding = Instance.new("UIPadding", holder)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 9)
    padding.PaddingBottom = UDim.new(0, 9)

    local titleLabel = Instance.new("TextLabel", holder)
    titleLabel.Name = "Title"
    titleLabel.LayoutOrder = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title)
    titleLabel.TextColor3 = self._Colors.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local description = Instance.new("TextLabel", holder)
    description.Name = "Description"
    description.LayoutOrder = 2
    description.Size = UDim2.new(1, 0, 0, 0)
    description.AutomaticSize = Enum.AutomaticSize.Y
    description.BackgroundTransparency = 1
    description.Text = tostring(desc)
    description.TextColor3 = self._Colors.TextDim
    description.Font = Enum.Font.Gotham
    description.TextSize = 11
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        titleLabel.TextColor3 = self._Colors.Text
        description.TextColor3 = self._Colors.TextDim
    end)
    return self:_registerSearchControl(holder, tostring(title) .. " " .. tostring(desc))
end

function Library:AddTextbox(page, text, placeholder, callback)
    if self:_isDead() then return end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddTextbox callback must be a function.")
    end
    callback = callback or function() end

    local holder = Instance.new("Frame", page)
    holder.Name = "Textbox"
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel", holder)
    label.Size = UDim2.new(0.42, -14, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = self._Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd

    local input = Instance.new("TextBox", holder)
    input.Name = "Input"
    input.Size = UDim2.new(0.58, -18, 0, 30)
    input.Position = UDim2.new(0.42, 4, 0.5, -15)
    input.BackgroundColor3 = self._Colors.Bg2
    input.BackgroundTransparency = 0.2
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = false
    input.Text = ""
    input.PlaceholderText = tostring(placeholder or "")
    input.PlaceholderColor3 = self._Colors.TextDim
    input.TextColor3 = self._Colors.Text
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 11
    input.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = self._Colors.Border
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5

    local inputPadding = Instance.new("UIPadding", input)
    inputPadding.PaddingLeft = UDim.new(0, 10)
    inputPadding.PaddingRight = UDim.new(0, 10)

    input.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.15), {Color = self._Colors.Accent, Transparency = 0.1}):Play()
        TweenService:Create(input, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    input.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.15), {Color = self._Colors.Border, Transparency = 0.5}):Play()
        TweenService:Create(input, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    end)

    input.FocusLost:Connect(function()
        callback(input.Text)
        self:_triggerAutoSave()
    end)

    self:_registerConfigState(self:_getConfigId("textbox", text),
        function() return input.Text end,
        function(v, silent)
            if type(v) ~= "string" then return end
            if input.Text == v then return end
            input.Text = v
            if not silent then
                callback(v)
                self:_triggerAutoSave()
            end
        end
    )

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        label.TextColor3 = self._Colors.Text
        input.BackgroundColor3 = self._Colors.Bg2
        input.TextColor3 = self._Colors.Text
        input.PlaceholderColor3 = self._Colors.TextDim
    end)
    self:_bindTooltip(label, text .. " — press Enter to submit")
    return self:_registerSearchControl(holder, tostring(text) .. " " .. tostring(placeholder or ""))
end

function Library:AddColorPicker(page, text, defaultColor3, callback)
    if self:_isDead() then return end
    if typeof(defaultColor3) ~= "Color3" then
        error("[DoD UI] AddColorPicker expects defaultColor3 to be a Color3 value.")
    end
    if callback ~= nil and type(callback) ~= "function" then
        error("[DoD UI] AddColorPicker callback must be a function.")
    end
    callback = callback or function() end

    local holder = Instance.new("Frame", page)
    holder.Name = "ColorPicker"
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = self._Colors.Card
    holder.BackgroundTransparency = 0.3
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel", holder)
    label.Size = UDim2.new(1, -72, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = self._Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd

    local preview = Instance.new("TextButton", holder)
    preview.Name = "Preview"
    preview.Size = UDim2.new(0, 42, 0, 24)
    preview.Position = UDim2.new(1, -54, 0.5, -12)
    preview.BackgroundColor3 = defaultColor3
    preview.Text = ""
    preview.AutoButtonColor = false
    preview.BorderSizePixel = 0
    Fn.bindPressAnimation(preview)
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)

    local previewStroke = Instance.new("UIStroke", preview)
    previewStroke.Color = self._Colors.Border
    previewStroke.Thickness = 1

    local hue, saturation, value = Color3.toHSV(defaultColor3)
    local currentColor = defaultColor3
    local popup = Instance.new("Frame", self._UI.MainGui)
    popup.Name = "ColorPickerPopup"
    popup.Size = UDim2.new(0, 230, 0, 176)
    popup.BackgroundColor3 = self._Colors.Bg2
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 210
    popup.ClipsDescendants = true
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 9)

    local popupStroke = Instance.new("UIStroke", popup)
    popupStroke.Color = self._Colors.Border
    popupStroke.Thickness = 1

    local saturationValue = Instance.new("Frame", popup)
    saturationValue.Name = "SaturationValue"
    saturationValue.Position = UDim2.new(0, 10, 0, 10)
    saturationValue.Size = UDim2.new(1, -52, 1, -46)
    saturationValue.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    saturationValue.BorderSizePixel = 0
    saturationValue.Active = true
    saturationValue.ZIndex = 211
    Instance.new("UICorner", saturationValue).CornerRadius = UDim.new(0, 5)

    local saturationGradient = Instance.new("UIGradient", saturationValue)
    saturationGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    saturationGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })

    local valueOverlay = Instance.new("Frame", saturationValue)
    valueOverlay.Size = UDim2.new(1, 0, 1, 0)
    valueOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    valueOverlay.BackgroundTransparency = 1
    valueOverlay.BorderSizePixel = 0
    valueOverlay.ZIndex = 212
    Instance.new("UICorner", valueOverlay).CornerRadius = UDim.new(0, 5)

    local valueGradient = Instance.new("UIGradient", valueOverlay)
    valueGradient.Rotation = 90
    valueGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })

    local selector = Instance.new("Frame", saturationValue)
    selector.Name = "Selector"
    selector.AnchorPoint = Vector2.new(0.5, 0.5)
    selector.Size = UDim2.new(0, 10, 0, 10)
    selector.BackgroundTransparency = 1
    selector.BorderSizePixel = 0
    selector.ZIndex = 213
    Instance.new("UICorner", selector).CornerRadius = UDim.new(1, 0)
    local selectorStroke = Instance.new("UIStroke", selector)
    selectorStroke.Color = Color3.new(1, 1, 1)
    selectorStroke.Thickness = 2

    local hueBar = Instance.new("TextButton", popup)
    hueBar.Name = "Hue"
    hueBar.Position = UDim2.new(1, -30, 0, 10)
    hueBar.Size = UDim2.new(0, 18, 1, -46)
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.Text = ""
    hueBar.AutoButtonColor = false
    hueBar.Active = true
    hueBar.ZIndex = 211
    Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 5)

    local hueGradient = Instance.new("UIGradient", hueBar)
    hueGradient.Rotation = 90
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })

    local currentPreview = Instance.new("Frame", popup)
    currentPreview.Name = "CurrentColor"
    currentPreview.Position = UDim2.new(0, 10, 1, -28)
    currentPreview.Size = UDim2.new(1, -20, 0, 18)
    currentPreview.BackgroundColor3 = currentColor
    currentPreview.BorderSizePixel = 0
    currentPreview.ZIndex = 211
    Instance.new("UICorner", currentPreview).CornerRadius = UDim.new(0, 5)

    local dragMode

    local function updateColor(notify)
        currentColor = Color3.fromHSV(hue, saturation, value)
        saturationValue.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        selector.Position = UDim2.new(saturation, 0, 1 - value, 0)
        preview.BackgroundColor3 = currentColor
        currentPreview.BackgroundColor3 = currentColor
        if notify then
            callback(currentColor)
            self:_triggerAutoSave()
        end
    end

    self:_registerConfigState(self:_getConfigId("colorpicker", text),
        function() return { currentColor.R, currentColor.G, currentColor.B } end,
        function(v, silent)
            if type(v) ~= "table" or type(v[1]) ~= "number" or type(v[2]) ~= "number" or type(v[3]) ~= "number" then return end
            local newColor = Color3.new(v[1], v[2], v[3])
            hue, saturation, value = Color3.toHSV(newColor)
            updateColor(false)
            if not silent then
                callback(currentColor)
                self:_triggerAutoSave()
            end
        end
    )

    local function pickFromPosition(mode, position)
        if mode == "SV" then
            local size = saturationValue.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then return end
            saturation = math.clamp((position.X - saturationValue.AbsolutePosition.X) / size.X, 0, 1)
            value = 1 - math.clamp((position.Y - saturationValue.AbsolutePosition.Y) / size.Y, 0, 1)
        elseif mode == "Hue" then
            local size = hueBar.AbsoluteSize
            if size.Y <= 0 then return end
            hue = 1 - math.clamp((position.Y - hueBar.AbsolutePosition.Y) / size.Y, 0, 1)
        end
        updateColor(true)
    end

    saturationValue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragMode = "SV"
            pickFromPosition(dragMode, input.Position)
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragMode = "Hue"
            pickFromPosition(dragMode, input.Position)
        end
    end)
    Fn.track(UserInputService.InputChanged, function(input)
        if dragMode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            pickFromPosition(dragMode, input.Position)
        end
    end, self)
    Fn.track(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragMode = nil
        end
    end, self)

    preview.MouseButton1Click:Connect(function()
        if popup.Visible then
            popup.Visible = false
            return
        end
        for _, other in ipairs(self._STATE.activeDropdownPopups) do
            if other.popup ~= popup then other.close() end
        end

        local camera = getCam()
        if not camera then return end
        local viewport = camera.ViewportSize
        local popupWidth, popupHeight = popup.AbsoluteSize.X, popup.AbsoluteSize.Y
        local x = math.clamp(preview.AbsolutePosition.X, 8, math.max(8, viewport.X - popupWidth - 8))
        local y = preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 6
        if y + popupHeight > viewport.Y - 8 then
            y = preview.AbsolutePosition.Y - popupHeight - 6
        end
        popup.Position = UDim2.fromOffset(x, math.max(8, y))
        popup.Visible = true
    end)

    Fn.track(UserInputService.InputBegan, function(input)
        if not popup.Visible
            or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then
            return
        end
        local position = input.Position
        local popupPosition, popupSize = popup.AbsolutePosition, popup.AbsoluteSize
        local inside = position.X >= popupPosition.X and position.X <= popupPosition.X + popupSize.X
            and position.Y >= popupPosition.Y and position.Y <= popupPosition.Y + popupSize.Y
        local previewPosition, previewSize = preview.AbsolutePosition, preview.AbsoluteSize
        local onPreview = position.X >= previewPosition.X and position.X <= previewPosition.X + previewSize.X
            and position.Y >= previewPosition.Y and position.Y <= previewPosition.Y + previewSize.Y
        if not inside and not onPreview then popup.Visible = false end
    end, self)

    table.insert(self._STATE.activeDropdownPopups, {
        popup = popup,
        close = function()
            popup.Visible = false
            dragMode = nil
        end,
    })

    self:_registerThemeRefresher(function()
        holder.BackgroundColor3 = self._Colors.Card
        label.TextColor3 = self._Colors.Text
        previewStroke.Color = self._Colors.Border
        popup.BackgroundColor3 = self._Colors.Bg2
        popupStroke.Color = self._Colors.Border
    end)

    self:_bindTooltip(label, text .. " — click preview to open")
    return self:_registerSearchControl(holder, text)
end

-- =========================================================
-- WINDOW TOGGLE / DESTROY
-- =========================================================

function Library:_isDead()
    return self._STATE ~= nil and self._STATE.Destroyed == true
end

function Library:Minimize()
    if self:_isDead() then return end
    local STATE = self._STATE
    local UI = self._UI
    if not STATE.GuiVisible or STATE.AnimatingGui then return end
    STATE.AnimatingGui = true
    
    self:PlaySound("Click")
    
    local centerX = 0.5
    local centerY = 0.5
    local camera = getCam()
    if UI.MainContainer and camera then
        local pos = UI.MainContainer.AbsolutePosition
        local size = UI.MainContainer.AbsoluteSize
        local vp = camera.ViewportSize
        centerX = (pos.X + size.X / 2) / vp.X
        centerY = (pos.Y + size.Y / 2) / vp.Y
    end
    
    for i = 1, 35 do
        local p = Instance.new("Frame")
        p.Parent = UI.MainGui
        p.Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10))
        p.Position = UDim2.fromScale(centerX + (math.random() - 0.5) * 0.1, centerY + (math.random() - 0.5) * 0.1)
        p.BackgroundColor3 = self._Colors.Accent
        p.BackgroundTransparency = math.random(20, 50) / 100
        p.ZIndex = 999
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
        
        local targetX = 0.5 + (math.random() - 0.5) * 0.08
        local targetY = 0.02 + (math.random() - 0.5) * 0.05
        
        local tweenInfo = TweenInfo.new(math.random(6, 12) / 10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(p, tweenInfo, {
            Position = UDim2.fromScale(targetX, targetY),
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(1.2, function() if p and p.Parent then p:Destroy() end end)
    end
    
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    
    TweenService:Create(UI.GuiBlur, tweenInfo, {Size = 0}):Play()
    TweenService:Create(UI.MainContainer, tweenInfo, {BackgroundTransparency = 1}):Play()
    if UI.AcrylicTexture then TweenService:Create(UI.AcrylicTexture, tweenInfo, {BackgroundTransparency = 1}):Play() end
    if UI.AcrylicSheen then TweenService:Create(UI.AcrylicSheen, tweenInfo, {BackgroundTransparency = 1}):Play() end
    TweenService:Create(UI.FocusOverlay, tweenInfo, {BackgroundTransparency = 1}):Play()
    
    local st = TweenService:Create(UI.MainScale, tweenInfo, {Scale = 1.2})
    st:Play()
    
    st.Completed:Connect(function()
        UI.MainContainer.Visible = false
        UI.ParticleBG.Visible = false
        UI.FocusOverlay.Visible = false
        STATE.GuiVisible = false
        STATE.AnimatingGui = false
        
        local btn = UI.MinimizeButton
        if btn then
            btn.Visible = true
            btn.Size = UDim2.fromOffset(0, 32)
            btn.Position = UDim2.new(0.5, 0, 0, -40)
            TweenService:Create(btn, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(120, 32),
                Position = UDim2.new(0.5, 0, 0, 16)
            }):Play()
        end
    end)
end

function Library:PlaySound(soundName)
    if self:_isDead() then return end
    local s = self._Sounds and self._Sounds[soundName]
    if s then
        s:Play()
    end
end

function Library:Toggle()
    if self:_isDead() then return end
    local STATE = self._STATE
    local UI = self._UI
    if STATE.AnimatingGui then return end
    STATE.AnimatingGui = true
    if STATE.GuiTween then STATE.GuiTween:Cancel() end

    local blurTarget = self.Acrylic and self.AcrylicBlurIntensity or 0
    if STATE.FocusOverlayEnabled then blurTarget = math.max(blurTarget, 12) end
    local mainBgTrans = self.Acrylic and 0.32 or 0.1

    if STATE.GuiVisible then
        -- CLOSE ANIMATION (Focus Zoom Out)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        
        TweenService:Create(UI.GuiBlur, tweenInfo, {Size = 0}):Play()
        TweenService:Create(UI.MainContainer, tweenInfo, {BackgroundTransparency = 1}):Play()
        if UI.AcrylicTexture then TweenService:Create(UI.AcrylicTexture, tweenInfo, {BackgroundTransparency = 1}):Play() end
        if UI.AcrylicSheen then TweenService:Create(UI.AcrylicSheen, tweenInfo, {BackgroundTransparency = 1}):Play() end
        TweenService:Create(UI.FocusOverlay, tweenInfo, {BackgroundTransparency = 1}):Play()
        
        STATE.GuiTween = TweenService:Create(UI.MainScale, tweenInfo, {Scale = 1.15})
        STATE.GuiTween:Play()
        
        STATE.GuiTween.Completed:Connect(function()
            UI.MainContainer.Visible = false
            UI.ParticleBG.Visible = false
            UI.FocusOverlay.Visible = false
            STATE.GuiVisible = false
            STATE.AnimatingGui = false
            STATE.GuiTween = nil
        end)
    else
        -- OPEN ANIMATION (Focus Zoom In)
        UI.MainContainer.Visible = true
        UI.ParticleBG.Visible = true
        STATE.GuiVisible = true
        if UI.MinimizeButton then
            UI.MinimizeButton.Visible = false
        end
        
        UI.MainScale.Scale = 1.15
        UI.MainContainer.BackgroundTransparency = 1
        if UI.AcrylicTexture then UI.AcrylicTexture.BackgroundTransparency = 1 end
        if UI.AcrylicSheen then UI.AcrylicSheen.BackgroundTransparency = 1 end
        UI.GuiBlur.Size = 24
        
        if STATE.FocusOverlayEnabled then
            UI.FocusOverlay.Visible = true
            UI.FocusOverlay.BackgroundTransparency = 1
        end

        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        
        TweenService:Create(UI.GuiBlur, tweenInfo, {Size = blurTarget}):Play()
        TweenService:Create(UI.MainContainer, tweenInfo, {BackgroundTransparency = mainBgTrans}):Play()
        if UI.AcrylicTexture then TweenService:Create(UI.AcrylicTexture, tweenInfo, {BackgroundTransparency = self.Acrylic and 0.94 or 1}):Play() end
        if UI.AcrylicSheen then TweenService:Create(UI.AcrylicSheen, tweenInfo, {BackgroundTransparency = self.Acrylic and 0.72 or 1}):Play() end
        
        if STATE.FocusOverlayEnabled then
            TweenService:Create(UI.FocusOverlay, tweenInfo, {
                BackgroundTransparency = (D.Themes[self.ThemeName] or {}).OverlayTransparency or 0.45
            }):Play()
        end
        
        STATE.GuiTween = TweenService:Create(UI.MainScale, tweenInfo, {Scale = 1})
        STATE.GuiTween:Play()
        
        STATE.GuiTween.Completed:Connect(function()
            STATE.AnimatingGui = false
            STATE.GuiTween = nil
        end)
    end
end

function Library:Destroy()
    local STATE = self._STATE
    if STATE.Destroyed then return end
    STATE.Destroyed = true
    STATE.WeatherEnabled = false
    if STATE.GuiTween then
        STATE.GuiTween:Cancel()
        STATE.GuiTween = nil
    end

    self:_stopWeather()
    for _, frame in ipairs(STATE.activeNotifs) do
        if frame and frame.Parent then frame:Destroy() end
        STATE.notifParts[frame] = nil
    end
    table.clear(STATE.activeNotifs)
    table.clear(STATE.NotifQueue)
    STATE.NotifActive = 0
    pcall(function() if self._UI.GuiBlur then self._UI.GuiBlur:Destroy() end end)
    pcall(function() if self._UI.MainGui then self._UI.MainGui:Destroy() end end)
    pcall(function() if self._UI.NotifGui then self._UI.NotifGui:Destroy() end end)
    pcall(function() if self._UI.TooltipGui then self._UI.TooltipGui:Destroy() end end)
    pcall(function() if self._UI.TooltipGui then self._UI.TooltipGui:Destroy() end end)
    pcall(function() if self._particleBGConn then self._particleBGConn:Disconnect() end end)
    for _, layer in ipairs(self._shadowLayers or {}) do
        pcall(function() layer.frame:Destroy() end)
    end
    Fn.disconnectAll(self)
    table.clear(STATE.ThemeRefreshers)
    table.clear(STATE.activeKeybindListeners)
    table.clear(STATE.KeybindOverlayRows)
    table.clear(STATE.activeDropdownPopups)
    table.clear(STATE.SearchSections)
    table.clear(STATE.SearchBodies)
    table.clear(STATE.SearchTopLevel)
end

-- =========================================================
-- MODULE EXPORT (UPDATED FOR MAXIMUM COMPATIBILITY)
-- =========================================================

local export = {
    new = function(...) return Library.new(...) end,
    Themes = D.ThemeNames,
    WeatherTypes = D.WeatherTypes,
    FocusOverlayTypes = D.FocusOverlayTypes,
}

setmetatable(export, {
    __call = function(_, ...)
        return Library.new(...)
    end
})

return export
