-- koffee v0.0.9
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.0.9"

--============================================================
-- THEME
--============================================================
local Theme = {
    Palette = {
        Background    = Color3.fromRGB(20, 16, 14),
        Panel         = Color3.fromRGB(30, 24, 21),
        PanelElevated = Color3.fromRGB(42, 34, 30),
        Pill          = Color3.fromRGB(50, 40, 34),
        Border        = Color3.fromRGB(47, 38, 33),
        BorderSubtle  = Color3.fromRGB(35, 28, 25),
        Text          = Color3.fromRGB(240, 232, 220),
        TextMuted     = Color3.fromRGB(138, 125, 112),
        TextFaint     = Color3.fromRGB(90, 82, 74),
        Accent        = Color3.fromRGB(212, 145, 90),
        Success       = Color3.fromRGB(127, 190, 143),
        Danger        = Color3.fromRGB(212, 106, 90),
        Snow          = Color3.fromRGB(255, 253, 248),
    },
    -- interface font. everything content-facing (module names, config text,
    -- etc.) will later get a user-selectable font from a small allowlist;
    -- this Ubuntu family is only for chrome (hud, tabs, toggles, toasts).
    Fonts = (function()
        local UI = "rbxasset://fonts/families/Ubuntu.json"
        local MONO = "rbxasset://fonts/families/RobotoMono.json"
        return {
            Regular = Font.new(UI,   Enum.FontWeight.Regular),
            Medium  = Font.new(UI,   Enum.FontWeight.Medium),
            Bold    = Font.new(UI,   Enum.FontWeight.Bold),
            Mono    = Font.new(MONO, Enum.FontWeight.Regular),
        }
    end)(),
    Sizes = {
        HudHeight    = 32,
        WindowWidth  = 620,
        WindowHeight = 460,
        TabBarHeight = 36,
    },
    Radius = { Small = 4, Medium = 6, Large = 8 },
    -- text sizes dropped 1pt across the board -- matcha-tight density
    Text   = { Tiny = 9, Small = 10, Body = 11, Header = 12, Title = 13 },
    Animation = {
        Fast       = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Normal     = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        -- pill: long pure ease-out per he. no ease-in curve, just decelerate.
        Pill       = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Slow       = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        WindowFade = TweenInfo.new(0.18, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    },
    Background = {
        DimTransparency  = 0.55,
        BlurSize         = 6,
        SnowflakeCount   = 70,
    },
}

--============================================================
-- SERVICES + UTIL
--============================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local function new(class, props, children)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do inst[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r or Theme.Radius.Medium) }) end
local function pillCorner() return new("UICorner", { CornerRadius = UDim.new(1, 0) }) end
local function stroke(color, thick)
    return new("UIStroke", {
        Color = color or Theme.Palette.Border,
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function colorToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

local function colorToRGB(c)
    return string.format("R %d  G %d  B %d",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

local function makeDraggable(handle, target)
    target = target or handle
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                       or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function guiParent()
    if gethui then return gethui() end
    local ok = pcall(function() return CoreGui.Name end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--============================================================
-- ROOT SCREEN
--============================================================
-- clean up stale koffee guis on re-execute
for _, g in ipairs(guiParent():GetChildren()) do
    if g.Name == "Koffee" then pcall(function() g:Destroy() end) end
end
for _, e in ipairs(Lighting:GetChildren()) do
    if e.Name == "KoffeeBlur" then pcall(function() e:Destroy() end) end
end

local screen = new("ScreenGui", {
    Name = "Koffee",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 2000000000,
    Parent = guiParent(),
})

--============================================================
-- BACKGROUND: dim + blur + snow (activates when window is open)
--============================================================
local dim = new("Frame", {
    Name = "Dim",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = screen,
})

local blur = new("BlurEffect", {
    Name = "KoffeeBlur",
    Size = 0,
    Parent = Lighting,
})

-- snow (Frame-based so it respects gui ZIndex and stays *under* the window)
local snowLayer = new("Frame", {
    Name = "Snow",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 5,
    Parent = screen,
})

local snowflakes = {}
local snowActive = false

local function viewport()
    return Camera.ViewportSize
end

-- each flake is a stack of 3 concentric circles for a soft radial edge,
-- with a per-flake DEPTH value (0=far, 1=close) driving size / speed / opacity /
-- sway. sorted into 3 ZIndex bands so closer flakes render on top.
local function newSnowflake()
    local vp = viewport()
    local depth = math.random()                     -- 0 = far, 1 = close
    local core  = 1.0 + depth * 2.5                 -- 1.0 - 3.5 px core diameter
    local sf = {
        depth     = depth,
        speedY    = 10 + depth * 42,                -- 10 - 52 px/sec (parallax)
        swayAmp   = 3 + depth * 12,                 -- 3 - 15 px
        swayFreq  = math.random(30, 90) / 100,
        swayPhase = math.random() * math.pi * 2,
        baseX     = math.random() * vp.X,
        y         = math.random() * vp.Y,
        alpha     = 0.28 + depth * 0.55,            -- 0.28 - 0.83
    }
    -- z-band: far flakes at ZIndex 3, close at ZIndex 7. still below window (30).
    local zBase = 3 + math.floor(depth * 3) * 2     -- 3, 5, or 7
    local wrap = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, core, 0, core),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zBase,
        Parent = snowLayer,
    })
    local function layer(mult, alphaMult, z)
        local f = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, core * mult, 0, core * mult),
            BackgroundColor3 = Theme.Palette.Snow,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = z,
            Parent = wrap,
        }, { pillCorner() })
        return { frame = f, alphaMult = alphaMult }
    end
    sf.wrap  = wrap
    sf.outer = layer(2.0, 0.12, zBase)
    sf.mid   = layer(1.4, 0.40, zBase + 1)
    sf.core  = layer(1.0, 1.00, zBase + 2)
    return sf
end

for i = 1, Theme.Background.SnowflakeCount do
    table.insert(snowflakes, newSnowflake())
end

local snowFade = 0  -- 0 = hidden, 1 = fully visible
local SNOW_FADE_SPEED = 1 / 0.18  -- match WindowFade duration -- linear ~5.5/s
RunService.RenderStepped:Connect(function(dt)
    local target = snowActive and 1 or 0
    if target > snowFade then
        snowFade = math.min(snowFade + dt * SNOW_FADE_SPEED, 1)
    elseif target < snowFade then
        snowFade = math.max(snowFade - dt * SNOW_FADE_SPEED, 0)
    end
    local vp = viewport()

    if snowFade < 0.01 then
        snowLayer.Visible = false
        return
    end
    snowLayer.Visible = true

    for _, sf in ipairs(snowflakes) do
        sf.swayPhase = sf.swayPhase + dt * sf.swayFreq
        sf.y = sf.y + sf.speedY * dt
        if sf.y > vp.Y + 8 then
            sf.y = -8
            sf.baseX = math.random() * vp.X
        end
        local x = sf.baseX + math.sin(sf.swayPhase) * sf.swayAmp
        sf.wrap.Position = UDim2.new(0, x, 0, sf.y)
        local visible = sf.alpha * snowFade
        sf.outer.frame.BackgroundTransparency = 1 - (visible * sf.outer.alphaMult)
        sf.mid.frame.BackgroundTransparency   = 1 - (visible * sf.mid.alphaMult)
        sf.core.frame.BackgroundTransparency  = 1 - (visible * sf.core.alphaMult)
    end
end)

local function setBackgroundActive(active)
    snowActive = active
    tween(dim, Theme.Animation.WindowFade, {
        BackgroundTransparency = active and (1 - Theme.Background.DimTransparency) or 1,
    })
    tween(blur, Theme.Animation.WindowFade, {
        Size = active and Theme.Background.BlurSize or 0,
    })
end

--============================================================
-- HUD STRIP (TOP)
--============================================================
local hud = new("Frame", {
    Name = "HUD",
    Size = UDim2.new(1, 0, 0, Theme.Sizes.HudHeight),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Theme.Palette.Background,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 20,
    Parent = screen,
}, {
    new("Frame", {
        Name = "BottomBorder",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme.Palette.BorderSubtle,
        BorderSizePixel = 0,
        ZIndex = 21,
    }),
})

-- left cluster: brand + stats widget
local hudLeft = new("Frame", {
    Name = "Left",
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 21,
    Parent = hud,
}, {
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 18),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    new("UIPadding", { PaddingLeft = UDim.new(0, 14) }),
})

new("TextLabel", {
    Name = "Brand",
    Text = "koffee",
    FontFace = Theme.Fonts.Bold,
    TextSize = Theme.Text.Title,
    TextColor3 = Theme.Palette.Accent,
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X,
    Size = UDim2.new(0, 0, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
    ZIndex = 22,
    Parent = hudLeft,
})

local statsWidget = new("Frame", {
    Name = "Stats",
    Size = UDim2.new(0, 260, 0, 22),
    BackgroundColor3 = Theme.Palette.Panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    ZIndex = 22,
    Parent = hudLeft,
}, {
    corner(Theme.Radius.Small),
    stroke(Theme.Palette.BorderSubtle),
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
    }),
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
})

local function statLabel(name, initial)
    return new("TextLabel", {
        Name = name,
        Text = initial,
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 23,
        Parent = statsWidget,
    })
end

local pingLabel = statLabel("Ping", "-- ms")
local fpsLabel  = statLabel("FPS",  "-- fps")
local timeLabel = statLabel("Time", "00:00:00")

-- right cluster: hotkeys widget
local hudRight = new("Frame", {
    Name = "Right",
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 21,
    Parent = hud,
}, {
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
    }),
    new("UIPadding", { PaddingRight = UDim.new(0, 14) }),
})

local hotkeysWidget = new("Frame", {
    Name = "Hotkeys",
    Size = UDim2.new(0, 200, 0, 22),
    BackgroundColor3 = Theme.Palette.Panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ZIndex = 22,
    Parent = hudRight,
}, {
    corner(Theme.Radius.Small),
    stroke(Theme.Palette.BorderSubtle),
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
    }),
})

local function hotkey(keyText, actionText)
    local wrap = new("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 23,
        Parent = hotkeysWidget,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
        }),
    })
    new("TextLabel", {
        Text = keyText,
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Accent,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 24,
        Parent = wrap,
    })
    new("TextLabel", {
        Text = actionText,
        FontFace = Theme.Fonts.Regular,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 24,
        Parent = wrap,
    })
end

-- top-right HUD only shows the menu key. Per-module keybinds are rebindable
-- via the pill next to each master toggle -- displaying them here would drift.
hotkey("del", "menu")

--============================================================
-- LIVE STATS
--============================================================
local uptimeStart = os.time()
local frameCount  = 0
local lastSample  = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastSample >= 0.5 then
        fpsLabel.Text = math.floor(frameCount / (now - lastSample) + 0.5) .. " fps"
        frameCount, lastSample = 0, now
    end
    local e = os.time() - uptimeStart
    timeLabel.Text = string.format("%02d:%02d:%02d",
        math.floor(e / 3600), math.floor((e % 3600) / 60), e % 60)
end)

task.spawn(function()
    while screen.Parent do
        local ok, p = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        pingLabel.Text = (ok and p or "--") .. " ms"
        task.wait(1)
    end
end)

--============================================================
-- MODULE SYSTEM + ACTIVE-MODULES TYPEWRITER ARRAY
--============================================================
-- markdown-blockquote-style module list:
--   |  ESP
--   |  Aimbot
-- vertical line on the left grows/shrinks smoothly with content,
-- each label fades in + settles up from a small y-offset.
local activeArray = new("Frame", {
    Name = "ActiveModules",
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.new(0, 16, 0, Theme.Sizes.HudHeight + 12),
    Size = UDim2.new(0, 240, 0, 300),
    BackgroundTransparency = 1,
    ZIndex = 15,
    Parent = screen,
})

local activeLine = new("Frame", {
    Name = "Line",
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.new(0, 0, 0, 2),
    Size = UDim2.new(0, 2, 0, 0),
    BackgroundColor3 = Theme.Palette.Snow,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 16,
    Parent = activeArray,
}, { pillCorner() })

local labelsColumn = new("Frame", {
    Name = "Labels",
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -12, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 16,
    Parent = activeArray,
})

local labelsLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Parent = labelsColumn,
})

-- line height tracks the labels column's actual content size
labelsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local h = labelsLayout.AbsoluteContentSize.Y
    tween(activeLine, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 2, 0, h),
    })
end)

local Modules = {}
local nextLayoutOrder = 0
local ROW_HEIGHT = 20
local ROW_ENTER = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function addToActiveArray(mod)
    nextLayoutOrder = nextLayoutOrder + 1
    -- wrapper is managed by UIListLayout; label inside is what we animate,
    -- so ListLayout doesn't fight us on Position.
    local wrapper = new("Frame", {
        Name = mod.Id,
        Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
        BackgroundTransparency = 1,
        LayoutOrder = nextLayoutOrder,
        ZIndex = 17,
        Parent = labelsColumn,
    })
    local label = new("TextLabel", {
        Text = mod.DisplayName,
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, -10, 0, 0),  -- start slightly to the left, slide in right
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 18,
        Parent = wrapper,
    })
    tween(label, ROW_ENTER, {
        Position = UDim2.new(0, 0, 0, 0),
        TextTransparency = 0,
    })
    mod._wrapper = wrapper
end

local function removeFromActiveArray(mod)
    if not mod._wrapper then return end
    local w = mod._wrapper
    mod._wrapper = nil
    for _, child in ipairs(w:GetChildren()) do
        if child:IsA("TextLabel") then
            tween(child, Theme.Animation.Fast, {
                TextTransparency = 1,
                Position = UDim2.new(0, -10, 0, 0),  -- slide back left on remove
            })
        end
    end
    task.delay(0.14, function()
        if w and w.Parent then w:Destroy() end
    end)
end

local function registerModule(id, displayName, onEnable, onDisable)
    Modules[id] = {
        Id = id,
        DisplayName = displayName,
        Enabled = false,
        OnEnable = onEnable,
        OnDisable = onDisable,
    }
    return Modules[id]
end

local function toggleModule(id)
    local m = Modules[id]
    if not m then return end
    m.Enabled = not m.Enabled
    if m.Enabled then
        local ok, err = pcall(m.OnEnable)
        if not ok then warn("[koffee] " .. id .. " enable failed: " .. tostring(err)) end
        addToActiveArray(m)
    else
        local ok, err = pcall(m.OnDisable)
        if not ok then warn("[koffee] " .. id .. " disable failed: " .. tostring(err)) end
        removeFromActiveArray(m)
    end
end

--============================================================
-- MAIN WINDOW
--============================================================
-- CanvasGroup so GroupTransparency can fade every child in one shot
-- (frame trees have no group opacity; per-child tweening every label +
--  stroke + corner is a nightmare).
local window = new("CanvasGroup", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, Theme.Sizes.WindowWidth, 0, Theme.Sizes.WindowHeight),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.Palette.Background,
    BorderSizePixel = 0,
    GroupTransparency = 0,
    ZIndex = 30,
    Parent = screen,
}, {
    corner(Theme.Radius.Large),
    stroke(Theme.Palette.Border),
})

local titleBar = new("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundTransparency = 1,
    ZIndex = 31,
    Parent = window,
}, {
    new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
})

new("TextLabel", {
    Text = "koffee",
    FontFace = Theme.Fonts.Medium,
    TextSize = Theme.Text.Header,
    TextColor3 = Theme.Palette.Text,
    BackgroundTransparency = 1,
    Size = UDim2.new(0.5, 0, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 32,
    Parent = titleBar,
})

new("TextLabel", {
    Text = "v" .. Koffee.Version,
    FontFace = Theme.Fonts.Mono,
    TextSize = Theme.Text.Small,
    TextColor3 = Theme.Palette.TextFaint,
    BackgroundTransparency = 1,
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 32,
    Parent = titleBar,
})

makeDraggable(titleBar, window)

-- tab bar with sliding pill
local tabBar = new("Frame", {
    Name = "TabBar",
    Size = UDim2.new(1, 0, 0, Theme.Sizes.TabBarHeight),
    Position = UDim2.new(0, 0, 0, 34),
    BackgroundTransparency = 1,
    ZIndex = 31,
    Parent = window,
}, {
    new("Frame", {
        Name = "BottomBorder",
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 1, -1),
        BackgroundColor3 = Theme.Palette.BorderSubtle,
        BorderSizePixel = 0,
        ZIndex = 32,
    }),
})

-- pill layer (behind buttons)
local pillLayer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 32,
    Parent = tabBar,
})

local pill = new("Frame", {
    Name = "Pill",
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Theme.Palette.Pill,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 32,
    Parent = pillLayer,
}, { pillCorner() })

-- button layer (in front of pill)
local buttonLayer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 33,
    Parent = tabBar,
}, {
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,  -- some runtimes default to Name; be explicit
    }),
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 6),
    }),
})

local content = new("Frame", {
    Name = "Content",
    Size = UDim2.new(1, 0, 1, -(34 + Theme.Sizes.TabBarHeight)),
    Position = UDim2.new(0, 0, 0, 34 + Theme.Sizes.TabBarHeight),
    BackgroundTransparency = 1,
    ZIndex = 31,
    Parent = window,
}, {
    new("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    }),
})

local tabs = {}
local tabOrder = 0        -- explicit LayoutOrder per tab
local activeTab = nil
local pillFirstShow = true

local function movePillTo(button, snap)
    local relX = button.AbsolutePosition.X - tabBar.AbsolutePosition.X
    local relY = button.AbsolutePosition.Y - tabBar.AbsolutePosition.Y
    local targetPos  = UDim2.new(0, relX, 0, relY)
    local targetSize = UDim2.new(0, button.AbsoluteSize.X, 0, button.AbsoluteSize.Y)
    if pillFirstShow or snap then
        pill.Position = targetPos
        pill.Size = targetSize
        if pillFirstShow then
            tween(pill, Theme.Animation.Normal, { BackgroundTransparency = 0 })
            pillFirstShow = false
        end
    else
        tween(pill, Theme.Animation.Pill, { Position = targetPos, Size = targetSize })
    end
end

-- reposition pill instantly whenever the tabBar moves (window drag, resize).
-- also acts as belt-and-suspenders on first-load: as soon as tabBar has a real
-- AbsolutePosition, this fires and snaps the pill onto the active tab.
tabBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if not activeTab then return end
    local tab = tabs[activeTab]
    if tab then movePillTo(tab.Button, true) end
end)

local function selectTab(name)
    if activeTab == name then return end
    activeTab = name
    for tabName, tab in pairs(tabs) do
        local isActive = tabName == name
        tween(tab.Button, Theme.Animation.Fast, {
            TextColor3 = isActive and Theme.Palette.Text or Theme.Palette.TextMuted,
        })
        tab.Panel.Visible = isActive
        if isActive then movePillTo(tab.Button) end
    end
end

local function addTab(name, buildFn)
    tabOrder = tabOrder + 1
    local button = new("TextButton", {
        Name = name,
        Text = name:lower(),
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        AutoButtonColor = false,
        LayoutOrder = tabOrder,
        ZIndex = 34,
        Parent = buttonLayer,
    }, {
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }),
    })

    local panel = new("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 32,
        Parent = content,
    })

    if buildFn then
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = panel,
        })
        buildFn(panel)
    else
        new("TextLabel", {
            Text = name:lower() .. " -- coming soon",
            FontFace = Theme.Fonts.Regular,
            TextSize = Theme.Text.Body,
            TextColor3 = Theme.Palette.TextFaint,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 33,
            Parent = panel,
        })
    end

    button.MouseEnter:Connect(function()
        if activeTab ~= name then
            tween(button, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text })
        end
    end)
    button.MouseLeave:Connect(function()
        if activeTab ~= name then
            tween(button, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        end
    end)
    button.MouseButton1Click:Connect(function() selectTab(name) end)

    tabs[name] = { Button = button, Panel = panel }
end

--============================================================
-- PANEL / CARD (grouped rounded container with optional title)
-- Matcha groups related controls in cards inside tab content.
-- Card auto-sizes vertically to fit its rows.
--============================================================
local function panel(parent, title)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 33,
        Parent = parent,
    }, {
        corner(Theme.Radius.Medium),
        stroke(Theme.Palette.BorderSubtle),
        new("UIPadding", {
            PaddingTop    = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft   = UDim.new(0, 14),
            PaddingRight  = UDim.new(0, 14),
        }),
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    if title then
        new("TextLabel", {
            Text = title,
            FontFace = Theme.Fonts.Medium,
            TextSize = Theme.Text.Body,
            TextColor3 = Theme.Palette.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = -1,   -- always first
            ZIndex = 34,
            Parent = card,
        })
        new("Frame", {  -- small spacer below the title
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Parent = card,
        })
    end
    return card
end

--============================================================
-- HOVER helper: adds a subtle background overlay that fades in/out
-- when the target's TextButton child is hovered. Idempotent per row.
--============================================================
local function attachHover(row, hoverBtn)
    local bg = new("Frame", {
        Name = "HoverBg",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 8, 1, 4),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 33,
        Parent = row,
    }, { corner(4) })
    hoverBtn.MouseEnter:Connect(function()
        tween(bg, Theme.Animation.Fast, { BackgroundTransparency = 0.85 })
    end)
    hoverBtn.MouseLeave:Connect(function()
        tween(bg, Theme.Animation.Fast, { BackgroundTransparency = 1 })
    end)
end

--============================================================
-- CHECKBOX (visual primitive shared by module + config variants)
-- Matcha-style: outer square with a thin border always visible + inset
-- accent fill that fades in when checked. Label goes accent-colored when on.
-- Row includes a hover overlay so users see it's interactable.
--============================================================
local CHECKBOX_ROW_HEIGHT = 18
local CHECKBOX_OUTER = 15
local CHECKBOX_INNER = 9
local CHECKBOX_LABEL_OFFSET = 24
local CHECKBOX_RIGHT_RESERVE = 70   -- space reserved on right for pill/swatches

local function checkboxVisual(parent, label, initialOn)
    local state = initialOn and true or false
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, CHECKBOX_ROW_HEIGHT),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    -- outer box: transparent, thin border always visible
    local box = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, CHECKBOX_OUTER, 0, CHECKBOX_OUTER),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 35,
        Parent = row,
    }, {
        corner(3),
        stroke(state and Theme.Palette.Accent or Theme.Palette.Border, 1),
    })
    -- inner fill: centered inside the outer box with a gap
    local innerFill = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, CHECKBOX_INNER, 0, CHECKBOX_INNER),
        BackgroundColor3 = Theme.Palette.Accent,
        BackgroundTransparency = state and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = box,
    }, { corner(2) })
    local lbl = new("TextLabel", {
        Text = label,
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = state and Theme.Palette.Accent or Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, CHECKBOX_LABEL_OFFSET, 0, 0),
        Size = UDim2.new(1, -CHECKBOX_LABEL_OFFSET - CHECKBOX_RIGHT_RESERVE, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 35,
        Parent = row,
    })
    -- click-catcher covers box + label area, LEAVES the right-reserve free
    -- so keybind pill / color swatches inside it stay interactable.
    local btn = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -CHECKBOX_RIGHT_RESERVE, 1, 0),
        ZIndex = 37,
        AutoButtonColor = false,
        Parent = row,
    })
    attachHover(row, btn)
    local function applyState()
        local strokeInst = box:FindFirstChildOfClass("UIStroke")
        tween(innerFill, Theme.Animation.Fast, {
            BackgroundTransparency = state and 0 or 1,
        })
        if strokeInst then
            tween(strokeInst, Theme.Animation.Fast, {
                Color = state and Theme.Palette.Accent or Theme.Palette.Border,
            })
        end
        tween(lbl, Theme.Animation.Fast, {
            TextColor3 = state and Theme.Palette.Accent or Theme.Palette.Text,
        })
    end
    return {
        row = row,
        button = btn,
        setState = function(newState)
            state = newState and true or false
            applyState()
        end,
        getState = function() return state end,
    }
end

local function moduleCheckbox(parent, label, moduleId)
    local mod = Modules[moduleId]
    local ctrl = checkboxVisual(parent, label, mod and mod.Enabled or false)
    ctrl.button.MouseButton1Click:Connect(function()
        toggleModule(moduleId)
        ctrl.setState(Modules[moduleId] and Modules[moduleId].Enabled)
    end)
    return ctrl
end

local function configCheckbox(parent, label, initialOn, onChange)
    local ctrl = checkboxVisual(parent, label, initialOn)
    ctrl.button.MouseButton1Click:Connect(function()
        local newState = not ctrl.getState()
        ctrl.setState(newState)
        if onChange then onChange(newState) end
    end)
    return ctrl
end

--============================================================
-- KEYBIND SYSTEM + KEYBIND PILL
-- Keybinds table maps moduleId -> KeyCode. InputBegan at bottom of file
-- reads it. Pill widget shows current key + click-to-rebind flow.
--============================================================
local Keybinds = {}     -- moduleId -> Enum.KeyCode
local pendingRebind = nil    -- { moduleId, pill } while waiting for next key

local function keybindPill(row, moduleId, initialKey)
    if initialKey then Keybinds[moduleId] = initialKey end
    local currentKey = Keybinds[moduleId]
    local pill = new("TextButton", {
        Name = "KeybindPill",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 34, 0, 15),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = currentKey and currentKey.Name or "-",
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Tiny,
        TextColor3 = Theme.Palette.TextMuted,
        ZIndex = 38,
        Parent = row,
    }, { pillCorner(), stroke(Theme.Palette.BorderSubtle) })
    pill.MouseEnter:Connect(function()
        tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text })
    end)
    pill.MouseLeave:Connect(function()
        if not (pendingRebind and pendingRebind.moduleId == moduleId) then
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        end
    end)
    pill.MouseButton1Click:Connect(function()
        pill.Text = "..."
        tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Accent })
        pendingRebind = { moduleId = moduleId, pill = pill }
    end)
    return pill
end

-- called from InputBegan when a rebind is pending
local function completeRebind(keyCode)
    if not pendingRebind then return end
    local moduleId = pendingRebind.moduleId
    local pill = pendingRebind.pill
    Keybinds[moduleId] = keyCode
    pill.Text = keyCode.Name
    -- growing pulse animation
    local origSize = pill.Size
    pill.Size = UDim2.new(0, origSize.X.Offset + 8, 0, origSize.Y.Offset + 4)
    tween(pill, Theme.Animation.Normal, { Size = origSize, TextColor3 = Theme.Palette.TextMuted })
    pendingRebind = nil
end

--============================================================
-- COLOR SWATCH with hover-preview tooltip (hex + rgb)
-- No color picker yet -- clicking is a no-op for now, hover only.
--============================================================
local function colorSwatch(parent, initialColor, size)
    size = size or 14
    local sw = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = initialColor,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = parent,
    }, { corner(3), stroke(Theme.Palette.Border, 1) })

    -- tooltip appears above the swatch on hover
    local tip = new("Frame", {
        Name = "Tooltip",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -8),
        Size = UDim2.new(0, 132, 0, 34),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 100,
        Parent = sw,
    }, { corner(4), stroke(Theme.Palette.Border) })
    local chip = new("Frame", {
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.new(0, 26, 1, -8),
        BackgroundColor3 = initialColor,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = tip,
    }, { corner(3) })
    local hexLbl = new("TextLabel", {
        Text = colorToHex(initialColor),
        FontFace = Theme.Fonts.Bold,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, 4),
        Size = UDim2.new(1, -40, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
        Parent = tip,
    })
    local rgbLbl = new("TextLabel", {
        Text = colorToRGB(initialColor),
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Tiny,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, 18),
        Size = UDim2.new(1, -40, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
        Parent = tip,
    })
    sw.MouseEnter:Connect(function() tip.Visible = true end)
    sw.MouseLeave:Connect(function() tip.Visible = false end)

    local api
    api = {
        instance = sw,
        setColor = function(c)
            sw.BackgroundColor3 = c
            chip.BackgroundColor3 = c
            hexLbl.Text = colorToHex(c)
            rgbLbl.Text = colorToRGB(c)
        end,
    }
    return api
end

--============================================================
-- DROPDOWN (label above + button that opens option list below)
-- Simple round-1 impl: no scroll, no search, click-outside-to-close is
-- handled by re-clicking the button. Options are a flat string list.
--============================================================
local openDropdowns = {}  -- track any open lists so we can close others on new open

local function dropdown(parent, label, options, initial, onChange)
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    new("TextLabel", {
        Text = label,
        FontFace = Theme.Fonts.Regular,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
        Parent = wrap,
    })
    local btn = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 35,
        Parent = wrap,
    }, { corner(4), stroke(Theme.Palette.BorderSubtle) })
    local valueLbl = new("TextLabel", {
        Text = initial or options[1] or "",
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 36,
        Parent = btn,
    })
    local caret = new("TextLabel", {
        Text = "v",
        FontFace = Theme.Fonts.Bold,
        TextSize = Theme.Text.Tiny,
        TextColor3 = Theme.Palette.TextMuted,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 12, 1, 0),
        ZIndex = 36,
        Parent = btn,
    })
    local list = new("Frame", {
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, #options * 20),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 80,
        Parent = btn,
    }, { corner(4), stroke(Theme.Palette.Border) })
    for i, opt in ipairs(options) do
        local optBtn = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, (i - 1) * 20),
            BackgroundColor3 = Theme.Palette.PanelElevated,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 81,
            Parent = list,
        })
        new("TextLabel", {
            Text = opt,
            FontFace = Theme.Fonts.Medium,
            TextSize = Theme.Text.Small,
            TextColor3 = Theme.Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 82,
            Parent = optBtn,
        })
        optBtn.MouseEnter:Connect(function()
            tween(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 0.85 })
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 1 })
        end)
        optBtn.MouseButton1Click:Connect(function()
            valueLbl.Text = opt
            list.Visible = false
            tween(caret, Theme.Animation.Fast, { Rotation = 0 })
            if onChange then onChange(opt) end
        end)
    end
    btn.MouseButton1Click:Connect(function()
        -- close any other open list
        for other, _ in pairs(openDropdowns) do
            if other ~= list then other.Visible = false end
        end
        list.Visible = not list.Visible
        openDropdowns[list] = list.Visible or nil
        tween(caret, Theme.Animation.Fast, { Rotation = list.Visible and 180 or 0 })
    end)
    return { setValue = function(v) valueLbl.Text = v end }
end

--============================================================
-- SLIDER (matcha-style: value in the header, thin track, small knob)
-- Value label doubles as a click-to-edit TextBox for precise input.
-- onChange fires live while dragging AND on textbox commit.
--============================================================
local function slider(parent, label, min, max, initial, precision, onChange)
    precision = precision or 0
    local function round(v)
        local m = 10 ^ precision
        return math.floor(v * m + 0.5) / m
    end
    local current = round(math.clamp(initial, min, max))
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    new("TextLabel", {
        Text = label,
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -80, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
        Parent = row,
    })
    -- value is a TextBox so clicking makes it directly editable
    local valueBox = new("TextBox", {
        Text = tostring(current),
        PlaceholderText = "",
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 80, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
        ZIndex = 38,
        Parent = row,
    })
    local track = new("Frame", {
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BorderSizePixel = 0,
        ZIndex = 34,
        Parent = row,
    }, { pillCorner() })
    local startPct = (current - min) / (max - min)
    local fill = new("Frame", {
        Size = UDim2.new(startPct, 0, 1, 0),
        BackgroundColor3 = Theme.Palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 35,
        Parent = track,
    }, { pillCorner() })
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(startPct, 0, 0.5, 0),
        Size = UDim2.new(0, 9, 0, 9),
        BackgroundColor3 = Theme.Palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = track,
    }, { pillCorner() })
    local hitArea = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(1, -84, 0, 14),   -- leave value box clickable
        ZIndex = 37,
        Parent = row,
    })
    local dragging = false

    local function applyValue()
        local pct = (current - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueBox.Text = tostring(current)
        if onChange then onChange(current) end
    end
    local function setFromInputX(inputX)
        local trackAbs = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        if trackW <= 0 then return end
        local pct = math.clamp((inputX - trackAbs) / trackW, 0, 1)
        current = round(min + (max - min) * pct)
        applyValue()
    end
    hitArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromInputX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging
        and (input.UserInputType == Enum.UserInputType.MouseMovement
          or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInputX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    valueBox.FocusLost:Connect(function(enterPressed)
        local n = tonumber(valueBox.Text)
        if n then
            current = round(math.clamp(n, min, max))
        end
        applyValue()
    end)
    -- hover feedback on the value box
    valueBox.MouseEnter:Connect(function()
        tween(valueBox, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Accent })
    end)
    valueBox.MouseLeave:Connect(function()
        tween(valueBox, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text })
    end)
end

--============================================================
-- ESP MODULE (v0.0.9 expansion)
-- Config:
--   TeamCheck      -- hide teammates (respects Player.Team)
--   VisibleCheck   -- (flag stored; raycast-based occlusion coloring TBD)
--   TeamBasedColor -- teammates in green, enemies in accent (chams color)
--   TextBackground -- dark box behind name/distance text
--   Outline        -- Highlight OutlineTransparency 0<->1
--   Glow           -- softer text stroke fake-glow
--   SelfESP        -- also apply to LocalPlayer
--   SizingType     -- "Bounding"|"Static"|"Prediction" (flag stored; Box ESP TBD)
--   RenderDistance -- hide beyond N studs (real optimization, not just visual)
-- Colors:
--   Visible / Hidden / Team -- exposed for future color picker
--============================================================
local ESP = {
    Config = {
        TeamCheck      = false,
        VisibleCheck   = false,
        TeamBasedColor = false,
        TextBackground = false,
        Outline        = true,
        Glow           = false,
        SelfESP        = false,
        SizingType     = "Bounding",
        RenderDistance = 1000,
    },
    Colors = {
        Visible = Color3.fromRGB(212, 145, 90),
        Hidden  = Color3.fromRGB(120, 120, 120),
        Team    = Color3.fromRGB(127, 190, 143),
    },
    Connections = {},
    Rigs = {},
    UpdateConn = nil,
}

local function makeRig(plr, character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 3)
    if not head then return nil end

    local hl = Instance.new("Highlight")
    hl.Name = "KoffeeESP"
    hl.FillColor = ESP.Colors.Visible
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = ESP.Config.Outline and 0 or 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = character
    hl.Parent = character

    local bb = Instance.new("BillboardGui")
    bb.Name = "KoffeeName"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 180, 0, 52)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 5000
    bb.Parent = head

    -- text background (Text Background toggle)
    local textBg = Instance.new("Frame")
    textBg.Name = "TextBg"
    textBg.AnchorPoint = Vector2.new(0.5, 0)
    textBg.Position = UDim2.new(0.5, 0, 0, -1)
    textBg.Size = UDim2.new(0, 100, 0, 32)
    textBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textBg.BackgroundTransparency = 0.5
    textBg.BorderSizePixel = 0
    textBg.Visible = ESP.Config.TextBackground
    textBg.ZIndex = 1
    textBg.Parent = bb
    local tbCorner = Instance.new("UICorner", textBg)
    tbCorner.CornerRadius = UDim.new(0, 3)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "Name"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Position = UDim2.new(0, 0, 0, 0)
    nameLbl.FontFace = Theme.Fonts.Medium
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = ESP.Colors.Visible
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.Text = plr.Name
    nameLbl.ZIndex = 2
    nameLbl.Parent = bb

    local distLbl = Instance.new("TextLabel")
    distLbl.Name = "Distance"
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, 0, 0, 12)
    distLbl.Position = UDim2.new(0, 0, 0, 17)
    distLbl.FontFace = Theme.Fonts.Mono
    distLbl.TextSize = 9
    distLbl.TextColor3 = Theme.Palette.TextMuted
    distLbl.TextStrokeTransparency = 0.6
    distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLbl.Text = "-- studs"
    distLbl.ZIndex = 2
    distLbl.Parent = bb

    local healthWrap = Instance.new("Frame")
    healthWrap.Name = "HealthWrap"
    healthWrap.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
    healthWrap.BackgroundTransparency = 0.35
    healthWrap.BorderSizePixel = 0
    healthWrap.AnchorPoint = Vector2.new(0.5, 0)
    healthWrap.Position = UDim2.new(0.5, 0, 0, 34)
    healthWrap.Size = UDim2.new(0.75, 0, 0, 3)
    healthWrap.ZIndex = 2
    healthWrap.Parent = bb
    local wCorner = Instance.new("UICorner", healthWrap)
    wCorner.CornerRadius = UDim.new(1, 0)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.BackgroundColor3 = Theme.Palette.Success
    healthFill.BorderSizePixel = 0
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.ZIndex = 3
    healthFill.Parent = healthWrap
    local fCorner = Instance.new("UICorner", healthFill)
    fCorner.CornerRadius = UDim.new(1, 0)

    return {
        character = character,
        head      = head,
        plr       = plr,
        hl        = hl,
        bb        = bb,
        nameLbl   = nameLbl,
        distLbl   = distLbl,
        healthWrap = healthWrap,
        healthFill = healthFill,
        textBg    = textBg,
    }
end

local function cleanRig(rig)
    if not rig then return end
    pcall(function() rig.hl:Destroy() end)
    pcall(function() rig.bb:Destroy() end)
end

-- Self ESP: LocalPlayer now allowed, gating happens in updateESPRigs.
local function applyESP(plr)
    if ESP.Rigs[plr] then return end
    local function attach(character)
        if not character then return end
        pcall(function()
            local old = character:FindFirstChild("KoffeeESP")
            if old then old:Destroy() end
        end)
        local rig = makeRig(plr, character)
        if rig then
            ESP.Rigs[plr].rig = rig
        end
    end
    ESP.Rigs[plr] = { conn = plr.CharacterAdded:Connect(attach) }
    if plr.Character then attach(plr.Character) end
end

local function stripESP(plr)
    local entry = ESP.Rigs[plr]
    if not entry then return end
    if entry.conn then entry.conn:Disconnect() end
    cleanRig(entry.rig)
    ESP.Rigs[plr] = nil
end

local function updateESPRigs()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local localTeam = LocalPlayer.Team
    for plr, entry in pairs(ESP.Rigs) do
        local rig = entry.rig
        if not (rig and rig.head and rig.head.Parent) then continue end

        -- Self ESP gate
        if plr == LocalPlayer and not ESP.Config.SelfESP then
            rig.hl.Enabled = false
            rig.bb.Enabled = false
            continue
        end

        -- Team check
        local sameTeam = plr.Team and localTeam and plr.Team == localTeam
        if sameTeam and ESP.Config.TeamCheck then
            rig.hl.Enabled = false
            rig.bb.Enabled = false
            continue
        end

        -- Render distance (real optimization -- hides + skips rest of work)
        local dist = (rig.head.Position - camPos).Magnitude
        if dist > ESP.Config.RenderDistance then
            rig.hl.Enabled = false
            rig.bb.Enabled = false
            continue
        end

        rig.hl.Enabled = true
        rig.bb.Enabled = true

        -- Color selection
        local color = ESP.Colors.Visible
        if ESP.Config.TeamBasedColor and sameTeam then
            color = ESP.Colors.Team
        end
        rig.hl.FillColor = color
        rig.nameLbl.TextColor3 = color

        -- Outline
        rig.hl.OutlineTransparency = ESP.Config.Outline and 0 or 1

        -- Glow (softer text stroke)
        if ESP.Config.Glow then
            rig.nameLbl.TextStrokeTransparency = 0.15
            rig.distLbl.TextStrokeTransparency = 0.25
        else
            rig.nameLbl.TextStrokeTransparency = 0.4
            rig.distLbl.TextStrokeTransparency = 0.6
        end

        -- Text background
        rig.textBg.Visible = ESP.Config.TextBackground

        -- Distance
        rig.distLbl.Text = math.floor(dist + 0.5) .. " studs"

        -- Health
        local hum = rig.character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            rig.healthFill.Size = UDim2.new(pct, 0, 1, 0)
            rig.healthFill.BackgroundColor3 =
                pct > 0.55 and Theme.Palette.Success
                or (pct > 0.25 and Color3.fromRGB(220, 180, 100) or Theme.Palette.Danger)
            rig.healthWrap.Visible = true
        else
            rig.healthWrap.Visible = false
        end
    end
end

registerModule("esp", "ESP",
    function()
        for _, plr in ipairs(Players:GetPlayers()) do applyESP(plr) end
        table.insert(ESP.Connections, Players.PlayerAdded:Connect(applyESP))
        table.insert(ESP.Connections, Players.PlayerRemoving:Connect(stripESP))
        ESP.UpdateConn = RunService.RenderStepped:Connect(updateESPRigs)
    end,
    function()
        for _, c in ipairs(ESP.Connections) do c:Disconnect() end
        table.clear(ESP.Connections)
        if ESP.UpdateConn then ESP.UpdateConn:Disconnect() ESP.UpdateConn = nil end
        for _, plr in ipairs(Players:GetPlayers()) do stripESP(plr) end
    end
)

--============================================================
-- WORLD MODULES: fullbright, no fog, custom time
-- Each module saves the original Lighting values on enable and restores on disable.
-- Custom Time additionally installs a Heartbeat that re-asserts ClockTime so
-- server-side day/night cycles can't fight us.
--============================================================
local World = {
    Fullbright = { Saved = nil },
    NoFog      = { Saved = nil },
    Time       = { Saved = nil, Target = 14, Conn = nil },
}

registerModule("fullbright", "Fullbright",
    function()
        World.Fullbright.Saved = {
            Ambient           = Lighting.Ambient,
            OutdoorAmbient    = Lighting.OutdoorAmbient,
            ColorShift_Top    = Lighting.ColorShift_Top,
            ColorShift_Bottom = Lighting.ColorShift_Bottom,
            Brightness        = Lighting.Brightness,
            GlobalShadows     = Lighting.GlobalShadows,
        }
        Lighting.Ambient           = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient    = Color3.fromRGB(178, 178, 178)
        Lighting.ColorShift_Top    = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness        = 1
        Lighting.GlobalShadows     = false
    end,
    function()
        local s = World.Fullbright.Saved
        if not s then return end
        Lighting.Ambient           = s.Ambient
        Lighting.OutdoorAmbient    = s.OutdoorAmbient
        Lighting.ColorShift_Top    = s.ColorShift_Top
        Lighting.ColorShift_Bottom = s.ColorShift_Bottom
        Lighting.Brightness        = s.Brightness
        Lighting.GlobalShadows     = s.GlobalShadows
        World.Fullbright.Saved     = nil
    end
)

registerModule("nofog", "No Fog",
    function()
        World.NoFog.Saved = {
            FogEnd   = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
        }
        Lighting.FogEnd   = 100000
        Lighting.FogStart = 100000
    end,
    function()
        local s = World.NoFog.Saved
        if not s then return end
        Lighting.FogEnd   = s.FogEnd
        Lighting.FogStart = s.FogStart
        World.NoFog.Saved = nil
    end
)

registerModule("customtime", "Custom Time",
    function()
        World.Time.Saved = { ClockTime = Lighting.ClockTime }
        Lighting.ClockTime = World.Time.Target
        World.Time.Conn = RunService.Heartbeat:Connect(function()
            if math.abs(Lighting.ClockTime - World.Time.Target) > 0.01 then
                Lighting.ClockTime = World.Time.Target
            end
        end)
    end,
    function()
        if World.Time.Conn then World.Time.Conn:Disconnect() World.Time.Conn = nil end
        local s = World.Time.Saved
        if s then
            Lighting.ClockTime = s.ClockTime
            World.Time.Saved = nil
        end
    end
)

--============================================================
-- TABS: build panels
--============================================================
-- tab order (per he): combat visuals world character options configs npc teams
addTab("Combat")

addTab("Visuals", function(root)
    local espPanel = panel(root, "esp")

    -- master toggle with rebindable keybind pill
    local master = moduleCheckbox(espPanel, "Enabled", "esp")
    keybindPill(master.row, "esp", Enum.KeyCode.E)

    configCheckbox(espPanel, "Team Check",       ESP.Config.TeamCheck,      function(v) ESP.Config.TeamCheck      = v end)

    -- Visible Check row: two color swatches on the right (visible / hidden)
    local visRow = configCheckbox(espPanel, "Visible Check", ESP.Config.VisibleCheck, function(v) ESP.Config.VisibleCheck = v end)
    local swatchWrap = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 34, 0, 14),
        BackgroundTransparency = 1,
        ZIndex = 38,
        Parent = visRow.row,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    colorSwatch(swatchWrap, ESP.Colors.Visible, 14)
    colorSwatch(swatchWrap, ESP.Colors.Hidden,  14)

    configCheckbox(espPanel, "Team Based Color", ESP.Config.TeamBasedColor, function(v) ESP.Config.TeamBasedColor = v end)
    configCheckbox(espPanel, "Text Background",  ESP.Config.TextBackground, function(v) ESP.Config.TextBackground = v end)
    configCheckbox(espPanel, "Outline",          ESP.Config.Outline,        function(v) ESP.Config.Outline        = v end)
    configCheckbox(espPanel, "Glow",             ESP.Config.Glow,           function(v) ESP.Config.Glow           = v end)
    configCheckbox(espPanel, "Self ESP",         ESP.Config.SelfESP,        function(v) ESP.Config.SelfESP        = v end)

    dropdown(espPanel, "Sizing Type", { "Bounding", "Static", "Prediction" }, ESP.Config.SizingType,
        function(v) ESP.Config.SizingType = v end)

    slider(espPanel, "Render Distance", 1, 30000, ESP.Config.RenderDistance, 0,
        function(v) ESP.Config.RenderDistance = v end)
end)

addTab("World", function(root)
    local lighting = panel(root, "world lighting")
    moduleCheckbox(lighting, "Fullbright",  "fullbright")
    moduleCheckbox(lighting, "No Fog",      "nofog")
    moduleCheckbox(lighting, "Custom Time", "customtime")
    slider(lighting, "Clock Time", 0, 24, World.Time.Target, 1, function(v)
        World.Time.Target = v
        if Modules.customtime and Modules.customtime.Enabled then
            Lighting.ClockTime = v
        end
    end)
end)

addTab("Character")
addTab("Options")
addTab("Configs")
addTab("NPC")
addTab("Teams")

-- select first tab AFTER layout AND positioning have settled.
-- v0.0.5 only checked AbsoluteSize -- but AbsolutePosition can still be zero
-- for a frame or two after that, which put the pill at (0,0) on first launch.
-- also, the tabBar AbsolutePosition signal above will re-snap once it moves.
task.spawn(function()
    local btn = tabs.Visuals.Button
    for _ = 1, 240 do
        local bp = btn.AbsolutePosition
        local bs = btn.AbsoluteSize
        local tp = tabBar.AbsolutePosition
        if bs.X > 0 and (bp.X ~= 0 or bp.Y ~= 0) and (tp.X ~= 0 or tp.Y ~= 0) then
            break
        end
        RunService.RenderStepped:Wait()
    end
    selectTab("Visuals")
end)

--============================================================
-- SESSION TOAST (BOTTOM-RIGHT)
--============================================================
local toast = new("Frame", {
    Name = "SessionToast",
    AnchorPoint = Vector2.new(1, 1),
    Size = UDim2.new(0, 260, 0, 46),
    Position = UDim2.new(1, -12, 1, -12),
    BackgroundColor3 = Theme.Palette.Panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ZIndex = 20,
    Parent = screen,
}, {
    corner(Theme.Radius.Medium),
    stroke(Theme.Palette.BorderSubtle),
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 8),
    }),
})

new("TextLabel", {
    Text = "session validated",
    FontFace = Theme.Fonts.Medium,
    TextSize = Theme.Text.Body,
    TextColor3 = Theme.Palette.Success,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
    Parent = toast,
})

new("TextLabel", {
    Text = "do not attempt to crack koffee or share credentials",
    FontFace = Theme.Fonts.Regular,
    TextSize = Theme.Text.Small,
    TextColor3 = Theme.Palette.TextMuted,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 16),
    Size = UDim2.new(1, 0, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
    Parent = toast,
})

--============================================================
-- WINDOW TOGGLE + BACKGROUND SYNC
-- Delete key toggles. Everything (window + snow + dim + blur) fades
-- with the same linear timing so they leave together, cleanly.
--============================================================
local windowOpen = true

local function setWindowOpen(open)
    if windowOpen == open then return end
    windowOpen = open
    if open then
        window.Visible = true
        window.GroupTransparency = 1
        tween(window, Theme.Animation.WindowFade, { GroupTransparency = 0 })
    else
        tween(window, Theme.Animation.WindowFade, { GroupTransparency = 1 })
        task.delay(0.2, function()
            if not windowOpen then window.Visible = false end
        end)
    end
    setBackgroundActive(open)
end

-- initial state
window.GroupTransparency = 0
window.Visible = true
setBackgroundActive(true)

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- pending rebind captures ANY next key (bypasses processed check so users
    -- can rebind even when a textbox has focus). Escape cancels.
    if pendingRebind then
        local pill = pendingRebind.pill
        if input.KeyCode == Enum.KeyCode.Escape then
            local prev = Keybinds[pendingRebind.moduleId]
            pill.Text = prev and prev.Name or "-"
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
            pendingRebind = nil
        else
            completeRebind(input.KeyCode)
        end
        return
    end

    if processed then return end

    -- menu toggle
    if input.KeyCode == Enum.KeyCode.Delete
    or input.KeyCode == Enum.KeyCode.RightShift then
        setWindowOpen(not windowOpen)
        return
    end

    -- module bindings
    for id, key in pairs(Keybinds) do
        if input.KeyCode == key then
            toggleModule(id)
            return
        end
    end
end)

return Koffee
