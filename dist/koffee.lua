-- koffee v0.0.15
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.0.15"

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
    -- v0.0.13 typography reset. Nunito read too "Roblox 2020" per he. Swapping
    -- to BuilderSans (Roblox's newer editorial sans -- cleaner geometry, less
    -- friendly-rounded, more UI-established) as the baseline. Sarpanch handles
    -- the AAA-game accent for brand mark + section headers -- it's a condensed
    -- grotesque (Rajdhani / Tungsten family vibe) which is where modern AAA game
    -- HUDs live typographically. Reads premium at UI sizes without shouting.
    Fonts = (function()
        local UI    = "rbxasset://fonts/families/BuilderSans.json"
        local TITLE = "rbxasset://fonts/families/Sarpanch.json"
        local MONO  = "rbxasset://fonts/families/RobotoMono.json"
        return {
            Regular = Font.new(UI,    Enum.FontWeight.Medium),
            Medium  = Font.new(UI,    Enum.FontWeight.SemiBold),
            Bold    = Font.new(UI,    Enum.FontWeight.Bold),
            Title   = Font.new(TITLE, Enum.FontWeight.Bold),
            Mono    = Font.new(MONO,  Enum.FontWeight.Medium),
        }
    end)(),
    Sizes = {
        HudHeight    = 34,
        -- bigger overall so density stays right at larger text sizes
        WindowWidth  = 640,
        WindowHeight = 820,
        TabBarHeight = 40,
    },
    Radius = { Small = 4, Medium = 6, Large = 8 },
    -- bumped +2 across the board: v0.0.10 sizes shrank visibly with Nunito
    Text   = { Tiny = 12, Small = 13, Body = 14, Header = 15, Title = 17 },
    Animation = {
        Fast       = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Normal     = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        -- pill: 0.35s pure ease-out per he
        Pill       = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Menu       = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Slow       = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        WindowFade = TweenInfo.new(0.18, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    },
    Background = {
        DimTransparency  = 0.55,
        -- stronger blur per he ("actual gaussian, not artificial")
        BlurSize         = 14,
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
-- v0.0.15: purge stale BillboardGuis from previous script versions. Older
-- makeRig parented "KoffeeName" bb to the character's Head; a fresh load
-- without cleanup would leave those visible over players. New rigs don't
-- create these, but old sessions in the same game session might have.
pcall(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch = plr.Character
        if ch then
            local h = ch:FindFirstChild("Head")
            if h then
                for _, kid in ipairs(h:GetChildren()) do
                    if kid.Name == "KoffeeName" then pcall(function() kid:Destroy() end) end
                end
            end
        end
    end
end)

local screen = new("ScreenGui", {
    Name = "Koffee",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 2000000000,
    Parent = guiParent(),
})

-- separate top-level ScreenGui for popups (dropdowns, color picker) so they
-- render ABOVE the main window's CanvasGroup regardless of ZIndex quirks.
-- also isolates positioning math from any CG rendering side-effects.
for _, g in ipairs(guiParent():GetChildren()) do
    if g.Name == "KoffeePopups" then pcall(function() g:Destroy() end) end
end
local popupScreen = new("ScreenGui", {
    Name = "KoffeePopups",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 2000000001,
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
    FontFace = Theme.Fonts.Title,   -- Sarpanch Bold -- AAA-game brand feel
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

-- v0.0.14: arraylist label uses RichText. Base module name in Text color,
-- optional detail suffix (e.g. " box" / " box, chams") in Muted color.
-- Format: string.format("%s<font color='rgb(...)'>%s</font>", name, detail)
local ARRAYLIST_MUTED_COLOR = "rgb(138,125,112)"   -- Theme.Palette.TextMuted

local function buildArrayLabelText(mod)
    local base = mod.DisplayName or mod.Id or "?"
    local detail = mod.GetDetail and mod.GetDetail() or ""
    if detail and detail ~= "" then
        return string.format("%s<font color='%s'>%s</font>", base, ARRAYLIST_MUTED_COLOR, detail)
    end
    return base
end

local function addToActiveArray(mod)
    -- v0.0.14: if a previous entry is still fading out (destroy pending) OR
    -- an already-live entry exists, kill it first. Prevents zombie rows when
    -- the user rapid-toggles a module.
    if mod._destroyThread then
        pcall(task.cancel, mod._destroyThread)
        mod._destroyThread = nil
    end
    if mod._wrapper and mod._wrapper.Parent then
        mod._wrapper:Destroy()
    end
    mod._wrapper = nil

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
        Text = buildArrayLabelText(mod),
        RichText = true,                                 -- v0.0.14 muted suffix
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
    mod._arrayLabel = label

    -- v0.0.14: if the module reports a detail string, refresh it lazily on
    -- Heartbeat (throttled to ~0.2s so we're not stringifying every frame).
    -- Disconnected in removeFromActiveArray.
    if mod.GetDetail then
        local accum = 0
        mod._detailConn = RunService.Heartbeat:Connect(function(dt)
            accum = accum + dt
            if accum < 0.2 then return end
            accum = 0
            if not (mod._arrayLabel and mod._arrayLabel.Parent) then return end
            local newText = buildArrayLabelText(mod)
            if mod._arrayLabel.Text ~= newText then
                mod._arrayLabel.Text = newText
            end
        end)
    end
end

local function removeFromActiveArray(mod)
    local w = mod._wrapper
    if not w then return end
    mod._wrapper = nil
    mod._arrayLabel = nil
    if mod._detailConn then
        mod._detailConn:Disconnect()
        mod._detailConn = nil
    end
    for _, child in ipairs(w:GetChildren()) do
        if child:IsA("TextLabel") then
            tween(child, Theme.Animation.Fast, {
                TextTransparency = 1,
                Position = UDim2.new(0, -10, 0, 0),  -- slide back left on remove
            })
        end
    end
    -- v0.0.14: track the destroy thread so a re-enable during the fade window
    -- can cancel it and prevent the "new row destroyed by old scheduled kill"
    -- bug.
    if mod._destroyThread then pcall(task.cancel, mod._destroyThread) end
    mod._destroyThread = task.delay(0.14, function()
        mod._destroyThread = nil
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
        Watchers = {},   -- v0.0.13: subscribers get notified after every state
                         -- flip so keybind-driven toggles update the checkbox
                         -- visual too. general pubsub -- any observer works.
    }
    return Modules[id]
end

-- v0.0.13: subscribe to a module's Enabled state. Callback receives the new
-- boolean state on every toggle (click OR keybind). Returns an unsubscribe fn.
local function subscribeModule(id, fn)
    local m = Modules[id]
    if not m then return function() end end
    table.insert(m.Watchers, fn)
    return function()
        for i, f in ipairs(m.Watchers) do
            if f == fn then table.remove(m.Watchers, i); break end
        end
    end
end

-- v0.0.14: toggleModule was blocking the click for as long as OnEnable took
-- (makeRig's WaitForChild("Head", 3) on each player in a full server -> up to
-- ~90s to release the checkbox). The user saw this as "Enabled takes YEARS to
-- toggle." Now the flow is:
--   1. flip the boolean         (instant)
--   2. update the arraylist     (instant, animation starts this frame)
--   3. fire watchers            (instant, checkbox visual + any observers)
--   4. run OnEnable/OnDisable   (task.spawn'd -- any yielding it does is
--                                 isolated from the click path)
-- The visual feedback is immediate; the actual module wiring races along
-- behind it.
local function toggleModule(id)
    local m = Modules[id]
    if not m then return end
    m.Enabled = not m.Enabled
    if m.Enabled then
        addToActiveArray(m)
    else
        removeFromActiveArray(m)
    end
    -- fire watchers BEFORE spawning the work so the visual updates land
    -- while the work is still starting
    for _, watcher in ipairs(m.Watchers) do
        pcall(watcher, m.Enabled)
    end
    -- async: any yielding inside on-enable/disable won't stall the toggle
    task.spawn(function()
        local cb = m.Enabled and m.OnEnable or m.OnDisable
        if not cb then return end
        local ok, err = pcall(cb)
        if not ok then
            warn("[koffee] " .. id .. " " .. (m.Enabled and "enable" or "disable")
                 .. " failed: " .. tostring(err))
        end
    end)
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
}, { pillCorner(), stroke(Theme.Palette.BorderSubtle, 1) })

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

-- Apple-style: on tab switch the pill first stretches to span both the current
-- and the destination tab, then contracts down to the destination. Two-phase
-- tween, both ease-out. Feels alive.
local PILL_STRETCH  = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local PILL_CONTRACT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

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
        return
    end

    -- stretch phase: cover both current + target
    local curX = pill.Position.X.Offset
    local curW = pill.Size.X.Offset
    local endX = relX
    local endW = button.AbsoluteSize.X
    local stretchX = math.min(curX, endX)
    local stretchW = math.max(curX + curW, endX + endW) - stretchX

    local t1 = TweenService:Create(pill, PILL_STRETCH, {
        Position = UDim2.new(0, stretchX, 0, relY),
        Size     = UDim2.new(0, stretchW, 0, button.AbsoluteSize.Y),
    })
    t1:Play()
    t1.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            TweenService:Create(pill, PILL_CONTRACT, {
                Position = targetPos,
                Size     = targetSize,
            }):Play()
        end
    end)
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

    -- ScrollingFrame per tab so long panel stacks don't clip. AutomaticCanvasSize
    -- reads its own children's total height so we don't have to size manually.
    local panel = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 32,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Palette.TextFaint,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = content,
    })

    if buildFn then
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = panel,
        })
        new("UIPadding", {
            PaddingBottom = UDim.new(0, 12),   -- room past last panel so scroll feels right
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
            PaddingTop    = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft   = UDim.new(0, 16),
            PaddingRight  = UDim.new(0, 16),
        }),
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),   -- compact between toggles (per he)
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    if title then
        new("TextLabel", {
            Text = title,
            FontFace = Theme.Fonts.Medium,
            TextSize = Theme.Text.Header,
            TextColor3 = Theme.Palette.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = -1,
            ZIndex = 34,
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
-- v0.0.12 semantics per he:
--   OFF -> ON  = fill GROWS OUTWARD from middle (size 0 -> INNER, opaque throughout)
--   ON  -> OFF = fill SHRINKS INWARD to middle (size INNER -> 0) with a super-fast
--                fade tail so it doesn't pop out of existence
-- Also cancels any in-flight tweens on each state change so rapid clicking can't
-- stack animations and desync the visual from the actual state.
--============================================================
local CHECKBOX_ROW_HEIGHT = 22
local CHECKBOX_OUTER = 16
local CHECKBOX_INNER = 12
local CHECKBOX_LABEL_OFFSET = 26
local CHECKBOX_RIGHT_RESERVE = 74

local function checkboxVisual(parent, label, initialOn)
    local state = initialOn and true or false
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, CHECKBOX_ROW_HEIGHT),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    -- outer box: subtle panel-elevated bg, no stroke
    local box = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, CHECKBOX_OUTER, 0, CHECKBOX_OUTER),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 35,
        Parent = row,
    }, { corner(4) })
    -- inner fill: anchored at box center so size 0 -> INNER grows outward evenly.
    -- Off state = size 0 + transparency 1. On state = size INNER + transparency 0.
    local innerFill = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = state and UDim2.new(0, CHECKBOX_INNER, 0, CHECKBOX_INNER)
                     or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Palette.Accent,
        BackgroundTransparency = state and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = box,
    }, { corner(3) })
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
    local btn = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -CHECKBOX_RIGHT_RESERVE, 1, 0),
        ZIndex = 37,
        AutoButtonColor = false,
        Parent = row,
    })
    attachHover(row, btn)

    local CB_GROW   = TweenInfo.new(0.16, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
    local CB_SHRINK = TweenInfo.new(0.12, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
    local CB_FADE   = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    local activeSize, activeFade
    local seq = 0
    local function applyState()
        seq = seq + 1
        local mySeq = seq
        -- kill anything in flight so rapid clicks don't fight each other
        if activeSize then activeSize:Cancel(); activeSize = nil end
        if activeFade then activeFade:Cancel(); activeFade = nil end
        if state then
            -- OFF -> ON: grow OUTWARD from center. Snap to 0 first (in case a
            -- prior tween was mid-shrink) and pop opacity to opaque immediately
            -- so the growth reads as substance appearing, not a fade-in.
            innerFill.Size = UDim2.new(0, 0, 0, 0)
            innerFill.BackgroundTransparency = 0
            activeSize = tween(innerFill, CB_GROW, {
                Size = UDim2.new(0, CHECKBOX_INNER, 0, CHECKBOX_INNER),
            })
        else
            -- ON -> OFF: shrink INWARD to center, then super-fast fade to hide.
            -- Ensure opacity is opaque going in (guards against superseded fade).
            innerFill.BackgroundTransparency = 0
            activeSize = tween(innerFill, CB_SHRINK, {
                Size = UDim2.new(0, 0, 0, 0),
            })
            task.delay(0.10, function()
                if mySeq ~= seq then return end   -- superseded by newer click
                activeFade = tween(innerFill, CB_FADE, { BackgroundTransparency = 1 })
            end)
        end
        tween(lbl, Theme.Animation.Fast, {
            TextColor3 = state and Theme.Palette.Accent or Theme.Palette.Text,
        })
    end
    return {
        row = row,
        button = btn,
        setState = function(newState)
            local nb = newState and true or false
            if nb == state then return end   -- no-op guard against redundant sets
            state = nb
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
        -- state sync is handled by the watcher below -- covers keybind toggles too
    end)
    -- v0.0.13: subscribe so keybind toggles (or any other toggleModule caller)
    -- keep the visual in lockstep with the actual module state
    subscribeModule(moduleId, function(newState)
        ctrl.setState(newState)
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
-- COLOR PICKER (popup: SV area + hue slider + hex input)
-- Parented to `screen` so it renders above the window CanvasGroup.
-- Reused across all color swatches -- one picker instance, retargeted.
--============================================================
local function parseHex(str)
    if not str then return nil end
    str = str:gsub("#", ""):gsub("%s", "")
    if #str ~= 6 then return nil end
    local r = tonumber(str:sub(1, 2), 16)
    local g = tonumber(str:sub(3, 4), 16)
    local b = tonumber(str:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local ColorPicker = { root = nil, activeSwatch = nil, callback = nil, h = 0, s = 0, v = 0 }

local function makeRainbowSequence()
    -- 7 stops around the hue wheel
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0.000, 1, 1)),
        ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
        ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.500, 1, 1)),
        ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
        ColorSequenceKeypoint.new(1.000, Color3.fromHSV(1.000, 1, 1)),
    })
end

local function buildColorPicker()
    local root = new("Frame", {
        Name = "ColorPicker",
        Size = UDim2.new(0, 260, 0, 260),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 250,
        Parent = popupScreen,
    }, {
        corner(6),
        stroke(Theme.Palette.Border, 1),
        new("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        }),
    })
    new("TextLabel", {
        Text = "color",
        FontFace = Theme.Fonts.Medium,
        TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 251,
        Parent = root,
    })
    -- SV picker area
    local svArea = new("Frame", {
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, -32, 0, 140),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 251,
        Parent = root,
    }, { corner(4) })
    -- white overlay (left = white, right = pure hue)
    local whiteOverlay = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 252,
        Parent = svArea,
    }, {
        corner(4),
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),
    })
    -- black overlay (top = clear, bottom = black)
    local blackOverlay = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 253,
        Parent = svArea,
    }, {
        corner(4),
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 90,
        }),
    })
    -- SV cursor: bigger + always shows current color inside (per he)
    local svCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        ZIndex = 254,
        Parent = svArea,
    }, {
        pillCorner(),
        stroke(Color3.new(1, 1, 1), 2),
    })
    -- hue slider
    local hueSlider = new("Frame", {
        Position = UDim2.new(1, -24, 0, 22),
        Size = UDim2.new(0, 20, 0, 140),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 251,
        Parent = root,
    }, {
        corner(4),
        new("UIGradient", { Color = makeRainbowSequence(), Rotation = 90 }),
    })
    local hueCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 4, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 252,
        Parent = hueSlider,
    }, { corner(2), stroke(Color3.new(0, 0, 0), 1) })
    -- hex input (leaves room on the right for the preview swatch)
    local hexBox = new("TextBox", {
        Position = UDim2.new(0, 0, 0, 178),
        Size = UDim2.new(1, -52, 0, 24),
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Text,
        Text = "#FFFFFF",
        ClearTextOnFocus = false,
        ZIndex = 251,
        Parent = root,
    }, {
        corner(4),
        stroke(Theme.Palette.BorderSubtle, 1),
        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
    })
    -- rgb readout below hex
    local rgbRead = new("TextLabel", {
        Position = UDim2.new(0, 0, 0, 208),
        Size = UDim2.new(1, -52, 0, 14),
        BackgroundTransparency = 1,
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "R 255  G 255  B 255",
        ZIndex = 251,
        Parent = root,
    })
    -- BOTTOM-RIGHT PREVIEW SWATCH -- shows current color as a big block (per he)
    local preview = new("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(0, 44, 0, 44),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 252,
        Parent = root,
    }, { corner(6), stroke(Theme.Palette.Border, 1) })

    local suppressRefresh = false

    local function applyToUI()
        suppressRefresh = true
        svArea.BackgroundColor3 = Color3.fromHSV(ColorPicker.h, 1, 1)
        svCursor.Position = UDim2.new(ColorPicker.s, 0, 1 - ColorPicker.v, 0)
        hueCursor.Position = UDim2.new(0.5, 0, ColorPicker.h, 0)
        local c = Color3.fromHSV(ColorPicker.h, ColorPicker.s, ColorPicker.v)
        hexBox.Text = colorToHex(c)
        rgbRead.Text = colorToRGB(c)
        svCursor.BackgroundColor3 = c
        preview.BackgroundColor3 = c
        if ColorPicker.callback then
            ColorPicker.callback(c)
        end
        suppressRefresh = false
    end

    local svDragging = false
    svArea.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        svDragging = true
        local abs = svArea.AbsolutePosition
        local siz = svArea.AbsoluteSize
        ColorPicker.s = math.clamp((input.Position.X - abs.X) / siz.X, 0, 1)
        ColorPicker.v = 1 - math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
        applyToUI()
    end)
    local hueDragging = false
    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        hueDragging = true
        local abs = hueSlider.AbsolutePosition
        local siz = hueSlider.AbsoluteSize
        ColorPicker.h = math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
        applyToUI()
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if svDragging then
            local abs = svArea.AbsolutePosition
            local siz = svArea.AbsoluteSize
            ColorPicker.s = math.clamp((input.Position.X - abs.X) / siz.X, 0, 1)
            ColorPicker.v = 1 - math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
            applyToUI()
        end
        if hueDragging then
            local abs = hueSlider.AbsolutePosition
            local siz = hueSlider.AbsoluteSize
            ColorPicker.h = math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
            applyToUI()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
        end
    end)
    hexBox.FocusLost:Connect(function()
        local c = parseHex(hexBox.Text)
        if c then
            ColorPicker.h, ColorPicker.s, ColorPicker.v = c:ToHSV()
            applyToUI()
        else
            local cur = Color3.fromHSV(ColorPicker.h, ColorPicker.s, ColorPicker.v)
            hexBox.Text = colorToHex(cur)
        end
    end)

    ColorPicker.root = root
    ColorPicker.apply = applyToUI
    return root
end

local function openColorPicker(swatchInstance, initialColor, onChange)
    if not ColorPicker.root then buildColorPicker() end
    ColorPicker.activeSwatch = swatchInstance
    ColorPicker.callback = onChange
    local h, s, v = initialColor:ToHSV()
    ColorPicker.h, ColorPicker.s, ColorPicker.v = h, s, v
    -- position near swatch (below + right, but clamp to viewport)
    local abs = swatchInstance.AbsolutePosition
    local siz = swatchInstance.AbsoluteSize
    local vp = Camera.ViewportSize
    local pickerW, pickerH = 260, 260
    local x = math.min(abs.X, vp.X - pickerW - 8)
    local y = math.min(abs.Y + siz.Y + 6, vp.Y - pickerH - 8)
    ColorPicker.root.Position = UDim2.new(0, x, 0, y - 4)
    ColorPicker.root.Visible = true
    ColorPicker.root.BackgroundTransparency = 1
    tween(ColorPicker.root, Theme.Animation.Menu, {
        BackgroundTransparency = 0.02,
        Position = UDim2.new(0, x, 0, y),
    })
    ColorPicker.apply()
end

local function closeColorPicker()
    if not ColorPicker.root or not ColorPicker.root.Visible then return end
    tween(ColorPicker.root, Theme.Animation.Menu, {
        BackgroundTransparency = 1,
    })
    task.delay(0.22, function()
        if ColorPicker.root then ColorPicker.root.Visible = false end
    end)
    ColorPicker.activeSwatch = nil
    ColorPicker.callback = nil
end

--============================================================
-- COLOR SWATCH: clickable, opens picker; also hover-shows a tooltip preview
-- Optional { onChange = fn(newColor), getColor = fn() -> Color3 } table.
--============================================================
local function colorSwatch(parent, initialColor, size, opts)
    opts = opts or {}
    size = size or 14
    local currentColor = initialColor
    local sw = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = parent,
    }, { corner(3), stroke(Theme.Palette.Border, 1) })

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
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = tip,
    }, { corner(3) })
    local hexLbl = new("TextLabel", {
        Text = colorToHex(currentColor),
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
        Text = colorToRGB(currentColor),
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

    local function refreshUI()
        sw.BackgroundColor3 = currentColor
        chip.BackgroundColor3 = currentColor
        hexLbl.Text = colorToHex(currentColor)
        rgbLbl.Text = colorToRGB(currentColor)
    end

    sw.MouseEnter:Connect(function() tip.Visible = true end)
    sw.MouseLeave:Connect(function() tip.Visible = false end)

    sw.MouseButton1Click:Connect(function()
        -- if picker already open on this swatch, close it
        if ColorPicker.activeSwatch == sw then
            closeColorPicker()
            return
        end
        openColorPicker(sw, currentColor, function(newColor)
            currentColor = newColor
            refreshUI()
            if opts.onChange then opts.onChange(newColor) end
        end)
    end)

    return {
        instance = sw,
        setColor = function(c)
            currentColor = c
            refreshUI()
        end,
        getColor = function() return currentColor end,
    }
end

--============================================================
-- DROPDOWN (label above + button that opens popup list below)
-- Popup is parented to `screen` (NOT the panel/window) so it renders
-- above the CanvasGroup and isn't clipped by it. Positioned each open
-- from the button's AbsolutePosition. Slide+fade animation. Chevron
-- arrow built from two rotated 1px lines. Closes on outside click.
--============================================================
local openDropdowns = {}  -- popup frames -> close-fn

local function chevron(parent, sizePx)
    sizePx = sizePx or 8
    local root = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, sizePx, 0, sizePx * 0.6),
        BackgroundTransparency = 1,
        ZIndex = 37,
        Parent = parent,
    })
    local armLen = sizePx * 0.62
    local left = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.28, 0, 0.5, 0),
        Size = UDim2.new(0, armLen, 0, 1.4),
        Rotation = 40,
        BackgroundColor3 = Theme.Palette.TextMuted,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = root,
    })
    local right = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.72, 0, 0.5, 0),
        Size = UDim2.new(0, armLen, 0, 1.4),
        Rotation = -40,
        BackgroundColor3 = Theme.Palette.TextMuted,
        BorderSizePixel = 0,
        ZIndex = 38,
        Parent = root,
    })
    return root, left, right
end

local function dropdown(parent, label, options, initial, onChange)
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
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
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
        Parent = wrap,
    })
    local btn = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(0, 0, 0, 22),   -- extra gap between label and button (was 14)
        Size = UDim2.new(1, 0, 0, 26),
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
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 36,
        Parent = btn,
    })
    local caretRoot = chevron(btn, 10)

    -- popup lives in the dedicated popup ScreenGui, above everything
    local list = new("Frame", {
        Size = UDim2.new(0, 100, 0, #options * 26),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200,
        Parent = popupScreen,
    }, {
        corner(4),
        stroke(Theme.Palette.Border, 1),
    })

    local isOpen = false
    local positionConn = nil     -- v0.0.12: RenderStepped lock so popup stays
                                 -- glued below the button even if the button's
                                 -- absolute position shifts (scroll, tab-switch,
                                 -- window drag). This fixes "popup spawns in the
                                 -- wrong place" bugs at their root -- we don't
                                 -- calculate once at open, we calculate every frame.
    local function placeBelow()
        local abs = btn.AbsolutePosition
        local siz = btn.AbsoluteSize
        if siz.X <= 0 or siz.Y <= 0 then return end
        list.Size = UDim2.new(0, siz.X, 0, #options * 26)
        list.Position = UDim2.new(0, abs.X, 0, abs.Y + siz.Y + 6)
    end

    local function closeList(instant)
        if not isOpen then return end
        isOpen = false
        openDropdowns[list] = nil
        if positionConn then positionConn:Disconnect(); positionConn = nil end
        tween(caretRoot, Theme.Animation.Menu, { Rotation = 0 })
        if instant then
            list.Visible = false
        else
            tween(list, Theme.Animation.Menu, {
                BackgroundTransparency = 1,
            })
            task.delay(0.22, function()
                if not isOpen then list.Visible = false end
            end)
        end
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                tween(child, Theme.Animation.Menu, { BackgroundTransparency = 1 })
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("TextLabel") then
                        tween(sub, Theme.Animation.Menu, { TextTransparency = 1 })
                    end
                end
            end
        end
    end
    local function openList()
        if isOpen then return end
        for _, closer in pairs(openDropdowns) do
            if closer ~= closeList then closer(true) end
        end
        isOpen = true
        openDropdowns[list] = closeList
        placeBelow()
        list.BackgroundTransparency = 1
        list.Visible = true
        -- lock position while open: RenderStepped keeps `list` glued to btn
        if positionConn then positionConn:Disconnect() end
        positionConn = RunService.RenderStepped:Connect(function()
            if not isOpen or not btn.Parent then return end
            placeBelow()
        end)
        tween(list, Theme.Animation.Menu, {
            BackgroundTransparency = 0.05,
        })
        tween(caretRoot, Theme.Animation.Menu, { Rotation = 180 })
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                tween(child, Theme.Animation.Menu, { BackgroundTransparency = 1 })
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("TextLabel") then
                        tween(sub, Theme.Animation.Menu, { TextTransparency = 0 })
                    end
                end
            end
        end
    end

    for i, opt in ipairs(options) do
        local optBtn = new("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 26),
            Position = UDim2.new(0, 0, 0, (i - 1) * 26),
            BackgroundColor3 = Theme.Palette.PanelElevated,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 201,
            Parent = list,
        })
        new("TextLabel", {
            Text = opt,
            FontFace = Theme.Fonts.Medium,
            TextSize = Theme.Text.Small,
            TextColor3 = Theme.Palette.Text,
            BackgroundTransparency = 1,
            TextTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 202,
            Parent = optBtn,
        })
        optBtn.MouseEnter:Connect(function()
            tween(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 0.7 })
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 1 })
        end)
        optBtn.MouseButton1Click:Connect(function()
            valueLbl.Text = opt
            closeList()
            if onChange then onChange(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    return {
        setValue = function(v) valueLbl.Text = v end,
        close = function() closeList(true) end,
    }
end

-- outside-click closer: closes any open dropdown OR color picker if click missed
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = input.Position

    -- dropdowns
    for list, closer in pairs(openDropdowns) do
        local abs = list.AbsolutePosition
        local siz = list.AbsoluteSize
        local inside = mp.X >= abs.X and mp.X <= abs.X + siz.X
                   and mp.Y >= abs.Y and mp.Y <= abs.Y + siz.Y
        if not inside then closer() end
    end

    -- color picker (skip close if click is on its owning swatch)
    if ColorPicker.root and ColorPicker.root.Visible then
        local abs = ColorPicker.root.AbsolutePosition
        local siz = ColorPicker.root.AbsoluteSize
        local insidePicker = mp.X >= abs.X and mp.X <= abs.X + siz.X
                         and mp.Y >= abs.Y and mp.Y <= abs.Y + siz.Y
        local onSwatch = false
        if ColorPicker.activeSwatch then
            local sabs = ColorPicker.activeSwatch.AbsolutePosition
            local ssiz = ColorPicker.activeSwatch.AbsoluteSize
            onSwatch = mp.X >= sabs.X and mp.X <= sabs.X + ssiz.X
                   and mp.Y >= sabs.Y and mp.Y <= sabs.Y + ssiz.Y
        end
        if not insidePicker and not onSwatch then
            closeColorPicker()
        end
    end
end)

--============================================================
-- SLIDER (thicker track, bigger knob, knob color contrasts fill)
-- Value doubles as click-to-edit TextBox with a hover-pill background.
--============================================================
local function slider(parent, label, min, max, initial, precision, onChange)
    precision = precision or 0
    local function round(v)
        local m = 10 ^ precision
        return math.floor(v * m + 0.5) / m
    end
    local current = round(math.clamp(initial, min, max))
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
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
        Size = UDim2.new(1, -90, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35,
        Parent = row,
    })
    -- value = TextBox with pill-hover background (matcha spec)
    local valueBox = new("TextBox", {
        Text = tostring(current),
        PlaceholderText = "",
        FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.Text,
        BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 1,   -- invisible until hovered/focused
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 82, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
        ZIndex = 38,
        Parent = row,
    }, {
        pillCorner(),
        stroke(Theme.Palette.BorderSubtle, 1),
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 10),
        }),
    })
    local valueStroke = valueBox:FindFirstChildOfClass("UIStroke")
    if valueStroke then valueStroke.Transparency = 1 end   -- hide stroke by default too
    local track = new("Frame", {
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 4),                     -- was 2 -- thicker per he
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
    -- knob: bigger (12 vs 9) and Text/white color (not Accent) per he
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(startPct, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Theme.Palette.Text,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = track,
    }, { pillCorner(), stroke(Theme.Palette.BorderSubtle, 1) })
    local hitArea = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, -86, 0, 14),
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
        if n then current = round(math.clamp(n, min, max)) end
        applyValue()
    end)
    -- hover: bg pill lights up
    valueBox.MouseEnter:Connect(function()
        tween(valueBox, Theme.Animation.Fast, {
            BackgroundTransparency = 0.35,
            TextColor3 = Theme.Palette.Accent,
        })
        if valueStroke then
            tween(valueStroke, Theme.Animation.Fast, { Transparency = 0 })
        end
    end)
    valueBox.MouseLeave:Connect(function()
        tween(valueBox, Theme.Animation.Fast, {
            BackgroundTransparency = 1,
            TextColor3 = Theme.Palette.Text,
        })
        if valueStroke then
            tween(valueStroke, Theme.Animation.Fast, { Transparency = 1 })
        end
    end)
end

--============================================================
-- ESP MODULE (v0.0.10)
-- Master toggle ("Enabled") just turns on the ESP framework. Chams
-- (colored Highlight fills) is now a SEPARATE future widget -- this
-- master doesn't apply any color to players.
--
-- Default rendering when master on = static 2D box (Boxes widget lets
-- you customize color/fill/type/corners).
--
-- Config groups:
--   Config (ESP-level toggles) -- shared across future widgets
--   Boxes (Boxes widget config)
--   Colors (color pool)
--============================================================
local ESP = {
    Config = {
        -- v0.0.15: text stuff (Names / Distance / their labels + BillboardGui)
        -- lives in the future Names module. TextBackground is SHARED plumbing
        -- for any future text-rendering module -- kept here as a bool because
        -- multiple overlays (Names, Distance, Health) will read the same
        -- preference. Currently no module renders text, so this is a stored
        -- config value only.
        TextBackground = false,
        CharacterOnly  = false,      -- ignore accessories/tools in bounding-box calc
        ImmediateMode  = true,       -- true = snap-to-frame, false = lerp smoothing
        TeamCheck      = false,
        VisibleCheck   = false,
        TeamBasedColor = false,      -- team color overrides box outline color on same-team
        -- v0.0.15 Outline semantics (final): Outline gates the box LINES
        -- (the 2D UIStroke, the cube edges). Fill + Corners are independent
        -- and unaffected. When Outline is off + Fill is on + Corners is off,
        -- 2D box shows just fill / cube shows just AABB fill. When Outline
        -- is off + Corners is on, corners still render (they're the box's
        -- line style, not a decorative accent). So the box "exists" as long
        -- as Fill or Corners is on -- Outline just controls its full outline.
        -- Also drives the arraylist accent line via applyGlobalOutline.
        Outline        = true,
        Glow           = false,
        SelfESP        = false,
        SizingType     = "Static",     -- per he: Static first + default
        RenderDistance = 1000,
    },
    Boxes = {
        Enabled      = false,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        FillColor    = Color3.fromRGB(212, 145, 90),
        FillBox      = false,
        BoxType      = "2D",       -- "2D" | "Cube"
        Corners      = false,
        CornerLength = 0.3,        -- 0-1, fraction of edge length
    },
    Colors = {
        Visible = Color3.fromRGB(212, 145, 90),
        Hidden  = Color3.fromRGB(120, 120, 120),
        Team    = Color3.fromRGB(127, 190, 143),
    },
    Connections = {},
    Rigs = {},
    UpdateConn = nil,
    BoxLayer = nil,
}

-- v0.0.12: Outline is a global thin-line accent switch. When OFF, the
-- arraylist's white vertical line hides too. Extend this function whenever
-- a new overlay module (Health, future) gains a subtle accent line.
-- (Main-interface strokes -- window/tabs/pills/widgets -- are NOT affected;
-- those are chrome, not accent.)
local function applyGlobalOutline()
    local on = ESP.Config.Outline
    -- fade the arraylist accent line in/out
    tween(activeLine, Theme.Animation.Fast, {
        BackgroundTransparency = on and 0.15 or 1,
    })
end

-- lazy: box layer created on first ESP enable
local function ensureBoxLayer()
    if ESP.BoxLayer and ESP.BoxLayer.Parent then return ESP.BoxLayer end
    ESP.BoxLayer = new("Frame", {
        Name = "ESPBoxLayer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 12,   -- above snow (3-7) + active-modules (15 is above), below window (30)
        Parent = screen,
    })
    return ESP.BoxLayer
end

-- helper: build 8 corner brackets around a rect. returns list of 8 Frame handles.
-- 2 lines per corner (horizontal + vertical) = 8 line frames total.
local function makeBoxCorners(parent)
    local corners = {}
    for _ = 1, 8 do
        table.insert(corners, new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            Visible = false,
            ZIndex = 14,
            Parent = parent,
        }))
    end
    return corners
end

-- 24 thin-line frames: slots 1..12 = full edge (anchor 0.5,0.5) OR A-side
-- partial in corners mode. Slots 13..24 = B-side partial in corners mode
-- (unused when not in corners mode). Anchor is set per-frame in updateESPRigs.
local function makeCubeEdges(parent)
    local edges = {}
    for _ = 1, 24 do
        table.insert(edges, new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 14,
            Parent = parent,
        }))
    end
    return edges
end

-- v0.0.13: known rig part names (R6 + R15). Used by CharacterOnly mode to
-- compute a bounding box from just the humanoid rig, excluding accessories,
-- tools, held items, and other model props parented under the character.
local RIG_PART_NAMES = {
    -- R6
    ["Head"] = true, ["HumanoidRootPart"] = true, ["Torso"] = true,
    ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
    -- R15
    ["UpperTorso"] = true, ["LowerTorso"] = true,
    ["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true,
    ["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
    ["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true,
    ["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true,
}

local function collectBodyParts(character)
    local parts = {}
    for _, ch in ipairs(character:GetChildren()) do
        if ch:IsA("BasePart") and RIG_PART_NAMES[ch.Name] then
            table.insert(parts, ch)
        end
    end
    return parts
end

-- v0.0.15: torso resolver. Prefers HumanoidRootPart (always present on
-- both R6 + R15 characters, sits at hip level = the true anchor for a
-- centered ESP box). Falls back to UpperTorso (R15) then Torso (R6) for
-- rigs without an HRP.
local function findTorso(character)
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

-- v0.0.12: real glow via layered halos. UIStroke can only be single-layer, so
-- we stack two frames behind the box, each larger + softer, colored by outline.
-- Enabled only when ESP.Config.Glow is on. Halo lives in ESP.BoxLayer next to
-- boxRoot so its ZIndex sits below (13 -> 12,11).
local function makeBoxHalo(parent)
    local outer = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 11,
        Parent = parent,
    }, { corner(6) })
    local inner = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 12,
        Parent = parent,
    }, { corner(5) })
    return { outer = outer, inner = inner }
end

local function makeRig(plr, character)
    -- v0.0.15: anchor is torso, not head. Head is on top of the character;
    -- anchoring distance / life-gate / static projection off it produced
    -- boxes that drifted upward and read as "grabbing UI" (projected point
    -- sat above the character silhouette when close). Torso (HRP) is at hip
    -- level and centered on the visible body.
    local torso = findTorso(character)
    if not torso then
        -- rig parts not loaded yet -- wait briefly, then bail if still absent.
        -- CharacterAdded fires on the fresh character before ALL descendants
        -- are guaranteed loaded, so a short wait catches the common case
        -- without blocking a full 3s per player.
        torso = character:WaitForChild("HumanoidRootPart", 2)
              or character:WaitForChild("UpperTorso", 0.5)
              or character:WaitForChild("Torso", 0.5)
    end
    if not torso then return nil end

    -- box widget (screen-space, lives in ESP.BoxLayer)
    -- boxRoot's own bg is the FILL now (was a separate boxFill child --
    -- consolidating fixes a rendering quirk where the fill wouldn't show).
    -- The UIStroke is the OUTLINE.
    ensureBoxLayer()
    local boxRoot = new("Frame", {
        Name = "Box_" .. plr.Name,
        BackgroundColor3 = Color3.fromRGB(212, 145, 90),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 13,
        Parent = ESP.BoxLayer,
    }, { stroke(Color3.new(1, 1, 1), 2) })
    local boxOutline = boxRoot:FindFirstChildOfClass("UIStroke")
    local boxCorners = makeBoxCorners(boxRoot)
    local cubeEdges = makeCubeEdges(ESP.BoxLayer)
    local boxHalo   = makeBoxHalo(ESP.BoxLayer)

    -- v0.0.14: BillboardGui + name/dist/textBg removed. Names / Distance /
    -- Text Background are all becoming a dedicated overlay module ("Names")
    -- with its own rig/subscription. Health same. ESP rig now contains only
    -- box widget state -- clean split by concern.

    return {
        character  = character,
        torso      = torso,                           -- v0.0.15 anchor
        plr        = plr,
        boxRoot    = boxRoot,
        boxOutline = boxOutline,
        boxCorners = boxCorners,
        cubeEdges  = cubeEdges,
        boxHalo    = boxHalo,
        -- v0.0.15: staticSize snapshot dropped. projectStatic uses fixed
        -- world-space marker offsets (+3 up / -4 down) instead of the old
        -- character:GetBoundingBox() snapshot -- distance / FOV drive size,
        -- so no per-rig snapshot is meaningful.
        bodyParts  = collectBodyParts(character),   -- for CharacterOnly mode
        -- smoothing state (used when ImmediateMode = false)
        lastBoxPos  = nil,
        lastBoxSize = nil,
    }
end

local function cleanRig(rig)
    if not rig then return end
    pcall(function() rig.boxRoot:Destroy() end)
    if rig.cubeEdges then
        for _, e in ipairs(rig.cubeEdges) do
            pcall(function() e:Destroy() end)
        end
    end
    if rig.boxHalo then
        pcall(function() rig.boxHalo.outer:Destroy() end)
        pcall(function() rig.boxHalo.inner:Destroy() end)
    end
end

-- v0.0.13 orphan-box fix:
--   Previous applyESP created a new rig on CharacterAdded but didn't clean
--   up the old one -- boxRoot/cubeEdges/halo/bb from the dead character stayed
--   parented to ESP.BoxLayer forever. That's the "boxes stick around after
--   enemy dies" bug and the "new round doesn't work" bug both.
--   Fix: clean the previous rig before making a new one, AND hook
--   CharacterRemoving so visuals disappear the frame the character despawns
--   instead of waiting for a stale render tick.
local function applyESP(plr)
    if ESP.Rigs[plr] then return end
    local entry = { rig = nil, addedConn = nil, removingConn = nil }
    ESP.Rigs[plr] = entry
    local function attach(character)
        if not character then return end
        -- kill the previous rig if there was one -- prevents leaked frames
        if entry.rig then
            cleanRig(entry.rig)
            entry.rig = nil
        end
        -- also purge any stale attachment left over from a prior session
        pcall(function()
            local old = character:FindFirstChild("KoffeeESP")
            if old then old:Destroy() end
        end)
        local rig = makeRig(plr, character)
        if rig then entry.rig = rig end
    end
    entry.addedConn = plr.CharacterAdded:Connect(attach)
    entry.removingConn = plr.CharacterRemoving:Connect(function()
        if entry.rig then
            cleanRig(entry.rig)
            entry.rig = nil
        end
    end)
    if plr.Character then attach(plr.Character) end
end

local function stripESP(plr)
    local entry = ESP.Rigs[plr]
    if not entry then return end
    if entry.addedConn then entry.addedConn:Disconnect() end
    if entry.removingConn then entry.removingConn:Disconnect() end
    cleanRig(entry.rig)
    ESP.Rigs[plr] = nil
end

-- project 8 bounding-box corners to viewport. returns:
--   screenCorners  -- list of {x, y, z} in viewport space
--   anyInFront     -- at least one corner visible
--   allInFront     -- every corner visible (safe for cube edge drawing)
-- Sizing modes (v0.0.13):
--   "Static"     -- distance-linked, aspect-locked screen box. Width/height
--                   are LINKED (both derived from a single projected height
--                   scalar). Only shrinks / grows -- never distorts. Uses a
--                   two-point vertical projection (top/bottom stud markers)
--                   so FOV + distance are respected but character animation
--                   and camera angle don't warp the aspect ratio.
--   "Bounding"   -- fresh GetBoundingBox per frame (breathes with animation)
--   "Prediction" -- Bounding + velocity lookahead to reduce jitter at high ping
local CUBE_EDGE_INDICES = {
    {1,2},{3,4},{1,3},{2,4},   -- front face
    {5,6},{7,8},{5,7},{6,8},   -- back face
    {1,5},{2,6},{3,7},{4,8},   -- connectors
}

-- v0.0.13 Static: aspect-locked, distance-linked, upward offset corrected.
--   Anchor is the character pivot (HumanoidRootPart). We project a 3-stud
--   marker above and a 4-stud marker below (asymmetric -- HRP sits at hip
--   height, so the box extending 3 up + 4 down centers on the visible body
--   and no longer reads as "offset upward"). Screen height = |top2D - bot2D|.
--   Width = height * STATIC_ASPECT (human-silhouette narrow rectangle).
--   Result: only ONE screen scalar drives everything, so width and height
--   are truly linked. Camera angle / character rotation / animation do NOT
--   change the box shape.
local STATIC_TOP_STUDS = 3
local STATIC_BOT_STUDS = 4
local STATIC_ASPECT    = 0.5   -- width = height * 0.5

local function projectStatic(torso)
    -- v0.0.15: anchor is torso.Position, not character:GetPivot(). Pivot
    -- can be stale/unset on some rigs (returns Model.WorldPivot which may
    -- not track HRP movement), which produced Static boxes drifting off
    -- the character. Torso.Position is a live world-space read.
    if not torso or not torso.Parent then return nil, false, false end
    local pos = torso.Position
    local topWorld = pos + Vector3.new(0, STATIC_TOP_STUDS, 0)
    local botWorld = pos + Vector3.new(0, -STATIC_BOT_STUDS, 0)
    local top2D = Camera:WorldToViewportPoint(topWorld)
    local bot2D = Camera:WorldToViewportPoint(botWorld)
    if top2D.Z <= 0 or bot2D.Z <= 0 then return nil, false, false end
    local height  = math.abs(bot2D.Y - top2D.Y)
    local width   = height * STATIC_ASPECT
    local centerX = (top2D.X + bot2D.X) * 0.5
    local centerY = (top2D.Y + bot2D.Y) * 0.5
    local x0 = centerX - width * 0.5
    local y0 = centerY - height * 0.5
    local x1 = x0 + width
    local y1 = y0 + height
    -- Emit 8 "corners" so the render pipeline can treat Static like the
    -- other modes. Front and back use the same 2D rectangle since Static
    -- has no depth information -- Cube mode with Static will render as a
    -- flat rect (Cube is really designed for Bounding / Prediction).
    local avgZ = (top2D.Z + bot2D.Z) * 0.5
    local c = table.create(8)
    c[1] = { x = x1, y = y0, z = avgZ }
    c[2] = { x = x0, y = y0, z = avgZ }
    c[3] = { x = x1, y = y1, z = avgZ }
    c[4] = { x = x0, y = y1, z = avgZ }
    c[5], c[6], c[7], c[8] = c[1], c[2], c[3], c[4]
    return c, true, true
end

-- v0.0.13: manual AABB from cached body parts. Ignores accessories/tools.
-- Uses part.Position + part.Size (axis-aligned) -- fine for character parts
-- which are mostly upright. Returns cframe (center) + size, matching the
-- shape of character:GetBoundingBox.
local function characterOnlyBBox(bodyParts)
    local minX, minY, minZ =  math.huge,  math.huge,  math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local found = false
    for _, part in ipairs(bodyParts) do
        if part.Parent then
            local pos = part.Position
            local hx, hy, hz = part.Size.X * 0.5, part.Size.Y * 0.5, part.Size.Z * 0.5
            if pos.X - hx < minX then minX = pos.X - hx end
            if pos.X + hx > maxX then maxX = pos.X + hx end
            if pos.Y - hy < minY then minY = pos.Y - hy end
            if pos.Y + hy > maxY then maxY = pos.Y + hy end
            if pos.Z - hz < minZ then minZ = pos.Z - hz end
            if pos.Z + hz > maxZ then maxZ = pos.Z + hz end
            found = true
        end
    end
    if not found then return nil end
    local center = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
    local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    return CFrame.new(center), size
end

local function project8(character, sizingType, characterOnly, bodyParts, rig)
    local cf, size
    if characterOnly then
        -- v0.0.15: refresh the cached body-parts list if it's empty (rig was
        -- created before parts fully loaded). Previously we silently fell
        -- back to full GetBoundingBox in this case, which read as "Character
        -- Only doesn't work" -- accessories still counted.
        if not bodyParts or #bodyParts == 0 then
            local fresh = collectBodyParts(character)
            if rig then rig.bodyParts = fresh end
            bodyParts = fresh
        end
        if #bodyParts == 0 then return nil, false, false end
        local c, s = characterOnlyBBox(bodyParts)
        if not c then return nil, false, false end
        cf, size = c, s
    else
        local ok, cframe, sz = pcall(character.GetBoundingBox, character)
        if not ok or not cframe then return nil, false, false end
        cf = cframe
        size = sz
    end
    if sizingType == "Prediction" then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- v0.0.15: prediction stretching fix. Two issues:
            --   1. Vertical velocity (jumping / falling) shifted the box up
            --      while GetBoundingBox stayed grounded -> visible stretch
            --      as the projected corners diverged from ground contact.
            --   2. 0.083s lead was too aggressive for real-world lag.
            -- Fix: zero out Y velocity (predict horizontal motion only) and
            -- drop the lead to 0.05s (~3 frames @ 60fps).
            local vel = hrp.AssemblyLinearVelocity
            local flat = Vector3.new(vel.X, 0, vel.Z)
            cf = cf + flat * 0.05
        end
    end

    local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
    local worldCorners = {
        (cf * CFrame.new( hx,  hy,  hz)).Position,
        (cf * CFrame.new(-hx,  hy,  hz)).Position,
        (cf * CFrame.new( hx, -hy,  hz)).Position,
        (cf * CFrame.new(-hx, -hy,  hz)).Position,
        (cf * CFrame.new( hx,  hy, -hz)).Position,
        (cf * CFrame.new(-hx,  hy, -hz)).Position,
        (cf * CFrame.new( hx, -hy, -hz)).Position,
        (cf * CFrame.new(-hx, -hy, -hz)).Position,
    }
    local screenCorners = table.create(8)
    local anyInFront, allInFront = false, true
    for i, wp in ipairs(worldCorners) do
        local sp = Camera:WorldToViewportPoint(wp)
        screenCorners[i] = { x = sp.X, y = sp.Y, z = sp.Z }
        if sp.Z > 0 then anyInFront = true else allInFront = false end
    end
    return screenCorners, anyInFront, allInFront
end

local function hideRigVisuals(rig)
    rig.boxRoot.Visible = false
    for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
    for _, f in ipairs(rig.boxCorners) do f.Visible = false end
    if rig.boxHalo then
        rig.boxHalo.outer.Visible = false
        rig.boxHalo.inner.Visible = false
    end
    -- reset smoothing state so re-enable snaps rather than lerping from stale
    rig.lastBoxPos = nil
    rig.lastBoxSize = nil
end

-- v0.0.13 render: gates are strict (dead / despawned / out-of-range / ancestry
-- broken -> hide immediately). Every visible ESP element is opt-in via its own
-- config toggle -- master ESP shows nothing on its own. Outline is a decorative
-- accent switch, NOT a gate for the box existing.
local function updateESPRigs()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local localTeam = LocalPlayer.Team
    for plr, entry in pairs(ESP.Rigs) do
        local rig = entry.rig
        -- v0.0.15 hard life gate. Torso (HRP) replaces head as the anchor:
        -- head is above the visible body so anchoring there produced boxes
        -- offset upward + reading as "grabbing UI." Torso sits at hip level,
        -- centered on the visible body. If the torso reference goes stale
        -- (rig-swapping games, respawn mid-frame), re-resolve from character.
        if not rig then continue end
        if not (rig.character and rig.character.Parent) then
            hideRigVisuals(rig); continue
        end
        if not (rig.torso and rig.torso.Parent) then
            rig.torso = findTorso(rig.character)
        end
        if not (rig.torso and rig.torso.Parent) then
            hideRigVisuals(rig); continue
        end
        local hum = rig.character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            hideRigVisuals(rig); continue
        end

        -- gates
        if plr == LocalPlayer and not ESP.Config.SelfESP then
            hideRigVisuals(rig); continue
        end
        local sameTeam = plr.Team and localTeam and plr.Team == localTeam
        if sameTeam and ESP.Config.TeamCheck then
            hideRigVisuals(rig); continue
        end
        local dist = (rig.torso.Position - camPos).Magnitude
        if dist > ESP.Config.RenderDistance then
            hideRigVisuals(rig); continue
        end

        -- v0.0.14: text-side rendering (names, distance, text background) all
        -- lives in the future Names/Distance module. This block is now just
        -- box logic -- no BillboardGui to enable, no labels to update.

        -- v0.0.14 box gate: whole box widget hides when Boxes.Enabled is off.
        -- Enabling ESP alone shows NO box -- Boxes has to be turned on for it.
        if not ESP.Boxes.Enabled then
            rig.boxRoot.Visible = false
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            if rig.boxHalo then
                rig.boxHalo.outer.Visible = false
                rig.boxHalo.inner.Visible = false
            end
            continue
        end

        -- BOX projection dispatch:
        --   Static -> aspect-locked, distance-linked screen box (no camera-angle warp).
        --             Cube mode is inherently 3D and needs depth info Static doesn't
        --             have, so Cube auto-falls-through to Bounding regardless of the
        --             SizingType dropdown -- otherwise a "Static + Cube" combo would
        --             draw a flat 2D rect (front and back corners identical).
        --   Bounding / Prediction -> 8-corner world projection with optional CharacterOnly.
        local corners, anyInFront, allInFront
        local isCube = ESP.Boxes.BoxType == "Cube"
        local effectiveSizing = ESP.Config.SizingType
        if isCube and effectiveSizing == "Static" then
            effectiveSizing = "Bounding"
        end
        if effectiveSizing == "Static" then
            corners, anyInFront, allInFront = projectStatic(rig.torso)
        else
            corners, anyInFront, allInFront =
                project8(rig.character, effectiveSizing,
                         ESP.Config.CharacterOnly, rig.bodyParts, rig)
        end

        if not corners or not anyInFront or not allInFront then
            rig.boxRoot.Visible = false
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            if rig.boxHalo then
                rig.boxHalo.outer.Visible = false
                rig.boxHalo.inner.Visible = false
            end
            continue
        end

        local outlineColor = ESP.Boxes.OutlineColor
        -- v0.0.14: TeamBasedColor now applies to box outline (was applied to
        -- text, which no longer exists in this module). Overrides only for
        -- same-team players.
        if ESP.Config.TeamBasedColor and sameTeam then
            outlineColor = ESP.Colors.Team
        end
        local fillColor    = ESP.Boxes.FillColor
        local fillOn       = ESP.Boxes.FillBox
        local cornersMode  = ESP.Boxes.Corners
        local cornerLen    = math.clamp(ESP.Boxes.CornerLength, 0.02, 0.5)
        -- v0.0.15 Outline: gates the box LINES (2D UIStroke AND cube edges).
        -- Fill + Corners are independent visual elements not gated by Outline.
        -- Turning Outline off means "no full-outline lines"; the box still
        -- exists via Fill and/or Corners.
        local outlineOn    = ESP.Config.Outline
        -- (isCube already declared above at the projection dispatch)

        -- projected AABB (2D box uses this directly; cube uses it for the
        -- optional Fill layer that sits behind the edges)
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, c in ipairs(corners) do
            if c.x < minX then minX = c.x end
            if c.x > maxX then maxX = c.x end
            if c.y < minY then minY = c.y end
            if c.y > maxY then maxY = c.y end
        end
        local w, h = maxX - minX, maxY - minY

        -- v0.0.13 Immediate Mode:
        --   true  = snap box pos/size to target each frame (matches character
        --           movement 1:1, no lag, may jitter slightly on fast pans)
        --   false = lerp pos/size toward target at 0.35 per frame (smoother,
        --           slight visible drag when the character teleports)
        local tX, tY, tW, tH
        if ESP.Config.ImmediateMode then
            tX, tY, tW, tH = minX, minY, w, h
            rig.lastBoxPos = nil     -- reset smoothing state so re-enable snaps
            rig.lastBoxSize = nil
        else
            rig.lastBoxPos  = rig.lastBoxPos  or Vector2.new(minX, minY)
            rig.lastBoxSize = rig.lastBoxSize or Vector2.new(w, h)
            rig.lastBoxPos  = rig.lastBoxPos:Lerp(Vector2.new(minX, minY), 0.35)
            rig.lastBoxSize = rig.lastBoxSize:Lerp(Vector2.new(w, h), 0.35)
            tX, tY = rig.lastBoxPos.X, rig.lastBoxPos.Y
            tW, tH = rig.lastBoxSize.X, rig.lastBoxSize.Y
        end
        rig.boxRoot.Position = UDim2.new(0, tX, 0, tY)
        rig.boxRoot.Size = UDim2.new(0, tW, 0, tH)
        rig.boxRoot.BackgroundColor3 = fillColor

        -- HALO (glow): scaled outward from AABB, tinted with outline color.
        -- 2 layers for a soft falloff. Uses the AABB even in cube mode so the
        -- halo remains a coherent bright bloom instead of a rotating polygon.
        if rig.boxHalo then
            if ESP.Config.Glow then
                local o = rig.boxHalo.outer
                local n = rig.boxHalo.inner
                o.Position = UDim2.new(0, tX - 6, 0, tY - 6)
                o.Size = UDim2.new(0, tW + 12, 0, tH + 12)
                o.BackgroundColor3 = outlineColor
                o.BackgroundTransparency = 0.85
                o.Visible = true
                n.Position = UDim2.new(0, tX - 3, 0, tY - 3)
                n.Size = UDim2.new(0, tW + 6, 0, tH + 6)
                n.BackgroundColor3 = outlineColor
                n.BackgroundTransparency = 0.65
                n.Visible = true
            else
                rig.boxHalo.outer.Visible = false
                rig.boxHalo.inner.Visible = false
            end
        end

        if isCube then
            -- boxRoot serves as the AABB Fill layer only in cube mode.
            rig.boxRoot.Visible = fillOn
            rig.boxRoot.BackgroundTransparency = fillOn and 0.72 or 1
            if rig.boxOutline then rig.boxOutline.Enabled = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end

            -- v0.0.15: cube edges/vertices gated by Outline OR Corners. In
            -- cube mode the edges ARE the box lines -- Outline off means "no
            -- full-outline lines," so full edges hide. Corners on is the
            -- alternative line style (vertex brackets) and shows regardless
            -- of Outline. If BOTH are off, cube shows only fill (if enabled).
            local wantLines = outlineOn or cornersMode
            local thick = ESP.Config.Glow and 2 or 1
            -- v0.0.15: cap corner segment length at CORNER_MAX_PX so brackets
            -- don't dominate huge close-up boxes.
            local CORNER_MAX_PX = 28
            for i, pair in ipairs(CUBE_EDGE_INDICES) do
                local a = corners[pair[1]]
                local b = corners[pair[2]]
                local aEdge = rig.cubeEdges[i]           -- slots 1..12
                local bEdge = rig.cubeEdges[i + 12]      -- slots 13..24
                local dx, dy = b.x - a.x, b.y - a.y
                local length = math.sqrt(dx * dx + dy * dy)
                if length < 1 or not wantLines then
                    aEdge.Visible = false
                    bEdge.Visible = false
                else
                    local rot = math.deg(math.atan2(dy, dx))
                    if cornersMode then
                        local segLen = math.clamp(length * cornerLen, 3, CORNER_MAX_PX)
                        aEdge.AnchorPoint = Vector2.new(0, 0.5)
                        aEdge.Position = UDim2.new(0, a.x, 0, a.y)
                        aEdge.Size = UDim2.new(0, segLen, 0, thick)
                        aEdge.Rotation = rot
                        aEdge.BackgroundColor3 = outlineColor
                        aEdge.BackgroundTransparency = 0
                        aEdge.Visible = true
                        bEdge.AnchorPoint = Vector2.new(1, 0.5)
                        bEdge.Position = UDim2.new(0, b.x, 0, b.y)
                        bEdge.Size = UDim2.new(0, segLen, 0, thick)
                        bEdge.Rotation = rot
                        bEdge.BackgroundColor3 = outlineColor
                        bEdge.BackgroundTransparency = 0
                        bEdge.Visible = true
                    else
                        aEdge.AnchorPoint = Vector2.new(0.5, 0.5)
                        aEdge.Position = UDim2.new(0, (a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
                        aEdge.Size = UDim2.new(0, length, 0, thick)
                        aEdge.Rotation = rot
                        aEdge.BackgroundColor3 = outlineColor
                        aEdge.BackgroundTransparency = 0
                        aEdge.Visible = true
                        bEdge.Visible = false
                    end
                end
            end
        else
            -- 2D bounding box. boxRoot IS the box. cube frames off.
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            rig.boxRoot.Visible = true
            rig.boxRoot.BackgroundTransparency = fillOn and 0.72 or 1

            -- UIStroke controlled by Outline toggle (accent). When corners
            -- mode is on, the stroke gives way to the corner brackets.
            if rig.boxOutline then
                rig.boxOutline.Color = outlineColor
                rig.boxOutline.Thickness = 1
                rig.boxOutline.Transparency = 0
                rig.boxOutline.Enabled = outlineOn and not cornersMode
            end

            -- Corner brackets: independent of Outline (they ARE the box lines
            -- in corners mode, not a decorative accent on top of a stroke).
            -- v0.0.15: cap segment length at 28px so brackets don't dominate
            -- huge close-up boxes.
            if cornersMode then
                local segLen = math.clamp(math.min(tW, tH) * cornerLen, 3, 28)
                local thick = 1
                local specs = {
                    { UDim2.new(0, 0, 0, 0),            UDim2.new(0, segLen, 0, thick) },
                    { UDim2.new(0, 0, 0, 0),            UDim2.new(0, thick,  0, segLen) },
                    { UDim2.new(1, -segLen, 0, 0),      UDim2.new(0, segLen, 0, thick) },
                    { UDim2.new(1, -thick, 0, 0),       UDim2.new(0, thick,  0, segLen) },
                    { UDim2.new(0, 0, 1, -thick),       UDim2.new(0, segLen, 0, thick) },
                    { UDim2.new(0, 0, 1, -segLen),      UDim2.new(0, thick,  0, segLen) },
                    { UDim2.new(1, -segLen, 1, -thick), UDim2.new(0, segLen, 0, thick) },
                    { UDim2.new(1, -thick, 1, -segLen), UDim2.new(0, thick,  0, segLen) },
                }
                for i, spec in ipairs(specs) do
                    local f = rig.boxCorners[i]
                    f.Position = spec[1]
                    f.Size = spec[2]
                    f.BackgroundColor3 = outlineColor
                    f.BackgroundTransparency = 0
                    f.Visible = true
                end
            else
                for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            end
        end
    end
end

local espModule = registerModule("esp", "ESP",
    function()
        -- v0.0.14: task.spawn per-player so makeRig's WaitForChild("Head", 3)
        -- doesn't cascade -- each player's rig setup runs in its own coroutine.
        -- Full-server initial attach is now roughly single-player-latency
        -- instead of Nx it.
        for _, plr in ipairs(Players:GetPlayers()) do
            task.spawn(applyESP, plr)
        end
        table.insert(ESP.Connections, Players.PlayerAdded:Connect(function(plr)
            task.spawn(applyESP, plr)
        end))
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

-- v0.0.14: arraylist subtitle -- "ESP box" (or "ESP box, chams" when chams
-- ships). Returns leading-space + comma-joined sub-mode names. Empty string
-- when nothing sub-active so the label renders as just "ESP" cleanly.
espModule.GetDetail = function()
    local parts = {}
    if ESP.Boxes.Enabled then table.insert(parts, "box") end
    -- future: chams, health, names, distance -- append their Enabled flags here
    if #parts == 0 then return "" end
    return " " .. table.concat(parts, ", ")
end

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

-- helper: attach two color swatches (visible + hidden) to a Visible Check row
local function attachDualSwatch(row, visColor, hidColor, onVis, onHid)
    local wrap = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 38,
        Parent = row,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    colorSwatch(wrap, visColor, 14, { onChange = onVis })
    colorSwatch(wrap, hidColor, 14, { onChange = onHid })
end

addTab("Visuals", function(root)
    -- ESP panel
    local espPanel = panel(root, "esp")

    local master = moduleCheckbox(espPanel, "Enabled", "esp")
    keybindPill(master.row, "esp", Enum.KeyCode.E)

    -- v0.0.14: Names / Distance / Text Background rows removed. They're moving
    -- to a dedicated "Names" module later. ESP master now controls the shared
    -- plumbing (team / visibility / outline / glow / self-esp / character-only /
    -- immediate / sizing / render distance) that the box + future name/chams/
    -- health modules read from.
    configCheckbox(espPanel, "Team Check",       ESP.Config.TeamCheck,      function(v) ESP.Config.TeamCheck      = v end)

    local visRow = configCheckbox(espPanel, "Visible Check", ESP.Config.VisibleCheck, function(v) ESP.Config.VisibleCheck = v end)
    attachDualSwatch(visRow.row,
        ESP.Colors.Visible, ESP.Colors.Hidden,
        function(c) ESP.Colors.Visible = c end,
        function(c) ESP.Colors.Hidden  = c end)

    configCheckbox(espPanel, "Team Based Color", ESP.Config.TeamBasedColor, function(v) ESP.Config.TeamBasedColor = v end)
    -- v0.0.15: Text Background is shared plumbing. Multiple future overlays
    -- (Names, Distance, Health) will read this flag to decide whether their
    -- text sits on a subtle background pill. Stored here so preferences
    -- follow the ESP module, which is always loaded.
    configCheckbox(espPanel, "Text Background",  ESP.Config.TextBackground, function(v) ESP.Config.TextBackground = v end)
    configCheckbox(espPanel, "Outline",          ESP.Config.Outline,        function(v)
        ESP.Config.Outline = v
        applyGlobalOutline()   -- flips arraylist accent line + future overlays
    end)
    configCheckbox(espPanel, "Glow",             ESP.Config.Glow,           function(v) ESP.Config.Glow           = v end)
    configCheckbox(espPanel, "Self ESP",         ESP.Config.SelfESP,        function(v) ESP.Config.SelfESP        = v end)
    configCheckbox(espPanel, "Character Only",   ESP.Config.CharacterOnly,  function(v) ESP.Config.CharacterOnly  = v end)
    configCheckbox(espPanel, "Immediate Mode",   ESP.Config.ImmediateMode,  function(v) ESP.Config.ImmediateMode  = v end)

    dropdown(espPanel, "Sizing Type", { "Static", "Bounding", "Prediction" }, ESP.Config.SizingType,
        function(v) ESP.Config.SizingType = v end)

    slider(espPanel, "Render Distance", 1, 30000, ESP.Config.RenderDistance, 0,
        function(v) ESP.Config.RenderDistance = v end)

    -- Boxes panel (below ESP)
    local boxesPanel = panel(root, "boxes")

    local boxesMaster = configCheckbox(boxesPanel, "Enabled", ESP.Boxes.Enabled,
        function(v) ESP.Boxes.Enabled = v end)
    attachDualSwatch(boxesMaster.row,
        ESP.Boxes.OutlineColor, ESP.Boxes.FillColor,
        function(c) ESP.Boxes.OutlineColor = c end,
        function(c) ESP.Boxes.FillColor    = c end)

    configCheckbox(boxesPanel, "Fill Box", ESP.Boxes.FillBox,
        function(v) ESP.Boxes.FillBox = v end)

    dropdown(boxesPanel, "Box Type", { "2D", "Cube" }, ESP.Boxes.BoxType,
        function(v) ESP.Boxes.BoxType = v end)

    configCheckbox(boxesPanel, "Corners", ESP.Boxes.Corners,
        function(v) ESP.Boxes.Corners = v end)

    slider(boxesPanel, "Corner Length", 0.05, 0.5, ESP.Boxes.CornerLength, 2,
        function(v) ESP.Boxes.CornerLength = v end)
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
