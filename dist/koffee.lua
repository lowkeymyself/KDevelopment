-- koffee v0.0.38
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.0.38"

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
        local MONO  = "rbxasset://fonts/families/RobotoMono.json"
        -- v0.0.29: Matcha's ACTUAL face is Proxima Soft Bold. We host the .ttf on a
        -- public repo and AUTO-DOWNLOAD it once (cached to the executor's workspace
        -- folder), wrap it in a Roblox font-family JSON so getcustomasset can hand a
        -- content id to Font.new. No manual file drop needed. Everything is pcall'd
        -- with a Nunito (closest built-in) fallback, so a locked-down executor or a
        -- failed download still renders -- the font is a nicety, never a hard dep.
        local FONT_URL  = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/ProximaSoft-Bold.ttf"
        local FONT_FILE = "koffee_proximasoft.ttf"
        local FONT_JSON = "koffee_proximasoft.json"
        local customFam = (function()
            local ok, res = pcall(function()
                local getasset = getcustomasset or getsynasset
                    or (syn and syn.getcustomasset)
                local isf, wf = isfile, writefile
                if not (getasset and isf and wf) then return nil end

                -- honour a manual drop first (any local proxima/koffee_font file),
                -- otherwise download the hosted ttf once and cache it.
                local target
                for _, name in ipairs({
                    FONT_FILE, "koffee_font.ttf", "koffee_font.otf",
                    "ProximaSoft-Bold.ttf", "ProximaSoft-Bold.otf",
                }) do
                    if not target and isf(name) then target = name end
                end
                if not target then
                    -- download: prefer a binary-safe request API, fall back to HttpGet
                    local body
                    local req = (syn and syn.request) or (http and http.request)
                        or http_request or request
                    if req then
                        local rok, r = pcall(req, { Url = FONT_URL, Method = "GET" })
                        if rok and r and r.Body and #r.Body > 4096 then body = r.Body end
                    end
                    if not body then
                        local hok, h = pcall(function() return game:HttpGetAsync(FONT_URL) end)
                        if hok and h and #h > 4096 then body = h end
                    end
                    if not body then return nil end   -- no HTTP -> Nunito fallback
                    wf(FONT_FILE, body)
                    target = FONT_FILE
                end

                local ttfId = getasset(target)
                -- one bold face driving every weight (Matcha's UI is single-weight).
                local fam = {
                    name  = "ProximaSoft",
                    faces = {
                        { name = "Regular",   weight = 400, style = "normal", assetId = ttfId },
                        { name = "SemiBold",  weight = 600, style = "normal", assetId = ttfId },
                        { name = "Bold",      weight = 700, style = "normal", assetId = ttfId },
                        { name = "ExtraBold", weight = 800, style = "normal", assetId = ttfId },
                    },
                }
                wf(FONT_JSON, game:GetService("HttpService"):JSONEncode(fam))
                return getasset(FONT_JSON)
            end)
            return ok and res or nil
        end)()
        local UI = customFam or "rbxasset://fonts/families/Nunito.json"
        Koffee.UsingCustomFont = customFam ~= nil
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
    -- v0.0.10 bumped +2 for Nunito (it rendered small). v0.0.30: Proxima Soft Bold
    -- has a larger apparent size than Nunito at the same point size, so we pull the
    -- whole scale back down -2 to match the previous (Nunito) visual weight.
    Text   = { Tiny = 10, Small = 11, Body = 12, Header = 13, Title = 15 },
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

-- v0.0.30 pill machinery, rewritten. The pill is a follower: its resting state is
-- ALWAYS the active tab button's live rect (position + size, both relative to the
-- tabBar). On a user tab-switch it plays a two-phase stretch->contract to the new
-- rect; the rest of the time it just snaps to the active button whenever that
-- button's geometry moves. That last part is the fix -- an AutomaticSize tab button
-- grows a few frames AFTER creation once the custom font's glyph metrics land, and
-- since the tabBar itself doesn't move, the old code never re-snapped and the pill
-- sat offset until you clicked another tab. Now every source of reflow (font load,
-- window drag, resize) re-snaps through the single geometry watcher below.
local PILL_STRETCH  = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local PILL_CONTRACT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local pillAnimating = false
local pillT1, pillT2 = nil, nil

-- active button's rect expressed in tabBar-local offsets
local function pillRectFor(button)
    return UDim2.new(0, button.AbsolutePosition.X - tabBar.AbsolutePosition.X,
                     0, button.AbsolutePosition.Y - tabBar.AbsolutePosition.Y),
           UDim2.new(0, button.AbsoluteSize.X, 0, button.AbsoluteSize.Y)
end

local function pillSnap(button)
    if pillT1 then pillT1:Cancel(); pillT1 = nil end
    if pillT2 then pillT2:Cancel(); pillT2 = nil end
    pillAnimating = false
    local pos, size = pillRectFor(button)
    pill.Position, pill.Size = pos, size
    if pillFirstShow then
        tween(pill, Theme.Animation.Normal, { BackgroundTransparency = 0 })
        pillFirstShow = false
    end
end

local function movePillTo(button, snap)
    if pillFirstShow or snap then pillSnap(button); return end
    local targetPos, targetSize = pillRectFor(button)
    -- stretch phase: span both the current pill and the destination, then contract.
    local curX, curW = pill.Position.X.Offset, pill.Size.X.Offset
    local endX, endW = targetPos.X.Offset, targetSize.X.Offset
    local stretchX = math.min(curX, endX)
    local stretchW = math.max(curX + curW, endX + endW) - stretchX
    if pillT1 then pillT1:Cancel() end
    if pillT2 then pillT2:Cancel() end
    pillAnimating = true
    pillT1 = TweenService:Create(pill, PILL_STRETCH, {
        Position = UDim2.new(0, stretchX, 0, targetPos.Y.Offset),
        Size     = UDim2.new(0, stretchW, 0, targetSize.Y.Offset),
    })
    pillT1:Play()
    pillT1.Completed:Connect(function(state)
        if state ~= Enum.PlaybackState.Completed then return end
        pillT2 = TweenService:Create(pill, PILL_CONTRACT, { Position = targetPos, Size = targetSize })
        pillT2:Play()
        pillT2.Completed:Connect(function(s2)
            if s2 == Enum.PlaybackState.Completed then pillAnimating = false end
        end)
    end)
end

-- single geometry watcher: re-snap the pill to the active button whenever anything
-- shifts its rect (font reflow, window drag/resize) UNLESS a switch animation owns
-- the pill right now. Fed by the tabBar move signal + each button's own size/pos
-- signals (hooked in addTab).
local function pillResync()
    if pillAnimating or not activeTab then return end
    local tab = tabs[activeTab]
    if tab then pillSnap(tab.Button) end
end
tabBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(pillResync)

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

-- v0.0.34: forward-declared shared upvalues. The config-system body + team/
-- friend helpers live inside an IIFE further down so their ~20 locals get their
-- OWN register budget (Luau's 200-local ceiling is per-function; the main chunk
-- is already close, which is why Combat is an IIFE too). Only these handles are
-- promoted to the main chunk so ESP / World / Combat can call them.
local Shared = { IgnoreFriends = false }   -- Options flag, read by every target gate
local isSameTeam, isFriend, registerConfig, rebuildConfigTabs

-- v0.0.37: OS-level input from the Koffee Helper (Roblox can't see mouse 4/5).
-- The poll loop at the bottom of the file fills XB1/XB2; binds can be the virtual
-- strings "XButton1"/"XButton2" which the helper-driven Heartbeats resolve.
local Helper = { Connected = false, XB1 = false, XB2 = false }
local VIRTUAL_LABELS = { XButton1 = "xb1", XButton2 = "xb2" }
-- display text for ANY bind: virtual string, Roblox EnumItem, or nil.
local function keyLabel(bind)
    if bind == nil then return nil end
    if type(bind) == "string" then return VIRTUAL_LABELS[bind] or bind end
    if typeof(bind) == "EnumItem" then return bind.Name end
    return nil
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

    -- v0.0.30: the button's own rect changing (AutomaticSize settling after the
    -- font's glyph metrics load, or a reflow) re-snaps the pill if this tab is the
    -- active one -- kills the "pill offset on launch until you switch tabs" bug.
    button:GetPropertyChangedSignal("AbsoluteSize"):Connect(pillResync)
    button:GetPropertyChangedSignal("AbsolutePosition"):Connect(pillResync)

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

    -- v0.0.34: stash the build fn so the config system can re-run it against the
    -- same panel (clears children first) to push loaded values into every widget.
    tabs[name] = { Button = button, Panel = panel, Build = buildFn }
end

-- v0.0.34: rebuild the config-driven tabs after a config load so sliders /
-- dropdowns / checkboxes / keybind pills re-read the freshly applied state.
-- moduleCheckbox is the only Watchers subscriber, so clearing Watchers first
-- keeps the subscriber count flat across reloads (they re-subscribe here).
local function rebuildTabPanel(name)
    local entry = tabs[name]
    if not (entry and entry.Build) then return end
    local p = entry.Panel
    for _, c in ipairs(p:GetChildren()) do c:Destroy() end
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = p,
    })
    new("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = p })
    pcall(entry.Build, p)
end
rebuildConfigTabs = function()
    for _, m in pairs(Modules) do m.Watchers = {} end
    for _, n in ipairs({ "Visuals", "Combat", "World", "Options" }) do
        rebuildTabPanel(n)
    end
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
    -- v0.0.34: only seed the default when nothing is bound yet, so a config load
    -- (or a tab rebuild) never clobbers the user's chosen / loaded keybind.
    if initialKey and Keybinds[moduleId] == nil then Keybinds[moduleId] = initialKey end
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
        Text = keyLabel(currentKey) or "no keybind",
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
            pendingRebind.pill.Text = keyLabel(Keybinds[pendingRebind.moduleId]) or "no keybind"
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
    pill.Text = keyLabel(keyCode) or "?"
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

local ColorPicker = { root = nil, activeSwatch = nil, callback = nil, h = 0, s = 0, v = 0,
    a = 1, alphaEnabled = false, onAlpha = nil }

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
    -- v0.0.31: optional alpha bar (right of hue). Grey backing + colour overlay
    -- that fades top(opaque)->bottom(transparent) reads as an alpha ramp. Only
    -- shown when a swatch opts into alpha (used by the FOV fill).
    local alphaBar = new("Frame", {
        Name = "AlphaBar",
        Position = UDim2.new(1, -50, 0, 22),
        Size = UDim2.new(0, 20, 0, 140),
        BackgroundColor3 = Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 251,
        Parent = root,
    }, { corner(4) })
    local alphaFill = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 252,
        Parent = alphaBar,
    }, {
        corner(4),
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Rotation = 90,
        }),
    })
    local alphaCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 4, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 253,
        Parent = alphaBar,
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
        alphaFill.BackgroundColor3 = c
        alphaCursor.Position = UDim2.new(0.5, 0, 1 - ColorPicker.a, 0)
        if ColorPicker.alphaEnabled and ColorPicker.onAlpha then
            ColorPicker.onAlpha(ColorPicker.a)
        end
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
    local alphaDragging = false
    alphaBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        alphaDragging = true
        local abs = alphaBar.AbsolutePosition
        local siz = alphaBar.AbsoluteSize
        ColorPicker.a = 1 - math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
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
        if alphaDragging then
            local abs = alphaBar.AbsolutePosition
            local siz = alphaBar.AbsoluteSize
            ColorPicker.a = 1 - math.clamp((input.Position.Y - abs.Y) / siz.Y, 0, 1)
            applyToUI()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
            alphaDragging = false
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
    ColorPicker.svArea = svArea
    ColorPicker.hueSlider = hueSlider
    ColorPicker.alphaBar = alphaBar
    return root
end

local function openColorPicker(swatchInstance, initialColor, onChange, opts)
    if not ColorPicker.root then buildColorPicker() end
    -- v0.0.16: cancel any pending close from a prior closeColorPicker call.
    -- Without this, the task.delay(0.22) from close fires AFTER open and
    -- hides the now-visible picker.
    if ColorPicker.closeTask then
        pcall(task.cancel, ColorPicker.closeTask)
        ColorPicker.closeTask = nil
    end
    opts = opts or {}
    ColorPicker.activeSwatch = swatchInstance
    ColorPicker.callback = onChange
    -- v0.0.31: alpha mode (fills). Reflow layout to make room for the alpha bar.
    ColorPicker.alphaEnabled = opts.alpha == true
    ColorPicker.a = opts.initialAlpha or 1
    ColorPicker.onAlpha = opts.onAlpha
    if ColorPicker.alphaEnabled then
        ColorPicker.root.Size = UDim2.new(0, 292, 0, 260)
        ColorPicker.svArea.Size = UDim2.new(1, -58, 0, 140)
        ColorPicker.alphaBar.Visible = true
    else
        ColorPicker.root.Size = UDim2.new(0, 260, 0, 260)
        ColorPicker.svArea.Size = UDim2.new(1, -32, 0, 140)
        ColorPicker.alphaBar.Visible = false
    end
    local h, s, v = initialColor:ToHSV()
    ColorPicker.h, ColorPicker.s, ColorPicker.v = h, s, v
    -- position near swatch (below + right, but clamp to viewport)
    local abs = swatchInstance.AbsolutePosition
    local siz = swatchInstance.AbsoluteSize
    local vp = Workspace.CurrentCamera.ViewportSize
    local pickerW, pickerH = (ColorPicker.alphaEnabled and 292 or 260), 260
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
        end, {
            alpha = opts.alpha,
            initialAlpha = opts.getAlpha and opts.getAlpha() or opts.initialAlpha,
            onAlpha = opts.onAlpha,
        })
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

    -- popup lives in the dedicated popup ScreenGui, above everything -- ZIndex 260
    -- so it clears the settings popup (210) AND the colour picker (250) when a
    -- dropdown is opened from inside one of them.
    local list = new("Frame", {
        Size = UDim2.new(0, 100, 0, #options * 26),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 260,
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
            ZIndex = 261,
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
            ZIndex = 262,
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
        frame = wrap,
        button = btn,
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
        Size = UDim2.new(1, 0, 0, 44),                       -- v0.0.32: taller
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
        Size = UDim2.new(1, -90, 0, 18),
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
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 6),                     -- v0.0.32: thicker track
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
    -- v0.0.31: dot-less slider -- just the filled accent line, no draggable knob
    -- (matcha style). The whole track width is the hit/drag area.
    local hitArea = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, -86, 0, 18),
        ZIndex = 37,
        Parent = row,
    })
    local dragging = false

    -- v0.0.32: animate the fill on programmatic set (click / typed value), snap
    -- during a live drag so it tracks the cursor 1:1.
    local function applyValue(animate)
        local pct = (current - min) / (max - min)
        if animate then
            tween(fill, Theme.Animation.Fast, { Size = UDim2.new(pct, 0, 1, 0) })
        else
            fill.Size = UDim2.new(pct, 0, 1, 0)
        end
        valueBox.Text = tostring(current)
        if onChange then onChange(current) end
    end
    local function setFromInputX(inputX)
        local trackAbs = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        if trackW <= 0 then return end
        local pct = math.clamp((inputX - trackAbs) / trackW, 0, 1)
        current = round(min + (max - min) * pct)
        applyValue(false)
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
        applyValue(true)
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
            return configCheckbox(popupFrame, label, initial, onChange)
        end
        function api:dropdown(label, options, initial, onChange)
            return dropdown(popupFrame, label, options, initial, onChange)
        end
        -- v0.0.28: colour control inside a settings popup (label + right swatch).
        -- v0.0.32: optional `sopts` (alpha etc) forwarded to colorSwatch.
        function api:swatch(label, initial, onChange, sopts)
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
            local o = { onChange = onChange }
            if sopts then for k, v in pairs(sopts) do o[k] = v end end
            colorSwatch(wrap, initial, 14, o)
            return r
        end
        -- v0.0.32: a row of N colour swatches (transparency is separate sliders now).
        function api:swatchRow(colors, onColor)
            local r = new("Frame", {
                Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 211, Parent = popupFrame,
            }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
            for i = 1, #colors do
                colorSwatch(r, colors[i], 14, { onChange = function(c) onColor(i, c) end })
            end
            return r
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
-- SHARED STATE + CONFIG SYSTEM (v0.0.34)
-- Wrapped in an IIFE so its ~20 locals get their own register budget (Luau's
-- 200-local limit is per-function; the main chunk is already near it). Only the
-- forward-declared upvalues (Shared/isSameTeam/isFriend/registerConfig/
-- rebuildConfigTabs) + Koffee.Config escape to the main chunk.
--   isSameTeam    : robust team check -- Team instance first, TeamColor/Neutral
--                   fallback for games that never assign a Team object
--   isFriend      : cached friendship lookup (IsFriendsWith yields, so resolve
--                   async once per userId; render loops read the cache)
--   ConfigRegistry: name -> live state table, walked by the config save/load
--============================================================
;(function()

-- Team check that survives games which never set Player.Team. If either player
-- carries a real Team object we trust it; otherwise we fall back to TeamColor
-- (skipping the neutral/FFA case so nobody is falsely marked a teammate).
function isSameTeam(plr, localPlr)
    localPlr = localPlr or LocalPlayer
    if not plr or plr == localPlr then return false end
    local a, b = localPlr.Team, plr.Team
    if a ~= nil or b ~= nil then return a == b end
    if localPlr.Neutral or plr.Neutral then return false end
    return localPlr.TeamColor == plr.TeamColor
end

-- IsFriendsWith is a yielding web call -- never run it inside a render loop.
-- Resolve once per userId on a background thread; the loop reads the cache and
-- treats "unknown yet" as not-a-friend until the lookup lands.
local friendStatus  = {}   -- userId -> bool
local friendPending = {}
function isFriend(plr)
    if not plr or plr == LocalPlayer then return false end
    local uid = plr.UserId
    if not uid or uid <= 0 then return false end
    local cached = friendStatus[uid]
    if cached ~= nil then return cached end
    if not friendPending[uid] then
        friendPending[uid] = true
        task.spawn(function()
            local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(uid) end)
            friendStatus[uid]  = (ok and res) or false
            friendPending[uid] = nil
        end)
    end
    return false
end

--== CONFIG SYSTEM -- save / load / auto-load per PlaceId. Subsystems register
-- their live state tables; save serializes to a Lua literal (Color3 / EnumItem /
-- Vector aware), load applies back IN PLACE so every live reference keeps
-- working, then re-syncs modules + rebuilds the config-driven tabs.
local ConfigRegistry = {}          -- name -> live table
function registerConfig(name, tbl) ConfigRegistry[name] = tbl end

local CFG_DIR = "Koffee/configs"

-- executor file API, all guarded so a locked-down runtime degrades to no-op.
local fileAPI = {
    write   = writefile,
    read    = readfile,
    isfile  = isfile,
    isfolder= isfolder,
    makefolder = makefolder,
    delfile = delfile,
    listfiles = listfiles,
}
local function filesReady()
    return fileAPI.write and fileAPI.read and fileAPI.isfile and fileAPI.listfiles
end
local function ensureDir()
    if not (fileAPI.isfolder and fileAPI.makefolder) then return end
    if not fileAPI.isfolder("Koffee")   then pcall(fileAPI.makefolder, "Koffee") end
    if not fileAPI.isfolder(CFG_DIR)     then pcall(fileAPI.makefolder, CFG_DIR) end
end

-- === serialize ============================================================
local encValue
local function encTable(tbl)
    local parts = {}
    for k, v in pairs(tbl) do
        -- skip private/runtime keys (_hooked, _target, connections handled below)
        if not (type(k) == "string" and k:sub(1, 1) == "_") then
            local ev = encValue(v)
            if ev ~= nil then
                local ek
                if type(k) == "number" then ek = "[" .. k .. "]"
                elseif type(k) == "string" then ek = "[" .. string.format("%q", k) .. "]"
                end
                if ek then parts[#parts + 1] = ek .. "=" .. ev end
            end
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end
encValue = function(v)
    local t = typeof(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "string" then return string.format("%q", v)
    elseif t == "Color3" then
        return string.format("Color3.new(%.6f,%.6f,%.6f)", v.R, v.G, v.B)
    elseif t == "EnumItem" then return tostring(v)          -- "Enum.KeyCode.E"
    elseif t == "Vector2" then return string.format("Vector2.new(%.6f,%.6f)", v.X, v.Y)
    elseif t == "Vector3" then return string.format("Vector3.new(%.6f,%.6f,%.6f)", v.X, v.Y, v.Z)
    elseif t == "table" then return encTable(v)
    end
    return nil   -- functions / Instances / connections / threads -> dropped
end

local function snapshotAll()
    local snap = { registry = {}, keybinds = {}, modules = {} }
    for name, tbl in pairs(ConfigRegistry) do snap.registry[name] = tbl end
    for id, key in pairs(Keybinds) do snap.keybinds[id] = key end
    for id, m in pairs(Modules) do snap.modules[id] = m.Enabled and true or false end
    return snap
end

-- === apply ================================================================
local function applyInto(target, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(target[k]) == "table" then
            applyInto(target[k], v)
        else
            target[k] = v
        end
    end
end

-- loadSnapshot applies a decoded config and then rebuilds the config-driven
-- tabs (rebuildConfigTabs is a main-chunk upvalue set near addTab) so sliders /
-- dropdowns / checkboxes / keybind pills re-read the freshly loaded state.
local function loadSnapshot(data)
    if type(data) ~= "table" then return false end
    if data.registry then
        for name, tbl in pairs(data.registry) do
            local target = ConfigRegistry[name]
            if target and type(tbl) == "table" then applyInto(target, tbl) end
        end
    end
    if data.keybinds then
        for k in pairs(Keybinds) do Keybinds[k] = nil end
        for id, key in pairs(data.keybinds) do
            -- accept Roblox EnumItems AND virtual XButton strings (v0.0.37)
            if typeof(key) == "EnumItem" or key == "XButton1" or key == "XButton2" then
                Keybinds[id] = key
            end
        end
    end
    if data.modules then
        for id, state in pairs(data.modules) do
            local m = Modules[id]
            if m and (m.Enabled and true or false) ~= (state and true or false) then
                toggleModule(id)
            end
        end
    end
    if rebuildConfigTabs then pcall(rebuildConfigTabs) end
    return true
end

-- === disk ops =============================================================
local ConfigIO = {}
function ConfigIO.list()
    local out = {}
    if not filesReady() then return out end
    ensureDir()
    local ok, files = pcall(fileAPI.listfiles, CFG_DIR)
    if not ok or type(files) ~= "table" then return out end
    for _, path in ipairs(files) do
        local name = tostring(path):match("([^/\\]+)%.koffee$")
        if name then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end
function ConfigIO.save(name)
    if not filesReady() then return false, "no file access" end
    name = tostring(name):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false, "name required" end
    ensureDir()
    local ok, text = pcall(function() return "return " .. encTable(snapshotAll()) end)
    if not ok then return false, "encode failed" end
    local wok = pcall(fileAPI.write, CFG_DIR .. "/" .. name .. ".koffee", text)
    if not wok then return false, "write failed" end
    return true, name
end
function ConfigIO.load(name)
    if not filesReady() then return false, "no file access" end
    local path = CFG_DIR .. "/" .. name .. ".koffee"
    if not fileAPI.isfile(path) then return false, "not found" end
    local rok, text = pcall(fileAPI.read, path)
    if not rok or type(text) ~= "string" then return false, "read failed" end
    local ldr = loadstring or load
    if not ldr then return false, "no loadstring" end
    local fn = ldr(text)
    if not fn then return false, "parse failed" end
    local dok, data = pcall(fn)
    if not dok then return false, "eval failed" end
    return loadSnapshot(data), name
end
function ConfigIO.delete(name)
    if not (filesReady() and fileAPI.delfile) then return false end
    local path = CFG_DIR .. "/" .. name .. ".koffee"
    if fileAPI.isfile(path) then return pcall(fileAPI.delfile, path) end
    return false
end
-- per-place auto-load marker: Koffee/configs/_auto_<PlaceId>.txt holds a name
local function autoPath() return CFG_DIR .. "/_auto_" .. tostring(game.PlaceId) .. ".txt" end
function ConfigIO.getAuto()
    if not filesReady() then return nil end
    local p = autoPath()
    if fileAPI.isfile(p) then
        local ok, v = pcall(fileAPI.read, p)
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return nil
end
function ConfigIO.setAuto(name)
    if not filesReady() then return end
    ensureDir()
    if name and name ~= "" then pcall(fileAPI.write, autoPath(), name)
    elseif fileAPI.delfile then pcall(fileAPI.delfile, autoPath()) end
end

Koffee.Config = ConfigIO

end)()   -- end SHARED STATE + CONFIG SYSTEM IIFE

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

-- v0.0.34: expose ESP state to the config system.
registerConfig("esp_config",     ESP.Config)
registerConfig("esp_render",     ESP.Render)
registerConfig("esp_boxes",      ESP.Boxes)
registerConfig("esp_names",      ESP.Names)
registerConfig("esp_indicators", ESP.Indicators)
registerConfig("esp_health",     ESP.Health)
registerConfig("esp_tracer",     ESP.Tracer)
registerConfig("esp_colors",     ESP.Colors)
registerConfig("shared",         Shared)

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
    -- v0.0.29: the group carries a KGrad so the cube fill can pick up the
    -- Gradient toggle. A UIGradient on a CanvasGroup tints the flattened strip
    -- image in one shot -- but only spans the group's OWN rect, so the render
    -- code resizes the group to hug the fill AABB (see updateESPRigs).
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
    }, { lineGradient() })
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
        -- v0.0.34: robust team detection (Team obj -> TeamColor/Neutral fallback)
        -- + Options "Ignore Friends" gate, shared with the combat systems.
        local same = isSameTeam(plr)
        if (same and ESP.Config.TeamCheck) or (Shared.IgnoreFriends and isFriend(plr)) then
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
        if ESP.Config.TeamBasedColor and same then
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
                local hx0, hx1 = math.huge, -math.huge
                local hy0, hy1 = math.huge, -math.huge
                for _, c in ipairs(hull) do
                    if c.x < hx0 then hx0 = c.x end
                    if c.x > hx1 then hx1 = c.x end
                    if c.y < hy0 then hy0 = c.y end
                    if c.y > hy1 then hy1 = c.y end
                end
                local totalH = hy1 - hy0
                local spanX  = math.max(hx1 - hx0, 1)
                local rowCount = math.clamp(math.floor(totalH / FILL_ROW_STEP), 1, MAX_FILL_ROWS)
                local rowH = totalH / rowCount
                -- v0.0.29: group hugs the fill AABB (not the full screen) so a
                -- gradient on the CanvasGroup spans the silhouette instead of a
                -- screen-wide slice. Strips are positioned RELATIVE to the group.
                rig.fillGroup.Position = UDim2.new(0, hx0, 0, hy0)
                rig.fillGroup.Size = UDim2.new(0, spanX, 0, totalH)
                rig.fillGroup.Visible = true
                rig.fillGroup.GroupTransparency = ESP.Boxes.FillTransparency
                -- v0.0.29: fill obeys the Gradient toggle. White strips + group
                -- gradient when on; flat fillColor when off.
                applyLineGradient(rig.fillGroup, lineGradOn)
                local stripCol = lineGradOn and Color3.new(1, 1, 1) or fillColor
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
                            -- coords are RELATIVE to the group's AABB origin now.
                            f.Position = UDim2.new(0, xl - hx0, 0, yTop - hy0)
                            f.Size = UDim2.new(0, math.max(xr - xl, 1), 0, rowH + 1)
                            f.BackgroundColor3 = stripCol
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
            -- v0.0.29: 2D fill obeys the Gradient toggle. boxRoot's own KGrad
            -- tints its background (the fill); off -> falls back to fillColor.
            -- The KGrad bleeds onto the KMain stroke, but that stroke carries its
            -- own inner gradient (applyStrokeGradient below) which overrides it.
            applyLineGradient(rig.boxRoot, lineGradOn and fillOn)

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

-- v0.0.34: only the Clock Time target persists (Saved/Conn are runtime + skipped
-- by the serializer). Fullbright/NoFog are pure toggles -> restored via modules.
registerConfig("world_time", World.Time)

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
--============================================================
-- COMBAT TAB (v0.0.31) -- matcha-parity restructure
-- Two columns, each a sub-tab panel (pill switcher inside the card):
--   left : Aimbot / Prediction / Smoothness / FOV   + Misc(Resolver)
--   right: Silent Aim / Prediction / FOV            + Trigger Bot
-- Wrapped in its own scope so its locals don't count against the main
-- chunk's 200-local ceiling. Backends: shared targeting engine + camera
-- aimbot (Camera/Mouse), prediction, per-axis smoothness, ragebot teleports,
-- silent-aim hook (fake-camera fire-read redirect), triggerbot, FOV circle.
--============================================================
-- IIFE (not a bare do-block): Luau's 200-local limit is per FUNCTION and a
-- do-block shares the enclosing function's registers, so all of Combat's locals
-- were counting against the main chunk (-> "Out of local registers"). A function
-- scope gives this whole tab its own register budget.
;(function()
local Combat = {
    Aim = {
        Enabled       = false,
        ActivationKey = Enum.UserInputType.MouseButton2,  -- KeyCode OR UserInputType
        ActivationMode= "Hold",                           -- "Hold" | "Toggle"
        Priority      = "Crosshair",                      -- "Nearest" | "Crosshair"
        HitPart       = "Head",
        AimType       = "Camera",                         -- "Camera" | "Mouse"
        -- v0.0.36: third-person mode moves the MOUSE onto the target instead of the
        -- camera -- for games where the shot follows the cursor, not the camera
        -- (Prison Life, Da Hood). Bind aimbot to a non-RMB key (e.g. XButton2) so
        -- it doesn't fight the game's own RMB shift-lock; hold it to snap-aim.
        ThirdPerson   = false,
        Distance      = 500,
        Sensitivity   = 0.4,
        TeamCheck     = true,
        VisibleCheck  = false,
        HealthCheck   = false,
        Sticky        = false,
        Rage          = false,
        RageType      = "Camera Teleport",                -- "Camera Teleport" | "Character Teleport"
        RageYOffset   = 0,                                -- Character Teleport vertical offset (-10..10)
        Snaplines     = false,                            -- one snapline toggle at a time (aim XOR silent)
        Predict       = { Enabled = false, X = 1.0, Y = 1.0 },
        Smooth        = { Enabled = false, X = 1.0, Y = 1.0 },
        _target       = nil,
        _rageLock     = nil,   -- locked ragebot victim (held for the key duration)
    },
    -- FOV is per-context now: Combat.Aim.FOV + Combat.Silent.FOV, each an
    -- independent circle (own size/style/fill). Built via defaultFovCfg() below.
    Trigger = {
        Enabled       = false,
        ActivationKey = Enum.KeyCode.Q,
        ActivationMode= "Hold",
        UseKey        = false,
        Priority      = "Crosshair",
        HitPart       = "Head",
        HitboxMul     = 1.0,
        Delay         = 1,        -- ms
        Release       = 10,       -- ms
        TeamCheck     = false,
        VisibleCheck  = false,
    },
    Silent = {   -- fake-camera silent aim
        Enabled       = false,
        -- v0.0.34: no activation key by default -- RequireLMB is the gate so silent
        -- "just works" on click. Set a key via the pill to add a hold/toggle arm.
        ActivationKey = nil,
        ActivationMode= "Hold",
        Priority      = "Crosshair",
        HitPart       = "Head",
        Method        = "Forced Magic-Bullet",            -- our fake-camera fire-read redirect
        Distance      = 500,
        TeamCheck     = true,
        VisibleCheck  = false,
        HealthCheck   = false,
        Sticky        = false,
        RequireLMB    = true,
        -- v0.0.35: AGGRESSIVE (default OFF) -- default silent only redirects the
        -- Mouse's aim reads (Hit/Target/UnitRay), which is safe on every game. On =
        -- ALSO hijack camera-ray methods + Workspace raycasts for cast-based guns.
        -- This is what breaks cameras / real-game weapons, so it's opt-in.
        Aggressive    = false,
        -- v0.0.34: third-person games fire from the gun/character, not the camera,
        -- so the fire ray's origin is offset and its direction need not align with
        -- the camera LookVector. On = relax the ray distinguisher so those redirect
        -- too (only matters with Aggressive on).
        ThirdPerson   = false,
        Snaplines     = false,
        Predict       = { Enabled = false, X = 1.0, Y = 1.0 },
        _hooked       = false,
    },
    Misc = { Resolver = false },
}

    -- one FOV config per context (aimbot + silent). Both can be active at once;
    -- each draws its own concentric ring at the size the user sets.
    local function defaultFovCfg()
        return {
            Enabled = false, Size = 100, Origin = "Center", Filled = false, Spin = false,
            Style = "Smooth", Color = Color3.new(1, 1, 1), FillColor = Color3.fromRGB(212, 145, 90),
            FillTransparency = 0.5, Thickness = 1, DotSize = 4, DotGap = 18,
            Fill = {
                RemoveOutline = false, Spin = false,
                Custom = {
                    Enabled = false, Points = 2, Triangle = false,
                    Colors = { Color3.fromRGB(212,145,90), Color3.fromRGB(230,200,120),
                               Color3.fromRGB(160,120,220), Color3.fromRGB(120,200,255) },
                    Alphas = { 0, 0, 0, 0 },
                    Moving = { Enabled = false, Speed = 1, Direction = 0 },
                },
            },
        }
    end
    Combat.Aim.FOV    = defaultFovCfg()
    Combat.Silent.FOV = defaultFovCfg()
    -- distinct defaults so both rings are visible at once -- identical size + origin
    -- overlap into a single ring ("can't see both"). The user can still match them.
    Combat.Silent.FOV.Size  = 140
    Combat.Silent.FOV.Color = Color3.fromRGB(130, 200, 255)

    -- v0.0.34: expose combat state to the config system (FOV cfgs are nested in
    -- Aim/Silent so they ride along). Underscore keys (_hooked/_target/_rageLock)
    -- are skipped by the serializer.
    registerConfig("combat_aim",     Combat.Aim)
    registerConfig("combat_silent",  Combat.Silent)
    registerConfig("combat_trigger", Combat.Trigger)
    registerConfig("combat_misc",    Combat.Misc)

    --== math helpers ==--
    local function shortestAngle(a) return (a + math.pi) % (2 * math.pi) - math.pi end
    local function lookAngles(dir)
        local flat = math.sqrt(dir.X * dir.X + dir.Z * dir.Z)
        return math.atan2(-dir.X, -dir.Z), math.atan2(dir.Y, flat)   -- yaw, pitch
    end
    local function aimCFrame(cam, from, targetPos, aX, aY)
        local dir = targetPos - from
        if dir.Magnitude < 1e-3 then return cam.CFrame end
        local gy, gp = lookAngles(dir)
        local cy, cp = lookAngles(cam.CFrame.LookVector)
        local ny = cy + shortestAngle(gy - cy) * aX
        local np = cp + (gp - cp) * aY
        return CFrame.new(from) * CFrame.fromEulerAnglesYXZ(np, ny, 0)
    end

    --== targeting engine (shared by aimbot / trigger / silent) ==--
    local function fovCenter(cfg)
        local vp = viewport()
        if cfg and cfg.Origin == "Mouse" then
            local m = UserInputService:GetMouseLocation()
            return Vector2.new(m.X, m.Y)
        end
        return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end

    -- friendly hit-part name -> candidate real part names (R15 first, R6 fallback)
    local HITPARTS = { "Head", "Torso", "HRP", "Left Arm", "Right Arm", "Left Leg",
        "Right Leg", "Left Hand", "Right Hand", "Left Foot", "Right Foot" }
    local HITMAP = {
        ["Head"]       = { "Head" },
        ["Torso"]      = { "UpperTorso", "Torso", "LowerTorso" },
        ["HRP"]        = { "HumanoidRootPart" },
        ["Left Arm"]   = { "LeftUpperArm", "LeftLowerArm", "Left Arm" },
        ["Right Arm"]  = { "RightUpperArm", "RightLowerArm", "Right Arm" },
        ["Left Leg"]   = { "LeftUpperLeg", "LeftLowerLeg", "Left Leg" },
        ["Right Leg"]  = { "RightUpperLeg", "RightLowerLeg", "Right Leg" },
        ["Left Hand"]  = { "LeftHand", "Left Arm" },
        ["Right Hand"] = { "RightHand", "Right Arm" },
        ["Left Foot"]  = { "LeftFoot", "Left Leg" },
        ["Right Foot"] = { "RightFoot", "Right Leg" },
    }
    local function aimPart(character, partName)
        local cands = HITMAP[partName] or { "Head" }
        for _, n in ipairs(cands) do
            local p = character:FindFirstChild(n)
            if p then return p end
        end
        return findTorso(character)
    end

    local function occluded(character, fromPos, toPos)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { character, LocalPlayer.Character }
        return Workspace:Raycast(fromPos, toPos - fromPos, rp) ~= nil
    end

    -- HealthCheck: skip protected targets (ForceField / spawn shield) or dead.
    local function healthOk(character, hum)
        if not (hum and hum.Health > 0) then return false end
        if character:FindFirstChildOfClass("ForceField") then return false end
        return true
    end

    -- returns player, part. maxRadius in screen px (math.huge = no FOV limit).
    local function getBestTarget(cfg, maxRadius, center)
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        center = center or fovCenter()
        local camPos = cam.CFrame.Position
        local best, bestPart, bestScore = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local alive = char and hum and hum.Health > 0
                local hcOk = (not cfg.HealthCheck) or (char and healthOk(char, hum))
                -- v0.0.34: robust team check + Options "Ignore Friends" gate
                local excluded = (cfg.TeamCheck and isSameTeam(plr))
                              or (Shared.IgnoreFriends and isFriend(plr))
                if alive and hcOk and not excluded then
                    if true then
                        local part = aimPart(char, cfg.HitPart)
                        if part then
                            local worldDist = (part.Position - camPos).Magnitude
                            if worldDist <= (cfg.Distance or math.huge) then
                                local sp = cam:WorldToViewportPoint(part.Position)
                                if sp.Z > 0 then
                                    local crossDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                    if crossDist <= maxRadius then
                                        local vis = not (cfg.VisibleCheck and occluded(char, camPos, part.Position))
                                        if vis then
                                            local score = (cfg.Priority == "Nearest") and worldDist or crossDist
                                            if score < bestScore then
                                                bestScore, best, bestPart = score, plr, part
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return best, bestPart
    end

    local function predicted(plr, part, pr)
        local pos = part.Position
        if not pr.Enabled then return pos end
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return pos end
        local v = hrp.AssemblyLinearVelocity
        return pos + Vector3.new(v.X / math.max(pr.X, 0.01), v.Y / math.max(pr.Y, 0.01), v.Z / math.max(pr.X, 0.01))
    end

    --== FOV circles (one per context -- aimbot + silent -- both can be active) ==--
    -- (glow removed in v0.0.32 -- the real soft glow waits on the external app.)
    local FOV_MAX_DOTS = 160
    local function makeFov(name)
        local circle = new("Frame", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 200, 0, 200),
            BackgroundColor3 = Color3.fromRGB(212, 145, 90),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 11,
            Parent = screen,
        }, { pillCorner(), stroke(Color3.new(1, 1, 1), 1), lineGradient() })
        local dotContainer = new("Frame", {
            Name = "Dots", Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, Visible = false, ZIndex = 12, Parent = circle,
        })
        local dots = {}
        for _ = 1, FOV_MAX_DOTS do
            dots[#dots + 1] = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 4, 0, 4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, ZIndex = 12, Parent = dotContainer,
            }, { pillCorner() })
        end
        return {
            circle = circle,
            stroke = circle:FindFirstChildOfClass("UIStroke"),
            grad = circle:FindFirstChild("KGrad"),
            dotContainer = dotContainer,
            dots = dots,
        }
    end
    local aimFov    = makeFov("KoffeeFOV_Aim")
    local silentFov = makeFov("KoffeeFOV_Silent")

    -- snaplines: one line from the FOV origin (mouse/center) to the targeted
    -- person. Uses the tracer backend (KGrad + KOutline, featureThickness, ESP
    -- tracer colour/gradient/outline). Only one context drives it (aim XOR silent).
    local snapLine = new("Frame", {
        Name = "KoffeeSnapline", AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Visible = false, ZIndex = 11, Parent = screen,
    }, { lineGradient(), lineOutline() })

    --== activation state ==--
    local aimHeld    = false
    local silentHeld = false   -- v0.0.34: optional silent arm key (nil key = always armed)
    local lmbDown    = false   -- v0.0.35: tracked LMB state (read inside the silent
                               -- hooks; IsMouseButtonPressed is a namecall + illegal there)
    local trigHeld   = false
    local trigBusy   = false
    local silentTarget = nil   -- the part (for Mouse.Target)
    local silentPos    = nil   -- Vector3 redirect point (predicted; drives Hit/UnitRay)

    local function inputMatches(input, bind)
        if typeof(bind) == "EnumItem" then
            if bind.EnumType == Enum.KeyCode then
                return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
            elseif bind.EnumType == Enum.UserInputType then
                return input.UserInputType == bind
            end
        end
        return false
    end
    local MOUSE_SHORT = { MouseButton1 = "lmb", MouseButton2 = "rmb", MouseButton3 = "mmb" }
    local function inputName(bind)
        -- v0.0.37: virtual helper binds (mouse 4/5) render as xb1/xb2
        if type(bind) == "string" then return VIRTUAL_LABELS[bind] or bind end
        if typeof(bind) == "EnumItem" then
            if bind.EnumType == Enum.UserInputType then
                return MOUSE_SHORT[bind.Name] or bind.Name
            end
            return bind.Name:lower()
        end
        return "-"
    end

    --== Hold/Toggle chooser popup (right-click the activation pill) ==--
    local activeChooser = nil
    local function closeChooser()
        if activeChooser then
            pcall(function() activeChooser.frame:Destroy() end)
            if activeChooser.conn then activeChooser.conn:Disconnect() end
            activeChooser = nil
        end
    end
    local function openChooser(pill, cfg)
        closeChooser()
        local frame = new("Frame", {
            Name = "ModeChooser", Size = UDim2.new(0, 120, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Palette.Panel,
            BackgroundTransparency = 0.02, BorderSizePixel = 0, ZIndex = 230, Parent = popupScreen,
        }, {
            corner(6), stroke(Theme.Palette.Border, 1),
            new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
            new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        for _, mode in ipairs({ "Hold", "Toggle" }) do
            local sel = cfg.ActivationMode == mode
            local opt = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Palette.PanelElevated,
                BackgroundTransparency = sel and 0.2 or 1, AutoButtonColor = false, Text = mode:lower(),
                FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
                TextColor3 = sel and Theme.Palette.Accent or Theme.Palette.TextMuted, ZIndex = 231, Parent = frame,
            }, { corner(4) })
            opt.MouseButton1Click:Connect(function()
                cfg.ActivationMode = mode
                closeChooser()
            end)
        end
        local abs, siz = pill.AbsolutePosition, pill.AbsoluteSize
        local ox, oy = popupOffsetFor(frame, abs.X + siz.X - 120, abs.Y + siz.Y + 6)
        frame.Position = UDim2.new(0, ox, 0, oy)
        activeChooser = { frame = frame }
        task.defer(function()
            if not activeChooser then return end
            activeChooser.conn = UserInputService.InputBegan:Connect(function(input)
                local it = input.UserInputType
                if it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.MouseButton2
                or it == Enum.UserInputType.Touch then
                    local mp = input.Position
                    local a, s = frame.AbsolutePosition, frame.AbsoluteSize
                    if not (mp.X >= a.X and mp.X <= a.X + s.X and mp.Y >= a.Y and mp.Y <= a.Y + s.Y) then
                        closeChooser()
                    end
                end
            end)
        end)
    end

    --== activation pill: click = rebind (any input), right-click = hold/toggle ==--
    local pendingActivation = nil
    local function activationPill(row, cfg)
        local pill = new("TextButton", {
            Name = "ActivationPill", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 30, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "-", FontFace = Theme.Fonts.Mono, TextSize = Theme.Text.Tiny,
            TextColor3 = Theme.Palette.TextMuted, ZIndex = 38, Parent = row,
        }, {
            pillCorner(), stroke(Theme.Palette.BorderSubtle),
            new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
        })
        local function refresh() pill.Text = inputName(cfg.ActivationKey) end
        refresh()
        pill.MouseEnter:Connect(function()
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text })
        end)
        pill.MouseLeave:Connect(function()
            if not (pendingActivation and pendingActivation.pill == pill) then
                tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
            end
        end)
        pill.MouseButton1Click:Connect(function()
            if pendingActivation and pendingActivation.pill ~= pill then pendingActivation.refresh() end
            pill.Text = "..."
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Accent })
            pendingActivation = { pill = pill, cfg = cfg, refresh = refresh }
        end)
        pill.MouseButton2Click:Connect(function() openChooser(pill, cfg) end)
        return pill
    end

    --== firing / silent hooks (executor globals guarded -- degrade cleanly) ==--
    local function clickMouse()
        if mouse1click then pcall(mouse1click)
        elseif mouse1press and mouse1release then
            pcall(mouse1press); task.wait(); pcall(mouse1release)
        end
    end
    -- UNIVERSAL SILENT AIM
    --
    -- Roblox FPS fire paths take three broad shapes:
    --   (a) mouse-based:  read Mouse.Hit / Mouse.Target / Mouse.UnitRay
    --   (b) camera-ray:   compute a Ray from Camera:ViewportPointToRay / ScreenPointToRay
    --   (c) direct cast:  Workspace:Raycast(camera_pos, camera_look * range, params)
    --                     or the older FindPartOnRayWithIgnoreList / *WithWhitelist
    --
    -- We hook all three. (a) + (b) are exact — always redirect when Silent is armed.
    -- (c) is dangerous because the same API is used by:
    --   - Popper (camera collision): origin BEHIND cam, direction points TOWARD cam
    --     (opposite LookVector), length ~5-15 studs
    --   - streaming/loading probes, character controllers, tool internals
    -- Distinguisher for a fire ray: forward-facing (dir . LookVector > 0.5)
    -- AND long-range (magnitude > 20). Popper is negative-dot and short -> skipped.
    -- Only the direction gets rotated to hit our target; length is preserved so the
    -- game's range gates still fire, and origin stays where the game put it.
    --
    -- Persistence: hookmetamethod stacks across re-executions and is never restored.
    -- The BODY installs at most once per session. All logic lives in the resolver
    -- functions we publish through getgenv, so every subsequent loader run rewires
    -- the behaviour with zero rejoin required.
    local function installSilentHooks()
        if Combat.Silent._hooked then return end
        Combat.Silent._hooked = true
        local genv = getgenv and getgenv()

        -- === LIVE LOGIC (repointable through getgenv every exec) ==================
        -- Each resolver returns (handled, value). handled=true short-circuits the
        -- game's real call; handled=false falls through to the original metamethod.
        local PASS_H, PASS_V = false, nil
        -- v0.0.35: redirect only when actually armed. silentPos is now kept fresh
        -- EVERY frame by the heartbeat (independent of LMB) so the redirect lands
        -- the instant the weapon reads it -- fixes "Require Left-Click misses" (the
        -- old code set silentPos reactively, one frame behind the click). The LMB
        -- gate is applied HERE via a tracked flag -- never IsMouseButtonPressed,
        -- which is a namecall and illegal inside these hooks.
        local function isArmed()
            if not silentPos then return false end
            if Combat.Silent.RequireLMB and not lmbDown then return false end
            return true
        end
        -- SAFE default: redirect ONLY the Mouse's own aim reads (Hit / Target /
        -- UnitRay). These are what FE weapons read and NOTHING else in the engine
        -- touches, so cameras, Popper occlusion, physics and other scripts stay
        -- untouched -- this is why the default never breaks the game / camera.
        local function resolveIndex(self, key)
            if key ~= "Hit" and key ~= "Target" and key ~= "UnitRay" then return PASS_H, PASS_V end
            if not (typeof(self) == "Instance" and self:IsA("Mouse")) then return PASS_H, PASS_V end
            if not isArmed() then return PASS_H, PASS_V end
            local pos, tgt = silentPos, silentTarget
            if key == "Hit" then return true, CFrame.new(pos) end
            if key == "Target" then return true, tgt end
            local cam = Workspace.CurrentCamera
            if cam then return true, Ray.new(cam.CFrame.Position, (pos - cam.CFrame.Position).Unit) end
            return PASS_H, PASS_V
        end
        -- AGGRESSIVE (opt-in, default OFF): ALSO redirect the camera-ray methods +
        -- forward Workspace raycasts. This rewrites EVERY matching ray the game
        -- casts (weapon validation, camera occlusion/Popper, physics), which is
        -- what breaks cameras + real-game guns when left on universally -- so it is
        -- gated behind the Aggressive toggle, for cast-based games only.
        local function resolveNamecall(self, method, args)
            if not Combat.Silent.Aggressive then return PASS_H, PASS_V end
            if not isArmed() then return PASS_H, PASS_V end
            local pos = silentPos
            local cam = Workspace.CurrentCamera
            if not cam then return PASS_H, PASS_V end
            -- Mouse camera-ray methods
            if method == "ViewportPointToRay" or method == "ScreenPointToRay" then
                local o = cam.CFrame.Position
                return true, Ray.new(o, (pos - o).Unit)
            end
            -- Direct raycast on Workspace (Vector3 origin + Vector3 direction).
            -- Redirect ONLY when this looks like a fire ray, not Popper collision.
            -- Same distinguisher for the two deprecated variants that take a Ray.
            if self == Workspace then
                if method == "Raycast" then
                    local origin, dir = args[1], args[2]
                    if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" then
                        local mag = dir.Magnitude
                        if mag > 20 then
                            local ok, dirU = pcall(function() return dir.Unit end)
                            if ok and (Combat.Silent.ThirdPerson or dirU:Dot(cam.CFrame.LookVector) > 0.5) then
                                args[2] = (pos - origin).Unit * mag
                                return "call", args   -- forward to old with mutated args
                            end
                        end
                    end
                elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist"
                    or method == "FindPartOnRay" then
                    local ray = args[1]
                    if typeof(ray) == "Ray" then
                        local mag = ray.Direction.Magnitude
                        if mag > 20 then
                            local ok, dirU = pcall(function() return ray.Direction.Unit end)
                            if ok and (Combat.Silent.ThirdPerson or dirU:Dot(cam.CFrame.LookVector) > 0.5) then
                                args[1] = Ray.new(ray.Origin, (pos - ray.Origin).Unit * mag)
                                return "call", args
                            end
                        end
                    end
                end
            end
            return PASS_H, PASS_V
        end
        if genv then
            genv.KoffeeResolveIndex    = resolveIndex
            genv.KoffeeResolveNamecall = resolveNamecall
            -- back-compat: pre-v0.0.33 hook bodies read this single resolver
            genv.KoffeeSilentResolve   = function() return silentPos, silentTarget end
        end

        -- === HOOK BODY (installed once, forever; delegates to resolvers) ==========
        if genv and genv.KoffeeSilentHooked then return end
        if genv then genv.KoffeeSilentHooked = true end
        pcall(function()
            local hookmm   = hookmetamethod
            local ncmethod = getnamecallmethod
            local wrap     = newcclosure or function(f) return f end
            if not hookmm then return end
            local oldIndex
            oldIndex = hookmm(game, "__index", wrap(function(self, key)
                local r = genv and genv.KoffeeResolveIndex
                if r then
                    local ok, handled, value = pcall(r, self, key)
                    if ok and handled then return value end
                end
                return oldIndex(self, key)
            end))
            local oldNc
            oldNc = hookmm(game, "__namecall", wrap(function(self, ...)
                -- Capture method BEFORE anything else and NEVER do a nested namecall
                -- in this hook -- getnamecallmethod reads one shared C state so a
                -- nested namecall corrupts the pending dispatch (previously broke
                -- Popper: "argument #1 expects a string, but Vector3 was passed").
                local m = ncmethod and ncmethod() or ""
                local r = genv and genv.KoffeeResolveNamecall
                if r then
                    local args = table.pack(...)
                    local ok, handled, value = pcall(r, self, m, args)
                    if ok then
                        if handled == true then return value end
                        if handled == "call" then return oldNc(self, table.unpack(value, 1, args.n)) end
                    end
                end
                return oldNc(self, ...)
            end))
        end)
    end

    --== render loops ==--
    -- aimbot: run AFTER the default camera update so our CFrame wins. cold-start
    -- safety: a prior run's binding survives re-exec and re-binding the same name
    -- throws -- unbind first so the loader can be re-run cleanly.
    pcall(function() RunService:UnbindFromRenderStep("KoffeeAimbot") end)
    RunService:BindToRenderStep("KoffeeAimbot", Enum.RenderPriority.Camera.Value + 1, function()
        if not (Combat.Aim.Enabled and aimHeld) then
            Combat.Aim._target = nil; Combat.Aim._rageLock = nil; return
        end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local maxR = Combat.Aim.FOV.Enabled and Combat.Aim.FOV.Size or math.huge
        local aimCenter = fovCenter(Combat.Aim.FOV)

        -- RAGEBOT: lock onto ONE victim when the key goes down and keep teleporting
        -- to them EVERY frame until release -- independent of Sticky, so you keep
        -- full camera look (up/down) while the teleport tracks the locked player.
        if Combat.Aim.Rage then
            local lock = Combat.Aim._rageLock
            local part
            if lock and lock.Character then
                local hum = lock.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then part = aimPart(lock.Character, Combat.Aim.HitPart) end
            end
            if not part then
                lock, part = getBestTarget(Combat.Aim, maxR, aimCenter)
                Combat.Aim._rageLock = lock
            end
            if not (lock and part) then return end
            local tpos = predicted(lock, part, Combat.Aim.Predict)
            if Combat.Aim.RageType == "Character Teleport" then
                local myc = LocalPlayer.Character
                local myroot = myc and (myc:FindFirstChild("HumanoidRootPart") or findTorso(myc))
                if myroot then
                    myroot.CFrame = CFrame.new(tpos + Vector3.new(0, Combat.Aim.RageYOffset, 0)) * myroot.CFrame.Rotation
                end
            else
                cam.CFrame = CFrame.new(tpos) * cam.CFrame.Rotation
            end
            return
        end
        Combat.Aim._rageLock = nil

        local plr, part
        if Combat.Aim.Sticky and Combat.Aim._target then
            local t = Combat.Aim._target
            local char = t.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local p = aimPart(char, Combat.Aim.HitPart)
                if p then
                    local sp = cam:WorldToViewportPoint(p.Position)
                    if sp.Z > 0 and (Vector2.new(sp.X, sp.Y) - aimCenter).Magnitude <= maxR then
                        plr, part = t, p
                    end
                end
            end
        end
        if not plr then
            plr, part = getBestTarget(Combat.Aim, maxR, aimCenter)
            Combat.Aim._target = plr
        end
        if not (plr and part) then return end
        local tpos = predicted(plr, part, Combat.Aim.Predict)

        -- sensitivity (base pull) + optional per-axis smoothness (higher = slower)
        local sens = math.clamp(Combat.Aim.Sensitivity, 0.01, 1)
        local aX, aY = sens, sens
        if Combat.Aim.Smooth.Enabled then
            aX = math.clamp(sens / math.max(Combat.Aim.Smooth.X, 0.01), 0, 1)
            aY = math.clamp(sens / math.max(Combat.Aim.Smooth.Y, 0.01), 0, 1)
        end

        if Combat.Aim.ThirdPerson then
            -- v0.0.36.1: drive the REAL mouse onto the target's screen point. Measured
            -- live: WorldToViewportPoint INCLUDES the 58px GUI inset but PlayerMouse.X/Y
            -- does NOT -- mixing them aimed a constant ~58px low (whole-body error at
            -- range). GetMouseLocation() is inset-included, matching WorldToViewportPoint,
            -- so the delta is 0 exactly on-target. Each frame nudges the cursor a fraction
            -- (aX/aY) and converges. Works free-cursor AND shift-lock.
            local sp = cam:WorldToViewportPoint(tpos)
            if sp.Z > 0 and mousemoverel then
                local ml = UserInputService:GetMouseLocation()
                pcall(mousemoverel, (sp.X - ml.X) * aX, (sp.Y - ml.Y) * aY)
            end
        elseif Combat.Aim.AimType == "Mouse" then
            local sp = cam:WorldToViewportPoint(tpos)
            if sp.Z > 0 and mousemoverel then
                pcall(mousemoverel, (sp.X - aimCenter.X) * aX, (sp.Y - aimCenter.Y) * aY)
            end
        else
            cam.CFrame = aimCFrame(cam, cam.CFrame.Position, tpos, aX, aY)
        end
    end)

    -- custom multi-point gradient. Colors/Alphas map LEFT-TO-RIGHT by index:
    -- point 1 = swatch 1, point 2 = swatch 2, ... (no more 1st/last endpoint jump).
    --
    -- STATIC (moving off): a plain linear ramp c1..cn evenly spaced across 0..1.
    -- MOVING (moving on): a seamless cyclic scroll -- the palette is treated as a
    -- ring (cn wraps back to c1) and sampled at fixed screen positions offset by a
    -- phase. Because position 0 and position 1 sample the same ring point, the loop
    -- has no visible seam and never snaps back (fixes the "bounce" + stretch).
    local function ringSample(t, get, n)
        t = t % 1
        local seg = t * n
        local i = math.floor(seg)
        local f = seg - i
        local a = get((i % n) + 1)
        local b = get(((i + 1) % n) + 1)
        return a, b, f
    end
    local function ringColor(C, n, t)
        local a, b, f = ringSample(t, function(k) return C[k] end, n)
        return a:Lerp(b, f)
    end
    local function ringAlpha(A, n, t)
        local a, b, f = ringSample(t, function(k) return A[k] end, n)
        return a + (b - a) * f
    end
    local function customColorSeq(cs)
        local C, n = cs.Colors, math.clamp(cs.Points or 2, 2, 4)
        local kps = {}
        for k = 1, n do kps[k] = ColorSequenceKeypoint.new((k - 1) / (n - 1), C[k]) end
        return ColorSequence.new(kps)
    end
    local function customTransSeq(cs)
        local A, n = cs.Alphas, math.clamp(cs.Points or 2, 2, 4)
        local kps = {}
        for k = 1, n do kps[k] = NumberSequenceKeypoint.new((k - 1) / (n - 1), A[k]) end
        return NumberSequence.new(kps)
    end
    local function scrollColorSeq(cs, s)
        local C, n = cs.Colors, math.clamp(cs.Points or 2, 2, 4)
        local kps = {}
        for k = 0, n do kps[k + 1] = ColorSequenceKeypoint.new(k / n, ringColor(C, n, (k / n) + s)) end
        return ColorSequence.new(kps)
    end
    local function scrollTransSeq(cs, s)
        local A, n = cs.Alphas, math.clamp(cs.Points or 2, 2, 4)
        local kps = {}
        for k = 0, n do kps[k + 1] = NumberSequenceKeypoint.new(k / n, ringAlpha(A, n, (k / n) + s)) end
        return NumberSequence.new(kps)
    end

    -- draw one FOV circle from its config. Both aimbot + silent circles use this.
    local function drawFov(h, cfg)
        if not cfg.Enabled then h.circle.Visible = false; return end
        local size = cfg.Size
        local c = fovCenter(cfg)
        h.circle.Visible = true
        h.circle.Position = UDim2.new(0, c.X, 0, c.Y)
        h.circle.Size = UDim2.new(0, size * 2, 0, size * 2)
        local dotsMode = cfg.Style == "Dots"
        local fillCfg  = cfg.Fill
        local custom   = fillCfg.Custom
        local filled   = cfg.Filled and not dotsMode
        local now      = os.clock()
        local spinDeg  = (now * 90) % 360

        -- FILL
        if filled then
            if custom.Enabled then
                h.circle.BackgroundColor3 = Color3.new(1, 1, 1)
                h.circle.BackgroundTransparency = cfg.FillTransparency
                if h.grad then
                    h.grad.Enabled = true
                    h.grad.Offset = Vector2.new(0, 0)   -- scroll is baked into the seq, never the offset
                    if custom.Moving.Enabled and not custom.Triangle then
                        local s = (now * custom.Moving.Speed * 0.15) % 1
                        h.grad.Color = scrollColorSeq(custom, s)
                        h.grad.Transparency = scrollTransSeq(custom, s)
                    else
                        h.grad.Color = customColorSeq(custom)
                        h.grad.Transparency = customTransSeq(custom)
                    end
                    local rot = custom.Moving.Direction or 0
                    if fillCfg.Spin or cfg.Spin then rot = rot + spinDeg end
                    h.grad.Rotation = rot
                end
            else
                -- v0.0.34: the FOV Fill is now FULLY decoupled from the Visuals
                -- "Gradient" toggle. Without its own Custom Gradient enabled the
                -- fill is a solid FillColor -- the ESP gradient never bleeds in.
                if h.grad then h.grad.Enabled = false end
                h.circle.BackgroundColor3 = cfg.FillColor
                h.circle.BackgroundTransparency = cfg.FillTransparency
            end
        else
            if h.grad then h.grad.Enabled = false end
            h.circle.BackgroundTransparency = 1
        end

        -- OUTLINE (RemoveOutline drops the ring even with fill on)
        if h.stroke then
            h.stroke.Color = cfg.Color
            h.stroke.Thickness = cfg.Thickness
            h.stroke.Enabled = (not dotsMode) and (not fillCfg.RemoveOutline)
        end

        -- DOTS (count scales with size; gap + dot size configurable; spins)
        h.dotContainer.Visible = dotsMode
        if dotsMode then
            local count = math.clamp(math.floor((2 * math.pi * size) / math.max(cfg.DotGap, 4)), 3, FOV_MAX_DOTS)
            local baseRot = cfg.Spin and math.rad(spinDeg) or 0
            for i = 1, FOV_MAX_DOTS do
                local d = h.dots[i]
                if i <= count then
                    local ang = (i / count) * math.pi * 2 + baseRot
                    d.Position = UDim2.new(0.5, math.cos(ang) * size, 0.5, math.sin(ang) * size)
                    d.Size = UDim2.new(0, cfg.DotSize, 0, cfg.DotSize)
                    d.BackgroundColor3 = cfg.Color
                    d.Visible = true
                else
                    d.Visible = false
                end
            end
        end
    end

    -- snapline: v0.0.36.1 -- origin follows the mouse cursor. Uses GetMouseLocation()
    -- (inset-included, like WorldToViewportPoint + the IgnoreGuiInset overlay) so the
    -- line anchors exactly ON the cursor. The old PlayerMouse.X/Y source excluded the
    -- 58px inset, which floated the origin ~58px above the cursor.
    local function drawSnaplines()
        local cfg, ctx, part
        if Combat.Aim.Snaplines then
            cfg, ctx = Combat.Aim, Combat.Aim.FOV
            -- focus on the person currently being targeted (locked/aimed)
            local t = Combat.Aim._rageLock or Combat.Aim._target
            if t and t.Character then part = aimPart(t.Character, cfg.HitPart) end
        elseif Combat.Silent.Snaplines then
            cfg, ctx = Combat.Silent, Combat.Silent.FOV
            part = silentTarget
        end
        if not cfg then snapLine.Visible = false; return end
        local cam = Workspace.CurrentCamera
        if not cam then snapLine.Visible = false; return end
        local origin = UserInputService:GetMouseLocation()
        if not part then
            local maxR = ctx.Enabled and ctx.Size or math.huge
            local _, p = getBestTarget(cfg, maxR, origin)
            part = p
        end
        if not part then snapLine.Visible = false; return end
        local sp = cam:WorldToViewportPoint(part.Position)
        if sp.Z <= 0 then snapLine.Visible = false; return end
        local ex, ey = sp.X, sp.Y
        local dx, dy = ex - origin.X, ey - origin.Y
        local dist = (part.Position - cam.CFrame.Position).Magnitude
        local thick = featureThickness(dist)
        snapLine.Visible = true
        snapLine.Position = UDim2.new(0, (origin.X + ex) * 0.5, 0, (origin.Y + ey) * 0.5)
        snapLine.Size = UDim2.new(0, math.sqrt(dx * dx + dy * dy), 0, thick)
        snapLine.Rotation = math.deg(math.atan2(dy, dx))
        snapLine.BackgroundColor3 = ESP.Tracer.Color
        applyLineOutline(snapLine, ESP.Config.Outline, ESP.Boxes.OutlineColor, math.max(1, thick))
        applyLineGradient(snapLine, ESP.Config.Gradient)
    end

    -- both FOV circles render independently of the aimbot/silent master toggles.
    RunService.RenderStepped:Connect(function()
        drawFov(aimFov, Combat.Aim.FOV)
        drawFov(silentFov, Combat.Silent.FOV)
        drawSnaplines()
    end)

    -- triggerbot (v0.0.36 rewrite). The old version fired on screen-space proximity
    -- to the crosshair (5px) -- pixel-tight and it never actually checked the crosshair
    -- was ON an enemy (a wall in the way still counted). Now it raycasts from the camera
    -- THROUGH the crosshair: it only fires if that ray's first hit is a live enemy
    -- character (team / friend checks applied, occlusion handled for free since the ray
    -- stops at the first wall). HitboxMul widens the sample into a small ring.
    local trigParams = RaycastParams.new()
    trigParams.FilterType = Enum.RaycastFilterType.Exclude
    local function crosshairEnemy()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local vp = cam.ViewportSize
        local cx, cy = vp.X * 0.5, vp.Y * 0.5
        trigParams.FilterDescendantsInstances = { LocalPlayer.Character }
        local function castAt(px, py)
            local ray = cam:ViewportPointToRay(px, py)
            local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, trigParams)
            if not (res and res.Instance) then return nil end
            local model = res.Instance:FindFirstAncestorWhichIsA("Model")
            local plr = model and Players:GetPlayerFromCharacter(model)
            if not plr or plr == LocalPlayer then return nil end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not (hum and hum.Health > 0) then return nil end
            if Combat.Trigger.TeamCheck and isSameTeam(plr) then return nil end
            if Shared.IgnoreFriends and isFriend(plr) then return nil end
            return plr
        end
        local hit = castAt(cx, cy)
        if hit then return hit end
        -- HitboxMul > 1: sample a small ring around the crosshair for forgiveness
        local mul = math.max(Combat.Trigger.HitboxMul, 1)
        if mul > 1 then
            local r = 5 * (mul - 1)
            for i = 0, 7 do
                local a = (i / 8) * math.pi * 2
                local p = castAt(cx + math.cos(a) * r, cy + math.sin(a) * r)
                if p then return p end
            end
        end
        return nil
    end
    RunService.Heartbeat:Connect(function()
        if not Combat.Trigger.Enabled then return end
        if Combat.Trigger.UseKey and not trigHeld then return end
        if trigBusy then return end
        if not crosshairEnemy() then return end
        trigBusy = true
        task.spawn(function()
            if Combat.Trigger.Delay > 0 then task.wait(Combat.Trigger.Delay / 1000) end
            -- re-confirm the crosshair is still on the enemy right before firing
            if Combat.Trigger.Enabled and crosshairEnemy() then clickMouse() end
            if Combat.Trigger.Release > 0 then task.wait(Combat.Trigger.Release / 1000) end
            trigBusy = false
        end)
    end)

    -- silent aim: keep the redirect target FRESH every frame while active. v0.0.35:
    -- the RequireLMB check is NO LONGER here -- silentPos is computed continuously
    -- (whenever enabled + armed-by-key + a target is acquirable) so it's already
    -- set the instant a weapon reads mouse.Hit. The LMB gate is applied at redirect
    -- time inside the hook (isArmed), which kills the one-frame "RequireLMB misses".
    RunService.Heartbeat:Connect(function()
        -- v0.0.36: authoritative LMB backfill -- if InputBegan's edge was ever missed
        -- (input consumed / gpe ordering), the poll re-sets it so RequireLMB can't get
        -- stuck "not held" while you're firing. Release still comes from InputEnded.
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then lmbDown = true end
        if not Combat.Silent.Enabled then silentTarget = nil; silentPos = nil; return end
        -- v0.0.34: if the user bound an arm key it must be held (per its mode);
        -- with no key bound (default) this gate is skipped entirely.
        if Combat.Silent.ActivationKey and not silentHeld then
            silentTarget = nil; silentPos = nil; return
        end
        local maxR = Combat.Silent.FOV.Enabled and Combat.Silent.FOV.Size or math.huge
        local plr, part = getBestTarget(Combat.Silent, maxR, fovCenter(Combat.Silent.FOV))
        if plr and part then
            silentTarget = part
            -- prediction shifts the redirect point for lead; the hooks read silentPos
            silentPos = predicted(plr, part, Combat.Silent.Predict)
        else
            silentTarget = nil; silentPos = nil
        end
    end)

    --== input: rebind capture + activation ==--
    UserInputService.InputBegan:Connect(function(input, gpe)
        -- v0.0.35: track LMB regardless of gpe so the silent redirect's RequireLMB
        -- gate is accurate (this flag replaces IsMouseButtonPressed polling).
        if input.UserInputType == Enum.UserInputType.MouseButton1 then lmbDown = true end
        if pendingActivation then
            local it = input.UserInputType
            -- v0.0.36: ESC CLEARS the bind (no activation key), not just cancels.
            if it == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
                pendingActivation.cfg.ActivationKey = nil
                pendingActivation.refresh(); pendingActivation = nil; return
            end
            -- v0.0.36: accept ANY key + ANY button-like input (mouse 1/2/3 and
            -- whatever else the runtime surfaces through InputBegan, e.g. XButton1/2
            -- on executors that deliver them). Only movement/wheel/focus are ignored.
            local bind
            if it == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                bind = input.KeyCode
            elseif it ~= Enum.UserInputType.Focus and it ~= Enum.UserInputType.MouseMovement
               and it ~= Enum.UserInputType.MouseWheel and it ~= Enum.UserInputType.None
               and it ~= Enum.UserInputType.TextInput and it ~= Enum.UserInputType.InputMethod then
                bind = it
            end
            if bind then
                pendingActivation.cfg.ActivationKey = bind
                pendingActivation.refresh()
                pendingActivation = nil
            end
            return
        end
        if gpe then return end
        if Combat.Aim.Enabled and inputMatches(input, Combat.Aim.ActivationKey) then
            if Combat.Aim.ActivationMode == "Toggle" then aimHeld = not aimHeld else aimHeld = true end
        end
        if Combat.Silent.Enabled and Combat.Silent.ActivationKey
        and inputMatches(input, Combat.Silent.ActivationKey) then
            if Combat.Silent.ActivationMode == "Toggle" then silentHeld = not silentHeld else silentHeld = true end
        end
        if Combat.Trigger.Enabled and inputMatches(input, Combat.Trigger.ActivationKey) then
            if Combat.Trigger.ActivationMode == "Toggle" then trigHeld = not trigHeld else trigHeld = true end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then lmbDown = false end
        if Combat.Aim.ActivationMode == "Hold" and inputMatches(input, Combat.Aim.ActivationKey) then
            aimHeld = false
        end
        if Combat.Silent.ActivationMode == "Hold" and Combat.Silent.ActivationKey
        and inputMatches(input, Combat.Silent.ActivationKey) then
            silentHeld = false
        end
        if Combat.Trigger.ActivationMode == "Hold" and inputMatches(input, Combat.Trigger.ActivationKey) then
            trigHeld = false
        end
    end)

    -- v0.0.37: VIRTUAL XBUTTON DRIVER. Roblox never fires InputBegan for mouse 4/5,
    -- so binds set to "XButton1"/"XButton2" are driven here off the Koffee Helper's
    -- polled state instead. Handles rebind capture (the helper sees the press Roblox
    -- can't) + hold/toggle activation for aim / silent / trigger.
    local pXB1, pXB2 = false, false
    RunService.Heartbeat:Connect(function()
        local xb1, xb2 = Helper.XB1, Helper.XB2
        local e1, e2 = (xb1 and not pXB1), (xb2 and not pXB2)   -- press edges
        local function down(k) return (k == "XButton1" and xb1) or (k == "XButton2" and xb2) or false end
        local function edge(k) return (k == "XButton1" and e1) or (k == "XButton2" and e2) or false end

        -- rebind capture: the activation pill is waiting -> bind the pressed XButton
        if pendingActivation then
            local k = (e2 and "XButton2") or (e1 and "XButton1") or nil
            if k then
                pendingActivation.cfg.ActivationKey = k
                pendingActivation.refresh(); pendingActivation = nil
            end
        end

        -- drive held-state for any context bound to a virtual XButton
        if type(Combat.Aim.ActivationKey) == "string" then
            if Combat.Aim.ActivationMode == "Toggle" then
                if edge(Combat.Aim.ActivationKey) then aimHeld = not aimHeld end
            else aimHeld = down(Combat.Aim.ActivationKey) end
        end
        if type(Combat.Silent.ActivationKey) == "string" then
            if Combat.Silent.ActivationMode == "Toggle" then
                if edge(Combat.Silent.ActivationKey) then silentHeld = not silentHeld end
            else silentHeld = down(Combat.Silent.ActivationKey) end
        end
        if type(Combat.Trigger.ActivationKey) == "string" then
            if Combat.Trigger.ActivationMode == "Toggle" then
                if edge(Combat.Trigger.ActivationKey) then trigHeld = not trigHeld end
            else trigHeld = down(Combat.Trigger.ActivationKey) end
        end

        pXB1, pXB2 = xb1, xb2
    end)

    --== modules (arraylist + master toggles) ==--
    registerModule("aimbot", "Aimbot",
        function() Combat.Aim.Enabled = true end,
        function() Combat.Aim.Enabled = false; aimHeld = false; Combat.Aim._target = nil; Combat.Aim._rageLock = nil end)
    registerModule("triggerbot", "Trigger Bot",
        function() Combat.Trigger.Enabled = true end,
        function() Combat.Trigger.Enabled = false; trigHeld = false end)
    registerModule("silentaim", "Silent Aim",
        function() installSilentHooks(); Combat.Silent.Enabled = true end,
        function() Combat.Silent.Enabled = false; silentTarget = nil end)
    -- FOV is an arraylist marker; the two per-context toggles (Aim.FOV / Silent.FOV)
    -- drive rendering. Detail shows "x2" when both circles are active.
    registerModule("fov", "FOV", function() end, function() end)
    Modules.fov.GetDetail = function()
        local n = (Combat.Aim.FOV.Enabled and 1 or 0) + (Combat.Silent.FOV.Enabled and 1 or 0)
        return n >= 2 and "    x2" or ""
    end
    local function syncFovModule()
        local want = Combat.Aim.FOV.Enabled or Combat.Silent.FOV.Enabled
        if want ~= (Modules.fov and Modules.fov.Enabled) then toggleModule("fov") end
    end

    --== small UI helpers scoped to this tab ==--
    local function attachSwatch(row, initial, onChange, opts)
        local wrap = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 14, 0, 16), BackgroundTransparency = 1, ZIndex = 38, Parent = row,
        })
        local o = { onChange = onChange }
        if opts then for k, v in pairs(opts) do o[k] = v end end
        return colorSwatch(wrap, initial, 14, o)
    end
    -- two swatches on one row (outline + fill-with-alpha) for a given FOV cfg
    local function attachFovSwatches(row, F)
        local wrap = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 36, 0, 16), BackgroundTransparency = 1, ZIndex = 38, Parent = row,
        }, {
            new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        colorSwatch(wrap, F.Color, 14, { onChange = function(c) F.Color = c end })
        colorSwatch(wrap, F.FillColor, 14, { onChange = function(c) F.FillColor = c end })
    end
    local function attachHelp(row)
        new("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
            Text = "?", FontFace = Theme.Fonts.Mono, TextSize = Theme.Text.Small, TextColor3 = Theme.Palette.TextFaint,
            BackgroundTransparency = 1, ZIndex = 38, Parent = row,
        })
    end

    -- shared FOV control set -- built in both the left (aimbot -> Aim.FOV) and
    -- right (silent -> Silent.FOV) sub-tabs, each bound to its own config.
    local function buildFovTab(parent, F)
        local enRow = configCheckbox(parent, "Enabled", F.Enabled, function(v)
            F.Enabled = v
            syncFovModule()   -- keep the single "FOV" arraylist marker + x2 detail in sync
        end)
        attachFovSwatches(enRow.row, F)
        -- right-click the Fill row: Remove Outline / Custom Gradient / Spin / Moving.
        -- Fill state is preserved across Style switches -- Dots just suppresses the
        -- fill visually (drawFov gates on `not dotsMode`), so flipping back to Smooth
        -- restores it without a re-toggle.
        local fillRow = configCheckbox(parent, "Filled", F.Filled, function(v) F.Filled = v end)
        rightClickSettings(fillRow.row, "fill", function(api)
            api:toggle("Remove Outline", F.Fill.RemoveOutline, function(v) F.Fill.RemoveOutline = v end)
            api:toggle("Spin", F.Fill.Spin, function(v) F.Fill.Spin = v end)
            local cg = F.Fill.Custom
            api:toggle("Custom Gradient", cg.Enabled, function(v) cg.Enabled = v end)
            api:swatchRow(cg.Colors, function(i, c) cg.Colors[i] = c end)
            for i = 1, 4 do
                api:slider(i .. " Transparency", 0, 1, cg.Alphas[i], 2, function(v) cg.Alphas[i] = v end)
            end
            api:dropdown("Points", { "2", "3", "4" }, tostring(cg.Points), function(v)
                cg.Points = tonumber(v) or 2
                if cg.Points ~= 3 then cg.Triangle = false end
            end)
            api:toggle("Triangle", cg.Triangle, function(v)
                if cg.Points ~= 3 then return end
                cg.Triangle = v
                if v then cg.Moving.Enabled = false end
            end)
            api:toggle("Moving Gradient", cg.Moving.Enabled, function(v)
                if cg.Triangle then return end
                cg.Moving.Enabled = v
            end)
            api:slider("Speed", 0, 5, cg.Moving.Speed, 2, function(v) cg.Moving.Speed = v end)
            api:slider("Direction", 0, 360, cg.Moving.Direction, 0, function(v) cg.Moving.Direction = v end)
        end)
        configCheckbox(parent, "Spin", F.Spin, function(v) F.Spin = v end)
        slider(parent, "Fill Transparency", 0, 1, F.FillTransparency, 2, function(v) F.FillTransparency = v end)
        slider(parent, "Size", 20, 500, F.Size, 0, function(v) F.Size = v end)
        dropdown(parent, "Origin", { "Center", "Mouse" }, F.Origin, function(v) F.Origin = v end)
        local styleDd = dropdown(parent, "Style", { "Smooth", "Dots" }, F.Style, function(v)
            F.Style = v
        end)
        -- right-click the Style dropdown to tune Dots
        rightClickSettings(styleDd.frame, "dots", function(api)
            api:slider("Dot Size", 1, 12, F.DotSize, 0, function(v) F.DotSize = v end)
            api:slider("Gap", 6, 60, F.DotGap, 0, function(v) F.DotGap = v end)
        end)
    end

    -- sub-tab pill switcher inside a card. Returns { name -> contentFrame }.
    local function subTabs(card, names)
        local bar = new("Frame", {
            Name = "SubTabs", Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Theme.Palette.Background, BackgroundTransparency = 0.35, BorderSizePixel = 0,
            LayoutOrder = 0, ZIndex = 34, Parent = card,
        }, {
            corner(6),
            new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }),
            new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2),
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        local buttons, content = {}, {}
        -- v0.0.32: fade content in on switch (CanvasGroup GroupTransparency).
        local function select(name)
            for n, b in pairs(buttons) do
                local on = (n == name)
                tween(b, Theme.Animation.Fast, {
                    BackgroundTransparency = on and 0.15 or 1,
                    TextColor3 = on and Theme.Palette.Text or Theme.Palette.TextMuted,
                })
                local cf = content[n]
                if on then
                    cf.Visible = true
                    cf.GroupTransparency = 0.4
                    tween(cf, Theme.Animation.Normal, { GroupTransparency = 0 })
                else
                    cf.Visible = false
                end
            end
        end
        for i, name in ipairs(names) do
            local b = new("TextButton", {
                Text = name:lower(), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 1, AutoButtonColor = false,
                FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body, TextColor3 = Theme.Palette.TextMuted,
                LayoutOrder = i, ZIndex = 35, Parent = bar,
            }, { corner(5), new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) })
            buttons[name] = b
            local cf = new("CanvasGroup", {
                Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Visible = false, LayoutOrder = i, ZIndex = 33, Parent = card,
            }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder }) })
            content[name] = cf
            b.MouseButton1Click:Connect(function() select(name) end)
        end
        select(names[1])
        return content
    end

    --== tab UI ==--
    addTab("Combat", function(cpanel)
        local cols = new("Frame", {
            Name = "Columns", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, ZIndex = 33, Parent = cpanel,
        }, {
            new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }),
        })
        local leftCol = new("Frame", {
            Name = "Left", Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 33, Parent = cols,
        }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder }) })
        local rightCol = new("Frame", {
            Name = "Right", Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 33, Parent = cols,
        }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder }) })

        -- snapline checkbox handles -- captured so enabling one clears the other
        -- (only one snapline context may be active at a time).
        local aimSnapCtrl, silentSnapCtrl

        --== LEFT COLUMN ==--
        local leftCard = panel(leftCol)
        local L = subTabs(leftCard, { "Aimbot", "Prediction", "Smoothness", "FOV" })

        -- Aimbot
        local aimRow = moduleCheckbox(L.Aimbot, "Enabled", "aimbot")
        activationPill(aimRow.row, Combat.Aim)
        configCheckbox(L.Aimbot, "Team Check", Combat.Aim.TeamCheck, function(v) Combat.Aim.TeamCheck = v end)
        configCheckbox(L.Aimbot, "Visible Check", Combat.Aim.VisibleCheck, function(v) Combat.Aim.VisibleCheck = v end)
        configCheckbox(L.Aimbot, "Health Check", Combat.Aim.HealthCheck, function(v) Combat.Aim.HealthCheck = v end)
        configCheckbox(L.Aimbot, "Sticky Aim", Combat.Aim.Sticky, function(v) Combat.Aim.Sticky = v end)
        -- v0.0.36: third-person cursor aim (move mouse, not camera). Bind aimbot to a
        -- non-RMB key (e.g. XButton2) so it doesn't clash with the game's shift-lock.
        configCheckbox(L.Aimbot, "Third Person", Combat.Aim.ThirdPerson, function(v) Combat.Aim.ThirdPerson = v end)
        slider(L.Aimbot, "Distance", 50, 5000, Combat.Aim.Distance, 0, function(v) Combat.Aim.Distance = v end)
        slider(L.Aimbot, "Sensitivity", 0.01, 1, Combat.Aim.Sensitivity, 2, function(v) Combat.Aim.Sensitivity = v end)
        dropdown(L.Aimbot, "Hit Part", HITPARTS, Combat.Aim.HitPart, function(v) Combat.Aim.HitPart = v end)
        dropdown(L.Aimbot, "Aim Type", { "Camera", "Mouse" }, Combat.Aim.AimType, function(v) Combat.Aim.AimType = v end)
        local rageRow = configCheckbox(L.Aimbot, "Ragebot", Combat.Aim.Rage, function(v) Combat.Aim.Rage = v end)
        attachHelp(rageRow.row)
        local rageTypeDd = dropdown(L.Aimbot, "Type", { "Camera Teleport", "Character Teleport" }, Combat.Aim.RageType,
            function(v) Combat.Aim.RageType = v end)
        -- right-click the Type dropdown to tune the Character Teleport vertical offset
        rightClickSettings(rageTypeDd.frame, "character teleport", function(api)
            api:slider("Y Offset", -10, 10, Combat.Aim.RageYOffset, 1, function(v) Combat.Aim.RageYOffset = v end)
        end)
        aimSnapCtrl = configCheckbox(L.Aimbot, "Snaplines", Combat.Aim.Snaplines, function(v)
            Combat.Aim.Snaplines = v
            if v then Combat.Silent.Snaplines = false; if silentSnapCtrl then silentSnapCtrl.setState(false) end end
        end)

        -- Prediction
        local predRow = configCheckbox(L.Prediction, "Enabled", Combat.Aim.Predict.Enabled,
            function(v) Combat.Aim.Predict.Enabled = v end)
        attachHelp(predRow.row)
        slider(L.Prediction, "X (Division)", 0.1, 10, Combat.Aim.Predict.X, 2, function(v) Combat.Aim.Predict.X = v end)
        slider(L.Prediction, "Y (Division)", 0.1, 10, Combat.Aim.Predict.Y, 2, function(v) Combat.Aim.Predict.Y = v end)

        -- Smoothness
        configCheckbox(L.Smoothness, "Enabled", Combat.Aim.Smooth.Enabled, function(v) Combat.Aim.Smooth.Enabled = v end)
        slider(L.Smoothness, "Smoothness X", 0.1, 20, Combat.Aim.Smooth.X, 1, function(v) Combat.Aim.Smooth.X = v end)
        slider(L.Smoothness, "Smoothness Y", 0.1, 20, Combat.Aim.Smooth.Y, 1, function(v) Combat.Aim.Smooth.Y = v end)

        -- FOV (shared control set)
        buildFovTab(L.FOV, Combat.Aim.FOV)

        -- Misc
        local miscCard = panel(leftCol, "Misc")
        configCheckbox(miscCard, "Resolver", Combat.Misc.Resolver, function(v) Combat.Misc.Resolver = v end)

        --== RIGHT COLUMN ==--
        local rightCard = panel(rightCol)
        local R = subTabs(rightCard, { "Silent Aim", "Prediction", "FOV" })

        -- Silent Aim
        local sRow = moduleCheckbox(R["Silent Aim"], "Enabled", "silentaim")
        activationPill(sRow.row, Combat.Silent)
        configCheckbox(R["Silent Aim"], "Team Check", Combat.Silent.TeamCheck, function(v) Combat.Silent.TeamCheck = v end)
        configCheckbox(R["Silent Aim"], "Visible Check", Combat.Silent.VisibleCheck, function(v) Combat.Silent.VisibleCheck = v end)
        configCheckbox(R["Silent Aim"], "Health Check", Combat.Silent.HealthCheck, function(v) Combat.Silent.HealthCheck = v end)
        configCheckbox(R["Silent Aim"], "Sticky Aim", Combat.Silent.Sticky, function(v) Combat.Silent.Sticky = v end)
        slider(R["Silent Aim"], "Distance", 50, 5000, Combat.Silent.Distance, 0, function(v) Combat.Silent.Distance = v end)
        dropdown(R["Silent Aim"], "Hit Part", HITPARTS, Combat.Silent.HitPart, function(v) Combat.Silent.HitPart = v end)
        dropdown(R["Silent Aim"], "Method", { "Forced Magic-Bullet" }, Combat.Silent.Method,
            function(v) Combat.Silent.Method = v end)
        configCheckbox(R["Silent Aim"], "Require Left-Click", Combat.Silent.RequireLMB, function(v) Combat.Silent.RequireLMB = v end)
        -- v0.0.35: default silent redirects only mouse aim reads (safe everywhere).
        -- Aggressive also hijacks camera-ray + raycast methods for cast-based guns
        -- (may break cameras / other games). Third Person only matters with it on.
        configCheckbox(R["Silent Aim"], "Aggressive Redirect", Combat.Silent.Aggressive, function(v) Combat.Silent.Aggressive = v end)
        configCheckbox(R["Silent Aim"], "Third Person", Combat.Silent.ThirdPerson, function(v) Combat.Silent.ThirdPerson = v end)
        silentSnapCtrl = configCheckbox(R["Silent Aim"], "Snaplines", Combat.Silent.Snaplines, function(v)
            Combat.Silent.Snaplines = v
            if v then Combat.Aim.Snaplines = false; if aimSnapCtrl then aimSnapCtrl.setState(false) end end
        end)

        -- Prediction (silent)
        configCheckbox(R.Prediction, "Enabled", Combat.Silent.Predict.Enabled, function(v) Combat.Silent.Predict.Enabled = v end)
        slider(R.Prediction, "X (Division)", 0.1, 10, Combat.Silent.Predict.X, 2, function(v) Combat.Silent.Predict.X = v end)
        slider(R.Prediction, "Y (Division)", 0.1, 10, Combat.Silent.Predict.Y, 2, function(v) Combat.Silent.Predict.Y = v end)

        -- FOV (same shared control set as the aimbot side)
        buildFovTab(R.FOV, Combat.Silent.FOV)

        -- Trigger Bot
        local trigCard = panel(rightCol, "Trigger Bot")
        local tRow = moduleCheckbox(trigCard, "Enabled", "triggerbot")
        activationPill(tRow.row, Combat.Trigger)
        configCheckbox(trigCard, "Visible Check", Combat.Trigger.VisibleCheck, function(v) Combat.Trigger.VisibleCheck = v end)
        configCheckbox(trigCard, "Team Check", Combat.Trigger.TeamCheck, function(v) Combat.Trigger.TeamCheck = v end)
        configCheckbox(trigCard, "Use Key", Combat.Trigger.UseKey, function(v) Combat.Trigger.UseKey = v end)
        slider(trigCard, "Hitbox Mul", 1, 10, Combat.Trigger.HitboxMul, 2, function(v) Combat.Trigger.HitboxMul = v end)
        slider(trigCard, "Delay (ms)", 0, 500, Combat.Trigger.Delay, 0, function(v) Combat.Trigger.Delay = v end)
        slider(trigCard, "Release (ms)", 0, 500, Combat.Trigger.Release, 0, function(v) Combat.Trigger.Release = v end)
    end)
end)()

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
    -- v0.0.34: ESP ships with NO keybind by default (pill reads "no keybind").
    keybindPill(master.row, "esp", nil)
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

--============================================================
-- OPTIONS TAB (v0.0.34)
--============================================================
addTab("Options", function(root)
    local card = panel(root, "options")
    -- Ignore Friends: friends are excluded from ESP + aimbot + silent + trigger.
    configCheckbox(card, "Ignore Friends", Shared.IgnoreFriends, function(v)
        Shared.IgnoreFriends = v
    end)
end)

--============================================================
-- CONFIGS TAB (v0.0.34) -- save / load / delete / auto-load per game
--============================================================
addTab("Configs", function(root)
    local CIO = Koffee.Config

    -- small pill button helper scoped to this tab
    local function mkBtn(parent, text, width, onClick, accent)
        local b = new("TextButton", {
            Text = text, AutoButtonColor = false,
            FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
            TextColor3 = accent and Theme.Palette.Accent or Theme.Palette.TextMuted,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, Size = UDim2.new(0, width, 0, 26),
            ZIndex = 36, Parent = parent,
        }, { corner(5), stroke(Theme.Palette.BorderSubtle) })
        b.MouseEnter:Connect(function() tween(b, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text }) end)
        b.MouseLeave:Connect(function()
            tween(b, Theme.Animation.Fast, { TextColor3 = accent and Theme.Palette.Accent or Theme.Palette.TextMuted })
        end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    --== save card ==--
    local saveCard = panel(root, "config manager")

    local status = new("TextLabel", {
        Text = "", FontFace = Theme.Fonts.Regular, TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35, Parent = saveCard,
    })
    local function setStatus(msg, ok)
        status.Text = msg
        status.TextColor3 = ok and Theme.Palette.Success or Theme.Palette.Danger
    end

    local topRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 35, Parent = saveCard,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder }) })
    local nameBox = new("TextBox", {
        Text = "", PlaceholderText = "config name...", ClearTextOnFocus = false,
        FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text, PlaceholderColor3 = Theme.Palette.TextFaint,
        BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Size = UDim2.new(1, -150, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 36, Parent = topRow,
    }, { corner(5), stroke(Theme.Palette.BorderSubtle),
        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })

    -- forward-declared so the buttons can call the list refresher
    local refreshList
    mkBtn(topRow, "save", 66, function()
        local ok, msg = CIO.save(nameBox.Text)
        if ok then setStatus("saved: " .. tostring(msg), true); nameBox.Text = ""; refreshList()
        else setStatus("save failed: " .. tostring(msg), false) end
    end, true).LayoutOrder = 2
    mkBtn(topRow, "refresh", 70, function() refreshList() end).LayoutOrder = 3

    --== list card ==--
    local listCard = panel(root, "saved configs")
    local listWrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, ZIndex = 35, Parent = listCard,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local emptyLbl = new("TextLabel", {
        Text = "no saved configs", FontFace = Theme.Fonts.Regular, TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextFaint, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 35, Parent = listCard,
    })

    refreshList = function()
        for _, c in ipairs(listWrap:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local names = CIO.list()
        local auto = CIO.getAuto()
        emptyLbl.Visible = (#names == 0)
        for i, name in ipairs(names) do
            local row = new("Frame", {
                Name = "cfgrow", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = i,
                BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.35,
                BorderSizePixel = 0, ZIndex = 35, Parent = listWrap,
            }, { corner(5), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6) }),
                new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    SortOrder = Enum.SortOrder.LayoutOrder }) })
            new("TextLabel", {
                Text = name, FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
                TextColor3 = Theme.Palette.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1, -210, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, ZIndex = 36, Parent = row,
            })
            mkBtn(row, "load", 58, function()
                local ok, msg = CIO.load(name)
                if ok then setStatus("loaded: " .. tostring(name), true)
                else setStatus("load failed: " .. tostring(msg), false) end
            end, true).LayoutOrder = 2
            mkBtn(row, (auto == name) and "auto*" or "auto", 58, function()
                if CIO.getAuto() == name then CIO.setAuto(nil); setStatus("auto-load cleared", true)
                else CIO.setAuto(name); setStatus("auto-load: " .. name, true) end
                refreshList()
            end, auto == name).LayoutOrder = 3
            mkBtn(row, "del", 46, function()
                CIO.delete(name); setStatus("deleted: " .. name, true); refreshList()
            end).LayoutOrder = 4
        end
    end
    refreshList()
end)

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

-- v0.0.36: does this input fire a bind? Binds are EnumItems -- a KeyCode
-- (keyboard) OR a UserInputType (mouse/other button).
local function bindMatches(input, bind)
    if typeof(bind) ~= "EnumItem" then return false end
    if bind.EnumType == Enum.KeyCode then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
    elseif bind.EnumType == Enum.UserInputType then
        return input.UserInputType == bind
    end
    return false
end

UserInputService.InputBegan:Connect(function(input, processed)
    local it = input.UserInputType

    -- pending rebind captures ANY key/button (bypasses processed so users can
    -- rebind even with a textbox focused). v0.0.36: ESC CLEARS the bind; mouse
    -- buttons (and whatever the runtime surfaces, e.g. XButton1/2) are accepted.
    if pendingRebind then
        local pill = pendingRebind.pill
        if it == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
            Keybinds[pendingRebind.moduleId] = nil
            pill.Text = "no keybind"
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
            pendingRebind = nil
            return
        end
        local bind
        if it == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            bind = input.KeyCode
        elseif it ~= Enum.UserInputType.Focus and it ~= Enum.UserInputType.MouseMovement
           and it ~= Enum.UserInputType.MouseWheel and it ~= Enum.UserInputType.None
           and it ~= Enum.UserInputType.TextInput and it ~= Enum.UserInputType.InputMethod then
            bind = it
        end
        if bind then completeRebind(bind) end
        return
    end

    if processed then return end

    -- menu toggle (keyboard only)
    if it == Enum.UserInputType.Keyboard
    and (input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.RightShift) then
        setWindowOpen(not windowOpen)
        return
    end

    -- module bindings (KeyCode or UserInputType)
    for id, key in pairs(Keybinds) do
        if bindMatches(input, key) then
            toggleModule(id)
            return
        end
    end
end)

-- v0.0.37: MODULE-keybind virtual XButton driver (mirror of the combat one, for
-- module keybind pills). Roblox can't fire mouse 4/5, so the helper drives rebind
-- capture + module toggles for keybinds set to a virtual XButton.
do
    local pXB1, pXB2 = false, false
    RunService.Heartbeat:Connect(function()
        local xb1, xb2 = Helper.XB1, Helper.XB2
        local e1, e2 = (xb1 and not pXB1), (xb2 and not pXB2)
        if pendingRebind then
            local k = (e2 and "XButton2") or (e1 and "XButton1") or nil
            if k then
                Keybinds[pendingRebind.moduleId] = k
                pendingRebind.pill.Text = keyLabel(k)
                tween(pendingRebind.pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
                pendingRebind = nil
            end
        elseif e1 or e2 then
            for id, key in pairs(Keybinds) do
                if (key == "XButton2" and e2) or (key == "XButton1" and e1) then
                    toggleModule(id)
                end
            end
        end
        pXB1, pXB2 = xb1, xb2
    end)
end

-- v0.0.37: poll the Koffee Helper for OS-level input (XButton1/2). It serves live
-- button state over localhost; we cache it in `Helper` for the virtual-bind drivers.
-- Degrades silently on a slow backoff when the helper isn't running.
do
    local HttpService = game:GetService("HttpService")
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    if reqFn then
        task.spawn(function()
            while true do
                local ok, res = pcall(reqFn, { Url = "http://127.0.0.1:7912/", Method = "GET" })
                local body = ok and res and res.Body
                local data
                if body then
                    local dok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
                    if dok then data = decoded end
                end
                if type(data) == "table" then
                    if not Helper.Connected then
                        Helper.Connected = true
                        print("[koffee] helper connected -- XButton1/2 available")
                    end
                    Helper.XB1 = data.xb1 and true or false
                    Helper.XB2 = data.xb2 and true or false
                    task.wait(0.03)
                else
                    if Helper.Connected then print("[koffee] helper disconnected") end
                    Helper.Connected, Helper.XB1, Helper.XB2 = false, false, false
                    task.wait(1)
                end
            end
        end)
    end
end

-- v0.0.34: auto-load this game's saved config (if one is pinned). Deferred +
-- pcall'd so a bad/locked config never blocks the UI from coming up.
task.spawn(function()
    local auto = Koffee.Config.getAuto()
    if not auto then return end
    task.wait(0.25)
    pcall(function() Koffee.Config.load(auto) end)
end)

return Koffee
