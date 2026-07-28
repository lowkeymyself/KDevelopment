-- koffee v0.0.28
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.0.28"

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
    -- v0.0.21 typography: match Matcha. Matcha's face is a soft rounded humanist
    -- at a heavy-ish weight, kept small -- reads premium without the sharp,
    -- "Roblox default" edge BuilderSans/Sarpanch had. Nunito is the closest
    -- built-in family (same soft-round humanist DNA); baselined at SemiBold so it
    -- never goes thin like the v0.0.5 Regular-weight attempt did. Bold for
    -- emphasis + wordmark. Mono stays RobotoMono for keybind pills / numerals.
    Fonts = (function()
        local UI    = "rbxasset://fonts/families/Nunito.json"
        local MONO  = "rbxasset://fonts/families/RobotoMono.json"
        return {
            Regular = Font.new(UI,   Enum.FontWeight.SemiBold),
            Medium  = Font.new(UI,   Enum.FontWeight.Bold),
            Bold    = Font.new(UI,   Enum.FontWeight.Bold),
            Title   = Font.new(UI,   Enum.FontWeight.ExtraBold),
            Mono    = Font.new(MONO, Enum.FontWeight.Medium),
        }
    end)(),
    Sizes = {
        HudHeight    = 34,
        -- bigger overall so density stays right at larger text sizes
        WindowWidth  = 640,
        WindowHeight = 820,
        TabBarHeight = 40,
    },
    Radius = { Small = 4, Medium = 6, Large = 8, XLarge = 12 },
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
-- v0.0.17: removed cached `Camera` global. All camera reads now go through
-- Workspace.CurrentCamera fresh, so games that swap CurrentCamera (custom
-- camera systems) don't leave us projecting through a dead camera.

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
-- v0.0.22: text-specific outline. Contextual mode hugs the GLYPHS of a
-- transparent-background TextLabel instead of boxing the whole label rect --
-- Border mode drew a black rectangle around every ESP label ("black box" bug).
local function textStroke(color, thick)
    return new("UIStroke", {
        Color = color or Color3.new(0, 0, 0),
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
    })
end
-- v0.0.24: the global Outline effect as a border around a thin feature line-frame
-- (skeleton, cube edge, tracer, corner, head dot). A UIStroke around the frame
-- renders as a separate dark edge on every side -- an outline that is truly its
-- OWN line, independent of the feature's fill colour. Disabled by default; the
-- render loop enables/colours/sizes it per frame. Named so it's findable.
local function lineOutline()
    return new("UIStroke", {
        Name = "KOutline",
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
-- v0.0.25: per-line animated gradient (the "Gradient" toggle). Disabled by
-- default; the render loop enables/colours/offsets it. Named so it's findable.
local function lineGradient()
    return new("UIGradient", { Name = "KGrad", Enabled = false })
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
    -- v0.0.17: read CurrentCamera fresh each call. Caching it at script init
    -- goes stale in games that swap CurrentCamera (custom camera systems).
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(0, 0)
end

-- v0.0.22 popup placement fix. Popups (dropdown lists, color picker, tooltips)
-- live in `popupScreen`, but their anchor buttons/swatches live in the main
-- `screen`. Empirically these two top-level ScreenGuis report AbsolutePosition in
-- DIFFERENT reference frames (offset by the GUI inset, e.g. 58px) even though both
-- set IgnoreGuiInset=true -- so writing a button's AbsolutePosition straight into a
-- popup's Position.Offset lands it `inset` px too high (the old "dropdown opens in
-- the middle of the button" bug). Given a desired screen-space TOP-LEFT, this
-- returns the Position offset that makes the popup's AbsolutePosition hit that
-- point, by subtracting the popup's live drift (Absolute - Offset). Self-
-- calibrating: collapses to a no-op when there's no mismatch, so it's always safe.
local function popupOffsetFor(popupFrame, screenX, screenY)
    local dx = popupFrame.AbsolutePosition.X - popupFrame.Position.X.Offset
    local dy = popupFrame.AbsolutePosition.Y - popupFrame.Position.Y.Offset
    return screenX - dx, screenY - dy
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
-- optional detail suffix (e.g. "box" / "box, name") in Muted color.
-- v0.0.17: detail suffix is now smaller (size 12 vs body 14) + wider spacing
-- from the base name per he. RichText <font size='N'> drives the size delta.
local ARRAYLIST_MUTED_COLOR = "rgb(138,125,112)"   -- Theme.Palette.TextMuted
local ARRAYLIST_DETAIL_SIZE = 12                    -- smaller than Body (14)

local function buildArrayLabelText(mod)
    local base = mod.DisplayName or mod.Id or "?"
    local detail = mod.GetDetail and mod.GetDetail() or ""
    if detail and detail ~= "" then
        return string.format("%s<font size='%d' color='%s'>%s</font>",
            base, ARRAYLIST_DETAIL_SIZE, ARRAYLIST_MUTED_COLOR, detail)
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
    -- v0.0.16: do NOT nil mod._wrapper here. addToActiveArray needs the
    -- reference to destroy the dying wrapper if the module is re-enabled
    -- during the 0.14s destroy-delay window (the fade itself is 0.10s; the
    -- wrapper lingers until the task.delay(0.14) below). Nilling it here orphaned the wrapper
    -- (the canceled destroy thread never ran, the frame stayed parented to
    -- labelsColumn consuming a LayoutOrder slot and ROW_HEIGHT pixels).
    -- If the destroy thread completes normally, mod._wrapper.Parent becomes
    -- nil and addToActiveArray's existence check skips the Destroy call.
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

-- v0.0.22: vertical resize grip at the window's bottom edge. Dragging it only
-- changes the window HEIGHT -- the top edge stays put and the tab ScrollingFrames
-- just crop/scroll to the new height. Nothing reflows horizontally.
local MIN_WIN_H, MAX_WIN_H = 360, 1000
local resizeGrip = new("TextButton", {
    Name = "ResizeGrip",
    Text = "",
    AutoButtonColor = false,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, 0),
    Size = UDim2.new(1, -24, 0, 12),
    BackgroundTransparency = 1,
    ZIndex = 33,
    Parent = window,
}, {
    new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 42, 0, 3),
        BackgroundColor3 = Theme.Palette.TextFaint,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 34,
    }, { pillCorner() }),
})
do
    local resizing, startY, startH, startPosOff
    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startY = input.Position.Y
            startH = window.Size.Y.Offset
            startPosOff = window.Position.Y.Offset
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
                       or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position.Y - startY
            local newH = math.clamp(startH + d, MIN_WIN_H, MAX_WIN_H)
            local applied = newH - startH
            window.Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset, 0, newH)
            -- center anchor: shift center down by half the growth so the TOP edge
            -- stays fixed and the window only extends/crops from the bottom.
            window.Position = UDim2.new(
                window.Position.X.Scale, window.Position.X.Offset,
                window.Position.Y.Scale, startPosOff + applied * 0.5)
        end
    end)
end

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
        corner(Theme.Radius.XLarge),   -- v0.0.22: rounder feature boxes (per Matcha)
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
        AutomaticSize = Enum.AutomaticSize.X,   -- v0.0.17: grow for long key names
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
    }, {
        pillCorner(),
        stroke(Theme.Palette.BorderSubtle),
        -- v0.0.17: pad so AutomaticSize.X doesn't glue text to the edges
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }),
    })
    pill.MouseEnter:Connect(function()
        tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text })
    end)
    pill.MouseLeave:Connect(function()
        if not (pendingRebind and pendingRebind.moduleId == moduleId) then
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        end
    end)
    pill.MouseButton1Click:Connect(function()
        -- v0.0.17: restore any previously-pending pill before switching rebind
        -- target. Without this, clicking pill A then pill B leaves pill A
        -- stuck showing "..." forever.
        if pendingRebind and pendingRebind.pill ~= pill then
            local prev = Keybinds[pendingRebind.moduleId]
            pendingRebind.pill.Text = prev and prev.Name or "-"
            tween(pendingRebind.pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        end
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

    local function applyToUI()
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
    -- v0.0.16: cancel any pending close from a prior closeColorPicker call.
    -- Without this, the task.delay(0.22) from close fires AFTER open and
    -- hides the now-visible picker.
    if ColorPicker.closeTask then
        pcall(task.cancel, ColorPicker.closeTask)
        ColorPicker.closeTask = nil
    end
    ColorPicker.activeSwatch = swatchInstance
    ColorPicker.callback = onChange
    local h, s, v = initialColor:ToHSV()
    ColorPicker.h, ColorPicker.s, ColorPicker.v = h, s, v
    -- position near swatch (below + right, but clamp to viewport)
    local abs = swatchInstance.AbsolutePosition
    local siz = swatchInstance.AbsoluteSize
    local vp = Workspace.CurrentCamera.ViewportSize
    local pickerW, pickerH = 260, 260
    local dx = math.min(abs.X, vp.X - pickerW - 8)
    local dy = math.min(abs.Y + siz.Y + 6, vp.Y - pickerH - 8)
    -- convert screen-space target -> popup Position offset (inset-safe).
    local x, y = popupOffsetFor(ColorPicker.root, dx, dy)
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
    -- v0.0.16: track the close thread so openColorPicker can cancel it if
    -- the picker is reopened before the fade completes.
    if ColorPicker.closeTask then
        pcall(task.cancel, ColorPicker.closeTask)
    end
    ColorPicker.closeTask = task.delay(0.22, function()
        ColorPicker.closeTask = nil
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

    -- v0.0.17: tooltip parented to popupScreen (not the swatch) so it
    -- escapes the window CanvasGroup's clip bounds. Positioned live on
    -- every hover from the swatch's AbsolutePosition.
    local TIP_W, TIP_H = 132, 34
    local tip = new("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, TIP_W, 0, TIP_H),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 100,
        Parent = popupScreen,
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

    sw.MouseEnter:Connect(function()
        local abs = sw.AbsolutePosition
        local siz = sw.AbsoluteSize
        local vp  = Workspace.CurrentCamera.ViewportSize
        local tipX = abs.X + siz.X * 0.5 - TIP_W * 0.5
        local tipY = abs.Y - TIP_H - 8
        tipX = math.clamp(tipX, 4, vp.X - TIP_W - 4)
        if tipY < 4 then tipY = abs.Y + siz.Y + 8 end
        local ox, oy = popupOffsetFor(tip, tipX, tipY)   -- inset-safe placement
        tip.Position = UDim2.new(0, ox, 0, oy)
        tip.Visible = true
    end)
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
    -- v0.0.20: fully rule-based placement. Anchor the list's TOP-LEFT to the
    -- button's bottom-left every frame, clamp X into the viewport, and flip the
    -- list ABOVE the button when there isn't room below. No hardcoded offsets --
    -- everything derives from the button's live rect + the viewport size.
    local GAP = 6
    local function placeBelow()
        local abs = btn.AbsolutePosition
        local siz = btn.AbsoluteSize
        if siz.X <= 0 or siz.Y <= 0 then return end
        local vp = viewport()
        local listH = #options * 26
        list.AnchorPoint = Vector2.new(0, 0)
        -- desired TOP-LEFT in the button's screen space.
        local desX = abs.X
        local desY = abs.Y + siz.Y + GAP
        -- flip above only if there is genuinely no room below.
        if vp.Y > 0 and desY + listH > vp.Y then
            local aboveY = abs.Y - listH - GAP
            if aboveY >= 0 then desY = aboveY end
        end
        if vp.X > 0 then
            desX = math.clamp(desX, 0, math.max(0, vp.X - siz.X))
        end
        -- convert the screen-space target into this popup's Position offset so it
        -- actually lands there (see popupOffsetFor -- fixes the inset mismatch).
        local ox, oy = popupOffsetFor(list, desX, desY)
        list.Size = UDim2.new(0, siz.X, 0, listH)
        list.Position = UDim2.new(0, ox, 0, oy)
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
        -- v0.0.17: option buttons stay at BackgroundTransparency = 1 always
        -- (only hover brings them to 0.7). The old transparency tween here
        -- was a no-op. Only the text labels need to fade out.
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
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
        -- v0.0.17: only text labels fade in. Option button bg is always 1
        -- (invisible) -- hover drives it to 0.7.
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
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
-- RIGHT-CLICK SETTINGS POPUP (v0.0.25)
-- Right-click a config row to open a small floating panel of extra controls
-- (built by the caller via api:slider(...)). Lives in popupScreen like the
-- dropdowns / colour picker, positioned inset-safe, closes on outside click.
--============================================================
local openSettingsPopups = {}   -- frame -> close fn

local function rightClickSettings(row, title, buildFn)
    local btn
    for _, c in ipairs(row:GetDescendants()) do
        if c:IsA("TextButton") then btn = c break end
    end
    if not btn then return end

    local popupFrame, isOpen = nil, false
    local function ensurePopup()
        if popupFrame then return end
        popupFrame = new("Frame", {
            Name = "Settings",
            Size = UDim2.new(0, 210, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Palette.Panel,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 210,
            Parent = popupScreen,
        }, {
            corner(6), stroke(Theme.Palette.Border, 1),
            new("UIPadding", {
                PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            }),
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        new("TextLabel", {
            Text = title, FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
            TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 211, Parent = popupFrame,
        })
        local api = {}
        function api:slider(label, mn, mx, initial, precision, onChange)
            slider(popupFrame, label, mn, mx, initial, precision, onChange)
        end
        function api:toggle(label, initial, onChange)
            configCheckbox(popupFrame, label, initial, onChange)
        end
        function api:dropdown(label, options, initial, onChange)
            dropdown(popupFrame, label, options, initial, onChange)
        end
        -- v0.0.28: colour control inside a settings popup (label + right swatch).
        function api:swatch(label, initial, onChange)
            local r = new("Frame", {
                Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
                ZIndex = 211, Parent = popupFrame,
            })
            new("TextLabel", {
                Text = label, FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
                TextColor3 = Theme.Palette.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1, -22, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 212, Parent = r,
            })
            local wrap = new("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 16), BackgroundTransparency = 1,
                ZIndex = 212, Parent = r,
            })
            colorSwatch(wrap, initial, 14, { onChange = onChange })
        end
        buildFn(api)
    end

    local function closePopup()
        if not isOpen then return end
        isOpen = false
        openSettingsPopups[popupFrame] = nil
        if popupFrame then popupFrame.Visible = false end
    end
    local function openPopup()
        ensurePopup()
        for _, closer in pairs(openSettingsPopups) do closer() end
        for _, closer in pairs(openDropdowns) do closer(true) end
        isOpen = true
        openSettingsPopups[popupFrame] = closePopup
        local abs, siz, vp = btn.AbsolutePosition, btn.AbsoluteSize, viewport()
        local dx = math.min(abs.X + siz.X - 40, math.max(4, vp.X - 214))
        local dy = math.min(abs.Y, math.max(4, vp.Y - 90))
        local ox, oy = popupOffsetFor(popupFrame, dx, dy)
        popupFrame.Position = UDim2.new(0, ox, 0, oy)
        popupFrame.Visible = true
    end

    btn.MouseButton2Click:Connect(function()
        if isOpen then closePopup() else openPopup() end
    end)
end

-- outside-click closer for the settings popups (own handler since openSettingsPopups
-- is declared below the main dropdown/picker closer).
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = input.Position
    for frame, closer in pairs(openSettingsPopups) do
        local abs, siz = frame.AbsolutePosition, frame.AbsoluteSize
        local inside = mp.X >= abs.X and mp.X <= abs.X + siz.X
                   and mp.Y >= abs.Y and mp.Y <= abs.Y + siz.Y
        if not inside then closer() end
    end
end)

--============================================================
-- ESP MODULE (v0.0.10)
-- Master toggle ("Enabled") just turns on the ESP framework + render loop.
-- Nothing draws until a sub-feature (Box / Name / Indicators / Health /
-- Tracer) is enabled -- the master applies no color to players on its own.
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
        -- v0.0.28: Text Background is now tunable (right-click the toggle): colour,
        -- transparency, and padding around every ESP text tag.
        TextBgColor        = Color3.fromRGB(0, 0, 0),
        TextBgTransparency = 0.35,
        TextBgPadding      = 5,
        CharacterOnly  = false,      -- ignore accessories/tools in bounding-box calc
        -- v0.0.28: Follow Direction is a CUBE-ONLY feature (orienting a flat 2D box
        -- to facing only made it less accurate). Default OFF; the Box Type dropdown
        -- forces it off on any switch and the toggle refuses to arm unless Cube.
        FollowDirection = false,     -- v0.0.23: box/cube orients to the player's facing
        ImmediateMode  = true,       -- true = snap-to-frame, false = lerp smoothing
        TeamCheck      = false,
        VisibleCheck   = false,
        TeamBasedColor = false,      -- team color overrides box outline color on same-team
        -- v0.0.17 Outline redesign: Outline is a thickness ACCENT, not a
        -- gate. Box lines (2D stroke / cube edges) ALWAYS render when the
        -- box is visible. Outline adds +1px thickness to all box lines.
        -- v0.0.19: Glow removed (deferred to helper app for real C++ blur).
        --   off: 1px | on: 2px
        -- v0.0.19: Outline no longer controls the arraylist accent line.
        Outline        = true,
        SelfESP        = false,
        TextGradient   = false,        -- v0.0.21: animated gradient on all ESP text
        -- v0.0.22: text gradient endpoint colors, editable via two swatches.
        GradientColorA = Color3.fromRGB(255, 253, 248),
        GradientColorB = Color3.fromRGB(212, 145, 90),
        -- v0.0.25: Gradient = animated gradient on every NON-text Second-Interface
        -- element (box, cube edges, corners, skeleton, tracer, head dot). Own
        -- colours. When on it OVERRIDES each feature's colour.
        Gradient       = false,
        GradientColorA2 = Color3.fromRGB(120, 200, 255),
        GradientColorB2 = Color3.fromRGB(200, 130, 255),
        -- v0.0.26: gradient tuning (right-click the Gradient toggle).
        GradientSpeed     = 0.5,   -- cycles/sec
        GradientRotation  = 0,     -- degrees; 0 = horizontal, 90 = vertical
        GradientSpacing   = 0.5,   -- 0..1 where the B color sits between the A ends
        GradientReverse   = false, -- flip travel direction
        SizingType     = "Static",     -- per he: Static first + default
        RenderDistance = 1000,
    },
    -- v0.0.22: shared Feature-Interface render model. One place drives the
    -- thickness of every rendered feature (box lines, cube edges, skeleton,
    -- tracer, corners, head dot, health bar). EqualSize on = constant thickness
    -- regardless of distance; off = thickness scales with distance (thicker up
    -- close, thinner far) so it reads like classic depth-scaled ESP.
    Render = {
        Thickness = 1,       -- base px thickness for all feature lines
        EqualSize = true,    -- true = distance-invariant, false = distance-scaled
    },
    Boxes = {
        Enabled      = false,
        -- v0.0.24: box's MAIN line color, now separate from the Outline. Changing
        -- this no longer drags the outline with it.
        Color        = Color3.fromRGB(255, 255, 255),
        -- Outline is a SEPARATE bordering line drawn around every feature (see
        -- ESP.Config.Outline). This is its color -- default black so it reads as a
        -- crisp border regardless of the feature colors.
        OutlineColor = Color3.fromRGB(0, 0, 0),
        FillColor    = Color3.fromRGB(212, 145, 90),
        FillBox      = false,
        FillTransparency = 0.72,   -- v0.0.28: right-click Fill Box to tune (0=solid, 1=invisible)
        BoxType      = "2D",       -- "2D" | "Cube"
        Corners      = false,
        CornerLength = 0.3,        -- 0-1, fraction of edge length
        -- v0.0.26: right-click the box "Enabled" toggle. 0 = use universal Thickness.
        Thickness        = 0,
        OutlineThickness = 2,      -- extra px the outline extends beyond the line
    },
    -- v0.0.21: Name overlay (billboard text above the head).
    Names = {
        Enabled = false,
        Type    = "Name",          -- "Name" (username) | "Display Name"
        Color   = Color3.fromRGB(255, 255, 255),
        TextSize         = 14,     -- v0.0.28: right-click Name to change
        OutlineThickness = 1,      -- v0.0.28: right-click Name to change
    },
    -- v0.0.21: Indicators -- small per-target markers.
    -- v0.0.25: per-feature settings (right-click popups): Distance.TextSize,
    -- Skeleton.Thickness (0 = use the universal Thickness), HeadDot.Size.
    Indicators = {
        Distance       = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), TextSize = 13, OutlineThickness = 1 }, -- below feet
        Skeleton       = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 0 }, -- 0 = universal
        HeadDot        = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Size = 6 },       -- dot at head
        -- v0.0.28: right-click Profile Picture for Size / Outline Thickness / Y Offset.
        ProfilePicture = { Enabled = false, Size = 40, OutlineThickness = 1, YOffset = 0 },          -- avatar above name
    },
    -- v0.0.21: Health -- vertical bar on the character's left, full body height.
    Health = {
        Bar     = { Enabled = false, Color = Color3.fromRGB(120, 220, 130) },
        Based   = false,            -- color the bar by health % (green -> red)
        Text    = false,            -- show the health number
        TextPos = "Above Name",     -- "Above Name" ([hp] Name) | "On Health Bar"
    },
    -- v0.0.21: Tracer -- line from a screen origin to the target.
    -- v0.0.25: Location = where on the target the tracer points (Below/Middle/Above).
    Tracer = {
        Enabled  = false,
        Color    = Color3.fromRGB(255, 255, 255),
        Origin   = "Bottom",         -- "Mouse" | "Bottom" | "Middle" | "Top" (screen start point)
        Location = "Middle",         -- "Below" | "Middle" | "Above" (target end point)
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

-- v0.0.19: applyGlobalOutline removed. The arraylist accent line is NO LONGER
-- gated by the Outline toggle. Outline is purely an ESP box thickness accent
-- now. The arraylist accent line stays at its default transparency (0.15)
-- permanently. If a future module needs a global accent toggle, build a
-- dedicated "Accent Line" toggle instead of hijacking Outline.

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
        }, { lineOutline(), lineGradient() }))
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
        }, { lineOutline(), lineGradient() }))
    end
    return edges
end

-- v0.0.20: scanline hull fill for CUBE boxes. Roblox GUI can't fill an
-- arbitrary perspective-skewed quad with a single Frame, so the cube "3D fill"
-- is drawn as a stack of horizontal strips spanning the projected convex
-- silhouette of the 8 box corners. Reads as a translucent solid occupying the
-- box volume instead of the old flat AABB rectangle. Strips are pooled per rig.
-- v0.0.28: trimmed from 90/3. A 90-strip CanvasGroup PER RIG was heavy enough that
-- compositing them while the menu's own CanvasGroup faded in stalled the open
-- ("menu takes a second to open with fill on"). 40 strips at step 5 still reads as
-- a smooth solid (the cube edges draw on top and hide any stair-stepping) for a
-- fraction of the frames + fill/hull work.
local MAX_FILL_ROWS = 40
local FILL_ROW_STEP = 5

local function makeFillRows(parent)
    -- v0.0.22: strips live in a CanvasGroup so overlapping/adjacent strips are
    -- flattened into ONE layer before transparency is applied -- this kills the
    -- double-darkened horizontal seams the old translucent-strip stack produced.
    -- Strips draw fully OPAQUE; the group carries the ~0.72 translucency.
    local group = new("CanvasGroup", {
        Name = "FillGroup",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0.72,
        Visible = false,
        ZIndex = 12,   -- behind cube edges (14) and boxRoot (13)
        Parent = parent,
    })
    local rows = {}
    for _ = 1, MAX_FILL_ROWS do
        rows[#rows + 1] = new("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 12,
            Parent = group,
        })
    end
    return group, rows
end

-- Andrew's monotone-chain convex hull. Points are {x=,y=,...} tables; extra
-- fields (z) are ignored. Returns the hull in CCW order.
local function convexHull(pts)
    local n = #pts
    if n < 3 then return pts end
    local p = table.create(n)
    for i = 1, n do p[i] = pts[i] end
    table.sort(p, function(a, b)
        if a.x == b.x then return a.y < b.y end
        return a.x < b.x
    end)
    local function cross(o, a, b)
        return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    end
    local lower = {}
    for i = 1, #p do
        while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p[i]) <= 0 do
            lower[#lower] = nil
        end
        lower[#lower + 1] = p[i]
    end
    local upper = {}
    for i = #p, 1, -1 do
        while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p[i]) <= 0 do
            upper[#upper] = nil
        end
        upper[#upper + 1] = p[i]
    end
    lower[#lower] = nil   -- drop the last point of each chain (shared endpoint)
    upper[#upper] = nil
    for i = 1, #upper do lower[#lower + 1] = upper[i] end
    return lower
end

-- horizontal span [xl,xr] where scanline `y` crosses a convex polygon (exactly
-- two crossings), or nil if the line misses it entirely.
local function hullSpanAtY(hull, y)
    local xl, xr = math.huge, -math.huge
    local m = #hull
    for i = 1, m do
        local a = hull[i]
        local b = hull[i % m + 1]
        if (a.y <= y) ~= (b.y <= y) then   -- edge straddles the scanline
            local t = (y - a.y) / (b.y - a.y)
            local x = a.x + (b.x - a.x) * t
            if x < xl then xl = x end
            if x > xr then xr = x end
        end
    end
    if xr < xl then return nil end
    return xl, xr
end

-- v0.0.21 overlay pools + billboards --------------------------------------
-- Skeleton lines + head dot + health bar + tracer are 2D screen-space frames
-- living in ESP.BoxLayer (same layer as the box). Name / distance / profile
-- picture are world-anchored BillboardGuis parented to the character parts.

local SKELETON_MAX = 24
local function makeSkeletonLines(parent)
    local lines = {}
    for _ = 1, SKELETON_MAX do
        lines[#lines + 1] = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 13,
            Parent = parent,
        }, { lineOutline(), lineGradient() })
    end
    return lines
end

local function makeHeadDot(parent)
    return new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 14,
        Parent = parent,
    }, { pillCorner(), lineOutline(), lineGradient() })
end

local function makeTracer(parent)
    return new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 13,
        Parent = parent,
    }, { lineOutline(), lineGradient() })
end

local function makeHealthBar(parent)
    local bg = new("Frame", {
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 13,
        Parent = parent,
    })
    local fill = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),           -- grow up from the bottom
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(120, 220, 130),
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = bg,
    })
    -- health number shown at the bar when Text Pos = "On Health Bar"
    local txt = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 3),          -- just below the bar
        Size = UDim2.new(0, 44, 0, 14),
        BackgroundTransparency = 1,
        FontFace = Theme.Fonts.Medium,
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "",
        Visible = false,
        ZIndex = 15,
        Parent = bg,
    }, { textStroke(Color3.new(0, 0, 0), 1) })
    return bg, fill, txt
end

-- v0.0.26: name / profile picture / distance are SCREEN-SPACE (2D) elements in
-- the box layer, positioned each frame from the projected head/feet. A 3D
-- BillboardGui drifted onto the head at some camera angles ("name inside the
-- head"); screen-space keeps text ALWAYS directly above the head / below the feet
-- no matter where the camera points.
local function makeTextTag(parent, anchorY, textSize)
    return new("TextLabel", {
        Name = "KTag",
        AnchorPoint = Vector2.new(0.5, anchorY),
        Size = UDim2.new(0, 0, 0, textSize + 4),
        AutomaticSize = Enum.AutomaticSize.X,   -- hug text so the optional bg is "small"
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,             -- toggled by Text Background
        BorderSizePixel = 0,
        FontFace = Theme.Fonts.Medium,
        TextSize = textSize,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "",
        Visible = false,
        ZIndex = 16,
        Parent = parent,
    }, {
        corner(4),
        new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
        textStroke(Color3.new(0, 0, 0), 1),
        new("UIGradient", { Enabled = false }),
    })
end
local function makeNameStack(parent)
    local nameLbl = makeTextTag(parent, 1, 14)   -- anchor bottom-center (sits above head)
    local pfp = new("ImageLabel", {
        Name = "KPfp",
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = Color3.fromRGB(20, 16, 14),
        BackgroundTransparency = 0.2,
        ScaleType = Enum.ScaleType.Crop,
        Image = "",
        Visible = false,
        ZIndex = 16,
        Parent = parent,
    }, { pillCorner(), stroke(Color3.new(1, 1, 1), 1) })
    return pfp, nameLbl
end

-- v0.0.21: skeleton bone pairs. Only pairs whose BOTH parts exist are drawn,
-- so the same table covers R6 and R15 (missing parts just skip).
local SKELETON_BONES = {
    -- R15
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
    -- R6
    { "Head", "Torso" },
    { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

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

-- v0.0.19: makeBoxHalo removed. Glow is deferred to the Koffee Helper app
-- (C++ real Gaussian blur). Frame-based halo layers read as flat
-- semi-transparent rectangles, not actual glow. Don't re-add frame halos.

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
    -- v0.0.26: the outline is a SEPARATE frame behind the box (its thicker stroke
    -- shows around the main line). Two concentric UIStrokes on one frame rendered
    -- unreliably -- the black outline covered the white main line ("box is just
    -- black on some people"). One stroke per frame renders correctly, like the
    -- skeleton lines do.
    local boxOutlineFrame = new("Frame", {
        Name = "BoxOutline_" .. plr.Name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 12,   -- behind boxRoot (13)
        Parent = ESP.BoxLayer,
    }, {
        new("UIStroke", { Name = "KOutline", Color = Color3.new(0, 0, 0), Thickness = 3,
            Enabled = true, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })
    local boxOutlineStroke = boxOutlineFrame:FindFirstChild("KOutline")
    local boxRoot = new("Frame", {
        Name = "Box_" .. plr.Name,
        BackgroundColor3 = Color3.fromRGB(212, 145, 90),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 13,
        Parent = ESP.BoxLayer,
    }, {
        new("UIStroke", { Name = "KMain", Color = Color3.new(1, 1, 1), Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        lineGradient(),
    })
    local boxOutline = boxRoot:FindFirstChild("KMain")             -- main box line
    local boxCorners = makeBoxCorners(boxRoot)
    local cubeEdges = makeCubeEdges(ESP.BoxLayer)
    local fillGroup, fillRows = makeFillRows(ESP.BoxLayer)   -- v0.0.20 cube 3D fill

    -- v0.0.21 overlays. 2D screen-space elements in ESP.BoxLayer.
    local skeleton = makeSkeletonLines(ESP.BoxLayer)
    local headDot  = makeHeadDot(ESP.BoxLayer)
    local tracer   = makeTracer(ESP.BoxLayer)
    local healthBg, healthFill, healthTxt = makeHealthBar(ESP.BoxLayer)
    -- v0.0.26: screen-space (2D) name / pfp / distance tags in the box layer.
    local head = character:FindFirstChild("Head") or torso
    local pfp, nameLbl = makeNameStack(ESP.BoxLayer)
    local distLbl = makeTextTag(ESP.BoxLayer, 0, 13)   -- anchor top-center (sits below feet)

    -- v0.0.14: BillboardGui + name/dist/textBg removed. Names / Distance /
    -- Text Background are all becoming a dedicated overlay module ("Names")
    -- with its own rig/subscription. Health same. ESP rig now contains only
    -- box widget state -- clean split by concern.

    return {
        character  = character,
        torso      = torso,                           -- v0.0.15 anchor
        plr        = plr,
        boxRoot    = boxRoot,
        boxOutline = boxOutline,                -- KMain stroke (main box line)
        boxOutlineFrame  = boxOutlineFrame,     -- v0.0.26 separate outline frame behind
        boxOutlineStroke = boxOutlineStroke,    -- its stroke
        boxCorners = boxCorners,
        cubeEdges  = cubeEdges,
        fillGroup  = fillGroup,                        -- v0.0.22 CanvasGroup wrapping fill strips
        fillRows   = fillRows,                        -- v0.0.20 cube 3D fill strips
        -- v0.0.21 overlays
        skeleton   = skeleton,
        headDot    = headDot,
        tracer     = tracer,
        healthBg   = healthBg,
        healthFill = healthFill,
        healthTxt  = healthTxt,
        head       = head,
        pfp        = pfp,
        nameLbl    = nameLbl,
        distLbl    = distLbl,
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
    pcall(function() rig.boxOutlineFrame:Destroy() end)
    if rig.cubeEdges then
        for _, e in ipairs(rig.cubeEdges) do
            pcall(function() e:Destroy() end)
        end
    end
    pcall(function() rig.fillGroup:Destroy() end)   -- v0.0.22 destroys child fill strips
    -- v0.0.21 overlays
    if rig.skeleton then
        for _, l in ipairs(rig.skeleton) do pcall(function() l:Destroy() end) end
    end
    pcall(function() rig.headDot:Destroy() end)
    pcall(function() rig.tracer:Destroy() end)
    pcall(function() rig.healthBg:Destroy() end)   -- fill is a child, goes with it
    pcall(function() rig.pfp:Destroy() end)
    pcall(function() rig.nameLbl:Destroy() end)
    pcall(function() rig.distLbl:Destroy() end)
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
-- v0.0.23: the 3 neighbours of each of the 8 cube corners (for the corner-bracket
-- render). corners[i] world order is (±hx,±hy,±hz) as built in project8.
local CUBE_VERTEX_NEIGHBORS = {
    {2,3,5}, {1,4,6}, {1,4,7}, {2,3,8},
    {1,6,7}, {2,5,8}, {3,5,8}, {4,6,7},
}

-- v0.0.13 Static: aspect-locked, distance-linked, upward offset corrected.
--   Anchor is the character pivot (HumanoidRootPart). We project markers
--   above and below the torso. v0.0.16: markers are now SYMMETRIC (+3/-3).
--   The old +3/-4 was asymmetric -- HRP sits at hip level (~3 studs), head
--   top is ~5.5, feet are at ~0. So +3 reaches head, -3 reaches feet. The
--   old -4 extended 1 stud below ground, shifting the box center 0.5 studs
--   below the visible character center. At range this read as "the top is
--   offset from the bottom" because the character sat in the upper portion
--   of the box with empty space at the bottom.
--   Screen height = |top2D - bot2D|. Width = height * STATIC_ASPECT.
--   Result: only ONE screen scalar drives everything, so width and height
--   are truly linked. Camera angle / character rotation / animation do NOT
--   change the box shape.
local STATIC_TOP_STUDS = 3
local STATIC_BOT_STUDS = 3
local STATIC_ASPECT    = 0.5   -- fallback width = height * 0.5 (used only if no bbox)

local function projectStatic(torso, character)
    -- v0.0.15: anchor is torso.Position (live world read).
    if not torso or not torso.Parent then return nil, false, false end
    local cam = Workspace.CurrentCamera
    if not cam then return nil, false, false end
    -- v0.0.26: derive the vertical extent from the ACTUAL character bounding box
    -- (centred on the real body), not a fixed ±3 studs off the hip. HRP sits at
    -- hip level, so ±3 was R6-calibrated and left R15 / non-blocky rigs offset.
    -- v0.0.28: also derive a real WIDTH from the body instead of a flat 0.5 aspect
    -- ("the snapshot static gets is really bad"). We take the body's horizontal
    -- girth (min of X/Z so a gun-pointing pose's depth doesn't inflate it) and
    -- project it along the camera's right axis, so the box actually hugs the body
    -- yet never warps with camera yaw (a single world width, aspect-stable).
    local centerWorld, topWorld, botWorld, girth
    if character then
        local ok, cf, size = pcall(character.GetBoundingBox, character)
        if ok and cf then
            centerWorld = cf.Position
            topWorld = cf.Position + Vector3.new(0, size.Y * 0.5, 0)
            botWorld = cf.Position - Vector3.new(0, size.Y * 0.5, 0)
            girth = math.min(size.X, size.Z)
        end
    end
    if not topWorld then
        local pos = torso.Position
        centerWorld = pos
        topWorld = pos + Vector3.new(0, STATIC_TOP_STUDS, 0)
        botWorld = pos + Vector3.new(0, -STATIC_BOT_STUDS, 0)
    end
    local top2D = cam:WorldToViewportPoint(topWorld)
    local bot2D = cam:WorldToViewportPoint(botWorld)
    if top2D.Z <= 0 or bot2D.Z <= 0 then return nil, false, false end
    local height  = math.abs(bot2D.Y - top2D.Y)
    local width
    if girth and centerWorld then
        -- project the body's half-girth along camera-right, measured at the body
        local right = cam.CFrame.RightVector
        local l2D = cam:WorldToViewportPoint(centerWorld - right * (girth * 0.5))
        local r2D = cam:WorldToViewportPoint(centerWorld + right * (girth * 0.5))
        width = math.abs(r2D.X - l2D.X)
    end
    if not width or width <= 0 then width = height * STATIC_ASPECT end
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
    -- v0.0.17: assign by VALUE (new tables), not by reference. The old
    -- `c[5..8] = c[1..4]` shared table refs -- a future mutation of c[1]
    -- would silently corrupt c[5]. Nothing mutates today, but this kills
    -- the latent footgun.
    c[5] = { x = x1, y = y0, z = avgZ }
    c[6] = { x = x0, y = y0, z = avgZ }
    c[7] = { x = x1, y = y1, z = avgZ }
    c[8] = { x = x0, y = y1, z = avgZ }
    return c, true, true
end

-- v0.0.13: manual bbox from cached body parts. Ignores accessories/tools.
-- v0.0.23: `refCF` makes it ORIENTED (Follow Direction). When given, every part
-- corner is measured in refCF-local space (the torso frame) so the box rotates
-- with the character instead of being a world-axis box. Without it, it falls back
-- to the old world-axis-aligned AABB. Returns cframe (center) + size, matching
-- the shape of character:GetBoundingBox.
local function characterOnlyBBox(bodyParts, refCF)
    local minX, minY, minZ =  math.huge,  math.huge,  math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local found = false
    if refCF then
        for _, part in ipairs(bodyParts) do
            if part.Parent then
                local pcf, ps = part.CFrame, part.Size
                local hx, hy, hz = ps.X * 0.5, ps.Y * 0.5, ps.Z * 0.5
                for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
                    local lp = refCF:PointToObjectSpace((pcf * CFrame.new(sx * hx, sy * hy, sz * hz)).Position)
                    if lp.X < minX then minX = lp.X end
                    if lp.X > maxX then maxX = lp.X end
                    if lp.Y < minY then minY = lp.Y end
                    if lp.Y > maxY then maxY = lp.Y end
                    if lp.Z < minZ then minZ = lp.Z end
                    if lp.Z > maxZ then maxZ = lp.Z end
                end end end
                found = true
            end
        end
        if not found then return nil end
        local localCenter = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
        local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
        return refCF * CFrame.new(localCenter), size   -- oriented to the torso frame
    end
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

-- v0.0.23: flatten an oriented (cf,size) box to a world-axis-aligned box (used
-- when Follow Direction is OFF -- the box becomes a plain world box that doesn't
-- rotate with the character).
local function axisAlignBox(cf, size)
    local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
    local minX, minY, minZ =  math.huge,  math.huge,  math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
        local p = (cf * CFrame.new(sx * hx, sy * hy, sz * hz)).Position
        if p.X < minX then minX = p.X end
        if p.X > maxX then maxX = p.X end
        if p.Y < minY then minY = p.Y end
        if p.Y > maxY then maxY = p.Y end
        if p.Z < minZ then minZ = p.Z end
        if p.Z > maxZ then maxZ = p.Z end
    end end end
    return CFrame.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5),
           Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
end

local function project8(character, sizingType, characterOnly, bodyParts, rig)
    local cf, size
    if characterOnly then
        -- v0.0.15: refresh the cached body-parts list if it's empty (rig was
        -- created before parts fully loaded). Previously we silently fell
        -- back to full GetBoundingBox in this case, which read as "Character
        -- Only doesn't work" -- accessories still counted.
        -- v0.0.25: re-collect when the cache looks INCOMPLETE (< 6 parts), not
        -- only when empty. A rig created before the R15 limbs finished loading
        -- would cache just HRP/torso and never refresh -> "Character Only shows
        -- only the torso" on R15. 6 covers a minimal R6; a fuller rig refreshes up.
        if not bodyParts or #bodyParts < 6 then
            local fresh = collectBodyParts(character)
            if rig then rig.bodyParts = fresh end
            bodyParts = fresh
        end
        if #bodyParts == 0 then return nil, false, false end
        -- v0.0.23: Follow Direction makes the Character-Only box ORIENTED to the
        -- torso frame (so Cube tracks the player's facing). Without it, Character
        -- Only built a world-axis box -- the "Character Only kills Follow
        -- Direction" bug. Falls back to world-axis when Follow Direction is off.
        local refCF = nil
        if ESP.Config.FollowDirection then
            local torso = (rig and rig.torso) or findTorso(character)
            if torso and torso.Parent then refCF = torso.CFrame end
        end
        local c, s = characterOnlyBBox(bodyParts, refCF)
        if not c then return nil, false, false end
        cf, size = c, s
        -- v0.0.28: cap depth in the oriented (torso-local) frame so a forward
        -- reach doesn't bloat the projected width.
        if refCF then size = Vector3.new(size.X, size.Y, math.min(size.Z, size.X)) end
    else
        local ok, cframe, sz = pcall(character.GetBoundingBox, character)
        if not ok or not cframe then return nil, false, false end
        cf = cframe
        size = sz
        -- v0.0.28: clamp the box DEPTH (front-back) to its width in the box's OWN
        -- oriented frame, BEFORE any axis-align. A character aiming/pointing at the
        -- camera extends its arms forward; that long depth otherwise projects as
        -- extra screen width and the box reads "too big when looking forward".
        size = Vector3.new(size.X, size.Y, math.min(size.Z, size.X))
        -- Follow Direction OFF: flatten the oriented GetBoundingBox to a plain
        -- world-axis box so the cube stops rotating with the character.
        if not ESP.Config.FollowDirection then
            cf, size = axisAlignBox(cf, size)
        end
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
    local cam = Workspace.CurrentCamera
    if not cam then return nil, false, false end
    for i, wp in ipairs(worldCorners) do
        local sp = cam:WorldToViewportPoint(wp)
        screenCorners[i] = { x = sp.X, y = sp.Y, z = sp.Z }
        if sp.Z > 0 then anyInFront = true else allInFront = false end
    end
    return screenCorners, anyInFront, allInFront
end

local function hideRigVisuals(rig)
    rig.boxRoot.Visible = false; if rig.boxOutlineFrame then rig.boxOutlineFrame.Visible = false end
    for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
    for _, f in ipairs(rig.boxCorners) do f.Visible = false end
    rig.fillGroup.Visible = false
    -- v0.0.21 overlays
    for _, l in ipairs(rig.skeleton) do l.Visible = false end
    rig.headDot.Visible = false
    rig.tracer.Visible = false
    rig.healthBg.Visible = false
    if rig.nameLbl then rig.nameLbl.Visible = false end
    if rig.pfp then rig.pfp.Visible = false end
    if rig.distLbl then rig.distLbl.Visible = false end
    -- reset smoothing state so re-enable snaps rather than lerping from stale
    rig.lastBoxPos = nil
    rig.lastBoxSize = nil
end

-- v0.0.22: single source of truth for Feature-Interface line thickness.
--   EqualSize on  -> return the flat base thickness (distance-invariant).
--   EqualSize off -> scale inversely with distance so lines are thick up close
--                    and thin far away, clamped so they never vanish or bloat.
-- REF_DIST is the distance at which scaled == base. Fractional px is fine (the
-- GUI renderer accepts it) and keeps the falloff smooth.
local EQ_REF_DIST = 32
local function featureThickness(dist)
    local base = ESP.Render.Thickness
    if ESP.Render.EqualSize or not dist then return base end
    local s = base * (EQ_REF_DIST / math.max(dist, 1))
    return math.clamp(s, math.max(0.1, base * 0.25), base * 5)   -- v0.0.23: sub-1 allowed
end

-- v0.0.22: animated text gradient. The ColorSequence is built A->B->A so it's
-- periodic -- sweeping Offset.X seamlessly loops with no snap at the wrap. Speed
-- is cycles/sec; we sweep offset 1 -> -1 (right to left) forever. Sequence is
-- rebuilt only when the endpoint colors actually change (cheap steady state).
local function makeGradSeqGetter()
    local lastA, lastB, lastS, seq
    return function(a, b, spacing)
        spacing = math.clamp(spacing or 0.5, 0.05, 0.95)
        if a ~= lastA or b ~= lastB or spacing ~= lastS or not seq then
            lastA, lastB, lastS = a, b, spacing
            -- A -> B -> A is periodic so the animated offset loops with no snap.
            -- `spacing` slides where B sits between the two A ends.
            seq = ColorSequence.new({
                ColorSequenceKeypoint.new(0, a),
                ColorSequenceKeypoint.new(spacing, b),
                ColorSequenceKeypoint.new(1, a),
            })
        end
        return seq
    end
end
local textGradSeq = makeGradSeqGetter()
local lineGradSeq = makeGradSeqGetter()
-- animated offset (Vector2) along the gradient's rotation, speed + reverse aware.
local function gradOffset()
    local sp = ESP.Config.GradientSpeed
    local t = ((os.clock() * sp) % 2) - 1        -- -1 -> 1, seamless
    if ESP.Config.GradientReverse then t = -t end
    local r = math.rad(ESP.Config.GradientRotation)
    return Vector2.new(math.cos(r) * t, math.sin(r) * t)
end

-- v0.0.24: toggle/colour a line-frame's separate outline border (the KOutline
-- UIStroke added by lineOutline()). Called wherever a feature line is shown so
-- the global Outline effect reaches EVERY feature, in its own colour.
-- v0.0.28: pin a UIStroke's colour against a sibling UIGradient bleeding into it.
-- A UIGradient parented to a GuiObject also tints that object's UIStroke, so with
-- the feature Gradient on, every outline turned rainbow ("outline doesn't work with
-- gradient on"). A UIGradient placed INSIDE the stroke, holding a flat one-colour
-- sequence, overrides the bleed and keeps the outline its own solid colour.
local function pinStrokeColor(stroke, on, color)
    local g = stroke:FindFirstChildOfClass("UIGradient")
    if not on then
        if g then g.Enabled = false end
        return
    end
    if not g then g = new("UIGradient", { Parent = stroke }) end
    g.Enabled = true
    g.Color = ColorSequence.new(color)
    g.Offset = Vector2.new(0, 0)
    g.Rotation = 0
end

local function applyLineOutline(frame, on, color, thick)
    local s = frame:FindFirstChild("KOutline")
    if not s then return end
    s.Enabled = on
    if on then
        s.Color = color
        s.Thickness = thick
    end
    -- keep the outline solid even when the frame's KGrad is animating
    local grad = frame:FindFirstChild("KGrad")
    pinStrokeColor(s, on and grad ~= nil and grad.Enabled, color)
end

-- v0.0.24: the Outline effect on ESP text. The label's Contextual UIStroke hugs
-- the glyphs; the Outline toggle drives whether it shows and in what colour.
-- v0.0.28: optional thickness + gradient-pin so the outline survives a text gradient.
local function applyTextOutline(lbl, on, color, thick)
    local s = lbl:FindFirstChildOfClass("UIStroke")
    if not s then return end
    s.Enabled = on
    if on then
        s.Color = color
        if thick then s.Thickness = thick end
    end
    local grad = lbl:FindFirstChildOfClass("UIGradient")
    pinStrokeColor(s, on and grad ~= nil and grad.Enabled, color)
end

-- v0.0.28: gradient that lives INSIDE a UIStroke (colours the stroke itself). The
-- 2D box's visible line IS a UIStroke; a UIGradient on the parent Frame did not
-- reliably tint it, so the box sat forced-white with the gradient invisible ("2D
-- box stuck white, colour/gradient don't work"). Driving the gradient from within
-- the stroke makes it show, and lets the flat-colour fallback restore any colour.
local function applyStrokeGradient(stroke, on, a, b)
    local g = stroke:FindFirstChildOfClass("UIGradient")
    if not on then
        if g then g.Enabled = false end
        return
    end
    if not g then g = new("UIGradient", { Parent = stroke }) end
    g.Enabled = true
    g.Color = lineGradSeq(a, b, ESP.Config.GradientSpacing)
    g.Rotation = ESP.Config.GradientRotation
    g.Offset = gradOffset()
end
local function applyGradient(lbl, on)
    local g = lbl:FindFirstChildOfClass("UIGradient")
    if not g then return end
    g.Enabled = on
    if on then
        g.Color = textGradSeq(ESP.Config.GradientColorA, ESP.Config.GradientColorB, ESP.Config.GradientSpacing)
        g.Rotation = ESP.Config.GradientRotation
        g.Offset = gradOffset()
    end
end
-- v0.0.25: line gradient (on a feature line-frame's KGrad UIGradient). When on it
-- OVERRIDES the feature colour (forces white so the gradient shows its own colours
-- -- gradient wins over per-feature colours, per he).
local function applyLineGradient(frame, on)
    local g = frame:FindFirstChild("KGrad")
    if not g then return end
    g.Enabled = on
    if on then
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        g.Color = lineGradSeq(ESP.Config.GradientColorA2, ESP.Config.GradientColorB2, ESP.Config.GradientSpacing)
        g.Rotation = ESP.Config.GradientRotation
        g.Offset = gradOffset()
    end
end

-- v0.0.21: world-anchored overlays (Name + Profile Picture above the head,
-- Distance below the feet). Independent of the 2D box projection. `overrideColor`
-- is the shared team/visible-check color (nil = use each element's own color).
local function updateBillboards(rig, plr, dist, overrideColor)
    local names  = ESP.Names
    local health = ESP.Health
    local grad   = ESP.Config.TextGradient
    local pfpCfg = ESP.Indicators.ProfilePicture
    local pfpOn  = pfpCfg.Enabled
    -- v0.0.28: Text Background is tunable (colour / transparency / padding).
    local bgOn   = ESP.Config.TextBackground
    local textBg = bgOn and ESP.Config.TextBgTransparency or 1
    local bgCol  = ESP.Config.TextBgColor
    local bgPad  = ESP.Config.TextBgPadding
    local outlineOn  = ESP.Config.Outline                    -- v0.0.24 Outline on text
    local outlineCol = ESP.Boxes.OutlineColor
    local function styleTextBg(lbl)
        lbl.BackgroundColor3 = bgCol
        lbl.BackgroundTransparency = textBg
        local pad = lbl:FindFirstChildOfClass("UIPadding")
        if pad then
            pad.PaddingLeft  = UDim.new(0, bgPad)
            pad.PaddingRight = UDim.new(0, bgPad)
        end
    end

    -- health text "Above Name" prefixes [hp] onto the name line
    local prefix = ""
    if health.Text and health.TextPos == "Above Name" then
        local hum = rig.character:FindFirstChildOfClass("Humanoid")
        if hum then prefix = "[" .. math.floor(hum.Health + 0.5) .. "] " end
    end
    local nameStr = prefix
    if names.Enabled then
        local n = (names.Type == "Display Name") and plr.DisplayName or plr.Name
        nameStr = nameStr .. n
    end
    local showName = nameStr ~= ""

    local cam = Workspace.CurrentCamera
    -- v0.0.26: project the head TOP (world) so the tags sit directly above the
    -- head on screen at any camera angle. Fall back to the torso if no head.
    local head = rig.head
    local headTopWorld
    if head and head.Parent then
        headTopWorld = head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.4, 0)
    else
        headTopWorld = rig.torso.Position + Vector3.new(0, 2.6, 0)
    end
    local hp = cam and cam:WorldToViewportPoint(headTopWorld)
    local headOn = hp and hp.Z > 0

    -- NAME (bottom-anchored just above the head top)
    if headOn and showName then
        rig.nameLbl.Text = nameStr
        rig.nameLbl.TextSize = names.TextSize or 14
        rig.nameLbl.TextColor3 = grad and Color3.new(1, 1, 1) or (overrideColor or names.Color)
        styleTextBg(rig.nameLbl)
        rig.nameLbl.Position = UDim2.new(0, hp.X, 0, hp.Y - 3)
        rig.nameLbl.Visible = true
        applyTextOutline(rig.nameLbl, outlineOn, outlineCol, names.OutlineThickness)
        applyGradient(rig.nameLbl, grad)
    else
        rig.nameLbl.Visible = false
    end

    -- PROFILE PICTURE (stacked above the name, else above the head)
    -- v0.0.28: size / outline thickness / Y offset are right-click tunable.
    if headOn and pfpOn then
        if rig.pfp.Image == "" then
            rig.pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
        end
        local pfpSize = pfpCfg.Size or 40
        rig.pfp.Size = UDim2.new(0, pfpSize, 0, pfpSize)
        local pfpStroke = rig.pfp:FindFirstChildOfClass("UIStroke")
        if pfpStroke then pfpStroke.Thickness = pfpCfg.OutlineThickness or 1 end
        local nameH = (showName and rig.nameLbl.Visible) and (rig.nameLbl.AbsoluteSize.Y + 3) or 0
        rig.pfp.Position = UDim2.new(0, hp.X, 0, hp.Y - 3 - nameH - (pfpCfg.YOffset or 0))
        rig.pfp.Visible = true
    else
        rig.pfp.Visible = false
    end

    -- DISTANCE (top-anchored just below the feet)
    local distCfg = ESP.Indicators.Distance
    if distCfg.Enabled then
        local feetWorld = rig.torso.Position - Vector3.new(0, 3.2, 0)
        local fp = cam and cam:WorldToViewportPoint(feetWorld)
        if fp and fp.Z > 0 then
            rig.distLbl.Text = math.floor(dist + 0.5) .. "m"
            rig.distLbl.TextSize = distCfg.TextSize or 13
            rig.distLbl.TextColor3 = grad and Color3.new(1, 1, 1) or (overrideColor or distCfg.Color)
            styleTextBg(rig.distLbl)
            rig.distLbl.Position = UDim2.new(0, fp.X, 0, fp.Y + 3)
            rig.distLbl.Visible = true
            applyTextOutline(rig.distLbl, outlineOn, outlineCol, distCfg.OutlineThickness)
            applyGradient(rig.distLbl, grad)
        else
            rig.distLbl.Visible = false
        end
    else
        rig.distLbl.Visible = false
    end
end

-- v0.0.21: skeleton -- project each bone pair whose both parts exist (covers R6
-- + R15 since missing parts skip) and draw a rotated line frame between them.
local function updateSkeleton(rig, overrideColor, dist)
    local cfg = ESP.Indicators.Skeleton
    -- v0.0.25: per-skeleton thickness override (right-click). 0 = universal.
    local st = cfg.Thickness or 0
    local thick = (st > 0) and st or featureThickness(dist)
    local outlineOn = ESP.Config.Outline
    local outlineCol = ESP.Boxes.OutlineColor
    local outlineThick = math.max(1, thick)
    if not cfg.Enabled then
        for _, l in ipairs(rig.skeleton) do l.Visible = false end
        return
    end
    local cam = Workspace.CurrentCamera
    local char = rig.character
    if not cam or not char then
        for _, l in ipairs(rig.skeleton) do l.Visible = false end
        return
    end
    local col = overrideColor or cfg.Color
    local slot = 0
    for _, bone in ipairs(SKELETON_BONES) do
        local pa = char:FindFirstChild(bone[1])
        local pb = char:FindFirstChild(bone[2])
        if pa and pb and pa:IsA("BasePart") and pb:IsA("BasePart") then
            local a = cam:WorldToViewportPoint(pa.Position)
            local b = cam:WorldToViewportPoint(pb.Position)
            if a.Z > 0 and b.Z > 0 then
                slot = slot + 1
                local line = rig.skeleton[slot]
                if line then
                    local dx, dy = b.X - a.X, b.Y - a.Y
                    local len = math.sqrt(dx * dx + dy * dy)
                    line.Size = UDim2.new(0, len, 0, thick)
                    line.Position = UDim2.new(0, (a.X + b.X) * 0.5, 0, (a.Y + b.Y) * 0.5)
                    line.Rotation = math.deg(math.atan2(dy, dx))
                    line.BackgroundColor3 = col
                    line.Visible = true
                    applyLineOutline(line, outlineOn, outlineCol, outlineThick)
                    applyLineGradient(line, ESP.Config.Gradient)
                end
            end
        end
    end
    for i = slot + 1, #rig.skeleton do rig.skeleton[i].Visible = false end
end

-- v0.0.13 render: gates are strict (dead / despawned / out-of-range / ancestry
-- broken -> hide immediately). Every visible ESP element is opt-in via its own
-- config toggle -- master ESP shows nothing on its own. v0.0.17: Outline is a
-- thickness accent, NOT a gate for box line existence.
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

        -- v0.0.21: shared color override, computed once per rig.
        --   team-based color (same team) wins, else Visible Check's visible/hidden
        --   color, else nil -> each element falls back to its own configured color.
        -- Visible Check does a single camera->torso raycast, excluding the local
        -- and target characters so only environment occlusion counts.
        local hidden = false
        if ESP.Config.VisibleCheck and rig.torso and rig.torso.Parent then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { rig.character, LocalPlayer.Character }
            local hit = Workspace:Raycast(camPos, rig.torso.Position - camPos, rp)
            hidden = hit ~= nil
        end
        local overrideColor = nil
        if ESP.Config.TeamBasedColor and sameTeam then
            overrideColor = ESP.Colors.Team
        elseif ESP.Config.VisibleCheck then
            overrideColor = hidden and ESP.Colors.Hidden or ESP.Colors.Visible
        end

        -- world-anchored overlays + skeleton render regardless of the box.
        updateBillboards(rig, plr, dist, overrideColor)
        updateSkeleton(rig, overrideColor, dist)

        -- 2D box-AABB features (box / health bar / head dot / tracer) share one
        -- projection. If none is enabled, hide them all and skip projecting.
        local need2D = ESP.Boxes.Enabled or ESP.Health.Bar.Enabled
                    or ESP.Indicators.HeadDot.Enabled or ESP.Tracer.Enabled
        if not need2D then
            rig.boxRoot.Visible = false; if rig.boxOutlineFrame then rig.boxOutlineFrame.Visible = false end
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            rig.fillGroup.Visible = false
            rig.headDot.Visible = false
            rig.tracer.Visible = false
            rig.healthBg.Visible = false
            continue
        end

        -- BOX projection dispatch:
        --   Static -> aspect-locked, distance-linked screen box (no camera-angle warp).
        --             Cube auto-falls-through to Bounding (Static has no depth info).
        --   Bounding / Prediction -> 8-corner world projection with optional CharacterOnly.
        local corners, anyInFront, allInFront
        local isCube = ESP.Boxes.BoxType == "Cube"
        local effectiveSizing = ESP.Config.SizingType
        if isCube and effectiveSizing == "Static" then
            effectiveSizing = "Bounding"
        end
        if effectiveSizing == "Static" then
            corners, anyInFront, allInFront = projectStatic(rig.torso, rig.character)
        else
            corners, anyInFront, allInFront =
                project8(rig.character, effectiveSizing,
                         ESP.Config.CharacterOnly, rig.bodyParts, rig)
        end

        if not corners or not anyInFront or not allInFront then
            rig.boxRoot.Visible = false; if rig.boxOutlineFrame then rig.boxOutlineFrame.Visible = false end
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            rig.fillGroup.Visible = false
            rig.headDot.Visible = false
            rig.tracer.Visible = false
            rig.healthBg.Visible = false
            continue
        end

        -- v0.0.24: box MAIN line colour (separate from Outline now). Team/visible
        -- override still wins.
        local boxColor     = overrideColor or ESP.Boxes.Color
        local fillColor    = ESP.Boxes.FillColor
        local fillOn       = ESP.Boxes.FillBox
        local cornersMode  = ESP.Boxes.Corners and not isCube   -- v0.0.26: corners are 2D-only
        local cornerLen    = math.clamp(ESP.Boxes.CornerLength, 0.02, 0.5)
        -- v0.0.22: base line thickness comes from the shared render model
        -- (Thickness slider + Equal Size). v0.0.24: Outline is a SEPARATE border
        -- line drawn around every feature, in its own colour.
        local outlineOn    = ESP.Config.Outline
        local outlineCol   = ESP.Boxes.OutlineColor
        local lineGradOn   = ESP.Config.Gradient      -- v0.0.25 gradient-everything
        local lineThick    = featureThickness(dist)
        -- v0.0.26: per-box thickness override (right-click box). 0 = universal.
        local boxThick     = (ESP.Boxes.Thickness > 0) and ESP.Boxes.Thickness or lineThick
        local boxOutExtra  = ESP.Boxes.OutlineThickness or 2   -- px the outline extends past the line
        local outlineThick = math.max(1, lineThick)   -- border width for line outlines (skeleton/tracer/etc)

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
        -- v0.0.21: the box itself is gated by Boxes.Enabled; the other 2D
        -- features (head dot / health bar / tracer) render below off the same
        -- projection whether or not the box widget is on.
        if ESP.Boxes.Enabled then
        rig.boxRoot.Position = UDim2.new(0, tX, 0, tY)
        rig.boxRoot.Size = UDim2.new(0, tW, 0, tH)
        rig.boxRoot.BackgroundColor3 = fillColor

        if isCube then
            -- v0.0.20: boxRoot (a flat AABB rectangle) is NO LONGER the cube
            -- fill -- that's exactly what made "Fill + Cube" read as a 2D box.
            -- The fill is now a scanline of horizontal strips spanning the
            -- projected convex silhouette of the 8 corners, so it looks like a
            -- translucent solid occupying the 3D box, matching the 2D fill's
            -- 0.72 transparency. Cube edges draw on top and hide the strip stair-
            -- stepping on the slanted sides.
            rig.boxRoot.Visible = false; if rig.boxOutlineFrame then rig.boxOutlineFrame.Visible = false end
            if rig.boxOutline then rig.boxOutline.Enabled = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end

            if fillOn then
                local hull = convexHull(corners)
                local hy0, hy1 = math.huge, -math.huge
                for _, c in ipairs(hull) do
                    if c.y < hy0 then hy0 = c.y end
                    if c.y > hy1 then hy1 = c.y end
                end
                local totalH = hy1 - hy0
                local rowCount = math.clamp(math.floor(totalH / FILL_ROW_STEP), 1, MAX_FILL_ROWS)
                local rowH = totalH / rowCount
                rig.fillGroup.Visible = true
                rig.fillGroup.GroupTransparency = ESP.Boxes.FillTransparency
                for i = 1, MAX_FILL_ROWS do
                    local f = rig.fillRows[i]
                    if i <= rowCount then
                        local yTop = hy0 + (i - 1) * rowH
                        -- widest span across the strip (sample near top AND bottom
                        -- edges) so the fill edges track the slanted silhouette
                        -- instead of stair-stepping off a single centre sample.
                        local l1, r1 = hullSpanAtY(hull, yTop + 0.5)
                        local l2, r2 = hullSpanAtY(hull, yTop + rowH - 0.5)
                        local xl = math.min(l1 or math.huge,  l2 or math.huge)
                        local xr = math.max(r1 or -math.huge, r2 or -math.huge)
                        if xl < xr then
                            -- opaque strip; the CanvasGroup carries the translucency
                            -- so overlaps don't double-darken (no seams). +1 height
                            -- overlap defeats fractional-rounding gaps for free.
                            f.Position = UDim2.new(0, xl, 0, yTop)
                            f.Size = UDim2.new(0, math.max(xr - xl, 1), 0, rowH + 1)
                            f.BackgroundColor3 = fillColor
                            f.Visible = true
                        else
                            f.Visible = false
                        end
                    else
                        f.Visible = false
                    end
                end
            else
                rig.fillGroup.Visible = false
            end

            -- v0.0.17: cube edges always render when box visible -- they ARE
            -- the box in cube mode. Corners mode changes the line STYLE
            -- (vertex brackets instead of full edges), not existence. Outline
            -- adds thickness via lineThick (computed above).
            local thick = boxThick
            local CORNER_MAX_PX = 28
            if cornersMode then
                -- v0.0.23: draw brackets ONLY at the 4 corners nearest the camera,
                -- each radiating its 3 incident edges. Bracketing all 8 corners made
                -- the front + back corner of each edge project onto nearly the same
                -- screen point and pile their stubs into a 6-line "star". Four front
                -- corners x 3 edges = clean 3-line 3D corners with no overlap.
                local order = { 1, 2, 3, 4, 5, 6, 7, 8 }
                table.sort(order, function(p, q) return corners[p].z < corners[q].z end)
                local slot = 0
                for k = 1, 4 do
                    local vi = order[k]
                    local a = corners[vi]
                    for _, nj in ipairs(CUBE_VERTEX_NEIGHBORS[vi]) do
                        local b = corners[nj]
                        local dx, dy = b.x - a.x, b.y - a.y
                        local length = math.sqrt(dx * dx + dy * dy)
                        slot = slot + 1
                        local e = rig.cubeEdges[slot]
                        if e then
                            if length >= 1 then
                                local maxSeg = length * 0.5
                                local segLen = math.clamp(length * cornerLen, math.min(3, maxSeg), maxSeg)
                                if segLen > CORNER_MAX_PX then segLen = CORNER_MAX_PX end
                                e.AnchorPoint = Vector2.new(0, 0.5)   -- radiate FROM the corner
                                e.Position = UDim2.new(0, a.x, 0, a.y)
                                e.Size = UDim2.new(0, segLen, 0, thick)
                                e.Rotation = math.deg(math.atan2(dy, dx))
                                e.BackgroundColor3 = boxColor
                                e.BackgroundTransparency = 0
                                e.Visible = true
                                applyLineOutline(e, outlineOn, outlineCol, outlineThick)
                                applyLineGradient(e, lineGradOn)
                            else
                                e.Visible = false
                            end
                        end
                    end
                end
                for i = slot + 1, #rig.cubeEdges do rig.cubeEdges[i].Visible = false end
            else
                -- full wireframe: one line per cube edge (12), centered.
                for i, pair in ipairs(CUBE_EDGE_INDICES) do
                    local a = corners[pair[1]]
                    local b = corners[pair[2]]
                    local aEdge = rig.cubeEdges[i]
                    local dx, dy = b.x - a.x, b.y - a.y
                    local length = math.sqrt(dx * dx + dy * dy)
                    if length < 1 then
                        aEdge.Visible = false
                    else
                        aEdge.AnchorPoint = Vector2.new(0.5, 0.5)
                        aEdge.Position = UDim2.new(0, (a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
                        aEdge.Size = UDim2.new(0, length, 0, thick)
                        aEdge.Rotation = math.deg(math.atan2(dy, dx))
                        aEdge.BackgroundColor3 = boxColor
                        aEdge.BackgroundTransparency = 0
                        aEdge.Visible = true
                        applyLineOutline(aEdge, outlineOn, outlineCol, outlineThick)
                        applyLineGradient(aEdge, lineGradOn)
                    end
                end
                for i = 13, #rig.cubeEdges do rig.cubeEdges[i].Visible = false end
            end
        else
            -- 2D bounding box. boxRoot IS the box. cube frames + fill strips off.
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            rig.fillGroup.Visible = false
            rig.boxRoot.Visible = true
            rig.boxRoot.BackgroundTransparency = fillOn and ESP.Boxes.FillTransparency or 1
            rig.boxRoot.BackgroundColor3 = fillColor

            -- v0.0.17: primary stroke ALWAYS enabled (suppressed only by
            -- corners mode which replaces it with brackets). v0.0.28: the box line
            -- is a UIStroke; colour it directly and drive the Gradient from INSIDE
            -- the stroke (a parent-frame gradient didn't tint it -> "stuck white").
            if rig.boxOutline then
                local strokeGrad = lineGradOn and not cornersMode
                rig.boxOutline.Color = strokeGrad and Color3.new(1, 1, 1) or boxColor
                rig.boxOutline.Thickness = boxThick
                rig.boxOutline.Transparency = 0
                rig.boxOutline.Enabled = not cornersMode
                applyStrokeGradient(rig.boxOutline, strokeGrad,
                    ESP.Config.GradientColorA2, ESP.Config.GradientColorB2)
            end
            -- v0.0.26: separate outline frame behind the box -- its thicker stroke
            -- shows as a border around the main line (reliable single-stroke render).
            if rig.boxOutlineFrame then
                local showOutline = outlineOn and not cornersMode
                rig.boxOutlineFrame.Visible = showOutline
                if showOutline then
                    rig.boxOutlineFrame.Position = UDim2.new(0, tX, 0, tY)
                    rig.boxOutlineFrame.Size = UDim2.new(0, tW, 0, tH)
                    rig.boxOutlineStroke.Color = outlineCol
                    rig.boxOutlineStroke.Thickness = boxThick + boxOutExtra
                end
            end

            -- Corner brackets: the box's line STYLE alternative to the full
            -- stroke. Uses lineThick so Outline emphasis applies here too.
            -- v0.0.15: cap segment length at 28px so brackets don't dominate
            -- huge close-up boxes.
            if cornersMode then
                local segLen = math.clamp(math.min(tW, tH) * cornerLen, 3, 28)
                local thick = boxThick
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
                    f.BackgroundColor3 = boxColor
                    f.BackgroundTransparency = 0
                    f.Visible = true
                    applyLineOutline(f, outlineOn, outlineCol, outlineThick)
                    applyLineGradient(f, lineGradOn)
                end
            else
                for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            end
        end
        else
            -- Boxes widget off: hide every box element. Head dot / health bar /
            -- tracer below still render off the shared projection.
            rig.boxRoot.Visible = false; if rig.boxOutlineFrame then rig.boxOutlineFrame.Visible = false end
            for _, e in ipairs(rig.cubeEdges) do e.Visible = false end
            for _, f in ipairs(rig.boxCorners) do f.Visible = false end
            rig.fillGroup.Visible = false
        end

        -- v0.0.22 HEAD DOT: centered on the REAL Head part (was pinned to the
        -- top of the projected AABB, which sat above the head / on hats). Project
        -- the head's world position directly and center the dot on it. Size rides
        -- the render model so it scales with distance when Equal Size is off.
        if ESP.Indicators.HeadDot.Enabled and rig.head and rig.head.Parent then
            local sp = cam:WorldToViewportPoint(rig.head.Position)
            if sp.Z > 0 then
                local d = rig.headDot
                -- v0.0.25: size from the right-click setting; scales with distance
                -- when Equal Size is off (like the other features).
                local sz = ESP.Indicators.HeadDot.Size or 6
                if not ESP.Render.EqualSize then
                    sz = math.clamp(sz * (EQ_REF_DIST / math.max(dist, 1)), sz * 0.35, sz * 3)
                end
                d.AnchorPoint = Vector2.new(0.5, 0.5)
                d.Size = UDim2.new(0, sz, 0, sz)
                d.Position = UDim2.new(0, sp.X, 0, sp.Y)
                d.BackgroundColor3 = overrideColor or ESP.Indicators.HeadDot.Color
                d.Visible = true
                applyLineOutline(d, outlineOn, outlineCol, outlineThick)
                applyLineGradient(d, lineGradOn)
            else
                rig.headDot.Visible = false
            end
        else
            rig.headDot.Visible = false
        end

        -- v0.0.21 HEALTH BAR: vertical bar just left of the box, full body
        -- height, fill grows up from the bottom by health %.
        if ESP.Health.Bar.Enabled then
            local hum = rig.character:FindFirstChildOfClass("Humanoid")
            local frac = 1
            if hum and hum.MaxHealth > 0 then
                frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            end
            -- v0.0.25: glue to the ACTUAL body, adaptive to R6/R15/any rig.
            --   vertical span = highest -> lowest projected body part (head->feet)
            --   left edge     = torso centre minus the torso's projected half-width
            -- so it hugs the body core -- not the wide Cube AABB, not outstretched
            -- arms, and not a fixed R6-calibrated stud offset (the old bug).
            local hbLeft, hbTop, hbBot = minX, minY, maxY
            do
                local parts = rig.bodyParts
                if not parts or #parts < 6 then parts = collectBodyParts(rig.character); rig.bodyParts = parts end
                local pminY, pmaxY, any = math.huge, -math.huge, false
                for _, p in ipairs(parts) do
                    if p.Parent then
                        local sp = cam:WorldToViewportPoint(p.Position)
                        if sp.Z > 0 then
                            any = true
                            if sp.Y < pminY then pminY = sp.Y end
                            if sp.Y > pmaxY then pmaxY = sp.Y end
                        end
                    end
                end
                local tcp = cam:WorldToViewportPoint(rig.torso.Position)
                local trp = cam:WorldToViewportPoint(rig.torso.Position + cam.CFrame.RightVector * 1.6)
                if any and tcp.Z > 0 then
                    hbTop, hbBot = pminY, pmaxY
                    hbLeft = tcp.X - math.abs(trp.X - tcp.X)
                end
            end
            local barW, gap = 3, 7
            rig.healthBg.Position = UDim2.new(0, hbLeft - gap - barW, 0, hbTop)
            rig.healthBg.Size = UDim2.new(0, barW, 0, math.max(hbBot - hbTop, 1))
            rig.healthBg.Visible = true
            local barColor
            if ESP.Health.Based then
                -- v0.0.22: pure red -> pure green (was a muted/desaturated pair).
                barColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), frac)
            else
                barColor = ESP.Health.Bar.Color
            end
            rig.healthFill.Size = UDim2.new(1, 0, frac, 0)
            rig.healthFill.BackgroundColor3 = barColor
            if ESP.Health.Text and ESP.Health.TextPos == "On Health Bar" then
                rig.healthTxt.Text = tostring(math.floor((hum and hum.Health or 0) + 0.5))
                rig.healthTxt.TextColor3 = barColor
                rig.healthTxt.Visible = true
            else
                rig.healthTxt.Visible = false
            end
        else
            rig.healthBg.Visible = false
        end

        -- v0.0.21 TRACER: line from the chosen screen origin to the target feet.
        if ESP.Tracer.Enabled then
            local vp = viewport()
            local ox, oy
            local o = ESP.Tracer.Origin
            if o == "Mouse" then
                local m = UserInputService:GetMouseLocation()
                ox, oy = m.X, m.Y
            elseif o == "Top" then
                ox, oy = vp.X * 0.5, 0
            elseif o == "Middle" then
                ox, oy = vp.X * 0.5, vp.Y * 0.5
            else
                ox, oy = vp.X * 0.5, vp.Y   -- Bottom
            end
            -- v0.0.25: Location = which point on the target the tracer ends at.
            local loc = ESP.Tracer.Location
            local tx2, ty2 = (minX + maxX) * 0.5, maxY   -- Below (feet), default fallback
            if loc == "Middle" then
                ty2 = (minY + maxY) * 0.5
            elseif loc == "Above" then
                ty2 = minY
            end
            local dx, dy = tx2 - ox, ty2 - oy
            local len = math.sqrt(dx * dx + dy * dy)
            local t = rig.tracer
            t.Size = UDim2.new(0, len, 0, featureThickness(dist))
            t.Position = UDim2.new(0, (ox + tx2) * 0.5, 0, (oy + ty2) * 0.5)
            t.Rotation = math.deg(math.atan2(dy, dx))
            t.BackgroundColor3 = overrideColor or ESP.Tracer.Color
            t.Visible = true
            applyLineOutline(t, outlineOn, outlineCol, outlineThick)
            applyLineGradient(t, lineGradOn)
        else
            rig.tracer.Visible = false
        end
    end
end

local espModule = registerModule("esp", "ESP",
    function()
        -- v0.0.14: task.spawn per-player so makeRig's WaitForChild("HumanoidRootPart", 2)
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
        -- v0.0.17: destroy the box layer too so a full ESP disable leaves
        -- no orphan frames on screen. ensureBoxLayer recreates it on next enable.
        if ESP.BoxLayer then
            pcall(function() ESP.BoxLayer:Destroy() end)
            ESP.BoxLayer = nil
        end
    end
)

-- v0.0.25: ESP's arraylist detail lists ONLY box + tracer as its arguments.
-- Everything else (Name, Distance, Skeleton, Head Dot, Profile Picture, Health)
-- is its OWN arraylist entry -- see the sub-feature sync below.
espModule.GetDetail = function()
    local parts = {}
    if ESP.Boxes.Enabled then table.insert(parts, "box") end
    if ESP.Tracer.Enabled then table.insert(parts, "tracer") end
    if #parts == 0 then return "" end
    return "    " .. table.concat(parts, ", ")
end

-- v0.0.25: ESP sub-features appear as their OWN lines in the arraylist (per he).
-- They aren't real modules (the ESP render loop draws them off config flags), so
-- these are display-only entries synced from the flags. Only shown while ESP
-- itself is enabled -- an entry the render loop isn't drawing would be a lie.
local subFeatureDefs = {
    { id = "esp_name",     name = "Name",            get = function() return ESP.Names.Enabled end },
    { id = "esp_distance", name = "Distance",        get = function() return ESP.Indicators.Distance.Enabled end },
    { id = "esp_skeleton", name = "Skeleton",        get = function() return ESP.Indicators.Skeleton.Enabled end },
    { id = "esp_headdot",  name = "Head Dot",        get = function() return ESP.Indicators.HeadDot.Enabled end },
    { id = "esp_pfp",      name = "Profile Picture", get = function() return ESP.Indicators.ProfilePicture.Enabled end },
    { id = "esp_health",   name = "Health",          get = function() return ESP.Health.Bar.Enabled end },
}
for _, def in ipairs(subFeatureDefs) do
    def.mod = { Id = def.id, DisplayName = def.name, Enabled = false, Watchers = {} }
end
do
    local accum = 0
    RunService.Heartbeat:Connect(function(dt)
        accum = accum + dt
        if accum < 0.15 then return end
        accum = 0
        local espOn = Modules.esp and Modules.esp.Enabled
        for _, def in ipairs(subFeatureDefs) do
            local on = espOn and def.get() or false
            if on and not def.mod.Enabled then
                def.mod.Enabled = true
                addToActiveArray(def.mod)
            elseif not on and def.mod.Enabled then
                def.mod.Enabled = false
                removeFromActiveArray(def.mod)
            end
        end
    end)
end

--============================================================
-- WORLD MODULES: fullbright, no fog, custom time
-- Each module saves the original Lighting values on enable and restores on disable.
-- v0.0.17: all three now install a Heartbeat that re-asserts values so
-- server-side day/night cycles / dynamic weather can't override us.
--============================================================
local World = {
    Fullbright = { Saved = nil, Conn = nil },
    NoFog      = { Saved = nil, Conn = nil },
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
        -- v0.0.17: re-assert every frame so server day/night cycles can't
        -- override us (consistent with Custom Time's Heartbeat).
        World.Fullbright.Conn = RunService.Heartbeat:Connect(function()
            if Lighting.Ambient ~= Color3.fromRGB(178, 178, 178) then
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            end
            Lighting.OutdoorAmbient    = Color3.fromRGB(178, 178, 178)
            Lighting.ColorShift_Top    = Color3.fromRGB(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
            Lighting.Brightness        = 1
            Lighting.GlobalShadows     = false
        end)
    end,
    function()
        if World.Fullbright.Conn then
            World.Fullbright.Conn:Disconnect()
            World.Fullbright.Conn = nil
        end
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
        -- v0.0.17: re-assert so games that dynamically push fog can't fight us.
        World.NoFog.Conn = RunService.Heartbeat:Connect(function()
            if Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
            if Lighting.FogStart ~= 100000 then Lighting.FogStart = 100000 end
        end)
    end,
    function()
        if World.NoFog.Conn then
            World.NoFog.Conn:Disconnect()
            World.NoFog.Conn = nil
        end
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

-- v0.0.18: single-swatch variant for rows that own one color (Outline accent).
-- Same right-aligned placement pattern as attachDualSwatch, just one swatch.
local function attachSingleSwatch(row, initialColor, onChange)
    local wrap = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 38,
        Parent = row,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    colorSwatch(wrap, initialColor, 14, { onChange = onChange })
end

addTab("Visuals", function(root)
    -- v0.0.21: two-column layout to match Matcha.
    --   left:  esp / box / name      right: indicators / health / tracer
    local columns = new("Frame", {
        Name = "Columns",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 32,
        Parent = root,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),
    })
    local function column(order)
        return new("Frame", {
            Size = UDim2.new(0.5, -6, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
            ZIndex = 32,
            Parent = columns,
        }, {
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
    end
    local leftCol  = column(1)
    local rightCol = column(2)

    --------------------------------------------------------------- ESP
    local espPanel = panel(leftCol, "esp")
    local master = moduleCheckbox(espPanel, "Enabled", "esp")
    keybindPill(master.row, "esp", Enum.KeyCode.E)
    configCheckbox(espPanel, "Team Check", ESP.Config.TeamCheck, function(v) ESP.Config.TeamCheck = v end)
    local visRow = configCheckbox(espPanel, "Visible Check", ESP.Config.VisibleCheck, function(v) ESP.Config.VisibleCheck = v end)
    attachDualSwatch(visRow.row, ESP.Colors.Visible, ESP.Colors.Hidden,
        function(c) ESP.Colors.Visible = c end,
        function(c) ESP.Colors.Hidden  = c end)
    configCheckbox(espPanel, "Team Based Color", ESP.Config.TeamBasedColor, function(v) ESP.Config.TeamBasedColor = v end)
    local gradRow = configCheckbox(espPanel, "Text Gradient", ESP.Config.TextGradient, function(v) ESP.Config.TextGradient = v end)
    attachDualSwatch(gradRow.row, ESP.Config.GradientColorA, ESP.Config.GradientColorB,
        function(c) ESP.Config.GradientColorA = c end,
        function(c) ESP.Config.GradientColorB = c end)
    -- v0.0.25: Gradient for everything (non-text) in the Feature Interface.
    local grad2Row = configCheckbox(espPanel, "Gradient", ESP.Config.Gradient, function(v) ESP.Config.Gradient = v end)
    attachDualSwatch(grad2Row.row, ESP.Config.GradientColorA2, ESP.Config.GradientColorB2,
        function(c) ESP.Config.GradientColorA2 = c end,
        function(c) ESP.Config.GradientColorB2 = c end)
    -- right-click either gradient toggle for tuning (shared settings).
    local function gradientSettings(popup)
        popup:slider("Speed", 0, 3, ESP.Config.GradientSpeed, 2, function(v) ESP.Config.GradientSpeed = v end)
        popup:slider("Direction", 0, 360, ESP.Config.GradientRotation, 0, function(v) ESP.Config.GradientRotation = v end)
        popup:slider("Spacing", 0.05, 0.95, ESP.Config.GradientSpacing, 2, function(v) ESP.Config.GradientSpacing = v end)
        popup:toggle("Reverse", ESP.Config.GradientReverse, function(v) ESP.Config.GradientReverse = v end)
    end
    rightClickSettings(grad2Row.row, "gradient", gradientSettings)
    rightClickSettings(gradRow.row, "gradient", gradientSettings)
    -- v0.0.28: Text Background is tunable -- right-click for colour / transparency / padding.
    local textBgRow = configCheckbox(espPanel, "Text Background", ESP.Config.TextBackground, function(v) ESP.Config.TextBackground = v end)
    rightClickSettings(textBgRow.row, "text background", function(popup)
        popup:swatch("Color", ESP.Config.TextBgColor, function(c) ESP.Config.TextBgColor = c end)
        popup:slider("Transparency", 0, 1, ESP.Config.TextBgTransparency, 2, function(v) ESP.Config.TextBgTransparency = v end)
        popup:slider("Padding", 0, 16, ESP.Config.TextBgPadding, 0, function(v) ESP.Config.TextBgPadding = v end)
    end)
    local outlineRow = configCheckbox(espPanel, "Outline", ESP.Config.Outline, function(v) ESP.Config.Outline = v end)
    attachSingleSwatch(outlineRow.row, ESP.Boxes.OutlineColor, function(c) ESP.Boxes.OutlineColor = c end)
    configCheckbox(espPanel, "Self ESP", ESP.Config.SelfESP, function(v) ESP.Config.SelfESP = v end)
    -- koffee extras (not in Matcha, kept): finer-grained bbox + smoothing control
    configCheckbox(espPanel, "Character Only", ESP.Config.CharacterOnly, function(v) ESP.Config.CharacterOnly = v end)
    -- v0.0.28: Follow Direction is Cube-only. It refuses to arm unless Box Type is
    -- Cube, and the Box Type dropdown forces it off on every switch (below).
    local followDirCtrl
    followDirCtrl = configCheckbox(espPanel, "Follow Direction", ESP.Config.FollowDirection, function(v)
        if v and ESP.Boxes.BoxType ~= "Cube" then
            followDirCtrl.setState(false)   -- 2D box -> not allowed, snap back off
            return
        end
        ESP.Config.FollowDirection = v
    end)
    configCheckbox(espPanel, "Immediate Mode", ESP.Config.ImmediateMode, function(v) ESP.Config.ImmediateMode = v end)
    dropdown(espPanel, "Sizing Type", { "Static", "Bounding", "Prediction" }, ESP.Config.SizingType,
        function(v) ESP.Config.SizingType = v end)
    slider(espPanel, "Render Distance", 1, 30000, ESP.Config.RenderDistance, 0,
        function(v) ESP.Config.RenderDistance = v end)
    -- v0.0.22: global Feature-Interface thickness + distance-invariance.
    -- v0.0.23: supports sub-1 (down to 0.1) for hairline lines.
    -- v0.0.28: Equal Size removed -- it broke distance-scaled features, so it's
    -- pinned ON permanently (constant thickness). Thickness slider still applies.
    slider(espPanel, "Thickness", 0.1, 8, ESP.Render.Thickness, 1,
        function(v) ESP.Render.Thickness = v end)

    --------------------------------------------------------------- Box
    local boxesPanel = panel(leftCol, "box")
    local boxesMaster = configCheckbox(boxesPanel, "Enabled", ESP.Boxes.Enabled, function(v) ESP.Boxes.Enabled = v end)
    -- v0.0.24: main box line colour + fill colour. Outline colour is its own swatch
    -- on the esp panel's Outline row (separate now).
    attachDualSwatch(boxesMaster.row, ESP.Boxes.Color, ESP.Boxes.FillColor,
        function(c) ESP.Boxes.Color     = c end,
        function(c) ESP.Boxes.FillColor = c end)
    rightClickSettings(boxesMaster.row, "box", function(popup)
        popup:slider("Thickness", 0.1, 8, ESP.Boxes.Thickness > 0 and ESP.Boxes.Thickness or ESP.Render.Thickness, 1, function(v) ESP.Boxes.Thickness = v end)
        popup:slider("Outline Thickness", 0, 6, ESP.Boxes.OutlineThickness, 1, function(v) ESP.Boxes.OutlineThickness = v end)
    end)
    -- v0.0.28: right-click Fill Box to tune its transparency.
    local fillRow = configCheckbox(boxesPanel, "Fill Box", ESP.Boxes.FillBox, function(v) ESP.Boxes.FillBox = v end)
    rightClickSettings(fillRow.row, "fill box", function(popup)
        popup:slider("Transparency", 0, 1, ESP.Boxes.FillTransparency, 2, function(v) ESP.Boxes.FillTransparency = v end)
    end)
    -- v0.0.26: Corners is 2D-only. Switching to Cube forces it off; you can't turn
    -- it on while Cube is selected.
    -- v0.0.28: switching Box Type ALSO forces Follow Direction off (it's Cube-only).
    local cornersCtrl
    dropdown(boxesPanel, "Box Type", { "2D", "Cube" }, ESP.Boxes.BoxType, function(v)
        ESP.Boxes.BoxType = v
        if v == "Cube" and ESP.Boxes.Corners then
            ESP.Boxes.Corners = false
            if cornersCtrl then cornersCtrl.setState(false) end
        end
        -- reset Follow Direction on any switch (per he) so it never lingers wrong
        ESP.Config.FollowDirection = false
        if followDirCtrl then followDirCtrl.setState(false) end
    end)
    cornersCtrl = configCheckbox(boxesPanel, "Corners", ESP.Boxes.Corners, function(v)
        if v and ESP.Boxes.BoxType == "Cube" then
            cornersCtrl.setState(false)   -- not allowed with Cube -- snap back off
            return
        end
        ESP.Boxes.Corners = v
    end)
    slider(boxesPanel, "Corner Length", 0.05, 0.5, ESP.Boxes.CornerLength, 2, function(v) ESP.Boxes.CornerLength = v end)

    --------------------------------------------------------------- Name
    local namePanel = panel(leftCol, "name")
    local nameMaster = configCheckbox(namePanel, "Enabled", ESP.Names.Enabled, function(v) ESP.Names.Enabled = v end)
    attachSingleSwatch(nameMaster.row, ESP.Names.Color, function(c) ESP.Names.Color = c end)
    -- v0.0.28: right-click Name for text size + outline thickness (all text does this).
    rightClickSettings(nameMaster.row, "name", function(popup)
        popup:slider("Text Size", 8, 28, ESP.Names.TextSize, 0, function(v) ESP.Names.TextSize = v end)
        popup:slider("Outline Thickness", 0, 6, ESP.Names.OutlineThickness, 1, function(v) ESP.Names.OutlineThickness = v end)
    end)
    dropdown(namePanel, "Type", { "Name", "Display Name" }, ESP.Names.Type, function(v) ESP.Names.Type = v end)

    --------------------------------------------------------------- Indicators
    -- Single panel (toggles live together in the UI); each is its own entry in
    -- the arraylist though (see GetDetail). Right-click Skeleton / Head Dot /
    -- Distance for per-feature settings popups.
    local indPanel = panel(rightCol, "indicators")
    local distRow = configCheckbox(indPanel, "Distance", ESP.Indicators.Distance.Enabled, function(v) ESP.Indicators.Distance.Enabled = v end)
    attachSingleSwatch(distRow.row, ESP.Indicators.Distance.Color, function(c) ESP.Indicators.Distance.Color = c end)
    rightClickSettings(distRow.row, "distance", function(popup)
        popup:slider("Text Size", 8, 28, ESP.Indicators.Distance.TextSize, 0, function(v) ESP.Indicators.Distance.TextSize = v end)
        popup:slider("Outline Thickness", 0, 6, ESP.Indicators.Distance.OutlineThickness, 1, function(v) ESP.Indicators.Distance.OutlineThickness = v end)
    end)
    local skelRow = configCheckbox(indPanel, "Skeleton", ESP.Indicators.Skeleton.Enabled, function(v) ESP.Indicators.Skeleton.Enabled = v end)
    attachSingleSwatch(skelRow.row, ESP.Indicators.Skeleton.Color, function(c) ESP.Indicators.Skeleton.Color = c end)
    rightClickSettings(skelRow.row, "skeleton", function(popup)
        popup:slider("Thickness", 0.1, 8, ESP.Indicators.Skeleton.Thickness or 0, 1, function(v) ESP.Indicators.Skeleton.Thickness = v end)
    end)
    local hdRow = configCheckbox(indPanel, "Head Dot", ESP.Indicators.HeadDot.Enabled, function(v) ESP.Indicators.HeadDot.Enabled = v end)
    attachSingleSwatch(hdRow.row, ESP.Indicators.HeadDot.Color, function(c) ESP.Indicators.HeadDot.Color = c end)
    rightClickSettings(hdRow.row, "head dot", function(popup)
        popup:slider("Size", 2, 24, ESP.Indicators.HeadDot.Size or 6, 0, function(v) ESP.Indicators.HeadDot.Size = v end)
    end)
    -- v0.0.28: right-click Profile Picture for size / outline thickness / Y offset.
    local pfpRow = configCheckbox(indPanel, "Profile Picture", ESP.Indicators.ProfilePicture.Enabled, function(v) ESP.Indicators.ProfilePicture.Enabled = v end)
    rightClickSettings(pfpRow.row, "profile picture", function(popup)
        popup:slider("Size", 16, 96, ESP.Indicators.ProfilePicture.Size, 0, function(v) ESP.Indicators.ProfilePicture.Size = v end)
        popup:slider("Outline Thickness", 0, 6, ESP.Indicators.ProfilePicture.OutlineThickness, 1, function(v) ESP.Indicators.ProfilePicture.OutlineThickness = v end)
        popup:slider("Y Offset", -80, 80, ESP.Indicators.ProfilePicture.YOffset, 0, function(v) ESP.Indicators.ProfilePicture.YOffset = v end)
    end)

    --------------------------------------------------------------- Health
    local healthPanel = panel(rightCol, "health")
    local hbRow = configCheckbox(healthPanel, "Health Bar", ESP.Health.Bar.Enabled, function(v) ESP.Health.Bar.Enabled = v end)
    attachSingleSwatch(hbRow.row, ESP.Health.Bar.Color, function(c) ESP.Health.Bar.Color = c end)
    configCheckbox(healthPanel, "Health Based", ESP.Health.Based, function(v) ESP.Health.Based = v end)
    configCheckbox(healthPanel, "Health Text", ESP.Health.Text, function(v) ESP.Health.Text = v end)
    dropdown(healthPanel, "Text Pos", { "Above Name", "On Health Bar" }, ESP.Health.TextPos, function(v) ESP.Health.TextPos = v end)

    --------------------------------------------------------------- Tracer
    local tracerPanel = panel(rightCol, "tracer")
    local trRow = configCheckbox(tracerPanel, "Enabled", ESP.Tracer.Enabled, function(v) ESP.Tracer.Enabled = v end)
    attachSingleSwatch(trRow.row, ESP.Tracer.Color, function(c) ESP.Tracer.Color = c end)
    dropdown(tracerPanel, "Origin", { "Mouse", "Bottom", "Middle", "Top" }, ESP.Tracer.Origin, function(v) ESP.Tracer.Origin = v end)
    dropdown(tracerPanel, "Location", { "Below", "Middle", "Above" }, ESP.Tracer.Location, function(v) ESP.Tracer.Location = v end)
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
        -- v0.0.22: popups live in a SEPARATE ScreenGui, so the window's fade
        -- doesn't touch them. Dismiss any open color picker + dropdowns on close
        -- so they don't linger over the game after the menu is hidden.
        closeColorPicker()
        for _, closer in pairs(openDropdowns) do closer(true) end
        for _, closer in pairs(openSettingsPopups) do closer() end
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
