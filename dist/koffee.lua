-- koffee v0.0.8
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.0.8"

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
    Text   = { Tiny = 10, Small = 11, Body = 12, Header = 13, Title = 14 },
    Animation = {
        -- snappier timings; anything longer than ~0.25s reads as laggy in an
        -- interface where the user expects instant response.
        Fast       = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Normal     = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Pill       = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Slow       = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        -- linear + fast for the open/close fade of window + snow + dim + blur.
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

-- each flake is a stack of 3 concentric circles (outer/mid/core) with
-- decreasing size and increasing opacity -- fakes a radial soft edge
-- since Roblox UIGradient is linear-only. no assets required.
local function newSnowflake()
    local vp = viewport()
    local core = math.random(15, 30) / 10   -- 1.5 - 3.0 px core diameter
    local sf = {
        speedY    = math.random(15, 38),
        swayAmp   = math.random(4, 14),
        swayFreq  = math.random(30, 90) / 100,
        swayPhase = math.random() * math.pi * 2,
        baseX     = math.random() * vp.X,
        y         = math.random() * vp.Y,
        alpha     = math.random(50, 90) / 100,
    }
    local wrap = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, core, 0, core),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
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
    sf.outer = layer(2.0, 0.12, 5)   -- softest halo
    sf.mid   = layer(1.4, 0.40, 6)   -- diffuse mid
    sf.core  = layer(1.0, 1.00, 7)   -- bright center
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

hotkey("del", "menu")
hotkey("e", "esp")

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
-- CHECKBOX (visual primitive shared by module + config variants)
-- Matcha-style small filled square. Label goes accent-colored when checked.
-- Callers get { setState, getState, button, box, labelObj } handles.
--============================================================
local function checkboxVisual(parent, label, initialOn)
    local state = initialOn and true or false
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    local box = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = state and Theme.Palette.Accent or Theme.Palette.PanelElevated,
        BorderSizePixel = 0,
        ZIndex = 35,
        Parent = row,
    }, {
        corner(3),
        stroke(state and Theme.Palette.Accent or Theme.Palette.Border, 1),
    })
    local lbl = new("TextLabel", {
        Text = label,
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = state and Theme.Palette.Accent or Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -22, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 35,
        Parent = row,
    })
    local btn = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 36,
        Parent = row,
    })
    local function applyState()
        tween(box, Theme.Animation.Fast, {
            BackgroundColor3 = state and Theme.Palette.Accent or Theme.Palette.PanelElevated,
        })
        local s = box:FindFirstChildOfClass("UIStroke")
        if s then
            tween(s, Theme.Animation.Fast, {
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

-- module-backed checkbox: toggles a registered module + syncs active-modules array
local function moduleCheckbox(parent, label, moduleId)
    local mod = Modules[moduleId]
    local ctrl = checkboxVisual(parent, label, mod and mod.Enabled or false)
    ctrl.button.MouseButton1Click:Connect(function()
        toggleModule(moduleId)
        ctrl.setState(Modules[moduleId] and Modules[moduleId].Enabled)
    end)
    return ctrl
end

-- callback-backed checkbox: for sub-configs that aren't top-level modules
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
-- SLIDER (matcha-style: value in the header, thin track, small knob)
-- onChange fires live while dragging.
--============================================================
local function slider(parent, label, min, max, initial, precision, onChange)
    precision = precision or 0
    local function round(v)
        local m = 10 ^ precision
        return math.floor(v * m + 0.5) / m
    end
    local current = round(math.clamp(initial, min, max))
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    -- header row: label left, value right (at same baseline)
    new("TextLabel", {
        Text = label,
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -60, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
        Parent = row,
    })
    local valueLbl = new("TextLabel", {
        Text = tostring(current),
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 60, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 35,
        Parent = row,
    })
    -- thin track below the header
    local track = new("Frame", {
        Position = UDim2.new(0, 0, 0, 24),
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
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Theme.Palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = track,
    }, { pillCorner() })
    -- expand the hit area up over the header row too, so click-anywhere-then-drag works
    local hitArea = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 14),
        ZIndex = 37,
        Parent = row,
        AutoButtonColor = false,
    })
    local dragging = false
    local function setFromInputX(inputX)
        local trackAbs = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        if trackW <= 0 then return end
        local pct = math.clamp((inputX - trackAbs) / trackW, 0, 1)
        current = round(min + (max - min) * pct)
        pct = (current - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLbl.Text = tostring(current)
        if onChange then onChange(current) end
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
end

--============================================================
-- ESP MODULE
-- Highlight (through-walls chams) + billboard stack: name / distance / health.
-- Sub-config toggles (Show Name / Show Distance / Show Health) live-update
-- rigs via a RenderStepped watcher that also refreshes distance + health bar.
--============================================================
local ESP = {
    Config = { Name = true, Distance = true, Health = true },
    Connections = {},
    Rigs = {},         -- [plr] = { conn=..., rig=<see makeRig> }
    UpdateConn = nil,
}

local function makeRig(plr, character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 3)
    if not head then return nil end

    local hl = Instance.new("Highlight")
    hl.Name = "KoffeeESP"
    hl.FillColor = Theme.Palette.Accent
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = character
    hl.Parent = character

    local bb = Instance.new("BillboardGui")
    bb.Name = "KoffeeName"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 180, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 5000
    bb.Parent = head

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "Name"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Position = UDim2.new(0, 0, 0, 0)
    nameLbl.FontFace = Theme.Fonts.Medium
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Theme.Palette.Text
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.Text = plr.Name
    nameLbl.Parent = bb

    local distLbl = Instance.new("TextLabel")
    distLbl.Name = "Distance"
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, 0, 0, 12)
    distLbl.Position = UDim2.new(0, 0, 0, 17)
    distLbl.FontFace = Theme.Fonts.Mono
    distLbl.TextSize = 10
    distLbl.TextColor3 = Theme.Palette.TextMuted
    distLbl.TextStrokeTransparency = 0.6
    distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLbl.Text = "-- studs"
    distLbl.Parent = bb

    local healthWrap = Instance.new("Frame")
    healthWrap.Name = "HealthWrap"
    healthWrap.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
    healthWrap.BackgroundTransparency = 0.35
    healthWrap.BorderSizePixel = 0
    healthWrap.AnchorPoint = Vector2.new(0.5, 0)
    healthWrap.Position = UDim2.new(0.5, 0, 0, 33)
    healthWrap.Size = UDim2.new(0.75, 0, 0, 3)
    healthWrap.Parent = bb
    local wCorner = Instance.new("UICorner", healthWrap)
    wCorner.CornerRadius = UDim.new(1, 0)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.BackgroundColor3 = Theme.Palette.Success
    healthFill.BorderSizePixel = 0
    healthFill.Size = UDim2.new(1, 0, 1, 0)
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
    }
end

local function cleanRig(rig)
    if not rig then return end
    pcall(function() rig.hl:Destroy() end)
    pcall(function() rig.bb:Destroy() end)
end

local function applyESP(plr)
    if plr == LocalPlayer then return end
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
    for plr, entry in pairs(ESP.Rigs) do
        local rig = entry.rig
        if rig and rig.head and rig.head.Parent then
            local dist = math.floor((rig.head.Position - camPos).Magnitude + 0.5)
            rig.distLbl.Text = dist .. " studs"
            rig.nameLbl.Visible = ESP.Config.Name
            rig.distLbl.Visible = ESP.Config.Distance

            local hum = rig.character:FindFirstChildOfClass("Humanoid")
            if hum and hum.MaxHealth > 0 then
                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                rig.healthFill.Size = UDim2.new(pct, 0, 1, 0)
                rig.healthFill.BackgroundColor3 =
                    pct > 0.55 and Theme.Palette.Success
                    or (pct > 0.25 and Color3.fromRGB(220, 180, 100) or Theme.Palette.Danger)
                rig.healthWrap.Visible = ESP.Config.Health
            else
                rig.healthWrap.Visible = false
            end
        end
    end
end

registerModule("esp", "Player ESP",
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
    local espPanel = panel(root, "player esp")
    moduleCheckbox(espPanel, "Player ESP", "esp")
    configCheckbox(espPanel, "Show Name",     ESP.Config.Name,     function(v) ESP.Config.Name = v end)
    configCheckbox(espPanel, "Show Distance", ESP.Config.Distance, function(v) ESP.Config.Distance = v end)
    configCheckbox(espPanel, "Show Health",   ESP.Config.Health,   function(v) ESP.Config.Health = v end)
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
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete
    or input.KeyCode == Enum.KeyCode.RightShift then
        setWindowOpen(not windowOpen)
    elseif input.KeyCode == Enum.KeyCode.E then
        toggleModule("esp")
    end
end)

return Koffee
