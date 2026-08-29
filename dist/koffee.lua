-- koffee v0.3.0
-- universal roblox internal suite
-- funded by konstant

local Koffee = {}
Koffee.Version = "0.3.0"

-- v0.1.3 ASSET PRELOADER + LOADING SCREEN. Every remote asset (interface font,
-- feature-font catalog, sound pack) downloads ONCE behind a blocking loading
-- screen; the suite below does not execute until the manifest settles. Cached
-- files skip instantly, so only a first run / cache wipe waits. Locked-down
-- executors (no file API) skip straight through -- the legacy fallbacks below
-- (Nunito face, silent-missing sounds) still cover them.
do
    local BASE = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/"
    local SOUNDS = {
        "12", "agpa2", "basshit", "bell", "blizzard", "bubble", "chockpro",
        "cod", "copperbell", "crowbar", "headshot", "hit", "knob",
        "minecraft orb", "neverlose", "rust", "skeet",
    }
    local MANIFEST = {
        { name = "proxima soft",           path = "koffee_proximasoft.ttf",             url = BASE .. "ProximaSoft-Bold.ttf", min = 4096 },
        { name = "font: minecraft bold",   path = "Koffee/fonts/MinecraftBold.otf",     url = BASE .. "MinecraftBold.otf",     min = 512 },
        { name = "font: minecraft regular",path = "Koffee/fonts/MinecraftRegular.otf",  url = BASE .. "MinecraftRegular.otf",  min = 512 },
        { name = "font: imgui",            path = "Koffee/fonts/ProggyClean.ttf",       url = BASE .. "ProggyClean.ttf",       min = 512 },
    }
    for _, s in ipairs(SOUNDS) do
        table.insert(MANIFEST, {
            name = "sound: " .. s,
            path = "Koffee/sounds/" .. s .. ".mp3",
            url  = BASE .. "sounds/" .. string.gsub(s, " ", "%%20") .. ".mp3",
            min  = 512,
        })
    end

    -- no file API -> nothing we can prefetch; fall through instantly (legacy paths).
    if writefile and isfile then
        local hostOk, host = pcall(function()
            if gethui then return gethui() end
            local cg = game:GetService("CoreGui")
            local _ = cg.Name
            return cg
        end)
        if hostOk and host then
            local TweenService = game:GetService("TweenService")
            local ACCENT  = Color3.fromRGB(212, 145, 90)
            local MINT    = Color3.fromRGB(127, 190, 143)
            local TEXT    = Color3.fromRGB(235, 225, 215)
            local MUTED   = Color3.fromRGB(140, 128, 118)
            local PANEL   = Color3.fromRGB(30, 24, 21)

            pcall(function()
                local orphan = host:FindFirstChild("KoffeePreloader")
                if orphan then orphan:Destroy() end
            end)

            local gui = Instance.new("ScreenGui")
            gui.Name = "KoffeePreloader"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 9999
            gui.Parent = host

            local root = Instance.new("Frame")
            root.Size = UDim2.new(1, 0, 1, 0)
            root.BackgroundColor3 = Color3.fromRGB(20, 16, 14)
            root.BorderSizePixel = 0
            root.Parent = gui

            local brand = Instance.new("TextLabel")
            brand.AnchorPoint = Vector2.new(0.5, 0)
            brand.Position = UDim2.new(0.5, 0, 0.5, -58)
            brand.Size = UDim2.new(0, 300, 0, 42)
            brand.BackgroundTransparency = 1
            brand.Text = "koffee"
            brand.Font = Enum.Font.GothamBold
            brand.TextSize = 34
            brand.TextColor3 = TEXT
            brand.Parent = root

            local sub = Instance.new("TextLabel")
            sub.AnchorPoint = Vector2.new(0.5, 0)
            sub.Position = UDim2.new(0.5, 0, 0.5, -18)
            sub.Size = UDim2.new(0, 300, 0, 16)
            sub.BackgroundTransparency = 1
            sub.Text = "v" .. Koffee.Version .. " -- warming up"
            sub.Font = Enum.Font.Gotham
            sub.TextSize = 12
            sub.TextColor3 = MUTED
            sub.TextTransparency = 0.2
            sub.Parent = root

            local track = Instance.new("Frame")
            track.AnchorPoint = Vector2.new(0.5, 0)
            track.Position = UDim2.new(0.5, 0, 0.5, 12)
            track.Size = UDim2.new(0, 280, 0, 4)
            track.BackgroundColor3 = PANEL
            track.BorderSizePixel = 0
            track.Parent = root
            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(1, 0)
            tCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = ACCENT
            fill.BorderSizePixel = 0
            fill.Parent = track
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(1, 0)
            fCorner.Parent = fill

            local status = Instance.new("TextLabel")
            status.AnchorPoint = Vector2.new(0.5, 0)
            status.Position = UDim2.new(0.5, 0, 0.5, 26)
            status.Size = UDim2.new(0, 340, 0, 16)
            status.BackgroundTransparency = 1
            status.Text = "checking cache"
            status.Font = Enum.Font.Gotham
            status.TextSize = 11
            status.TextColor3 = MUTED
            status.TextTruncate = Enum.TextTruncate.AtEnd
            status.Parent = root

            local btnRow = Instance.new("Frame")
            btnRow.AnchorPoint = Vector2.new(0.5, 0)
            btnRow.Position = UDim2.new(0.5, 0, 0.5, 52)
            btnRow.Size = UDim2.new(0, 280, 0, 28)
            btnRow.BackgroundTransparency = 1
            btnRow.Visible = false
            btnRow.Parent = root

            local function mkBtn(x, w, label, color)
                local b = Instance.new("TextButton")
                b.AnchorPoint = Vector2.new(0, 0.5)
                b.Position = UDim2.new(0, x, 0.5, 0)
                b.Size = UDim2.new(0, w, 1, 0)
                b.BackgroundColor3 = PANEL
                b.BorderSizePixel = 0
                b.Text = label
                b.Font = Enum.Font.Gotham
                b.TextSize = 12
                b.TextColor3 = color
                b.Parent = btnRow
                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 6)
                bc.Parent = b
                return b
            end
            local retryBtn = mkBtn(0, 134, "retry", TEXT)
            local skipBtn  = mkBtn(146, 134, "skip", MUTED)

            local pctLabel = Instance.new("TextLabel")
            pctLabel.AnchorPoint = Vector2.new(0.5, 0)
            pctLabel.Position = UDim2.new(0.5, 0, 0.5, -80)
            pctLabel.Size = UDim2.new(0, 300, 0, 14)
            pctLabel.BackgroundTransparency = 1
            pctLabel.Text = ""
            pctLabel.Font = Enum.Font.Gotham
            pctLabel.TextSize = 10
            pctLabel.TextColor3 = MUTED
            pctLabel.Parent = root

            local function setBar(done, total)
                local pct = total > 0 and (done / total) or 1
                fill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quart, 0.18, true)
                pctLabel.Text = math.floor(pct * 100 + 0.5) .. "%"
            end

            local function close()
                Koffee._assetsReady = true
                local out = TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                })
                for _, l in ipairs({ brand, sub, status, pctLabel }) do
                    TweenService:Create(l, out.TweenInfo, { TextTransparency = 1 }):Play()
                end
                TweenService:Create(fill, out.TweenInfo, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(track, out.TweenInfo, { BackgroundTransparency = 1 }):Play()
                out:Play()
                out.Completed:Wait()
                gui:Destroy()
            end

            local req = request or (http and http.request) or http_request or (syn and syn.request)
            local function fetch(url, min)
                if req then
                    local ok, res = pcall(req, { Url = url, Method = "GET" })
                    if ok and res and ((res.StatusCode or 200) == 200)
                        and type(res.Body) == "string" and #res.Body >= min then
                        return res.Body
                    end
                end
                local ok2, body = pcall(function() return game:HttpGetAsync(url) end)
                if ok2 and type(body) == "string" and #body >= min then return body end
                local ok3, body2 = pcall(function() return game:HttpGet(url) end)
                if ok3 and type(body2) == "string" and #body2 >= min then return body2 end
                return nil
            end

            pcall(makefolder, "Koffee")
            pcall(makefolder, "Koffee/sounds")
            pcall(makefolder, "Koffee/fonts")

            local function settle(entry)
                for attempt = 1, 2 do
                    local body = fetch(entry.url, entry.min)
                    if body then
                        if pcall(writefile, entry.path, body) and isfile(entry.path) then
                            return true
                        end
                    end
                    task.wait(0.25 * attempt)
                end
                return false
            end

            local failed = {}
            local function runList(entries, total)
                for _, e in ipairs(entries) do
                    if isfile(e.path) then
                        local good = 0
                        for _, f in ipairs(MANIFEST) do
                            if isfile(f.path) then good = good + 1 end
                        end
                        setBar(good, total)
                    else
                        status.Text = e.name
                        if not settle(e) then
                            table.insert(failed, e)
                        end
                        local good = 0
                        for _, f in ipairs(MANIFEST) do
                            if isfile(f.path) then good = good + 1 end
                        end
                        setBar(good, total)
                    end
                    task.wait()
                end
            end

            runList(MANIFEST, #MANIFEST)

            while #failed > 0 do
                status.TextColor3 = Color3.fromRGB(220, 110, 100)
                status.Text = failed[1].name .. " failed" ..
                    (#failed > 1 and (" +" .. tostring(#failed - 1) .. " more") or "")
                btnRow.Visible = true
                local choice = nil
                local c1 = retryBtn.MouseButton1Click:Connect(function() choice = "retry" end)
                local c2 = skipBtn.MouseButton1Click:Connect(function() choice = "skip" end)
                while choice == nil do task.wait() end
                c1:Disconnect(); c2:Disconnect()
                btnRow.Visible = false
                if choice == "skip" then break end
                local retrySet = failed
                failed = {}
                status.TextColor3 = MUTED
                runList(retrySet, #MANIFEST)
            end

            status.TextColor3 = MINT
            status.Text = "ready"
            close()
        else
            Koffee._assetsReady = true
        end
    else
        Koffee._assetsReady = true
    end
end

-- v0.0.70: Adonis / __newindex AC neutralizer (zyn). Hooks the anti-cheat's
-- Detected/Kill paths to no-ops. Fully guarded: if the runtime lacks any required
-- global (getgc, hookfunction, setthreadidentity, getrenv) the whole block pcalls
-- out and the suite loads normally.
-- v0.1.1: DEFERRED to task.spawn. The getgc(true) walk is O(N) over every live GC
-- object -- on populated games (busy Adonis servers, dev-console builds) this
-- crossed the "game freezes on load" threshold. Deferring means the AC hooks
-- install one frame after script load instead of before the first line of user
-- code runs; Adonis doesn't fire in that window in any observed game. Still
-- pcall'd -- errors here must never take the suite down.
task.spawn(function()
pcall(function()
    if not (getgc and hookfunction and setthreadidentity and getrenv) then return end
    local dbg = false          -- flip true to see what the AC tried to do
    local held = {}            -- keep hook refs alive
    local flagged, killer

    setthreadidentity(2)
    for _, v in getgc(true) do
        if typeof(v) == "table" then
            local det = rawget(v, "Detected")
            local kil = rawget(v, "Kill")
            if typeof(det) == "function" and not flagged then
                flagged = det
                pcall(function()
                    hookfunction(flagged, function(method, info)
                        if dbg and method ~= "_" then
                            warn(("Adonis AntiCheat flagged\nMethod: %s\nInfo: %s"):format(tostring(method), tostring(info)))
                        end
                        return true
                    end)
                    table.insert(held, flagged)
                end)
            end
            if rawget(v, "Variables") and rawget(v, "Process") and typeof(kil) == "function" and not killer then
                killer = kil
                pcall(function()
                    hookfunction(killer, function(reason)
                        if dbg then warn("adonis tried to kill (fb): " .. tostring(reason)) end
                    end)
                    table.insert(held, killer)
                end)
            end
        end
    end

    -- defeat debug.info-based detection of the flagged-fn hook
    pcall(function()
        local realInfo = getrenv().debug.info
        local wrapper  = newcclosure or function(f) return f end
        local o; o = hookfunction(realInfo, wrapper(function(...)
            local a = ...
            if flagged and a == flagged then
                if dbg then warn("zyn | adonis gone") end
                return coroutine.yield(coroutine.running())
            end
            return o(...)
        end))
    end)

    setthreadidentity(7)
end)
end)

-- v0.0.96 EXECUTOR PROFILING + SAFE MODE PROMPT. Weak executors crash when
-- silent aim installs the full __namecall hook (newcclosure+hookmetamethod is a
-- known bricker). If the executor isn't on the known-good list (Potassium/Volt),
-- prompt for the SAFE variant: __index-only redirect (Mouse.Hit/Target/UnitRay
-- only, no __namecall, no Camera/pos spoof) -> the game doesn't crash, but
-- wallbang + forced-mb stay disabled. Prompt yields on a BindableEvent.
Koffee._safeMode = false
Koffee._exec     = "Unknown"
do
    local execName = "Unknown"
    pcall(function()
        if identifyexecutor then
            local a, b = identifyexecutor()
            if type(a) == "string" and #a > 0 then execName = a
            elseif type(b) == "string" and #b > 0 then execName = b end
        end
    end)
    Koffee._exec = execName
    -- v0.1.1: case-insensitive lookup. identifyexecutor() casing isn't contractual
    -- across runtimes ("Potassium" vs "potassium" both seen in the wild); a strict
    -- match sends whitelisted users into the safe-mode BindableEvent gate, which
    -- yields the load thread until they click a button they don't know they need.
    local KNOWN_STRONG = { potassium = true, volt = true }
    if not (type(execName) == "string" and KNOWN_STRONG[execName:lower()]) then
        local ok, answer = pcall(function()
            local Players = game:GetService("Players")
            local CoreGui = game:GetService("CoreGui")
            local player  = Players.LocalPlayer
            if not player then return nil end
            local host    = (gethui and gethui()) or CoreGui or player:WaitForChild("PlayerGui", 3)
            if not host then return nil end

            local gui = Instance.new("ScreenGui")
            gui.Name = "KoffeeExecPrompt_" .. tostring(math.random(100000, 999999))
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn   = false
            gui.DisplayOrder   = 2147483647
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pcall(function() gui.Parent = host end)

            local dim = Instance.new("Frame", gui)
            dim.Size = UDim2.fromScale(1, 1)
            dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            dim.BackgroundTransparency = 0.35
            dim.BorderSizePixel = 0
            dim.ZIndex = 1

            local card = Instance.new("Frame", gui)
            card.AnchorPoint = Vector2.new(0.5, 0.5)
            card.Position = UDim2.fromScale(0.5, 0.5)
            card.Size = UDim2.fromOffset(420, 200)
            card.BackgroundColor3 = Color3.fromRGB(27, 22, 19)
            card.BorderSizePixel = 0
            card.ZIndex = 2
            local corner = Instance.new("UICorner", card); corner.CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", card)
            stroke.Color = Color3.fromRGB(217, 150, 95)
            stroke.Thickness = 1
            stroke.Transparency = 0.4

            local title = Instance.new("TextLabel", card)
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(18, 14)
            title.Size = UDim2.new(1, -36, 0, 22)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 16
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextColor3 = Color3.fromRGB(217, 150, 95)
            title.Text = "Low-end executor detected"
            title.ZIndex = 3

            local exec = Instance.new("TextLabel", card)
            exec.BackgroundTransparency = 1
            exec.Position = UDim2.fromOffset(18, 40)
            exec.Size = UDim2.new(1, -36, 0, 18)
            exec.Font = Enum.Font.Gotham
            exec.TextSize = 13
            exec.TextXAlignment = Enum.TextXAlignment.Left
            exec.TextColor3 = Color3.fromRGB(142, 129, 116)
            exec.Text = "Detected: " .. execName
            exec.ZIndex = 3

            local body = Instance.new("TextLabel", card)
            body.BackgroundTransparency = 1
            body.Position = UDim2.fromOffset(18, 68)
            body.Size = UDim2.new(1, -36, 0, 60)
            body.Font = Enum.Font.Gotham
            body.TextSize = 13
            body.TextWrapped = true
            body.TextXAlignment = Enum.TextXAlignment.Left
            body.TextYAlignment = Enum.TextYAlignment.Top
            body.TextColor3 = Color3.fromRGB(242, 234, 223)
            body.Text = "This runtime may not handle silent aim's full hook stack. Load the safe version of Koffee? (silent aim will use a lighter path.)"
            body.ZIndex = 3

            local yes = Instance.new("TextButton", card)
            yes.AnchorPoint = Vector2.new(1, 1)
            yes.Position = UDim2.new(1, -18, 1, -14)
            yes.Size = UDim2.fromOffset(90, 32)
            yes.BackgroundColor3 = Color3.fromRGB(217, 150, 95)
            yes.BorderSizePixel = 0
            yes.AutoButtonColor = true
            yes.Font = Enum.Font.GothamBold
            yes.TextSize = 13
            yes.TextColor3 = Color3.fromRGB(15, 12, 10)
            yes.Text = "Yes (Safe)"
            yes.ZIndex = 3
            local yc = Instance.new("UICorner", yes); yc.CornerRadius = UDim.new(0, 6)

            local no = Instance.new("TextButton", card)
            no.AnchorPoint = Vector2.new(1, 1)
            no.Position = UDim2.new(1, -114, 1, -14)
            no.Size = UDim2.fromOffset(90, 32)
            no.BackgroundColor3 = Color3.fromRGB(41, 33, 29)
            no.BorderSizePixel = 0
            no.AutoButtonColor = true
            no.Font = Enum.Font.GothamBold
            no.TextSize = 13
            no.TextColor3 = Color3.fromRGB(242, 234, 223)
            no.Text = "No (Full)"
            no.ZIndex = 3
            local nc = Instance.new("UICorner", no); nc.CornerRadius = UDim.new(0, 6)

            local bindable = Instance.new("BindableEvent")
            yes.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end); bindable:Fire(true) end)
            no.MouseButton1Click:Connect(function()  pcall(function() gui:Destroy() end); bindable:Fire(false) end)
            return bindable.Event:Wait()
        end)
        if ok and answer == true then Koffee._safeMode = true end
    end
end

-- THEME
local Theme = {
    -- v0.0.48 premium pass: deeper background for real contrast against the panels,
    -- borders pulled up so card edges read crisp (not muddy), accent a touch brighter.
    Palette = {
        Background    = Color3.fromRGB(21, 18, 16),
        Panel         = Color3.fromRGB(27, 22, 19),
        PanelElevated = Color3.fromRGB(41, 33, 29),
        Pill          = Color3.fromRGB(50, 40, 34),
        Border        = Color3.fromRGB(60, 49, 42),
        BorderSubtle  = Color3.fromRGB(40, 32, 28),
        Text          = Color3.fromRGB(242, 234, 223),
        TextMuted     = Color3.fromRGB(142, 129, 116),
        TextFaint     = Color3.fromRGB(94, 85, 77),
        Accent        = Color3.fromRGB(217, 150, 95),
        Success       = Color3.fromRGB(127, 190, 143),
        Danger        = Color3.fromRGB(212, 106, 90),
        Snow          = Color3.fromRGB(255, 253, 248),
    },
    -- placeholder
    Fonts = (function()
        local MONO  = "rbxasset://fonts/families/RobotoMono.json"
        -- v0.0.29: Matcha's ACTUAL face is Proxima Soft Bold. We auto-download the .ttf once
        -- (cached to executor workspace), wrap it in a font-family JSON for getcustomasset.
        -- Everything is pcall'd with a Nunito fallback -- locked-down executors still render.
        -- Font is a nicety, never a hard dep.
        -- v0.1.1: SYNC path is CACHE-ONLY. If the cached ttf+json are already on
        -- disk, we register them synchronously. If NOT, we return nil (Nunito
        -- fallback) and kick off the download in a background task so the NEXT
        -- session finds the cache. This kills a ~700KB HTTP-download-on-main-
        -- thread that friend's game froze on when a first-run happened after a
        -- fresh executor cache wipe.
        local FONT_URL  = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/ProximaSoft-Bold.ttf"
        local FONT_FILE = "koffee_proximasoft.ttf"
        -- v0.2.1: versioned filename + always-rebuild. The OLD `koffee_proximasoft.json`
        -- cached across sessions was the source of the "font shows as Nunito" bug --
        -- `getcustomasset()` produces a per-session asset URL for the ttf, but the
        -- JSON on disk still held the PRIOR session's URL, which Roblox couldn't
        -- resolve this session, silently falling back to the engine default (Nunito).
        -- Bumping the filename ignores every stale cache in the wild; regenerating
        -- unconditionally on every load keeps the assetId inside the JSON fresh.
        local FONT_JSON = "koffee_proximasoft_v2.json"
        local FONT_JSON_OLD = "koffee_proximasoft.json"
        local customFam = (function()
            local ok, res = pcall(function()
                local getasset = getcustomasset or getsynasset
                    or (syn and syn.getcustomasset)
                local isf, wf = isfile, writefile
                if not (getasset and isf and wf) then return nil end

                -- honour a manual drop first (any local proxima/koffee_font file),
                -- otherwise register the hosted ttf if already cached.
                local target
                for _, name in ipairs({
                    FONT_FILE, "koffee_font.ttf", "koffee_font.otf",
                    "ProximaSoft-Bold.ttf", "ProximaSoft-Bold.otf",
                }) do
                    if not target and isf(name) then target = name end
                end
                if not target then
                    -- CACHE MISS: background-download for next session, return nil now.
                    task.spawn(function()
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
                        if body then pcall(wf, FONT_FILE, body) end
                    end)
                    return nil
                end

                -- v0.2.1: nuke the v1 cache from prior sessions -- if it survived to
                -- disk here, its embedded ttf assetId is guaranteed stale by now.
                if delfile and isf(FONT_JSON_OLD) then pcall(delfile, FONT_JSON_OLD) end
                -- CACHE HIT: rebuild the family JSON synchronously every load. The
                -- ttfId embedded below MUST come from THIS session's getasset() call --
                -- caching the JSON across sessions was the "font renders as Nunito"
                -- bug (see comment above FONT_JSON). Cheap: one getasset + JSONEncode
                -- + writefile per load. No HTTP, all local.
                local ttfId = getasset(target)
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
    -- v0.0.97 FEATURE-INTERFACE FONT SYSTEM (custom font for everything outside the
    -- main Koffee window). The main interface (the window you open with Delete) keeps
    -- using Theme.Fonts (ProximaSoft). Feature interface things -- arraylist, ESP
    -- name/distance/health tags, HUD stats labels, etc. -- register their TextLabels
    -- via Theme.fei(label, fontKey, baseSize) so when the user picks a custom font +
    -- size in Options we hot-swap FontFace + scale TextSize across all of them at
    -- once without touching each call site. Defaults to FontTable -- the system is a
    -- no-op while FeiOn is false, so feature elements look exactly like before.
    FeiOn     = false,
    FeiSize   = 12,                       -- global text size used when FeiOn
    FeiScale  = 1.0,                      -- FeiSize / Text.Body -- multiplies base sizes
    _fei      = { labels = {}, fonts = { Regular=true, Medium=true, Bold=true, Title=true, Mono=true } },
    Sizes = {
        HudHeight    = 34,
        -- bigger overall so density stays right at larger text sizes
        WindowWidth  = 640,
        WindowHeight = 820,
        TabBarHeight = 40,
    },
    -- v0.0.48: tighter radii read sharper / more premium than the previous soft-round set
    Radius = { Small = 3, Medium = 5, Large = 7, XLarge = 10 },
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

-- v0.0.97 FEATURE-INTERFACE FONT SYSTEM -- the custom font table + helpers live
-- OUTSIDE the Theme literal (they close over the Theme local). FeiFonts starts as
-- an opaque alias of Fonts; setFeiFont swaps entries and applyFei re-applies them to
-- the registered feature-interface TextLabels (arraylist / ESP tags / HUD stats /
-- health bar text, etc.). While FeiOn is false, the FeiFonts table is never read,
-- so this whole system is a no-op for users who keep the custom font off.
Theme.FeiFonts = {
    Regular = Theme.Fonts.Regular,
    Medium  = Theme.Fonts.Medium,
    Bold    = Theme.Fonts.Bold,
    Title   = Theme.Fonts.Title,
    Mono    = Theme.Fonts.Mono,
}

-- register a feature-interface TextLabel so its FontFace + TextSize follow the
-- custom-font toggle. Returns (FontFace, TextSize) to set right now.
-- `fontKey` is Regular / Medium / Bold / Title / Mono; `baseSize` is the Theme.Text
-- size the label would normally use -- scaled by FeiScale while FeiOn (preserves the
-- name/is-on/detail hierarchy of the arraylist and the ESP tag sizes).
function Theme.fei(label, fontKey, baseSize)
    table.insert(Theme._fei.labels, { label = label, fontKey = fontKey, baseSize = baseSize })
    if Theme.FeiOn then
        local sz = math.round(baseSize * Theme.FeiScale)
        local f = Theme.FeiFonts[fontKey] or Theme.Fonts[fontKey]
        pcall(function()
            label.FontFace = f
            label.TextSize = sz
        end)
        return f, sz
    end
    return Theme.Fonts[fontKey], baseSize
end

-- re-apply the current Fei state (font + scaled size) to every registered label.
-- Call after toggling On/Off, after changing the custom font, or after changing the
-- global size. Stale entries (destroyed labels) are cleaned up lazily.
function Theme.applyFei()
    local live = {}
    for _, e in ipairs(Theme._fei.labels) do
        local lbl = e.label
        if lbl and lbl.Parent then
            local f, sz
            if Theme.FeiOn then
                f = Theme.FeiFonts[e.fontKey] or Theme.Fonts[e.fontKey]
                sz = math.round(e.baseSize * Theme.FeiScale)
            else
                f = Theme.Fonts[e.fontKey]
                sz = e.baseSize
            end
            pcall(function()
                lbl.FontFace = f
                lbl.TextSize = sz
            end)
            live[#live + 1] = e
        end
    end
    Theme._fei.labels = live
end

function Theme.setFeiOn(on)
    Theme.FeiOn = on == true
    Theme.applyFei()
end

function Theme.setFeiSize(n)
    n = tonumber(n) or Theme.Text.Body
    Theme.FeiSize  = n
    Theme.FeiScale = n / Theme.Text.Body
    Theme.applyFei()
end

-- v0.0.97 custom feature font catalog. Hosted on the koffee-assets repo (same as
-- ProximaSoft + the sound pack). Each spec is a URL + a workspace cache path under
-- the Koffee/ folder. The Size of the custom font itself is controlled by FeiSize
-- via the Options slider, not here.
--
-- Wrapped in do/end so FONTS_CATALOG / feiFontCache / loadFeiFont don't add to the
-- chunk-local count -- the file sits at Luau's 200-register ceiling. Only the
-- Theme.setFeiFont assignment below escapes to chunk scope.
do
    local FONTS_CATALOG = {
        ["Minecraft Bold"] = {
            url  = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/MinecraftBold.otf",
            file = "Koffee/fonts/MinecraftBold.otf",
        },
        ["Minecraft Regular"] = {
            url  = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/MinecraftRegular.otf",
            file = "Koffee/fonts/MinecraftRegular.otf",
        },
        ["ImGui"] = {
            url  = "https://raw.githubusercontent.com/lowkeymyself/koffee-assets/main/ProggyClean.ttf",
            file = "Koffee/fonts/ProggyClean.ttf",
        },
    }

    -- cached Font.new handles so re-selecting a font doesn't re-download / re-register.
    local feiFontCache = {}

    local function loadFeiFont(name)
        if feiFontCache[name] then return feiFontCache[name] end
        local spec = FONTS_CATALOG[name]
        if not spec then return nil end
        local ok, res = pcall(function()
            local getasset = getcustomasset or getsynasset
                or (syn and syn.getcustomasset)
            local isf, wf = isfile, writefile
            if not (getasset and isf and wf) then return nil end

            -- Koffee/fonts/ may not exist; try to make it (writefile on known executors
            -- creates parent dirs; on others it errors silently -- we fall back to a
            -- flat filename below). best-effort: ignore any makefolder failure.
            if makefolder then pcall(makefolder, "Koffee") pcall(makefolder, "Koffee/fonts") end

            -- download the otf once and cache it under spec.file (flat fallback below).
            local usedFile = spec.file
            if not isf(spec.file) then
                local body
                local req = (syn and syn.request) or (http and http.request)
                    or http_request or request
                if req then
                    local rok, r = pcall(req, { Url = spec.url, Method = "GET" })
                    if rok and r and r.Body and #r.Body > 512 then body = r.Body end
                end
                if not body then
                    local hok, h = pcall(function() return game:HttpGetAsync(spec.url) end)
                    if hok and h and #h > 512 then body = h end
                end
                if not body then return nil end
                local wrote = pcall(wf, spec.file, body)
                if (not wrote) or (not isf(spec.file)) then
                    local ext = spec.file:match("%.(.+)$") or "ttf"
                    usedFile = "koffee_" .. name:gsub("%s", "_") .. "." .. ext
                    wf(usedFile, body)
                end
            end

            -- v0.0.97: register as a font-family JSON (one face per weight) so Roblox
            -- renders at all sizes -- a bare single-face URL with Font.new(id, weight)
            -- silently falls back to the system default at sizes/weights it can't find,
            -- which is why the custom font looked like a generic default before. mirror
            -- the ProximaSoft path: build a family JSON, write it, point Font.new at the
            -- JSON URL with the desired weight.
            -- v0.2.1: bumped filename (_v2) + always-rebuild. Same stale-assetId bug as
            -- ProximaSoft's -- getcustomasset() gives per-session ttf URLs, so a JSON
            -- cached across sessions rendered as the engine default. Ignore the v1
            -- cache in the wild; regenerate every load with THIS session's ttfId.
            local famFile    = "koffee_fei_" .. name:gsub("%s","_"):lower() .. "_v2.json"
            local famFileOld = "koffee_fei_" .. name:gsub("%s","_"):lower() .. ".json"
            if delfile and isf(famFileOld) then pcall(delfile, famFileOld) end
            do
                local ttfId = getasset(usedFile)
                local fam = {
                    name  = name:gsub("%s", ""),
                    faces = {
                        { name = "Regular",   weight = 400, style = "normal", assetId = ttfId },
                        { name = "Medium",    weight = 500, style = "normal", assetId = ttfId },
                        { name = "SemiBold",  weight = 600, style = "normal", assetId = ttfId },
                        { name = "Bold",      weight = 700, style = "normal", assetId = ttfId },
                        { name = "ExtraBold", weight = 800, style = "normal", assetId = ttfId },
                    },
                }
                wf(famFile, game:GetService("HttpService"):JSONEncode(fam))
            end
            local famId = getasset(famFile)
            local f = Font.new(famId, Enum.FontWeight.Regular)
            feiFontCache[name] = f
            return f
        end)
        return (ok and res) and res or nil
    end

    -- swap the custom font in (or revert to Theme.Fonts when name == "None"). Downloads
    -- on demand the first time a font is selected. Recursively re-applies to all tracked
    -- feature-interface labels.
    function Theme.setFeiFont(name)
        if not name or name == "None" then
            for k in pairs(Theme.FeiFonts) do Theme.FeiFonts[k] = Theme.Fonts[k] end
        else
            local f = loadFeiFont(name)
            if f then
                for k in pairs(Theme.FeiFonts) do Theme.FeiFonts[k] = f end
            else
                for k in pairs(Theme.FeiFonts) do Theme.FeiFonts[k] = Theme.Fonts[k] end
            end
        end
        Theme.applyFei()
    end

    -- expose the loader so the Main-Interface mirror can reuse the same catalog.
    function Theme.loadFeiFont(name) return loadFeiFont(name) end

    -- v0.0.99 MAIN-INTERFACE FONT MIRROR: "Custom Font (MI)". Same catalog as the
    -- feature font, but applied to the main window's OWN text (labels, buttons,
    -- textboxes) instead of the feature interface. Original FontFace + TextSize per
    -- label is snapshotted on first touch, so the mirror is fully reversible.
    -- v0.1.0: independent name + size. Size swaps TextSize on the same labels
    -- (TextSize stays a plain number swap; the rows don't reflow, same as before).
    Theme._miface_cache = {}
    Theme.MIFontOn = false
    function Theme.applyMIFont(root, face, size)
        if not root then return end
        size = tonumber(size)
        if face then
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
                    local c = Theme._miface_cache[v]
                    if not c then
                        c = { face = v.FontFace, size = v.TextSize }
                        Theme._miface_cache[v] = c
                    end
                    pcall(function() v.FontFace = face end)
                    if size then pcall(function() v.TextSize = size end) end
                end
            end
            Theme.MIFontOn = true
        else
            -- off: restore every snapshotted label to its original face/size.
            -- Stale entries (destroyed labels) get pruned.
            for v, c in pairs(Theme._miface_cache) do
                if v and v.Parent then
                    pcall(function() v.FontFace = c.face end)
                    pcall(function() v.TextSize = c.size end)
                else
                    Theme._miface_cache[v] = nil
                end
            end
            Theme.MIFontOn = false
        end
    end
end

-- SERVICES + UTIL
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

-- v0.0.98: MAIN-INTERFACE ANIMATION LAYER. Every widget class in the window gets
-- a short, quick motion -- nothing here touches the Second Interface (top bar /
-- HUD / toast / arraylist / ESP). Three primitives, all built on a per-instance
-- UIScale (visual-only, never fights UIListLayout / AutomaticSize):
--   uScaleOf(inst)  -- lazily attaches one UIScale per instance
--   popFx(btn)      -- press feedback: squash to 0.95 while held, spring back
--   popIn(inst, f)  -- entrance: scale f -> 1 (fades transparency too if asked)
--   pulse(inst, s)  -- one-shot: to f then back to 1 (ticks, pops, catches)
local _us_cache = {}
local function uScaleOf(inst)
    local sc = _us_cache[inst]
    if not sc then
        sc = new("UIScale", { Parent = inst })
        _us_cache[inst] = sc
    end
    return sc
end

-- press-squash: everything clickable in the window responds with a tiny squash
-- instead of static text swaps. Cancel-proof: MouseLeave while held restores.
local function popFx(btn)
    local sc = uScaleOf(btn)
    btn.MouseButton1Down:Connect(function()
        tween(sc, Theme.Animation.Fast, { Scale = 0.94 })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(sc, Theme.Animation.Fast, { Scale = 1 })
    end)
    btn.MouseLeave:Connect(function()
        tween(sc, Theme.Animation.Fast, { Scale = 1 })
    end)
end

-- entrance: fade + grow-in (cards, tab panels, popups).
-- one-shot tick: to `to` then settle back to 1.
local function pulse(inst, to)
    local sc = uScaleOf(inst)
    sc.Scale = to
    tween(sc, Theme.Animation.Fast, { Scale = 1 })
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

-- SESSION IDENTITY: randomize every instance name + getgenv keys per session.
-- Name-scanning ACs (game LocalScripts walking PlayerGui/Lighting/Workspace)
-- never see a static "Koffee*" string. Cleanup is ref-based, not name-based.
local KID = (function()
    local genv = (getgenv and getgenv()) or {}
    local BOOT = "\6_rt_fx_ctx"   -- stable across re-execs; looks like an engine field
    local set   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local function rand(n)
        local t = {}
        for i = 1, n do local j = math.random(1, #set); t[i] = set:sub(j, j) end
        return table.concat(t)
    end
    local ctx = genv[BOOT]
    if ctx then
        -- re-exec: destroy all tracked instances from the previous run
        for _, inst in ipairs(ctx.instances or {}) do pcall(function() inst:Destroy() end) end
        ctx.instances = {}
    else
        ctx = { instances = {}, names = {}, keys = {}, bind = rand(12) }
        genv[BOOT] = ctx
    end
    -- obfuscated, session-stable repoint keys replace the static "Koffee*" getgenv names
    ctx.keys.ri     = ctx.keys.ri     or ("_" .. rand(14))
    ctx.keys.nc     = ctx.keys.nc     or ("_" .. rand(14))
    ctx.keys.res    = ctx.keys.res    or ("_" .. rand(14))
    ctx.keys.hooked = ctx.keys.hooked or ("_" .. rand(14))
    ctx.keys.ctrl   = ctx.keys.ctrl   or ("_" .. rand(14))
    return {
        ctx   = ctx,
        name  = function(k)
            ctx.names[k] = ctx.names[k] or rand(math.random(9, 15))
            return ctx.names[k]
        end,
        track = function(inst) table.insert(ctx.instances, inst); return inst end,
    }
end)()

local function guiParent()
    if gethui then return gethui() end
    local ok = pcall(function() return CoreGui.Name end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ROOT SCREEN (ref-tracked cleanup; no static "Koffee" names in the GUI tree)
-- v0.0.15: also purge stale BillboardGuis from older builds ("KoffeeName" on Head).
pcall(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch = plr.Character
        if ch then
            local h = ch:FindFirstChild("Head")
            if h then
                for _, kid in ipairs(h:GetChildren()) do
                    if kid.ClassName == "BillboardGui" and kid.Name:len() > 8 and not kid.Name:find("[%s%p]") then
                        pcall(function() kid:Destroy() end)
                    end
                end
            end
        end
    end
end)

local screen = KID.track(new("ScreenGui", {
    Name = KID.name("root"),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = math.random(4000, 8000),
    Parent = guiParent(),
}))

-- separate top-level ScreenGui for popups (dropdowns, color picker) so they
-- render ABOVE the main window's CanvasGroup regardless of ZIndex quirks.
local popupScreen = KID.track(new("ScreenGui", {
    Name = KID.name("popups"),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = screen.DisplayOrder + 1,
    Parent = guiParent(),
}))

-- BACKGROUND: dim + blur + snow (activates when window is open)
local dim = new("Frame", {
    Name = KID.name("dim"),
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = screen,
})

local blur = KID.track(new("BlurEffect", {
    Name = KID.name("blur"),
    Size = 0,
    Parent = Lighting,
}))

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

-- HUD STRIP (TOP)
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
    Text = "Koffee",
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
    local lbl = new("TextLabel", {
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
    -- v0.0.97: feature-interface font system (custom font + global size)
    lbl.FontFace, lbl.TextSize = Theme.fei(lbl, "Mono", Theme.Text.Small)
    return lbl
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

-- v0.0.97: replaced the "del menu" hotkey panel with an Apple-style signal
-- indicator (4 ascending bars on a shared baseline, rounded like iOS wifi).
-- Color tracks ping latency:  green (<=100ms) / yellow (<=200ms) / red
-- (<=350ms) / deep red (>350ms). The widget locals + paint closure live inside
-- a do/end so they don't add to the chunk-local count (the file sits at Luau's
-- 200-register ceiling); only the paintSignal forward declaration escapes so
-- the ping task can reach it.
local paintSignal
do
    -- 4 bars sitting on the same baseline; heights chosen to climb from short
    -- to tall inside the 22px panel, widths uniform. Sizes: {w, h}.
    local barSpecs = { { 4, 6 }, { 4, 9 }, { 4, 12 }, { 4, 15 } }
    local BAR_W, BAR_H_MAX = 4, 15

    local signalWidget = new("Frame", {
        Name = "Signal",
        Size = UDim2.new(0, 8 + #barSpecs * BAR_W + (#barSpecs - 1) * 2 + 8, 0, BAR_H_MAX + 4),
        BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 22,
        Parent = hudRight,
    }, {
        corner(Theme.Radius.Small),
        stroke(Theme.Palette.BorderSubtle),
        new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
    })

    -- bars bottom-anchored so they share the baseline -- height drives the
    -- "ascending" look without any manual vertical offsets.
    local signalBars = {}
    for i, spec in ipairs(barSpecs) do
        signalBars[i] = new("Frame", {
            Name = "Bar" .. i,
            Size = UDim2.new(0, spec[1], 0, spec[2]),
            Position = UDim2.new(0, 6 + (i - 1) * (BAR_W + 2), 1, -2),
            AnchorPoint = Vector2.new(0, 1),     -- bottom-aligned
            BackgroundColor3 = Theme.Palette.TextFaint,
            BorderSizePixel = 0,
            ZIndex = 23,
            Parent = signalWidget,
        }, { corner(1.5) })
    end

    local function pingColor(ms)
        if not ms or ms <= 0 then return Theme.Palette.TextFaint end
        if ms <= 100 then return Color3.fromRGB(127, 190, 143) end      -- green
        if ms <= 200 then return Color3.fromRGB(232, 196, 110) end     -- yellow
        if ms <= 350 then return Color3.fromRGB(212, 106, 90) end       -- red
        return Color3.fromRGB(148, 54, 42)                              -- deep red
    end

    paintSignal = function(ms)
        local c = pingColor(ms)
        for _, bar in ipairs(signalBars) do bar.BackgroundColor3 = c end
    end
end

-- LIVE STATS
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
        paintSignal(ok and p or nil)
        task.wait(1)
    end
end)

-- MODULE SYSTEM + ACTIVE-MODULES TYPEWRITER ARRAY
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
local KoffeeOptions = {
    Arraylist = true, ArraylistOutline = false, ArraylistOutlineSize = 1,
    -- v0.0.97 custom feature-interface font (arraylist / ESP / health text / HUD stats,
    -- everything outside the main Koffee window). On/Name/Size ride the config system.
    CustomFontOn   = false,
    CustomFontName = "None",       -- "None" | "Minecraft Bold" | "Minecraft Regular" | "ImGui" (user-expandable)
    CustomFontSize = 12,           -- global text size used when CustomFontOn is true
    -- v0.0.99+: MIRROR font for the main window's own text. v0.1.0: independent
    -- of the feature font -- own name + own size, both ride the config system.
    MIFontOn   = false,
    MIFontName = "None",           -- separate catalog pick
    MIFontSize = 12,               -- "12" = Theme mirror default; slider in right-click
}
local nextLayoutOrder = 0
local ROW = {
    height = 20,
    enter  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    muted  = "rgb(138,125,112)",   -- Theme.Palette.TextMuted
    detail = 12,                   -- smaller than Body (14)
    on     = "rgb(217,150,95)",    -- Theme.Palette.Accent (the "on" tag)
}

-- v0.0.73: the plain (tag-free) visible string -- base + detail + " on" when active.
-- Drives BOTH the sort key (length + alpha) and equality checks. Spaces in the detail
-- (e.g. ESP's "    box") are intentionally counted, so "ESP    box" sorts above "Health".
local function arrayPlainText(mod)
    local s = mod.DisplayName or mod.Id or "?"
    local detail = mod.GetDetail and mod.GetDetail() or ""
    if detail ~= "" then s = s .. detail end
    if mod.IsActive and mod.IsActive() then s = s .. "  on" end
    return s
end

local function buildArrayLabelText(mod)
    local base = mod.DisplayName or mod.Id or "?"
    local detail = mod.GetDetail and mod.GetDetail() or ""
    -- v0.0.97: scale the RichText-embedded detail/on font sizes by FeiScale when the
    -- custom feature font is on, so the body/detail hierarchy survives the global size.
    local scale = Theme.FeiOn and Theme.FeiScale or 1
    local s = base
    if detail and detail ~= "" then
        s = s .. string.format("<font size='%d' color='%s'>%s</font>",
            math.round(ROW.detail * scale), ROW.muted, detail)
    end
    if mod.IsActive and mod.IsActive() then
        s = s .. string.format("<font size='%d' color='%s'>  on</font>",
            math.round((ROW.detail - 2) * scale), ROW.muted)
    end
    return s
end

-- v0.0.73: arraylist is sorted by visible-text LENGTH descending (longer feature names on
-- top -- "Silent Aim" above "ESP"), tie-broken alphabetically ascending ("A" above "B",
-- "ESP box" above "ESP tracer"). `shown` holds every live entry; resortArray reassigns
-- LayoutOrder so the UIListLayout reflows.
local shown = {}
local function arrayLess(a, b)
    local ta, tb = arrayPlainText(a), arrayPlainText(b)
    if #ta ~= #tb then return #ta > #tb end   -- longer first
    return ta < tb                            -- alphabetical A..Z
end
local function resortArray()
    table.sort(shown, arrayLess)
    for i, m in ipairs(shown) do
        if m._wrapper then m._wrapper.LayoutOrder = i end
    end
end
local function shownRemove(mod)
    for i, m in ipairs(shown) do
        if m == mod then table.remove(shown, i); return end
    end
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
        Size = UDim2.new(1, 0, 0, ROW.height),
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
        -- v0.0.95 arraylist gradient hook: UIGradient child fed by the ESP Text
        -- Gradient system (below the addToActiveArray block). Disabled by default;
        -- the sync heartbeat flips it on + updates Color/Rotation/Offset per frame
        -- when ESP.Config.TextGradient is true.
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, -10, 0, 0),  -- start slightly to the left, slide in right
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 18,
        Parent = wrapper,
    })
    -- v0.0.97: register this arraylist label with the feature-interface font system
    -- (custom font + global size slider in Options). The label is re-built per
    -- module toggle, so register it fresh each time.
    label.FontFace, label.TextSize = Theme.fei(label, "Medium", Theme.Text.Body)
    -- v0.0.76: per-label UIStroke driven by ESP.Config.Outline (wired below, once
    -- ESP exists). Contextual so it hugs the glyphs (Border would box the label rect).
    -- Starts disabled -- the outline heartbeat flips it on if Outline is on.
    local arrStroke = textStroke(Color3.new(0, 0, 0), 1)
    arrStroke.Name = "KArrayStroke"
    arrStroke.Enabled = false
    arrStroke.Parent = label
    -- v0.0.95: UIGradient for text-gradient-on-arraylist. Disabled by default;
    -- flipped on + refreshed per frame by the sync heartbeat when
    -- ESP.Config.TextGradient is true (wired after ESP config exists).
    local arrGrad = new("UIGradient", { Enabled = false, Parent = label })
    arrGrad.Name = "KArrayGrad"
    tween(label, ROW.enter, {
        Position = UDim2.new(0, 0, 0, 0),
        TextTransparency = 0,
    })
    mod._wrapper = wrapper
    mod._arrayLabel = label

    -- v0.0.73: register in the sorted set + reflow (length-desc, alpha tie-break).
    shownRemove(mod)
    table.insert(shown, mod)
    resortArray()

    -- v0.0.14: refresh the detail string lazily on Heartbeat (~0.2s throttle, no per-frame stringify).
    -- v0.0.73: also covers the IsActive "on" tag, and re-sorts when the visible length changes.
    -- Disconnected in removeFromActiveArray.
    if mod.GetDetail or mod.IsActive then
        local accum = 0
        mod._detailConn = RunService.Heartbeat:Connect(function(dt)
            accum = accum + dt
            if accum < 0.2 then return end
            accum = 0
            if not (mod._arrayLabel and mod._arrayLabel.Parent) then return end
            -- v0.0.97: the gradient heartbeat toggles RichText off when the text
            -- gradient is active (UIGradient is ignored on RichText labels). Match
            -- the label's current RichText state here so the detail poll doesn't
            -- write tagged text onto a non-RichText label (would show raw <font>).
            local newText = mod._arrayLabel.RichText
                and buildArrayLabelText(mod)
                or  arrayPlainText(mod)
            if mod._arrayLabel.Text ~= newText then
                mod._arrayLabel.Text = newText
                resortArray()
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
    shownRemove(mod)   -- v0.0.73: drop from the sorted set immediately so the rest reflow
    resortArray()
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
        Watchers = {},   -- v0.0.13: pubsub; notified on every toggle so keybind flips update checkbox visuals.
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

-- MAIN WINDOW
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
    Text = "Koffee",
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

-- v0.0.98/99 pill machinery. Follower pill: resting state is ALWAYS the active
-- tab button's live rect; on switch it pops (stretch past destination) then
-- contracts; snaps via pillResync whenever button geometry moves. v0.0.99:
-- a generation token lets stale tween completions bail instead of fighting a
-- newer switch (the "pill flickers every other click" fix).
local PILL_STRETCH  = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local PILL_CONTRACT = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local pillAnimating = false
local pillT1, pillT2 = nil, nil
local pillGen = 0

-- active button's rect expressed in tabBar-local offsets
local function pillRectFor(button)
    return UDim2.new(0, button.AbsolutePosition.X - tabBar.AbsolutePosition.X,
                     0, button.AbsolutePosition.Y - tabBar.AbsolutePosition.Y),
           UDim2.new(0, button.AbsoluteSize.X, 0, button.AbsoluteSize.Y)
end

local function pillSnap(button)
    pillGen = pillGen + 1   -- v0.99: a snap supersedes every in-flight tween
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
    if pillT1 then pillT1:Cancel(); pillT1 = nil end
    if pillT2 then pillT2:Cancel(); pillT2 = nil end
    local targetPos, targetSize = pillRectFor(button)
    pillGen = pillGen + 1
    local gen = pillGen
    pillAnimating = true
    -- v0.0.98: the pill POP -- grows only HALF A PILL past the destination (hard
    -- cap, centered on the target so it reads as the pill swelling, not moving
    -- across), then the only move left is shrinking to the exact resting rect.
    -- No walk-span, no accumulation: a switch mid-flight cancels both tweens and
    -- the pop restarts from the CURRENT rect, so the pill can never grow forever.
    local w    = targetSize.X.Offset
    local ow   = w + w * 0.5
    local ox   = targetPos.X.Offset - (ow - w) * 0.5
    local y    = targetPos.Y.Offset
    local h    = targetSize.Y.Offset
    pillT1 = TweenService:Create(pill, PILL_STRETCH, {
        Position = UDim2.new(0, ox, 0, y),
        Size     = UDim2.new(0, ow, 0, h),
    })
    pillT1:Play()
    pillT1.Completed:Connect(function(state)
        if gen ~= pillGen then return end   -- superseded -- the newer switch owns everything
        if state ~= Enum.PlaybackState.Completed then return end
        if pillT2 then pillT2:Cancel() end
        pillT2 = TweenService:Create(pill, PILL_CONTRACT, {
            Position = targetPos,
            Size     = targetSize,
        })
        pillT2:Play()
        pillT2.Completed:Connect(function(_)
            if gen ~= pillGen then return end   -- stale: a newer pop or snap already owns the pill
            -- v0.98 hard rule: ANY finish clears the flag. A stale `true`
            -- permanently blocked pillResync and wedged the pill huge.
            pillAnimating = false
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
        -- v0.0.99: pure crossfade -- the outgoing panel fades out, the incoming
        -- fades in. No scale pop, no scroll jump: panels are ScrollingFrames so
        -- the fade lives on each tab's CanvasGroup wrapper (GroupTransparency).
        -- Panels get CanvasGroup wrappers in addTab; the wrapper's Visible flag
        -- is the real show/hide (GroupTransparency = 1 is not enough -- children
        -- of an invisible canvas can still eat input).
        local w = tab.Wrap
        if isActive then
            tab.Panel.CanvasPosition = Vector2.new(0, 0)
            w.GroupTransparency = 1
            w.Visible = true
            tween(w, Theme.Animation.Slow, { GroupTransparency = 0 })
            movePillTo(tab.Button)
        else
            tween(w, Theme.Animation.Slow, { GroupTransparency = 1 })
            task.delay(0.35, function()
                if activeTab ~= tabName then w.Visible = false end
            end)
        end
    end
end

-- v0.0.34: forward-declared shared upvalues. Config + team/friend helpers live inside
-- IIFEs so their locals get their OWN register budget (Luau's 200-local ceiling is
-- per-function; main chunk is already close). Only these handles are promoted so
-- ESP / World / Combat can call them.
-- Options flag + Team Check config:
--   MyTeams      : Team NAMES the user marked "my team" (allies -> skipped)
--   AdvancedTeam : use automatic isSameTeam heuristic instead of manual list
local Shared = { IgnoreFriends = false, AdvancedTeam = false, MyTeams = {} }
-- v0.0.97 Target Lock: type a player name, toggle the feature on, hit the keybind
-- to "activate" -- while active, the named player is the ONLY target for aimbot,
-- silent aim, trigger bot AND the only player ESP renders. Deactivate (hit the
-- keybind again) -> normal multi-target behaviour resumes. The toggle (Enabled)
-- arms the feature; the keybind (Active) engages / disengages the lock at runtime.
Shared.TargetLock = {
    Enabled  = false,   -- master toggle (arms the keybind)
    Name     = "",      -- target's username or display name (case-insensitive substring match)
    Key      = nil,     -- activation keybind (set via the keybind pill)
    _active  = false,   -- runtime: is the lock currently engaged?
}
-- resolve the current TargetLock.Name to a live Player or nil.
function Shared.targetLockPlayer()
    if not (Shared.TargetLock.Enabled and Shared.TargetLock._active) then return nil end
    local query = Shared.TargetLock.Name
    if not query or query == "" then return nil end
    query = query:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(query, 1, true) or plr.DisplayName:lower():find(query, 1, true) then
            return plr
        end
    end
    return nil
end
function Shared.targetLockMatches(plr)
    if not (Shared.TargetLock.Enabled and Shared.TargetLock._active) then return false end
    return Shared.targetLockPlayer() == plr
end
local isSameTeam, isFriend, registerConfig, rebuildConfigTabs, isTeammate
-- v0.0.97 hardening: give the forward-declared registerConfig a real default NOW so
-- a nil never reaches the registry call sites (the REAL definition is re-assigned
-- by the config IIFE below -- same local slot, later assignment wins at runtime).
registerConfig = function(name, tbl) end

-- v0.0.37: OS-level input from the Koffee Helper (Roblox can't see mouse 4/5).
-- The poll loop at the bottom of the file fills XB1/XB2; binds can be the virtual
-- strings "XButton1"/"XButton2" which the helper-driven Heartbeats resolve.
local Helper = { Connected = false, XB1 = false, XB2 = false }
local VIRTUAL_LABELS = { XButton1 = "xb1", XButton2 = "xb2" }
-- display text for ANY bind: virtual string, Roblox EnumItem, or nil.
-- v0.0.94: short-name modifier map for combo pill display ("LeftShift" -> "Shift").
local MOD_SHORT = {
    LeftShift = "Shift", RightShift = "Shift",
    LeftControl = "Ctrl", RightControl = "Ctrl",
    LeftAlt = "Alt",   RightAlt = "Alt",
}
local function keyLabel(bind)
    if bind == nil then return nil end
    if type(bind) == "string" then return VIRTUAL_LABELS[bind] or bind end
    if typeof(bind) == "EnumItem" then return bind.Name end
    -- v0.0.94 combo bind: { mod = KeyCode, key = KeyCode } -> "Shift+C"
    if type(bind) == "table" and bind.mod and bind.key then
        local m = (typeof(bind.mod) == "EnumItem") and (MOD_SHORT[bind.mod.Name] or bind.mod.Name) or tostring(bind.mod)
        local k = (typeof(bind.key) == "EnumItem") and bind.key.Name or tostring(bind.key)
        return m .. "+" .. k
    end
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
    -- v0.0.99: each panel sits inside a CanvasGroup wrapper so tab switches can
    -- CROSSFADE (ScrollingFrames have no GroupTransparency of their own). The
    -- wrap owns Visible; the panel owns scroll.
    local wrap = new("CanvasGroup", {
        Name = "Wrap",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 32,
        Parent = content,
    })
    local panel = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = true,
        ZIndex = 33,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Palette.TextFaint,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = wrap,
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
    -- NOTE: no popFx here -- tab labels must never squash/scale on press (per he).
    -- The pill's own pop is the tab switch's motion.

    -- v0.0.34: stash the build fn so the config system can re-run it against the
    -- same panel (clears children first) to push loaded values into every widget.
    tabs[name] = { Button = button, Panel = panel, Wrap = wrap, Build = buildFn }
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
    for _, n in ipairs({ "Visuals", "Combat", "World", "Character", "Options" }) do
        rebuildTabPanel(n)
    end
end

-- PANEL / CARD (grouped rounded container with optional title)
-- Matcha groups related controls in cards inside tab content.
-- Card auto-sizes vertically to fit its rows.
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
        corner(Theme.Radius.XLarge),
        stroke(Theme.Palette.BorderSubtle),
        -- v0.0.48: subtle top-lit gradient for depth. A UIGradient on a plain Frame
        -- only tints THIS frame's own background fill (children render on top,
        -- untouched -- unlike a CanvasGroup, which flattens + tints everything). The
        -- ramp is grayscale so it just darkens the card's lower half ~10%, giving each
        -- panel a soft light-from-above read instead of a flat slab.
        new("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(226, 226, 226)),
        }),
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
    -- v0.0.98: every card enters with a short fade + grow when its tab first
    -- builds (rebuildConfigTabs re-runs build fns, so cards re-pop on reload too).
    -- GroupTransparency only exists on CanvasGroups, and cards stay plain Frames
    -- (their own UIGradient must not flatten children), so the entrance is a pure
    -- scale pop -- same quick-arrive feel, zero alpha dependency.
    local sc = uScaleOf(card)
    sc.Scale = 0.96
    task.delay(0.03, function()
        if not card.Parent then return end
        tween(sc, Theme.Animation.Normal, { Scale = 1 })
    end)
    return card
end

-- HOVER helper: adds a subtle background overlay that fades in/out
-- when the target's TextButton child is hovered. Idempotent per row.
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

-- CHECKBOX (visual primitive shared by module + config variants)
-- v0.0.12 semantics per he:
--   OFF -> ON  = fill GROWS OUTWARD from middle (size 0 -> INNER, opaque throughout)
--   ON  -> OFF = fill SHRINKS INWARD to middle (size INNER -> 0) with a super-fast
--                fade tail so it doesn't pop out of existence
-- Also cancels any in-flight tweens on each state change so rapid clicking can't
-- stack animations and desync the visual from the actual state.
local CBOX = { h = 22, outer = 16, inner = 12, off = 26, reserve = 74 }

local function checkboxVisual(parent, label, initialOn)
    local state = initialOn and true or false
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, CBOX.h),
        BackgroundTransparency = 1,
        ZIndex = 34,
        Parent = parent,
    })
    -- outer box: subtle panel-elevated bg, no stroke
    local box = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, CBOX.outer, 0, CBOX.outer),
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
        Size = state and UDim2.new(0, CBOX.inner, 0, CBOX.inner)
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
        Position = UDim2.new(0, CBOX.off, 0, 0),
        Size = UDim2.new(1, -CBOX.off - CBOX.reserve, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 35,
        Parent = row,
    })
    local btn = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -CBOX.reserve, 1, 0),
        ZIndex = 37,
        AutoButtonColor = false,
        Parent = row,
    })
    attachHover(row, btn)
    popFx(btn)   -- v0.0.98: checkbox rows squash on press

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
                Size = UDim2.new(0, CBOX.inner, 0, CBOX.inner),
            })
            pulse(box, 1.12)   -- v0.0.98: box ticks out as the fill grows in
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

-- KEYBIND SYSTEM + KEYBIND PILL
-- Keybinds table maps moduleId -> KeyCode. InputBegan at bottom of file
-- reads it. Pill widget shows current key + click-to-rebind flow.
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
        pulse(pill, 1.1)   -- v0.0.98: pill ticks when the rebind arms
        pendingRebind = { moduleId = moduleId, pill = pill }
    end)
    popFx(pill)
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

-- COLOR PICKER (popup: SV area + hue slider + hex input)
-- Parented to `screen` so it renders above the window CanvasGroup.
-- Reused across all color swatches -- one picker instance, retargeted.
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
    local rsc = uScaleOf(ColorPicker.root)   -- v0.0.98: picker grows open
    rsc.Scale = 0.94
    tween(ColorPicker.root, Theme.Animation.Menu, {
        BackgroundTransparency = 0.02,
        Position = UDim2.new(0, x, 0, y),
    })
    tween(rsc, Theme.Animation.Menu, { Scale = 1 })
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

-- COLOR SWATCH: clickable, opens picker; also hover-shows a tooltip preview
-- Optional { onChange = fn(newColor), getColor = fn() -> Color3 } table.
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
    popFx(sw)   -- v0.0.98: swatches squash on press

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

-- DROPDOWN (label above + button that opens popup list below)
-- Popup is parented to `screen` (NOT the panel/window) so it renders
-- above the CanvasGroup and isn't clipped by it. Positioned each open
-- from the button's AbsolutePosition. Slide+fade animation. Chevron
-- arrow built from two rotated 1px lines. Closes on outside click.
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
    -- v0.0.12: RenderStepped lock keeps popup glued below the button even when it shifts
    -- (scroll, tab-switch, drag) -- calculate every frame, not once at open.
    local positionConn = nil
    -- v0.0.20: rule-based placement: anchor list TOP-LEFT to button bottom-left every
    -- frame, clamp X to viewport, flip above when no room below. All from live rect.
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
        -- v0.0.17: option button bg stays at transparency 1 (hover drives it to 0.7).
        -- Only the text labels need to fade out.
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
        for _, entry in pairs(openDropdowns) do
            if entry.close ~= closeList then entry.close(true) end
        end
        isOpen = true
        openDropdowns[list] = { btn = btn, close = closeList }
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
        -- v0.0.98: popup drops open with a quick grow (scale from 0.92) instead
        -- of materialising -- same Menu timing as the fade so they land together.
        local usc = uScaleOf(list)
        usc.Scale = 0.92
        tween(usc, Theme.Animation.Menu, { Scale = 1 })
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
            pulse(valueLbl, 1.08)   -- v0.0.98: value ticks on pick
            closeList()
            if onChange then onChange(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    popFx(btn)   -- v0.0.98: dropdowns squash on press
    return {
        frame = wrap,
        button = btn,
        setValue = function(v) valueLbl.Text = v end,
        close = function() closeList(true) end,
        -- v0.0.47: full teardown -- the popup `list` lives on popupScreen (not a
        -- child of wrap), so destroying the wrap alone leaks it. Callers that
        -- rebuild a dropdown (e.g. the config manager's live selector) use this.
        destroy = function() closeList(true); list:Destroy(); wrap:Destroy() end,
    }
end

-- outside-click closer: closes any open dropdown OR color picker if click missed
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = input.Position

    -- dropdowns. Skip the click that lands ON a list's own button -- that click
    -- is handled by the button's own toggle handler, so the closer must not close
    -- first (otherwise: press closes on mouse-down via the closer, release
    -- reopens on the button's click -- the flicker/reopen the closer caused).
    for list, entry in pairs(openDropdowns) do
        local abs = list.AbsolutePosition
        local siz = list.AbsoluteSize
        local inside = mp.X >= abs.X and mp.X <= abs.X + siz.X
                   and mp.Y >= abs.Y and mp.Y <= abs.Y + siz.Y
        local playsOwnToggle = false
        if entry.btn then
            local babs = entry.btn.AbsolutePosition
            local bsiz = entry.btn.AbsoluteSize
            playsOwnToggle = mp.X >= babs.X and mp.X <= babs.X + bsiz.X
                        and mp.Y >= babs.Y and mp.Y <= babs.Y + bsiz.Y
        end
        if not inside and not playsOwnToggle then entry.close() end
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

-- SLIDER (thicker track, bigger knob, knob color contrasts fill)
-- Value doubles as click-to-edit TextBox with a hover-pill background.
local function slider(parent, label, min, max, initial, precision, onChange, opts)
    precision = precision or 0
    opts = opts or {}   -- v0.0.56: opts.infinite -> value at max shows "Infinite", onChange gets math.huge
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
        Text = (opts.infinite and current >= max) and "Infinite" or tostring(current),
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
    -- v0.0.99: a proper knob -- small ball at the fill tip (AnchorPoint 0.5,0.5 so
    -- it sits ON the tip, straddling the fill edge, instead of hanging off it).
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(startPct, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Theme.Palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 36,
        Parent = track,
    }, { corner(6), stroke(Theme.Palette.Border, 1) })
    -- v0.0.99: drag area is the ENTIRE row width (was reserving 86px for the value
    -- box -- when the fill sat far right, the last 86px of the track was dead
    -- space and the knob end was unreachable). The value box lives at the top of
    -- the row, nowhere near the track, so nothing needs reserving.
    local hitArea = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 37,
        Parent = row,
    })
    local dragging = false

    local function applyValue(animate)
        local pct = (current - min) / (max - min)
        if animate then
            tween(fill, Theme.Animation.Fast, { Size = UDim2.new(pct, 0, 1, 0) })
            tween(knob, Theme.Animation.Fast, { Position = UDim2.new(pct, 0, 0.5, 0) })
        else
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
        end
        if animate then pulse(track, 1.02) end   -- v0.0.98: track ticks on settle
        local atMax = opts.infinite and current >= max
        valueBox.Text = atMax and "Infinite" or tostring(current)
        if onChange then onChange(atMax and math.huge or current) end
    end
    local function setFromInputX(inputX)
        local trackAbs = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        if trackW <= 0 then return end
        local pct = math.clamp((inputX - trackAbs) / trackW, 0, 1)
        current = round(min + (max - min) * pct)
        applyValue(false)
    end
    UserInputService.InputChanged:Connect(function(input)
        if dragging
        and (input.UserInputType == Enum.UserInputType.MouseMovement
          or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInputX(input.Position.X)
        end
    end)
    -- v0.0.98: track squashes to 0.98 while the drag grabs it, springs back on
    -- release (both on the button's own end AND the service end as a failsafe).
    hitArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tween(uScaleOf(hitArea), Theme.Animation.Fast, { Scale = 0.98 })
            setFromInputX(input.Position.X)
        end
    end)
    hitArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            tween(uScaleOf(hitArea), Theme.Animation.Fast, { Scale = 1 })
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging
        and (input.UserInputType == Enum.UserInputType.MouseButton1
          or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(uScaleOf(hitArea), Theme.Animation.Fast, { Scale = 1 })
        end
    end)
    valueBox.FocusLost:Connect(function(enterPressed)
        if opts.infinite and valueBox.Text:lower():find("inf") then
            current = max
        else
            local n = tonumber(valueBox.Text)
            if n then current = round(math.clamp(n, min, max)) end
        end
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

-- RIGHT-CLICK SETTINGS POPUP (v0.0.25)
-- Right-click a config row to open a small floating panel of extra controls
-- (built by the caller via api:slider(...)). Lives in popupScreen like the
-- dropdowns / colour picker, positioned inset-safe, closes on outside click.
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
        local api = { frame = popupFrame }   -- v0.0.46: expose parent for custom content
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
        local psc = uScaleOf(popupFrame)   -- v0.0.98: settings popup grows open
        psc.Scale = 0.94
        tween(psc, Theme.Animation.Menu, { Scale = 1 })
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

-- v0.0.46: shared Team Check settings popup. Lists every Team as an ally toggle (ticked = skip in ESP/aim).
-- "Advanced" ignores the manual list, uses the automatic isSameTeam heuristic, and greys the list out.
local function teamCheckSettings(api)
    local frame = api.frame
    local dimGroups = {}
    local function refreshDim()
        local t = Shared.AdvancedTeam and 0.62 or 0
        for _, cg in ipairs(dimGroups) do cg.GroupTransparency = t end
    end
    api:toggle("Advanced", Shared.AdvancedTeam, function(v)
        Shared.AdvancedTeam = v
        refreshDim()
    end)
    local teams = {}
    pcall(function() teams = game:GetService("Teams"):GetTeams() end)
    if #teams == 0 then
        new("TextLabel", {
            Text = "no teams in this game -- use Advanced",
            FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
            TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, ZIndex = 212, Parent = frame,
        })
    end
    for _, team in ipairs(teams) do
        local name = team.Name
        -- CanvasGroup so GroupTransparency dims the whole row uniformly when greyed.
        local cg = new("CanvasGroup", {
            Size = UDim2.new(1, 0, 0, CBOX.h),
            BackgroundTransparency = 1, GroupTransparency = 0,
            BorderSizePixel = 0, ZIndex = 211, Parent = frame,
        })
        local ctrl = checkboxVisual(cg, name, Shared.MyTeams[name] == true)
        ctrl.button.MouseButton1Click:Connect(function()
            if Shared.AdvancedTeam then return end   -- greyed out: ignore clicks
            local ns = not ctrl.getState()
            ctrl.setState(ns)
            Shared.MyTeams[name] = ns and true or nil
        end)
        dimGroups[#dimGroups + 1] = cg
    end
    refreshDim()
end

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

-- v0.0.46: the "is this player an ally to skip?" gate every Team Check reads.
--   Advanced ON  -> automatic isSameTeam (robust for FFA / TDM / single-Team games).
--   Advanced OFF -> manual: ally iff player's Team name is in Shared.MyTeams (right-click list).
function isTeammate(plr)
    if not plr or plr == LocalPlayer then return false end
    if Shared.AdvancedTeam then return isSameTeam(plr) end
    local t = plr.Team
    return t ~= nil and Shared.MyTeams[t.Name] == true
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
        if v ~= v then return "0" end                       -- NaN -> 0
        if v == math.huge then return "math.huge" end        -- v0.0.56: "Infinite" sliders round-trip
        if v == -math.huge then return "-math.huge" end
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
-- v0.0.50: SET-shaped tables must be REPLACED, not deep-merged. `MyTeams` is a
-- name-set where unticking a team does `MyTeams[name] = nil` -- an absent key IS
-- the "not my team" value. Deep-merging can only ADD keys, so loading a config
-- left every previously-ticked team behind and the player kept being treated as
-- an ally. (Flagged as a caveat when MyTeams shipped in v0.0.46.) Cleared IN
-- PLACE rather than reassigned so live references to the table keep working --
-- the same reason the whole loader applies in place.
-- Deep-merge stays the default: every other registered table is a fixed schema
-- where a missing key means "this config predates the field", not "unset it".
local REPLACE_TABLES = { MyTeams = true }
local function applyInto(target, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(target[k]) == "table" then
            if REPLACE_TABLES[k] then
                for old in pairs(target[k]) do target[k][old] = nil end
            end
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
    -- per-game custom-anim list (place 155615604): a config saved in another
    -- game can carry an animation Name that doesn't exist in THIS game's list.
    -- Snap it before the tab rebuild renders the dropdown (reads the live
    -- registered table, freshly merged above; the per-game lists are seeded
    -- onto Koffee by the character-visual IIFE).
    local ca = ConfigRegistry and ConfigRegistry["custom_anim"]
    if ca then
        local ids = Koffee._animIDs
        if ids and not ids[ca.Name] then
            local opts = Koffee._animDropdown
            ca.Name = (opts and opts[1]) or "Orbit 1"
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
    -- v0.0.96: the Arraylist option is registered state too, so a load can flip
    -- it -- re-apply the actual column visibility (the rebuilt tab's checkbox
    -- reads KoffeeOptions but nothing drives the live column off it).
    if labelsColumn then labelsColumn.Visible = KoffeeOptions.Arraylist == true end
    -- v0.0.97: a loaded config can flip CustomFontOn / change the font / size --
    -- push those into the Theme so the feature interface reflects the saved state.
    pcall(function()
        Theme.setFeiSize(KoffeeOptions.CustomFontSize)
        Theme.setFeiOn(KoffeeOptions.CustomFontOn == true)
        if KoffeeOptions.CustomFontOn then Theme.setFeiFont(KoffeeOptions.CustomFontName) end
        -- v0.0.99: mirror the MI font toggle across config loads (fonts + tab
        -- rebuilds happen together; re-apply AFTER the rebuild so fresh labels
        -- get the swap too). loadSnapshot's rebuildConfigTabs ran above.
        Theme.applyMIFont(window, KoffeeOptions.MIFontOn and Theme.loadFeiFont(KoffeeOptions.MIFontName) or nil,
            KoffeeOptions.MIFontOn and KoffeeOptions.MIFontSize or nil)
    end)
    -- v0.0.97: Target Lock runtime state must not ride a config load -- a save
    -- taken mid-engagement would resurrect a stale lock after switching configs.
    if Shared.TargetLock then Shared.TargetLock._active = false end
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
    -- v0.0.50 fix: `return loadSnapshot(data), name` handed the CONFIG NAME back as
    -- the second return on failure, so the UI printed "load failed: <name>" instead
    -- of a reason. Split the two paths so the error slot always carries an error.
    if not loadSnapshot(data) then return false, "bad config data" end
    return true, name
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

-- ESP MODULE (v0.0.10)
-- Master toggle ("Enabled") just turns on the ESP framework + render loop.
-- Nothing draws until a sub-feature (Box / Name / Indicators / Health /
-- Tracer) is enabled -- the master applies no color to players on its own.
--
-- Config groups:
--   Config (ESP-level toggles) -- shared across future widgets
--   Boxes (Boxes widget config)
--   Colors (color pool)
local ESP = {
    Config = {
        -- TextBackground: shared bool for future text modules (Names/Distance/Health
        -- all read the same preference). No module renders text yet; config-only.
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
        -- v0.0.17: Outline is a thickness ACCENT (not a gate): +1px on all box lines when on.
        -- v0.0.19: Glow removed; Outline no longer controls the arraylist accent line.
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

-- v0.0.19: applyGlobalOutline removed. Outline is purely a box thickness accent now;
-- the arraylist accent line stays at its default transparency (0.15) permanently.
-- Future accent needs: build a dedicated "Accent Line" toggle, don't hijack Outline.

-- v0.0.76: Outline now ALSO drives an outline around every arraylist label. Each
-- label carries a KArrayStroke (added in addToActiveArray, disabled by default);
-- this heartbeat toggles + tints it live off ESP.Config.Outline + ESP.Boxes.OutlineColor.
-- Kept here (after ESP is defined) so the upvalue resolves cleanly -- addToActiveArray
-- sits above ESP in the file and can't reference it directly.
-- v0.1.0: textGradSeq/gradOffset are defined further down (after makeGradSeqGetter),
-- so a bare reference here would bind to a nil GLOBAL and crash the heartbeat the
-- moment TextGradient toggles on. Pre-declare the slots; they get filled below.
local textGradSeq = nil
local gradOffset = nil
local lineGradSeq = nil
RunService.Heartbeat:Connect(function()
    local on = ESP.Config.Outline == true
    local col = ESP.Boxes.OutlineColor
    -- v0.0.95: text gradient sync -- same loop for the KArrayGrad UIGradient.
    -- When ESP.Config.TextGradient is on, we apply the same gradient sequence
    -- ESP text labels use (textGradSeq with GradientColorA/B, Rotation, Spacing,
    -- animated offset) so arraylist reads exactly like the ESP text.
    local gradOn = ESP.Config.TextGradient == true
    local gSeq, gRot, gOff
    if gradOn then
        gSeq = textGradSeq(ESP.Config.GradientColorA, ESP.Config.GradientColorB, ESP.Config.GradientSpacing)
        gRot = ESP.Config.GradientRotation
        gOff = gradOffset()
    end
    for _, m in ipairs(shown) do
        local lbl = m._arrayLabel
        if lbl and lbl.Parent then
            local s = lbl:FindFirstChild("KArrayStroke")
            if s then
                local strokeEnabled, strokeColor, strokeSize
                if KoffeeOptions.ArraylistOutline then
                    strokeEnabled = true
                    strokeSize = KoffeeOptions.ArraylistOutlineSize
                    strokeColor = Color3.new(0, 0, 0)
                else
                    strokeEnabled = on
                    strokeSize = 1
                    strokeColor = col
                end
                if s.Enabled ~= strokeEnabled then s.Enabled = strokeEnabled end
                if s.Thickness ~= strokeSize then s.Thickness = strokeSize end
                if s.Color ~= strokeColor then s.Color = strokeColor end
            end
            local g = lbl:FindFirstChild("KArrayGrad")
            if g then
                if g.Enabled ~= gradOn then g.Enabled = gradOn end
                -- v0.0.97: UIGradient does not render on RichText labels (Roblox
                -- limitation -- the gradient is silently ignored when RichText is on).
                -- When the gradient is active, flip RichText off + use the plain-text
                -- label so the gradient's ColorSequence actually paints the glyphs.
                -- When off, flip RichText back on for the per-span size/colour hierarchy.
                if gradOn then
                    if lbl.RichText then lbl.RichText = false end
                    local pt = arrayPlainText(m)
                    if lbl.Text ~= pt then lbl.Text = pt end
                    g.Color    = gSeq
                    g.Rotation = gRot
                    g.Offset   = gOff
                    if lbl.TextColor3 ~= Color3.new(1, 1, 1) then
                        lbl.TextColor3 = Color3.new(1, 1, 1)
                    end
                else
                    if not lbl.RichText then lbl.RichText = true end
                    local rt = buildArrayLabelText(m)
                    if lbl.Text ~= rt then lbl.Text = rt end
                    if lbl.TextColor3 == Color3.new(1, 1, 1) then
                        lbl.TextColor3 = Theme.Palette.Text
                    end
                end
            end
        end
    end
end)

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
local FILL = { max = 40, step = 5 }

local function makeFillRows(parent)
    -- v0.0.22: CanvasGroup flattens overlapping strips into ONE layer before transparency,
    -- killing the double-darkened seams the old stack produced. Strips are opaque;
    -- the group carries ~0.72 translucency.
    -- v0.0.29: group carries a KGrad for the Gradient toggle. UIGradient on a
    -- CanvasGroup spans only the group's rect, so render resizes it to the fill AABB.
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
    for _ = 1, FILL.max do
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
    -- v0.0.97: feature-interface font system (custom font + global size)
    txt.FontFace, txt.TextSize = Theme.fei(txt, "Medium", 12)
    return bg, fill, txt
end

-- v0.0.26: name / profile picture / distance are SCREEN-SPACE (2D) elements in
-- the box layer, positioned each frame from the projected head/feet. A 3D
-- BillboardGui drifted onto the head at some camera angles ("name inside the
-- head"); screen-space keeps text ALWAYS directly above the head / below the feet
-- no matter where the camera points.
local function makeTextTag(parent, anchorY, textSize)
    local lbl = new("TextLabel", {
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
    -- v0.0.97: feature-interface font system. The ESP render loop re-applies
    -- textSize per-frame from ESP.Names.TextSize / Distance.TextSize; that loop
    -- also honours FeiScale (see the render step), so registration here lets the
    -- hot-swap propagate to every pooled name / distance tag automatically.
    Theme.fei(lbl, "Medium", textSize)
    return lbl
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

    -- v0.0.14: BillboardGui + name/dist/textBg moved to dedicated overlay modules.
    -- ESP rig now contains only box widget state -- clean split by concern.

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
        -- v0.0.15: staticSize snapshot dropped; distance/FOV drive size, so no per-rig snapshot is meaningful.
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

-- v0.0.13 orphan-box fix: previous applyESP didn't clean the old rig on CharacterAdded, so
-- boxRoot/cubeEdges/halo/bb from dead characters stayed in ESP.BoxLayer forever
-- ("boxes stick after death", "new round doesn't work"). Fix: clean before creating, and hook
-- CharacterRemoving so visuals disappear the frame the character despawns.
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
            local old = character:FindFirstChild(KID.name("esp_layer"))
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
local STATIC = { top = 3, bot = 3, aspect = 0.5 }   -- fallback width = height * 0.5 (used only if no bbox)

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
        topWorld = pos + Vector3.new(0, STATIC.top, 0)
        botWorld = pos + Vector3.new(0, -STATIC.bot, 0)
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
    if not width or width <= 0 then width = height * STATIC.aspect end
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
textGradSeq = makeGradSeqGetter()
lineGradSeq = makeGradSeqGetter()
-- animated offset (Vector2) along the gradient's rotation, speed + reverse aware.
gradOffset = function()
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
        rig.nameLbl.TextSize = Theme.FeiOn
            and math.round((names.TextSize or 14) * Theme.FeiScale)
            or  (names.TextSize or 14)
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
            rig.distLbl.TextSize = Theme.FeiOn
                and math.round((distCfg.TextSize or 13) * Theme.FeiScale)
                or  (distCfg.TextSize or 13)
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
        -- v0.0.46: team gate via isTeammate (manual team list or Advanced auto-detect)
        -- + Options "Ignore Friends" gate, shared with the combat systems.
        local same = isTeammate(plr)
        if (same and ESP.Config.TeamCheck) or (Shared.IgnoreFriends and isFriend(plr)) then
            hideRigVisuals(rig); continue
        end
        -- v0.0.97 TARGET LOCK: while engaged, only the named player's rig renders.
        if Shared.TargetLock.Enabled and Shared.TargetLock._active
        and Shared.targetLockPlayer() ~= plr then
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
                local rowCount = math.clamp(math.floor(totalH / FILL.step), 1, FILL.max)
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
                for i = 1, FILL.max do
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
            -- v0.0.81: bar width proportional to the ON-SCREEN body height so both
            -- dimensions shrink together as the target moves away -- reads correctly
            -- at any range. Was distance-scaled in v0.0.76 which made the bar THICKER
            -- as the body got SMALLER (opposite of natural). Clamp 1..6 keeps it
            -- visible at extreme range without dominating at point-blank.
            local barW = math.clamp((hbBot - hbTop) * 0.04, 1, 6)
            local barLeft = ESP.Boxes.Enabled and tX or hbLeft
            rig.healthBg.Position = UDim2.new(0, barLeft - 2 - barW, 0, hbTop)
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

-- WORLD MODULES: fullbright, no fog, custom time
-- Each module saves the original Lighting values on enable and restores on disable.
-- v0.0.17: all three now install a Heartbeat that re-asserts values so
-- server-side day/night cycles / dynamic weather can't override us.
local World = {
    Fullbright = { Saved = nil, Conn = nil },
    NoFog      = { Saved = nil, Conn = nil },
    Time       = { Saved = nil, Target = 14, Conn = nil },
    -- v0.0.100: effects batch
    CC     = { Saved = nil, Conn = nil, Owned = nil, Saturation = 0, Contrast = 0, Brightness = 0, Tint = Color3.fromRGB(255, 255, 255) },
    Light  = { Saved = nil, Conn = nil, Color = Color3.fromRGB(255, 255, 255), Intensity = 1 },
    Sky    = { Saved = nil, Conn = nil },
    Clouds = { Saved = nil, Conn = nil },
    Gfx    = { Saved = nil },
}

-- v0.0.34: only the Clock Time target persists (Saved/Conn are runtime + skipped
-- by the serializer). Fullbright/NoFog are pure toggles -> restored via modules.
registerConfig("world_time", World.Time)
-- v0.0.100: slider/swatch values for the effects batch persist; Saved/Conn don't.
registerConfig("world_cc", World.CC)
registerConfig("world_light", World.Light)

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

-- WORLD EFFECTS (v0.0.100): color correction, ambient tint, sky/clouds kill,
-- low graphics. Same save/restore + Heartbeat re-assert pattern as above.

registerModule("colorcorrection", "Color Correction",
    function()
        local fx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if fx then
            World.CC.Owned = false
        else
            fx = Instance.new("ColorCorrectionEffect")
            fx.Name = "KoffeeCC"
            fx.Parent = Lighting
            World.CC.Owned = true
        end
        World.CC.Saved = {
            Origin = fx.Origin, Saturation = fx.Saturation,
            Contrast = fx.Contrast, Brightness = fx.Brightness, TintColor = fx.TintColor,
        }
        World.CC.Conn = RunService.Heartbeat:Connect(function()
            local f = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if not f then
                f = Instance.new("ColorCorrectionEffect")
                f.Name = "KoffeeCC"
                f.Parent = Lighting
                World.CC.Owned = true
            end
            f.Saturation = World.CC.Saturation
            f.Contrast   = World.CC.Contrast
            f.Brightness = World.CC.Brightness
            f.TintColor  = World.CC.Tint
        end)
    end,
    function()
        if World.CC.Conn then World.CC.Conn:Disconnect(); World.CC.Conn = nil end
        local fx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        local s = World.CC.Saved
        if fx and s then
            if World.CC.Owned then
                fx:Destroy()
            else
                fx.Origin = s.Origin; fx.Saturation = s.Saturation
                fx.Contrast = s.Contrast; fx.Brightness = s.Brightness
                fx.TintColor = s.TintColor
            end
        end
        World.CC.Saved = nil; World.CC.Owned = nil
    end
)

registerModule("ambientcolor", "Ambient Color",
    function()
        World.Light.Saved = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
        World.Light.Conn = RunService.Heartbeat:Connect(function()
            local c = World.Light.Color * World.Light.Intensity
            Lighting.Ambient = c
            Lighting.OutdoorAmbient = c
        end)
    end,
    function()
        if World.Light.Conn then World.Light.Conn:Disconnect(); World.Light.Conn = nil end
        local s = World.Light.Saved
        if not s then return end
        Lighting.Ambient = s.Ambient
        Lighting.OutdoorAmbient = s.OutdoorAmbient
        World.Light.Saved = nil
    end
)

registerModule("removesky", "Remove Sky",
    function()
        local skies = {}
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then table.insert(skies, { sky = sky, parent = sky.Parent }) end
        end
        for _, w in ipairs(workspace:GetChildren()) do
            if w:IsA("Sky") then table.insert(skies, { sky = w, parent = w.Parent }) end
        end
        World.Sky.Saved = skies
        for _, e in ipairs(skies) do e.sky.Parent = nil end
        World.Sky.Conn = RunService.Heartbeat:Connect(function()
            for _, e in ipairs(World.Sky.Saved or {}) do e.sky.Parent = nil end
        end)
    end,
    function()
        if World.Sky.Conn then World.Sky.Conn:Disconnect(); World.Sky.Conn = nil end
        local s = World.Sky.Saved
        if not s then return end
        for _, e in ipairs(s) do
            if e.parent then e.sky.Parent = e.parent end
        end
        World.Sky.Saved = nil
    end
)

registerModule("noclouds", "Disable Clouds",
    function()
        local list = {}
        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Clouds") then table.insert(list, { c = c, on = c.Enable }) end
        end
        World.Clouds.Saved = list
        for _, e in ipairs(list) do e.c.Enable = false end
        World.Clouds.Conn = RunService.Heartbeat:Connect(function()
            for _, c in ipairs(workspace:GetChildren()) do
                if c:IsA("Clouds") and c.Enable then c.Enable = false end
            end
        end)
    end,
    function()
        if World.Clouds.Conn then World.Clouds.Conn:Disconnect(); World.Clouds.Conn = nil end
        local s = World.Clouds.Saved
        if not s then return end
        for _, e in ipairs(s) do e.c.Enable = e.on end
        World.Clouds.Saved = nil
    end
)

registerModule("lowgfx", "Low Graphics",
    function()
        local rs = settings().Rendering
        World.Gfx.Saved = rs.QualityLevel
        pcall(function() rs.QualityLevel = 1 end)
    end,
    function()
        local s = World.Gfx.Saved
        if s == nil then return end
        pcall(function() settings().Rendering.QualityLevel = s end)
        World.Gfx.Saved = nil
    end
)

-- MOVEMENT MODULES (v0.0.49)
-- No Jump Cooldown / Infinite Jump. Both bypass client anti-jumps that throttle via
-- GetPropertyChangedSignal("Jump") -- we drive ChangeState(Jumping) instead, so their
-- watcher never fires.
--   Infinite Jump    = jump on every request, air included.
--   No Jump Cooldown = same bypass, grounded-only (kills throttle, keeps gravity).
-- One shared JumpRequest handler reads both states; OnEnable/OnDisable are no-ops.
-- JumpRequest is universal (keyboard/mobile/gamepad); humanoid re-resolved per press
-- for respawn-safety.
registerModule("nojumpcd", "No Jump Cooldown", function() end, function() end)
registerModule("infjump",  "Infinite Jump",    function() end, function() end)

UserInputService.JumpRequest:Connect(function()
    local inf = Modules.infjump  and Modules.infjump.Enabled
    local njc = Modules.nojumpcd and Modules.nojumpcd.Enabled
    if not (inf or njc) then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if not inf and hum.FloorMaterial == Enum.Material.Air then return end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- MOVEMENT SUITE (v0.0.52)
-- Character-tab movement features with a two-step activation model (per He): the
-- checkbox ARMS a feature, a per-feature keybind ACTIVATES it (pill: left-click =
-- rebind, right-click = Hold/Toggle). Enable, then hold/press the key to use.
-- Antifling is the lone exception -- no key, on = on. Own IIFE for the ~200-local
-- budget (same reason as Combat). Tab builder is published on Koffee._characterTab
-- so the Character addTab (below, in normal tab order) can call it.
;(function()

local UIS = UserInputService
local function char()   return LocalPlayer.Character end
local function humOf()  local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf()
    local c = char(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or (humOf() and humOf().RootPart) or c.PrimaryPart
end
local function camCF() local cc = Workspace.CurrentCamera; return cc and cc.CFrame end

-- persisted config. Key = EnumItem/string/nil, Mode = "Hold"|"Toggle", speeds numeric.
local Move = {
    WalkSpeed    = { Speed = 60,  Key = nil, Mode = "Hold"   },
    TeleportWalk = { Speed = 80,  Key = nil, Mode = "Hold"   },
    Fly          = { Speed = 120, Key = nil, Mode = "Toggle", Kind = "Default Fly" },
    Spin         = { Speed = 600, Key = nil, Mode = "Toggle", BypassCameraLock = false },
    Noclip       = {              Key = nil, Mode = "Toggle" },
    Float        = { Speed = 50,  Key = nil, Mode = "Hold"   },
    ClickTP      = {              Key = nil, Mode = "Toggle" },
}
registerConfig("movement", Move)

-- id -> its config sub-table (activation pills + input matching)
local CustomAnimCFG = { Key = nil, Mode = "Toggle", Name = "Orbit 1" }
local CFG = {
    walkspeed = Move.WalkSpeed, teleportwalk = Move.TeleportWalk, fly = Move.Fly,
    spinbot = Move.Spin, noclip = Move.Noclip, float = Move.Float, clicktp = Move.ClickTP,
    customanim = CustomAnimCFG,
}
-- v0.0.96: CustomAnim got its own registry slot. Its Key/Mode live here (off
-- the movement CFG table) and the Name field must survive a config save/load just
-- like every other dropdown value -- without this it only rode along implicitly
-- through Visual.CustomAnim and could be lost when the CFG was reloaded.
registerConfig("custom_anim", CustomAnimCFG)

-- held[id] = keybind-driven "active" flag; a feature RUNS only when its module is
-- Enabled (armed) AND held (activated).
local held = {}
local function isActive(id)
    local m = Modules[id]
    return (m and m.Enabled and held[id]) or false
end

local function matchBind(input, bind)
    if typeof(bind) ~= "EnumItem" then return false end
    if bind.EnumType == Enum.KeyCode then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
    elseif bind.EnumType == Enum.UserInputType then
        return input.UserInputType == bind
    end
    return false
end

--== movers (BodyVelocity/BodyGyro -- universal, KID-tracked for cleanup) ==--
local st = {}
local function makeBV(part, maxForce)
    local bv = new("BodyVelocity", { Name = KID.name("m_bv"), MaxForce = maxForce, Velocity = Vector3.zero, P = 1250 })
    KID.track(bv); bv.Parent = part; return bv
end
local function makeBG(part)
    local bg = new("BodyGyro", { Name = KID.name("m_bg"), MaxTorque = Vector3.new(4e5, 4e5, 4e5), P = 3e4, D = 500 })
    KID.track(bg); bg.Parent = part; return bg
end
local function killMover(s)
    if not s then return end
    if s.bv then pcall(function() s.bv:Destroy() end); s.bv = nil end
    if s.bg then pcall(function() s.bg:Destroy() end); s.bg = nil end
    s.part = nil
end

-- world-space fly/float direction from WASD + camera (+ vertical keys)
local function moveVector(includeVertical)
    local cf = camCF(); if not cf then return Vector3.zero end
    local v = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then v = v + cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then v = v - cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then v = v + cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then v = v - cf.RightVector end
    if includeVertical then
        if UIS:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            v = v - Vector3.new(0, 1, 0)
        end
    end
    if v.Magnitude > 0 then v = v.Unit end
    return v
end

--== per-feature on/off/step (driven by the edge loop below) ==--
local FEAT = {}

FEAT.walkspeed = {
    on   = function() local h = humOf(); st.walkspeed = { orig = h and h.WalkSpeed or 16 } end,
    off  = function() local h = humOf(); if h and st.walkspeed then pcall(function() h.WalkSpeed = st.walkspeed.orig end) end st.walkspeed = nil end,
    step = function() local h = humOf(); if h then h.WalkSpeed = Move.WalkSpeed.Speed end end,
}

FEAT.teleportwalk = {
    step = function(dt)
        local h, r = humOf(), rootOf(); if not (h and r) then return end
        local d = h.MoveDirection
        if d.Magnitude > 0 then r.CFrame = r.CFrame + d * (Move.TeleportWalk.Speed * dt) end
    end,
}

FEAT.fly = {
    on  = function() st.fly = {} end,
    off = function()
        killMover(st.fly)
        local h = humOf(); if h then h.PlatformStand = false end
        local c = char(); local head = c and c:FindFirstChild("Head")
        if head then head.Anchored = false end
        st.fly = nil
    end,
    step = function(dt)
        local s = st.fly; if not s then return end
        local h, r = humOf(), rootOf(); if not (h and r) then killMover(s); return end
        local kind, speed = Move.Fly.Kind, Move.Fly.Speed
        local c = char(); local head = c and c:FindFirstChild("Head")
        if kind == "CFrame Fly" then
            killMover(s)
            speed = math.min(speed, 1000)
            if not head then return end
            h.PlatformStand = true; head.Anchored = true
            local v = moveVector(true)
            if v.Magnitude > 0 then head.CFrame = head.CFrame + v * (speed * dt) end
        else
            if head and head.Anchored then head.Anchored = false end
            local target = r
            if kind == "Vehicle Fly" then
                local seat = h.SeatPart
                if seat then target = seat.AssemblyRootPart or seat end
            end
            if s.part ~= target or not (s.bv and s.bv.Parent) then
                killMover(s); s.part = target
                s.bv = makeBV(target, Vector3.new(9e9, 9e9, 9e9))
                s.bg = makeBG(target)
            end
            h.PlatformStand = true
            s.bv.Velocity = moveVector(true) * speed
            local cf = camCF(); if cf and s.bg then s.bg.CFrame = cf end
        end
    end,
}

-- v0.0.97 Spinbot rewrite -- single path: HRP rotation at Last+1 priority.
-- Writes run AFTER every game character controller so HRP actually spins in
-- first-person / shift-lock / camera-lock games alike -- in first person the
-- camera follows HRP so the view spins with it; in third-person the camera
-- follows the character position but the body rotates underneath.
-- BypassCameraLock flag is now informational (UI label) -- both modes use the
-- same writer since Last+1 beats any character controller.
local function findRootJoint(char)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, c in ipairs(hrp:GetChildren()) do
        if c:IsA("Motor6D") then return c end
    end
    return nil
end
FEAT.spinbot = {
    on = function() st.spin = { a = 0, joint = nil, origC0 = nil, boundRS = false } end,
    off = function()
        local s = st.spin
        if not s then return end
        if s.joint and s.origC0 then
            pcall(function() s.joint.C0 = s.origC0 end)
        end
        if s.boundRS then
            pcall(function() RunService:UnbindFromRenderStep("KSpinbot") end)
        end
        st.spin = nil
    end,
    step = function(dt)
        local s = st.spin; if not s then return end
        -- Nonlinear map: slider 1..1000 -> rad/s via 0.05 * v^1.7, so 1 is a
        -- near-invisible crawl (~3 deg/s) and 1000 is ~630 rev/s.
        s.a = s.a + math.rad(0.05 * Move.Spin.Speed ^ 1.7) * dt
        -- bind HRP writer at Last+1 the first time we run (and on mode flip back
        -- from the legacy bypass path). Same priority as the aimbot step so the
        -- render order is predictable.
        if not s.boundRS then
            if s.joint and s.origC0 then
                pcall(function() s.joint.C0 = s.origC0 end)
                s.joint = nil; s.origC0 = nil
            end
            pcall(function()
                RunService:BindToRenderStep("KSpinbot",
                    Enum.RenderPriority.Last.Value + 1, function()
                        local sp = st.spin; if not sp then return end
                        local r = rootOf(); if not r then return end
                        r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, sp.a, 0)
                    end)
            end)
            s.boundRS = true
        end
    end,
}

FEAT.float = {
    on  = function() st.float = {} end,
    off = function() killMover(st.float); st.float = nil end,
    step = function()
        local s, r = st.float, rootOf()
        if not (s and r) then if s then killMover(s) end return end
        if s.part ~= r or not (s.bv and s.bv.Parent) then
            killMover(s); s.part = r
            s.bv = makeBV(r, Vector3.new(0, 9e9, 0))   -- vertical only; XZ free to walk
        end
        local vy = 0
        if UIS:IsKeyDown(Enum.KeyCode.E) then vy = Move.Float.Speed end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then vy = -Move.Float.Speed end
        s.bv.Velocity = Vector3.new(0, vy, 0)
    end,
}

-- edge + step driver (Heartbeat). pcall-guarded so one feature erroring can't kill it.
local prev = {}
RunService.Heartbeat:Connect(function(dt)
    for id, f in pairs(FEAT) do
        local a = isActive(id)
        if a ~= prev[id] then
            prev[id] = a
            if a then if f.on then pcall(f.on) end else if f.off then pcall(f.off) end end
        end
        if a and f.step then pcall(f.step, dt) end
    end
end)

--== click-TP ground indicator (Koffee-styled ring + crosshair on the mouse point) ==--
local mouse = LocalPlayer:GetMouse()
local tpInd = nil
local function ensureIndicator()
    if tpInd and tpInd.Parent then return tpInd end
    local part = new("Part", { Name = KID.name("m_ind"), Anchored = true, CanCollide = false,
        CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(6, 0.1, 6),
        Material = Enum.Material.SmoothPlastic })
    local gui = new("SurfaceGui", { Name = "s", Face = Enum.NormalId.Top,
        CanvasSize = Vector2.new(200, 200), LightInfluence = 0, AlwaysOnTop = false })
    local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, {
        pillCorner(), new("UIStroke", { Color = Theme.Palette.Accent, Thickness = 4, Transparency = 0.1 }),
    })
    ring.Parent = gui
    -- crosshair: two bars 90deg apart, centered
    local barH = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.34, 0, 0, 3), BackgroundColor3 = Theme.Palette.Accent, BorderSizePixel = 0 }, { pillCorner() })
    local barV = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 3, 0.34, 0), BackgroundColor3 = Theme.Palette.Accent, BorderSizePixel = 0 }, { pillCorner() })
    barH.Parent = gui; barV.Parent = gui
    gui.Parent = part
    KID.track(part); part.Parent = Workspace
    tpInd = part
    return part
end
RunService.RenderStepped:Connect(function()
    if isActive("clicktp") then
        local ind = ensureIndicator()
        local g = ind:FindFirstChildWhichIsA("SurfaceGui")
        local pos = mouse.Hit and mouse.Hit.Position
        if pos then ind.CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0)); if g then g.Enabled = true end end
    elseif tpInd then
        local g = tpInd:FindFirstChildWhichIsA("SurfaceGui"); if g then g.Enabled = false end
    end
end)

--== noclip + antifling (Stepped -- beats physics; noclip snapshots on first frame) ==--
RunService.Stepped:Connect(function()
    if isActive("noclip") then
        local c = char()
        if c then
            if not st.noclip then
                local snap = {}
                for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then snap[p] = p.CanCollide end end
                st.noclip = snap
            end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end
    elseif st.noclip then
        for p, cc in pairs(st.noclip) do if p and p.Parent then pcall(function() p.CanCollide = cc end) end end
        st.noclip = nil
    end
    local af = Modules.antifling
    if af and af.Enabled then
        local r = rootOf()
        if r then
            if r.AssemblyAngularVelocity.Magnitude > 40 then r.AssemblyAngularVelocity = Vector3.zero end
            local lv = r.AssemblyLinearVelocity
            if lv.Magnitude > 500 then r.AssemblyLinearVelocity = lv.Unit * 60 end
        end
    end
end)

--== activation pill (left-click = rebind, right-click = Hold/Toggle) ==--
local pendingBind = nil
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
    local frame = new("Frame", { Name = KID.name("m_mode"), Size = UDim2.new(0, 120, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Palette.Panel,
        BackgroundTransparency = 0.02, BorderSizePixel = 0, ZIndex = 230 }, {
        corner(6), stroke(Theme.Palette.Border, 1),
        new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
        new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    frame.Parent = popupScreen
    -- v0.0.98: chooser drops open with a quick grow.
    local fsc = uScaleOf(frame)
    fsc.Scale = 0.92
    tween(fsc, Theme.Animation.Menu, { Scale = 1 })
    for _, mode in ipairs({ "Hold", "Toggle" }) do
        local sel = cfg.Mode == mode
        local opt = new("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Palette.PanelElevated,
            BackgroundTransparency = sel and 0.2 or 1, AutoButtonColor = false, Text = mode:lower(),
            FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
            TextColor3 = sel and Theme.Palette.Accent or Theme.Palette.TextMuted, ZIndex = 231 }, { corner(4) })
        opt.Parent = frame
        popFx(opt)   -- v0.0.98: chooser options squash on press
        opt.MouseButton1Click:Connect(function()
            cfg.Mode = mode
            pulse(opt, 1.08)
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
                if not (mp.X >= a.X and mp.X <= a.X + s.X and mp.Y >= a.Y and mp.Y <= a.Y + s.Y) then closeChooser() end
            end
        end)
    end)
end
local function clearPending()
    if pendingBind then
        pendingBind.refresh()
        tween(pendingBind.pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        pendingBind = nil
    end
end
local function activationPill(row, cfg)
    local pill = new("TextButton", { Name = KID.name("m_pill"), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 30, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        AutoButtonColor = false, Text = keyLabel(cfg.Key) or "-", FontFace = Theme.Fonts.Mono,
        TextSize = Theme.Text.Tiny, TextColor3 = Theme.Palette.TextMuted, ZIndex = 38 }, {
        pillCorner(), stroke(Theme.Palette.BorderSubtle),
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })
    pill.Parent = row
    local function refresh() pill.Text = keyLabel(cfg.Key) or "-" end
    pill.MouseEnter:Connect(function() tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text }) end)
    pill.MouseLeave:Connect(function()
        if not (pendingBind and pendingBind.pill == pill) then
            tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.TextMuted })
        end
    end)
    pill.MouseButton1Click:Connect(function()
        if pendingBind and pendingBind.pill ~= pill then clearPending() end
        pill.Text = "..."
        tween(pill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Accent })
        pendingBind = { pill = pill, cfg = cfg, refresh = refresh }
    end)
    pill.MouseButton2Click:Connect(function() openChooser(pill, cfg) end)
    popFx(pill)   -- v0.0.98: activation pills squash on press
    return pill
end

--== input: rebind capture + activation + click-TP teleport ==--
UserInputService.InputBegan:Connect(function(input, gpe)
    if pendingBind then
        local it = input.UserInputType
        if it == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
            pendingBind.cfg.Key = nil; clearPending(); return
        end
        local bind
        if it == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then bind = input.KeyCode
        elseif it ~= Enum.UserInputType.Focus and it ~= Enum.UserInputType.MouseMovement
           and it ~= Enum.UserInputType.MouseWheel and it ~= Enum.UserInputType.None
           and it ~= Enum.UserInputType.TextInput and it ~= Enum.UserInputType.InputMethod then bind = it end
        if bind then pendingBind.cfg.Key = bind; clearPending() end
        return
    end
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isActive("clicktp") then
        local r = rootOf(); local pos = mouse.Hit and mouse.Hit.Position
        if r and pos then
            -- v0.0.76: match the floor's rotation, not just its position -- so you can TP
            -- onto a ramp/wall and stand tangent to the surface. Fresh raycast for the
            -- normal (mouse.Hit's CFrame doesn't carry the surface normal on all runtimes).
            local ur = mouse.UnitRay
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { char(), tpInd }
            local hit = ur and Workspace:Raycast(ur.Origin, ur.Direction * 5000, rp)
            local up = (hit and hit.Normal) or Vector3.new(0, 1, 0)
            -- project current facing onto the surface tangent plane so we don't flip
            -- when the floor is upside-down; degenerate case falls back to right-vec.
            local curLook = r.CFrame.LookVector
            local look = curLook - up * curLook:Dot(up)
            if look.Magnitude < 0.01 then
                local rv = r.CFrame.RightVector
                look = rv - up * rv:Dot(up)
            end
            if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
            look = look.Unit
            local origin = pos + up * 3
            r.CFrame = CFrame.lookAt(origin, origin + look, up)
        end
    end
    for id, cfg in pairs(CFG) do
        local m = Modules[id]
        if m and m.Enabled and cfg.Key and matchBind(input, cfg.Key) then
            if cfg.Mode == "Toggle" then held[id] = not held[id] else held[id] = true end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    for id, cfg in pairs(CFG) do
        if cfg.Mode == "Hold" and cfg.Key and matchBind(input, cfg.Key) then held[id] = false end
    end
end)

-- virtual XButton driver (mirror of combat's; helper feeds mouse 4/5 state)
;(function()
    local pXB1, pXB2 = false, false
    RunService.Heartbeat:Connect(function()
        local xb1, xb2 = Helper.XB1, Helper.XB2
        local e1, e2 = (xb1 and not pXB1), (xb2 and not pXB2)
        local function down(k) return (k == "XButton1" and xb1) or (k == "XButton2" and xb2) or false end
        local function edge(k) return (k == "XButton1" and e1) or (k == "XButton2" and e2) or false end
        if pendingBind then
            local k = (e2 and "XButton2") or (e1 and "XButton1") or nil
            if k then pendingBind.cfg.Key = k; clearPending() end
        end
        for id, cfg in pairs(CFG) do
            if type(cfg.Key) == "string" then
                local m = Modules[id]
                if m and m.Enabled then
                    if cfg.Mode == "Toggle" then if edge(cfg.Key) then held[id] = not held[id] end
                    else held[id] = down(cfg.Key) end
                end
            end
        end
        pXB1, pXB2 = xb1, xb2
    end)
end)()

--== modules (checkbox = arm). OnDisable clears held so re-arming starts inactive. ==--
local function reg(id, name)
    local m = registerModule(id, name, function() end, function() held[id] = false end)
    m.IsActive = function() return held[id] == true end   -- v0.0.73: arraylist "on" once the keybind activates it
    return m
end
reg("walkspeed", "WalkSpeed"); reg("teleportwalk", "Teleport Walk"); reg("fly", "Fly")
reg("spinbot", "Spinbot"); reg("noclip", "Noclip"); reg("float", "Float"); reg("clicktp", "Click TP")
reg("customanim", "Custom Anim")
registerModule("antifling", "Antifling", function() end, function() end)   -- no keybind: on = on

-- VISUAL FEATURES (v0.0.54) -- plain toggles (no keybind), passive visual effects.
--   Arms Offset: universal, animation-safe. Custom arms on the player's character
--     (R6/R15 limbs, or custom meshes welded to them) all hang off the shoulder
--     Motor6D chain, so offsetting the shoulder C0 shifts the whole arm + anything
--     welded to it. Pre-multiplying by a pure-translation CFrame moves the offset in
--     TORSO space, so both shoulders shift the same world direction (not mirrored).
--   Character Material: force Material + Color on every BasePart; snapshot+restore.
local Visual = {
    Arms     = { X = 0, Y = 0, Z = 0, RX = 0, RY = 0, RZ = 0 },
    Material = { Name = "Neon", Color = Color3.fromRGB(212, 145, 90) },
}
-- CustomAnim config reused from CFG so the pill/held system drives it
Visual.CustomAnim = CFG.customanim
registerConfig("character_visual", Visual)

local SHOULDER = { ["Right Shoulder"] = true, ["Left Shoulder"] = true,
                   ["RightShoulder"]  = true, ["LeftShoulder"]  = true }
local armState = { char = nil, joints = nil }
-- v0.0.76: force re-cache on every respawn so the offset reapplies after death.
-- CharacterAdded fires before the shoulders exist on the new rig, so we ALSO
-- rebuild whenever the joints table is empty on a tick where the module is on
-- (the shoulders show up a few frames later; the render loop keeps retrying).
LocalPlayer.CharacterAdded:Connect(function()
    armState.char = nil
    armState.joints = nil
end)
local function applyArms()
    local c = char()
    if not c then return end
    -- Re-cache when: (a) character swapped (respawn), (b) no cache yet, or
    -- (c) the cache is empty (respawn tick fired before shoulders loaded).
    if armState.char ~= c or not armState.joints or next(armState.joints) == nil then
        armState.char = c; armState.joints = {}
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("Motor6D") and SHOULDER[d.Name] then armState.joints[d] = d.C0 end
        end
    end
    local A = Visual.Arms
    local off = CFrame.new(A.X, A.Y, A.Z) * CFrame.Angles(math.rad(A.RX), math.rad(A.RY), math.rad(A.RZ))
    for j, orig in pairs(armState.joints) do
        if j.Parent then j.C0 = off * orig end
    end
end
local function restoreArms()
    if armState.joints then
        for j, orig in pairs(armState.joints) do
            if j.Parent then pcall(function() j.C0 = orig end) end
        end
    end
    armState.char = nil; armState.joints = nil
end

-- v0.0.55: Material was tinting (Color worked) but not changing Material because a
-- BasePart's SurfaceAppearance (PBR texture) OVERRIDES Material visually, and a
-- MeshPart.TextureID likewise masks it. Modern avatar bodies (and games that keep your
-- real avatar meshes, e.g. Prison Life) have these -> forced Material never rendered.
-- Fix: while active, PARK the SurfaceAppearance (unparent) + clear MeshPart.TextureID
-- so the forced Material actually shows; restore both on disable.
local matSnap = {}   -- part -> { Material, Color, TextureID|nil }
local saSnap  = {}   -- SurfaceAppearance -> original parent (parked while active)
local function matEnum()
    local ok, m = pcall(function() return Enum.Material[Visual.Material.Name] end)
    return (ok and m) or Enum.Material.Plastic
end
local function applyMaterial()
    local c = char(); if not c then return end
    local mat, col = matEnum(), Visual.Material.Color
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and not p:GetAttribute("KFF") then   -- skip forcefield shells
            if not matSnap[p] then
                matSnap[p] = { p.Material, p.Color, p:IsA("MeshPart") and p.TextureID or nil }
            end
            p.Material = mat; p.Color = col
            if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
        elseif p:IsA("SurfaceAppearance") then
            if not saSnap[p] and p.Parent then saSnap[p] = p.Parent; p.Parent = nil end
        end
    end
end
local function restoreMaterial()
    for sa, par in pairs(saSnap) do
        if sa and par and par.Parent then pcall(function() sa.Parent = par end) end
    end
    saSnap = {}
    for p, s in pairs(matSnap) do
        if p and p.Parent then pcall(function()
            p.Material = s[1]; p.Color = s[2]
            if s[3] ~= nil and p:IsA("MeshPart") then p.TextureID = s[3] end
        end) end
    end
    matSnap = {}
end

-- v0.0.66 -> v0.0.97: Static Forcefield shell. Originally a separate module with
-- its own toggle; v0.0.97 folded it into the Material dropdown as a "Static"
-- option so the user picks forcefield-look material once instead of toggling two
-- things. Clones each visible part's shape, sets Material = ForceField, welds it
-- on. Marked with the KFF attribute so Character Material skips it. v0.0.97:
-- skip MeshParts and parts whose descendants include a mesh -- cloning those
-- produced a duplicate visible head/face floating at the same CFrame (the
-- "second head stuck on blue" bug the user reported).
local ffShell, ffChar = {}, nil
local function clearFF()
    for _, shell in pairs(ffShell) do pcall(function() shell:Destroy() end) end
    ffShell, ffChar = {}, nil
end
local function partHasMesh(p)
    if p:IsA("MeshPart") then return true end
    for _, ch in ipairs(p:GetChildren()) do
        if ch:IsA("SpecialMesh") or ch:IsA("DataModelMesh") then return true end
    end
    return false
end
local function applyFF()
    local c = char(); if not c then return end
    if ffChar ~= c then clearFF(); ffChar = c end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and not ffShell[p] and not p:GetAttribute("KFF")
           and p.Name ~= "HumanoidRootPart" and p.Transparency < 1
           and not partHasMesh(p) then
            local ok, shell = pcall(function()
                local s = p:Clone()
                for _, ch in ipairs(s:GetChildren()) do
                    if not (ch:IsA("SpecialMesh") or ch:IsA("DataModelMesh")) then ch:Destroy() end
                end
                s.Name = KID.name("ff")
                s:SetAttribute("KFF", true)
                s.Material = Enum.Material.ForceField
                s.Color = Color3.fromRGB(120, 180, 255)
                s.Transparency = 0; s.Reflectance = 0; s.CastShadow = false
                s.CanCollide, s.CanQuery, s.CanTouch = false, false, false
                s.Massless, s.Anchored = true, false
                s.CFrame = p.CFrame
                local w = Instance.new("WeldConstraint")
                w.Part0, w.Part1 = p, s; w.Parent = s
                KID.track(s); s.Parent = c
                return s
            end)
            if ok and shell then ffShell[p] = shell end
        end
    end
end

-- v0.0.76: Body Removal -- makes every character body part invisible (and their
-- Decals/Textures, for classic R6 face + Shirt/Pants graphics). Snapshots the
-- original Transparency per instance so disable restores exactly what was there
-- (including intentionally-hidden parts). Skips the forcefield shell (KFF) so
-- Static Forcefield stays visible on top, and skips HumanoidRootPart (already
-- invisible). Respawn-safe: new-character parts fresh-snapshot on their first tick.
local bodySnap = {}
local function applyBodyRemoval()
    local c = char(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if (p:IsA("BasePart") and not p:GetAttribute("KFF") and p.Name ~= "HumanoidRootPart")
            or p:IsA("Decal") or p:IsA("Texture") then
            if bodySnap[p] == nil then bodySnap[p] = p.Transparency end
            if p.Transparency ~= 1 then p.Transparency = 1 end
        end
    end
end
local function restoreBodyRemoval()
    for p, t in pairs(bodySnap) do
        if p and p.Parent then pcall(function() p.Transparency = t end) end
    end
    bodySnap = {}
end

-- v0.0.94 THIRD PERSON. Universal over-the-shoulder camera. LTM stays off
-- (character hidden per game rules), camera writes at RenderPriority 200
-- (one below the aimbot's 201 so aimbot wins when armed), HRP.CFrame
-- written only while enabled, and camera/mouse restore on disable.
local TP = {
    Enabled     = false,
    Sensitivity = 0.25,
    Zoom        = 7.5,
    MinZoom     = 2,
    MaxZoom     = 25,
    ShoulderX   = 1.75,
    ShoulderY   = 0.5,
    _rotX       = 0,
    _rotY       = 0,
    _origCam    = nil,   -- Camera.CameraType before enable
    _origMB     = nil,   -- MouseBehavior before enable
}
local function tpOnEnable()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    TP._origCam = cam.CameraType
    TP._origMB  = UserInputService.MouseBehavior
    local rx, ry = cam.CFrame:ToEulerAnglesYXZ()
    TP._rotX, TP._rotY = rx, ry
    cam.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end
local function tpOnDisable()
    local cam = Workspace.CurrentCamera
    if cam then cam.CameraType = TP._origCam or Enum.CameraType.Custom end
    UserInputService.MouseBehavior = TP._origMB or Enum.MouseBehavior.Default
end
UserInputService.InputChanged:Connect(function(input, gpe)
    if not (Modules.thirdperson and Modules.thirdperson.Enabled) then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        TP._rotY = TP._rotY - math.rad(input.Delta.X * TP.Sensitivity)
        TP._rotX = math.clamp(TP._rotX - math.rad(input.Delta.Y * TP.Sensitivity), -math.rad(80), math.rad(80))
    elseif input.UserInputType == Enum.UserInputType.MouseWheel then
        TP.Zoom = math.clamp(TP.Zoom - input.Position.Z * 0.75, TP.MinZoom, TP.MaxZoom)
    end
end)
-- v0.0.94: bind at Camera priority (200) -- aimbot binds at Camera+1 (201) so
-- aimbot's write wins WHEN aimbot is aiming, ours wins otherwise. cleaner than
-- Heartbeat/RenderStepped competition.
pcall(function() RunService:UnbindFromRenderStep("KThirdPerson") end)
RunService:BindToRenderStep("KThirdPerson", Enum.RenderPriority.Camera.Value, function()
    if not (Modules.thirdperson and Modules.thirdperson.Enabled) then return end
    local char = LocalPlayer.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not (hrp and head) then return end
    -- LTM=0 ONLY while enabled (source script bug: this ran always -> character
    -- was forced visible even with the feature off).
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
    end
    local cam = Workspace.CurrentCamera; if not cam then return end
    cam.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, TP._rotY, 0)
    local headPos = head.Position
    local rotation = CFrame.Angles(0, TP._rotY, 0) * CFrame.Angles(TP._rotX, 0, 0)
    local shoulder = Vector3.new(TP.ShoulderX, TP.ShoulderY, 0)
    local tp = headPos + (rotation * shoulder) + (rotation * Vector3.new(0, 0, TP.Zoom))
    cam.CFrame = CFrame.new(tp, headPos + (rotation * shoulder))
end)

registerModule("armsoffset",   "Arms Offset",       function() end, function() restoreArms() end)
registerModule("charmaterial", "Character Material", function() end, function() restoreMaterial() end)
ANIM_IDS = {
    ["Orbit 1"] = "118314972618293", ["Orbit 2"] = "133811691098518", ["Orbit 3"] = "138488217385385", ["Orbit 4"] = "91729309021707",
    ["Aura 1"] = "140445336277156", ["Aura 2"] = "107902247206226", ["Aura 3"] = "71799101103620",
    ["Small Body 1"] = "132582392404773", ["Small Body 2"] = "117450501566142"
}
local ANIM_LOOP = {}
ANIM_DROPDOWN = { "Orbit 1", "Orbit 2", "Orbit 3", "Orbit 4", "Aura 1", "Aura 2", "Aura 3", "Small Body 1", "Small Body 2" }
-- Place 155615604: replace the whole custom-anim list with these (loop only where noted)
if game.PlaceId == 155615604 then
    ANIM_IDS = {
        ["Prone"] = "481089053",
        ["Prone Walking"] = "481088553",
        ["Sitting"] = "178130996",
        ["Climbing"] = "180436334",
        ["Falling"] = "180436148",
        ["Reloading"] = "388723916"
    }
    ANIM_LOOP = { ["Prone Walking"] = true, ["Reloading"] = true }
    ANIM_DROPDOWN = { "Prone", "Prone Walking", "Sitting", "Climbing", "Falling", "Reloading" }
    if not ANIM_IDS[Visual.CustomAnim.Name] then Visual.CustomAnim.Name = "Prone" end
end
-- published for the config-load sanitize (config system lives in its own IIFE
-- which runs BEFORE this block assigns the per-game lists).
Koffee._animIDs = ANIM_IDS
Koffee._animDropdown = ANIM_DROPDOWN
local currentAnimTrack = nil
local currentAnimId = nil
local function stopOtherTracks(animator)
    local ok, list = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not list then return end
    for _, t in ipairs(list) do
        if t ~= currentAnimTrack then pcall(function() t:Stop() end) end
    end
end
RunService.Heartbeat:Connect(function()
    local active = Modules.customanim and Modules.customanim.IsActive()
    if not active then
        if currentAnimTrack then
            currentAnimTrack:Stop()
            currentAnimTrack:Destroy()
            currentAnimTrack = nil
        end
        currentAnimId = nil
        return
    end
    local targetId = ANIM_IDS[Visual.CustomAnim.Name]
    if not targetId then
        if currentAnimTrack then
            currentAnimTrack:Stop()
            currentAnimTrack:Destroy()
            currentAnimTrack = nil
        end
        currentAnimId = nil
        return
    end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    if currentAnimTrack and currentAnimId == targetId then
        if not currentAnimTrack.IsPlaying then currentAnimTrack:Play() end
        stopOtherTracks(animator)
        return
    end
    if currentAnimTrack then
        currentAnimTrack:Stop()
        currentAnimTrack:Destroy()
        currentAnimTrack = nil
    end
    local animObject = nil
    local success, objects = pcall(function() return game:GetObjects("rbxassetid://" .. targetId) end)
    if success and objects and #objects > 0 then
        for _, obj in ipairs(objects) do
            if obj:IsA("Animation") then animObject = obj; break end
            local childAnim = obj:FindFirstChildOfClass("Animation", true)
            if childAnim then animObject = childAnim; break end
        end
    end
    if not animObject then
        animObject = Instance.new("Animation")
        animObject.AnimationId = "rbxassetid://" .. targetId
    end
    local looping = true
    if next(ANIM_LOOP) then looping = ANIM_LOOP[Visual.CustomAnim.Name] == true end
    local ok, track = pcall(function() return animator:LoadAnimation(animObject) end)
    if ok and track then
        track.Looped = looping
        track.Priority = Enum.AnimationPriority.Action4
        track:Play()
        currentAnimTrack = track
        currentAnimId = targetId
        stopOtherTracks(animator)
    end
end)
registerModule("staticff",     "Static Forcefield", function() end, function() clearFF() end)  -- v0.0.97: kept registered (no UI toggle) so clearFF runs if a config still has it on
registerModule("bodyremoval",  "Body Removal",      function() end, function() restoreBodyRemoval() end)
registerModule("thirdperson",  "3rd Person",        function() tpOnEnable() end, function() tpOnDisable() end)
RunService.RenderStepped:Connect(function()
    if Modules.armsoffset   and Modules.armsoffset.Enabled   then pcall(applyArms) end
    if Modules.charmaterial and Modules.charmaterial.Enabled then pcall(applyMaterial) end
    if Modules.staticff     and Modules.staticff.Enabled     then pcall(applyFF) end
    if Modules.bodyremoval  and Modules.bodyremoval.Enabled  then pcall(applyBodyRemoval) end
end)

-- curated material list (dropdown). Names resolve via Enum.Material[name].
local MATERIALS = { "Plastic", "SmoothPlastic", "Neon", "ForceField", "Static", "Glass", "Metal",
    "DiamondPlate", "Foil", "Wood", "WoodPlanks", "Marble", "Granite", "Slate", "Concrete",
    "Brick", "Cobblestone", "Ice", "Grass", "Sand", "Fabric", "Pebble", "CorrodedMetal" }

-- v0.0.58: expandable material preview -- click the small preview to open a mac-styled
-- (Koffee-coloured) floating window: drag the title bar to move, hold right-click on the
-- viewport to orbit the model, click the red dot (or the window is single-instance) to
-- close. Live-syncs to the current material + colour selection.
local expandedWin = nil
local function closeMaterialPreview()
    if expandedWin then
        for _, c in ipairs(expandedWin.conns) do pcall(function() c:Disconnect() end) end
        pcall(function() expandedWin.frame:Destroy() end)
        expandedWin = nil
    end
end
local function openMaterialPreview()
    closeMaterialPreview()
    local W, H, BAR = 340, 380, 30
    local frame = new("Frame", { Name = KID.name("m_prev"), Size = UDim2.new(0, W, 0, H),
        Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2), BackgroundColor3 = Theme.Palette.Panel,
        BorderSizePixel = 0, ZIndex = 300 }, { corner(10), stroke(Theme.Palette.Border, 1) })
    KID.track(frame); frame.Parent = popupScreen
    -- mac title bar (rounded top; square the bottom edge so it seams into the body)
    local bar = new("Frame", { Size = UDim2.new(1, 0, 0, BAR), BackgroundColor3 = Theme.Palette.PanelElevated,
        BorderSizePixel = 0, ZIndex = 301, Parent = frame }, { corner(10) })
    new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Palette.PanelElevated, BorderSizePixel = 0, ZIndex = 301, Parent = bar })
    local dotColors = { Color3.fromRGB(232, 106, 92), Color3.fromRGB(230, 190, 110), Color3.fromRGB(127, 190, 143) }
    for i = 1, 3 do
        local d = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 10 + (i - 1) * 18, 0.5, -6), BackgroundColor3 = dotColors[i],
            BorderSizePixel = 0, ZIndex = 303, Parent = bar }, { pillCorner() })
        if i == 1 then d.MouseButton1Click:Connect(closeMaterialPreview) end
    end
    new("TextLabel", { Text = "material", FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 302, Parent = bar })
    -- viewport body
    local vp = new("ViewportFrame", { Position = UDim2.new(0, 0, 0, BAR), Size = UDim2.new(1, 0, 1, -BAR),
        BackgroundColor3 = Theme.Palette.Background, ZIndex = 301, Parent = frame,
        LightDirection = Vector3.new(-1, -1, -0.5), Ambient = Color3.fromRGB(140, 140, 140),
        LightColor = Color3.new(1, 1, 1) }, { new("UICorner", { CornerRadius = UDim.new(0, 10) }) })
    local part = new("Part", { Size = Vector3.new(4, 4, 4), Anchored = true, CFrame = CFrame.new(),
        Material = matEnum(), Color = Visual.Material.Color })
    part.Parent = vp
    local vcam = new("Camera", {}); vcam.Parent = vp; vp.CurrentCamera = vcam
    local yaw, pitch, dist = math.rad(30), math.rad(18), 10
    local function updateCam()
        local pos = (CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, dist)).Position
        vcam.CFrame = CFrame.new(pos, Vector3.zero)
    end
    updateCam()
    -- drag (title bar) + orbit (right-drag on viewport)
    local dragging, dragStart, startPos = false, nil, nil
    local rotating, rotStart = false, nil
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    vp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            rotating = true; rotStart = input.Position
        end
    end)
    expandedWin = { frame = frame, conns = {} }
    table.insert(expandedWin.conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if dragging and dragStart then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif rotating and rotStart then
            local delta = input.Position - rotStart
            rotStart = input.Position
            yaw = yaw - delta.X * 0.01
            pitch = math.clamp(pitch - delta.Y * 0.01, -1.4, 1.4)
            updateCam()
        end
    end))
    table.insert(expandedWin.conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then rotating = false end
    end))
    table.insert(expandedWin.conns, RunService.RenderStepped:Connect(function()
        if not (expandedWin and expandedWin.frame.Parent) then return end
        part.Material = matEnum(); part.Color = Visual.Material.Color
    end))
end

--== tab builder (called by the Character addTab in normal tab order) ==--
Koffee._characterTab = function(root)
    local mv = panel(root, "Movement")
    moduleCheckbox(mv, "No Jump Cooldown", "nojumpcd")
    moduleCheckbox(mv, "Infinite Jump",    "infjump")
    local function feat(label, id)
        local c = moduleCheckbox(mv, label, id)
        activationPill(c.row, CFG[id])
        return c
    end
    feat("WalkSpeed", "walkspeed")
    slider(mv, "Speed", 0, 5000, Move.WalkSpeed.Speed, 0, function(v) Move.WalkSpeed.Speed = v end)
    feat("Teleport Walk", "teleportwalk")
    slider(mv, "TP Speed", 0, 500, Move.TeleportWalk.Speed, 0, function(v) Move.TeleportWalk.Speed = v end)
    feat("Fly", "fly")
    slider(mv, "Fly Speed", 0, 5000, Move.Fly.Speed, 0, function(v) Move.Fly.Speed = v end)
    dropdown(mv, "Fly Mode", { "Default Fly", "Vehicle Fly", "CFrame Fly" }, Move.Fly.Kind, function(v) Move.Fly.Kind = v end)
    feat("Spinbot", "spinbot")
    slider(mv, "Spin Speed", 1, 1000, Move.Spin.Speed, 0, function(v) Move.Spin.Speed = v end)
    configCheckbox(mv, "Bypass Camera Lock", Move.Spin.BypassCameraLock, function(v) Move.Spin.BypassCameraLock = v end)
    feat("Noclip", "noclip")
    feat("Float", "float")
    slider(mv, "Float Speed", 0, 200, Move.Float.Speed, 0, function(v) Move.Float.Speed = v end)
    feat("Click TP", "clicktp")
    moduleCheckbox(mv, "Antifling", "antifling")

    -- visual box
    local vis = panel(root, "Visual")
    local vpPart   -- viewport preview part (forward decl; swatch/dropdown closures set it)

    -- Character Material: enable toggle + colour swatch on the row
    local matCtrl = moduleCheckbox(vis, "Character Material", "charmaterial")
    local swWrap = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 16), BackgroundTransparency = 1, ZIndex = 38, Parent = matCtrl.row })
    colorSwatch(swWrap, Visual.Material.Color, 14, { onChange = function(cval)
        Visual.Material.Color = cval
        if vpPart then vpPart.Color = cval end
    end })

    -- material dropdown (left) + live viewport preview (right)
    local matRow = new("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 34, Parent = vis })
    local ddHost = new("Frame", { Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, ZIndex = 34, Parent = matRow })
    dropdown(ddHost, "Material", MATERIALS, Visual.Material.Name, function(v)
        Visual.Material.Name = v
        if vpPart then vpPart.Material = matEnum() end
        -- v0.0.97: "Static" option drives the static forcefield shell overlay
        -- (was a separate toggle pre-v0.0.97). Clear on any non-Static selection.
        if v == "Static" then applyFF() else clearFF() end
    end)
    local vpf = new("ViewportFrame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 22),
        Size = UDim2.new(0, 44, 0, 26), BackgroundColor3 = Theme.Palette.PanelElevated,
        BackgroundTransparency = 0.15, ZIndex = 35, Parent = matRow,
        LightDirection = Vector3.new(-1, -1, -0.5), Ambient = Color3.fromRGB(150, 150, 150),
        LightColor = Color3.new(1, 1, 1) }, { corner(4), stroke(Theme.Palette.BorderSubtle) })
    vpPart = new("Part", { Size = Vector3.new(2, 2, 2), Anchored = true, CFrame = CFrame.new(),
        Material = matEnum(), Color = Visual.Material.Color })
    vpPart.Parent = vpf
    local vpCam = new("Camera", { CFrame = CFrame.new(Vector3.new(2.2, 1.8, 2.2), Vector3.new(0, 0, 0)) })
    vpCam.Parent = vpf
    vpf.CurrentCamera = vpCam
    -- click the preview to expand into a draggable, rotatable window
    vpf.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then openMaterialPreview() end
    end)

    -- v0.0.97: Static Forcefield was removed as a separate toggle -- it's now a
    -- "Static" option inside the Material dropdown above. The shell logic
    -- (applyFF / clearFF) lives on so saved configs that still have the old
    -- toggle on can be cleared cleanly via the module's onDisable hook.

    -- v0.0.76: Body Removal -- makes every character body part invisible while enabled
    moduleCheckbox(vis, "Body Removal", "bodyremoval")

    -- v0.0.94 3rd Person: toggle + keybind pill (combo-aware -- accepts Shift+C etc.).
    -- No default keybind so it doesn't conflict with anything the user has bound.
    local tpRow = moduleCheckbox(vis, "3rd Person", "thirdperson")
    keybindPill(tpRow.row, "thirdperson", nil)

    -- Arms Offset: enable toggle + X/Y/Z sliders (+-50)
    moduleCheckbox(vis, "Arms Offset", "armsoffset")
    slider(vis, "Arm X", -50, 50, Visual.Arms.X, 1, function(v) Visual.Arms.X = v end)
    slider(vis, "Arm Y", -50, 50, Visual.Arms.Y, 1, function(v) Visual.Arms.Y = v end)
    slider(vis, "Arm Z", -50, 50, Visual.Arms.Z, 1, function(v) Visual.Arms.Z = v end)
    slider(vis, "Arm Rot X", -180, 180, Visual.Arms.RX, 0, function(v) Visual.Arms.RX = v end)
    slider(vis, "Arm Rot Y", -180, 180, Visual.Arms.RY, 0, function(v) Visual.Arms.RY = v end)
    slider(vis, "Arm Rot Z", -180, 180, Visual.Arms.RZ, 0, function(v) Visual.Arms.RZ = v end)

    -- Custom Anim
    local animRow = moduleCheckbox(vis, "Custom Anim", "customanim")
    activationPill(animRow.row, CFG.customanim)
    dropdown(vis, "Animation", ANIM_DROPDOWN, Visual.CustomAnim.Name, function(v) Visual.CustomAnim.Name = v end)
end

end)()

-- TABS: build panels
-- tab order (per he): combat visuals world character options configs npc teams
-- COMBAT TAB (v0.0.31): two-column card (pill switcher):
--   left : Aimbot / Prediction / Smoothness / FOV + Misc(Resolver)
--   right: Silent Aim / Prediction / FOV          + Trigger Bot
-- Backends: shared targeting engine, camera/mouse aimbot, prediction, per-axis
-- smoothness, ragebot teleports, silent-aim hook, triggerbot, FOV circle.
-- IIFE (not do-block): Luau's 200-local limit is per FUNCTION; a do-block shares
-- the main chunk's registers (-> "Out of local registers"). IIFE = own budget.
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
        PerfectLock   = false,                            -- v0.0.96: true = snap straight onto the target, ignores Sensitivity + Smooth
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
        -- v0.2.0: Wallbang (renamed from Pos Spoof). Under Raycast method,
        -- rewrites the workspace:Raycast ORIGIN to 3 studs in front of the target so
        -- the client ray reaches them through any wall.
        -- v0.3.0: Wallbang now also flows to the External method via POST /config -->
        -- KoffeeHelper reads the flag and widens its raycast-inline-hook rewrite
        -- (origin shift + visibility-filter bypass) inside Roblox. Under Forced MB /
        -- Second-Camera the checkbox is inert -- neither Lua-side arm nor helper
        -- config reads it there.
        Wallbang      = false,
        Snaplines     = false,
        Predict       = { Enabled = false, X = 1.0, Y = 1.0 },
        -- v0.0.39: Forced Magic-Bullet is UNIVERSAL by default -- fire-read is always
        -- on. The ~90% of games that don't read mouse.Hit build their shot from
        -- Camera.CFrame / the cursor; we spoof those reads the instant the WEAPON
        -- SCRIPT makes them, scoped by getcallingscript so the real camera (renderer/
        -- Popper) is never touched and the view never moves. SpoofScope is the caller-
        -- identification strategy (both exclude the PlayerModule camera).
        SpoofScope    = "Auto (Learn)",
        _hooked       = false,
    },
    Misc = { Resolver = false },
    -- v0.0.88 HIT / KILL SOUNDS. Detection: universal Humanoid.Health drop watcher
    -- (A) per player. Attribution: "invisible target lock" -- each frame while LMB
    -- held, the enemy CLOSEST to the mouse cursor (screen-space, within MouseRadius
    -- pixels) is designated your current mouse target; when THAT enemy's Health
    -- drops, it's YOUR hit. Independent of silent aim / aimbot lock state.
    -- Presets = a small named-sound registry, Custom Id > 0 overrides. Cooldown
    -- between plays (per-type) so rapid auto-fire hits don't stack into a buzz.
    -- Suppresses when the Koffee window is open (per Jack -- no ear fatigue in-UI).
    HitSounds = {
        Hit = {
            Enabled  = false,
            Preset   = "hit",
            CustomId = 0,       -- 0 = use preset (local mp3 via getcustomasset)
            Volume   = 1.0,
            Pitch    = 1.0,
            Cooldown = 50,      -- ms
        },
        Kill = {
            Enabled  = false,
            Preset   = "bell",
            CustomId = 0,
            Volume   = 1.0,
            Pitch    = 1.0,
            Cooldown = 200,
        },
        Overlap     = true,     -- v0.0.89: true = clone-per-play (real overlap); false = stop previous then play
        -- v0.0.92 attribution window (seconds) -- after aiming at an enemy (LMB
        -- press edge OR any Heartbeat while LMB held), that enemy stays valid as
        -- YOUR target for this long. Handles snipers (fast tap, 200ms+ damage
        -- delay before health drops) + multiple in-flight shots (each captured
        -- target has its own timestamp).
        AttrWindow  = 2.0,
        -- v0.0.93 pre-click damage window (ms). Bypasses the left-click delay
        -- problem -- if the target took damage in the last BeforeClick ms BEFORE
        -- Koffee registered the LMB press, we still fire the sound on that press.
        -- Slider 1..500. Handles input lag / roundtrip / game processing gaps.
        BeforeClick = 100,
    },
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
    registerConfig("combat_sounds",  Combat.HitSounds)

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
                -- v0.0.46: team check (manual list / Advanced) + "Ignore Friends" gate
                local excluded = (cfg.TeamCheck and isTeammate(plr))
                              or (Shared.IgnoreFriends and isFriend(plr))
                if alive and hcOk and not excluded then
                    -- v0.0.97 TARGET LOCK: while engaged, only the named player is
                    -- a legal target at all. Everything else is invisible to the
                    -- targeting loop (aim, silent, trigger all share this).
                    if not (Shared.TargetLock.Enabled and Shared.TargetLock._active)
                       or Shared.targetLockPlayer() == plr then
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
        return pos + Vector3.new(v.X / math.max(pr.X, 0.01), v.Y / math.max(pr.Y, 0.01), v.Z / math.max(pr.Z, 0.01))
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
    local aimFov    = makeFov(KID.name("fov_aim"))
    local silentFov = makeFov(KID.name("fov_silent"))

    -- snaplines: one line from the FOV origin (mouse/center) to the targeted
    -- person. Uses the tracer backend (KGrad + KOutline, featureThickness, ESP
    -- tracer colour/gradient/outline). Only one context drives it (aim XOR silent).
    local snapLine = new("Frame", {
        Name = KID.name("snapline"), AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Visible = false, ZIndex = 11, Parent = screen,
    }, { lineGradient(), lineOutline() })

    --== activation state ==--
    local aimHeld    = false
    local silentHeld = false   -- v0.0.34: optional silent arm key (nil key = always armed)
    local lmbDown    = false   -- v0.0.35: tracked LMB state (read inside the silent
                               -- hooks; IsMouseButtonPressed is a namecall + illegal there)
    local lmbClickAt = 0       -- v0.0.69: os.clock() of the last LMB press -> a short Pos Spoof
                               -- fire-window, so a weapon that reads a frame or two AFTER the
                               -- click (or fires multiple pellets) still gets the spoofed origin
    local trigHeld   = false
    local trigBusy   = false
    local silentTarget = nil   -- the part (for Mouse.Target)
    local silentPos    = nil   -- Vector3 redirect point (predicted; drives Hit/UnitRay)

    -- v0.0.39: fire-read resolver state + caller scoping. ONE local table so the
    -- Combat chunk's ~200-local budget stays below the limit; resolvers read it
    -- as an upvalue. cam/camPos/screen cached per frame (never re-read Camera.*
    -- inside the hook -- re-entry/recursion), mouse for identity compares, and
    -- the learned weapon/camera-controller sets are only touched by namecall-safe
    -- code (never lazily inside a hook: FindFirstChild is a namecall).
    local SR = { cam = nil, camPos = nil, screen = nil, mouse = nil, pm = nil }
    local getCS = getcallingscript   -- executor global; nil on runtimes without it
    SR.own = getCS and getCS()       -- Koffee's own script: never spoof its OWN camera
                                     -- reads (the aimbot loop) if silent is co-armed.
    pcall(function() SR.mouse = LocalPlayer:GetMouse() end)
    -- PlayerModule (the standard camera root) is resolved HERE + in the heartbeat --
    -- both namecall-safe contexts. NEVER resolve it lazily inside a hook (FindFirstChild
    -- is a namecall; a nested namecall inside the __namecall hook corrupts the pending
    -- dispatch and breaks the weapon after one shot).
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        SR.pm = ps and ps:FindFirstChild("PlayerModule")
    end)
    -- is `src` the camera system? standard camera = a PlayerModule descendant -- NEVER
    -- spoofed, so the real view can't be rotated out from under the player.
    -- CRITICAL: walks .Parent (property __index reads only) -- NO namecall -- so this
    -- is safe to call from inside the __namecall hook.
    function SR.isView(src)
        if not src then return false end
        local pm = SR.pm
        if not pm then return false end
        local a, n = src, 0
        while a and n < 16 do
            if a == pm then return true end
            a = a.Parent
            n = n + 1
        end
        return false
    end
    -- should THIS caller be handed the spoofed aim direction (Camera.CFrame / cursor /
    -- camera-rays)? mouse.Hit/Target/UnitRay are handled separately + ungated (only aim
    -- code reads those). Excludes Koffee's own reads and the camera system (PlayerModule)
    -- so the real view / Popper are never touched.
    -- v0.0.70: learned CONTROLLER set. Any non-Koffee script that WRITES Camera.CFrame
    -- or the local root's CFrame/Position is a camera/position CONTROLLER (FpsController,
    -- custom movement handlers, etc.) -- it must NEVER be handed the spoofed aim/position,
    -- or the read-spoof rotates the real view / teleports you on games with custom handlers.
    -- Populated by the __newindex writer-detector; only pure-READER (shooting) code is left
    -- to be spoofed. Session-stable so re-exec keeps what it already learned.
    -- v0.1.5 Second-Camera: the learned set is actually ENFORCED (v0.0.70 shipped the
    -- detector but the revert removed enforcement). In SC mode a script that writes
    -- Camera.CFrame is a RENDERER and always gets real data, while pure-reader weapon
    -- scripts get bent continuously -- that is the actual "two cameras" split: the game's
    -- fire logic sees the locked direction, your view never moves. Merged handler+weapon
    -- scripts land in the set too and degrade to MB (switch methods there).
    function SR.spoofAim(src)
        if not src then return false end
        if src == SR.own then return false end              -- never Koffee's own reads
        if SR.isView(src) then return false end             -- never the camera system
        if Combat.Silent.Method == "Second-Camera" then
            -- v0.1.5: learned renderers ALWAYS see real data -- absolute, no waivers.
            -- (a v0.1.6 click-window waiver was ripped: bending a writer's reads at ANY
            -- time bends the view, because it writes what it read straight back.)
            -- These games are covered by the OUTBOUND path instead (FireServer arg
            -- rewrite in resolveNamecall) -- the client sees truth, the wire carries
            -- the lock.
            local set = getgenv and getgenv()[KID.ctx.keys.ctrl]
            if set and rawget(set, src) then return false end  -- learned renderer: real data
        end
        return true                                         -- any non-camera script
    end

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
    -- v0.0.97: Target Lock status updater -- set by the Combat UI builder (which owns
    -- tlStatus); the key-toggle handler above calls it after flipping _active.
    local tlStatusUpdater = nil
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
    -- v0.0.79: prefer VirtualInputManager per v0.0.35 finding -- on Potassium (and
    -- some other executors) mouse1click/mouse1press don't flip IsMouseButtonPressed
    -- and don't fire the game's InputBegan handler, so the game's weapon never sees
    -- a click. VIM's SendMouseButtonEvent DOES fire InputBegan reliably. Fall back
    -- to mouse1click / mouse1press+release only if VIM isn't available.
    local VIM = nil
    pcall(function() VIM = game:GetService("VirtualInputManager") end)
    -- v0.0.80: throttled LMB synthesis when the cursor is over the Koffee window,
    -- so silent/trigger can't re-click our own GUI (GetMouseLocation is inset-included;
    -- subtract GuiService:GetGuiInset() before comparing with AbsolutePosition).
    local GuiService = game:GetService("GuiService")
    local function mouseOverKoffee()
        if not (window and window.GroupTransparency < 1) then return false end
        local mp = UserInputService:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        local mx, my = mp.X - inset.X, mp.Y - inset.Y
        local wp, ws = window.AbsolutePosition, window.AbsoluteSize
        return mx >= wp.X and mx <= wp.X + ws.X
           and my >= wp.Y and my <= wp.Y + ws.Y
    end
    local function clickMouse()
        if mouseOverKoffee() then return end
        if VIM then
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            return
        end
        if mouse1click then pcall(mouse1click)
        elseif mouse1press and mouse1release then
            pcall(mouse1press); task.wait(); pcall(mouse1release)
        end
    end
    -- UNIVERSAL SILENT AIM: hooks the three fire-ray shapes (mouse reads,
    -- camera-rays, direct Workspace rays). Camera-ray + mouse reads redirect
    -- exactly; direct-cast rays only rotate the DIRECTION (never origin) and
    -- only when forward-facing (dir . LookVector > 0.5) and long-range (> 20),
    -- so camera-collision (Popper) and probe rays are skipped untouched.
    -- Hooks install once per session; all logic lives in getgenv-published
    -- resolvers so every re-exec just rewires the bodies.
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
            -- v0.1.2 Second-Camera method: fully engagement-gated. Reads pass through
            -- REAL unless an actual shot is happening (optional activation key held +
            -- LMB down / post-click window). Between shots the game sees 100% vanilla
            -- aim data; during the window the full spoof set runs (v0.1.4).
            if Combat.Silent.Method == "Second-Camera" then
                if Combat.Silent.ActivationKey and not silentHeld then return false end
                return lmbDown or (os.clock() - lmbClickAt) < 0.12
            end
            if Combat.Silent.RequireLMB and not lmbDown then return false end
            return true
        end
        -- v0.0.64 Pos Spoof arm gate: active whenever a target is acquired (NO RequireLMB --
        -- "doesn't need left-click"). Only gated by the module + an optional activation key.
        -- v0.2.0: renamed Pos Spoof -> Wallbang and gated to the Raycast method ONLY. Under
        -- Forced MB / Second-Camera this is a hard no-op (posFire() collapses to false), so
        -- every legacy posFire()-guarded spoof block below is dormant unless the user picks
        -- Method = "Raycast". Wallbang's actual effect lives in the workspace:Raycast branch.
        local function posArmed()
            if Combat.Silent.Method ~= "Raycast" then return false end
            if not Combat.Silent.Wallbang then return false end
            if not (Combat.Silent.Enabled and silentPos and silentTarget) then return false end
            if Combat.Silent.ActivationKey and not silentHeld then return false end
            return true
        end
        -- v0.0.68: Pos Spoof only manipulates the ORIGIN during the actual shot (LMB frame).
        -- Doing it every frame corrupted the viewmodel (FpsController reads Camera.CFrame for
        -- BOTH the arms/gun render AND the shot) -- that broke the aim entirely. Gated to the
        -- fire frame, the viewmodel is normal between shots and only the shot gets moved.
        -- v0.0.75: RequireLMB OFF -> Pos Spoof fires continuously (matches silent aim's own
        -- RequireLMB behaviour); RequireLMB ON -> gated to the click frame + 120ms window so
        -- single-shot pistols/snipers that read one frame late still land. Fixes "pistols
        -- don't wallbang unless you hold left click" on games where the weapon reads mouse.Hit
        -- before our lmbDown flag flips.
        local function posFire()
            if not posArmed() then return false end
            -- v0.1.2: Second-Camera always rides the shot window (RequireLMB is
            -- inherent to the method -- the click IS the engagement).
            if Combat.Silent.Method == "Second-Camera" then
                return lmbDown or (os.clock() - lmbClickAt) < 0.12
            end
            if not Combat.Silent.RequireLMB then return true end
            return lmbDown or (os.clock() - lmbClickAt) < 0.12
        end
        -- Camera.CFrame spoof gate for Forced MB lives inline in resolveIndex now
        -- (v0.1.8: RequireLMB-off is continuous for non-writer callers; learned camera
        -- writers stay click-window gated). The old camFire() helper is gone.
        -- the wallbang shot geometry: origin 3 studs IN FRONT of the target (your side, past
        -- any wall between you and them), aimed AT the target -> the client raycast hits them
        -- with no wall in the way. Uses cached camPos (no Camera re-read inside the hook).
        local function wallShot()
            local cp = SR.camPos
            if not cp then return silentPos, Vector3.new(0, 0, -1) end
            local d = silentPos - cp
            if d.Magnitude < 1e-3 then return silentPos, Vector3.new(0, 0, -1) end
            d = d.Unit
            return silentPos - d * 3, d
        end
        -- optional diagnostic: getgenv().KoffeePosDebug -> throttled log of what got spoofed
        -- for which calling script (confirms the weapon's reads are being caught).
        local lastDbg = 0
        local function dbg(what)
            if not (genv and genv.KoffeePosDebug) then return end
            local now = os.clock()
            if now - lastDbg < 0.5 then return end
            lastDbg = now
            print("[koffee][pos] spoofed " .. what .. " caller=" .. tostring(getCS and getCS()))
        end
        -- v0.1.6: outbound-path diagnostic -- throttled log of EVERY FireServer/InvokeServer
        -- from a learned-controller script: arg types + whether any shape matched. This is
        -- how you tell "rewrite never fired" from "fired but the game uses buffer blobs".
        local lastOutDbg = 0
        -- SAFE default: redirect ONLY the Mouse's own aim reads (Hit / Target /
        -- UnitRay). These are what FE weapons read and NOTHING else in the engine
        -- touches, so cameras, Popper occlusion, physics and other scripts stay
        -- untouched -- this is why the default never breaks the game / camera.
        local function resolveIndex(self, key)
            -- v0.3.0: External method delegates ALL silent-aim work to KoffeeHelper.exe
            -- over localhost HTTP. Under this method, every Lua-side spoof stays dormant
            -- so the game sees 100% vanilla client behaviour -- the raycast rewrite
            -- happens inside Roblox via the helper's inline hook on the raycast bound
            -- function, not here.
            if Combat.Silent.Method == "External" then return PASS_H, PASS_V end
            -- (A) Mouse aim reads (Hit/Target/UnitRay) -- safe on every game, no caller
            -- scoping needed (nothing but aim code reads these). v0.0.35 behaviour.
            if (key == "Hit" or key == "Target" or key == "UnitRay")
               and typeof(self) == "Instance" and self:IsA("Mouse") then
                if not isArmed() then return PASS_H, PASS_V end
                local pos, tgt = silentPos, silentTarget
                if key == "Hit" then return true, CFrame.new(pos) end
                if key == "Target" then return true, tgt end
                -- UnitRay: Pos Spoof (fire frame) -> origin in front of the target (wallbang);
                -- else the real camera origin (direction to target). Pos Spoof is
                -- gated off in safe mode -- keep the plain camera-origin ray.
                -- v0.2.0: Raycast method's wallbang lives ONLY in the workspace:Raycast
                -- branch (see resolveNamecall). Skip the UnitRay wallshot cascade so
                -- the mouse.UnitRay fallback stays honest camera->target under Raycast.
                if not Combat.Silent._safe and Combat.Silent.Method ~= "Raycast"
                   and posFire() then local o, d = wallShot(); return true, Ray.new(o, d) end
                if SR.camPos then return true, Ray.new(SR.camPos, (pos - SR.camPos).Unit) end
                return PASS_H, PASS_V
            end
            -- v0.0.96 SAFE MODE: everything below (Camera.CFrame spoof, Mouse.X/Y
            -- spoof, Pos Spoof part reads) is skipped on weak execs -- these paths
            -- are the ones that freeze/dump the game on runtimes that can't hold a
            -- stable hookmetamethod C-closure across the extra scoping work. Mouse
            -- aim reads above are enough for basic silent aim on client-authoritative
            -- games; server-authoritative wallbang stays disabled here.
            if Combat.Silent._safe then return PASS_H, PASS_V end
            -- (B) v0.0.39 FIRE-READ: spoof the aim the instant the WEAPON SCRIPT reads
            -- Camera.CFrame or the cursor -- scoped by getcallingscript so the real
            -- camera/renderer is never modified. Camera.CFrame is gated by camFire
            -- (fire-frame window; continuous spoof froze custom camera controllers);
            -- Mouse.X/Y uses isArmed (continuous -- only aim code reads mouse coords).
            -- v0.1.5 Second-Camera: the CFrame gate is ENGAGEMENT, not the click window.
            -- While armed (target + activation key if set), weapon-facing callers get the
            -- bent CFrame CONTINUOUSLY and learned renderers (writer-detector) always get
            -- real CFrame via spoofAim -- so a separate controller never moves your view,
            -- spray or not. Merged handler+weapon games degrade (their script writes the
            -- camera -> excluded -> switch to Forced MB there).
            local scCam = false
            if Combat.Silent.Method == "Second-Camera" then
                scCam = silentPos ~= nil
                    and (not Combat.Silent.ActivationKey or silentHeld)
            elseif Combat.Silent.Method == "Forced Magic-Bullet" and silentPos then
                -- Forced MB. v0.1.8: Require Left-Click OFF is now TRULY continuous --
                -- v0.2.0: explicit method match -- Raycast method never spoofs Camera.CFrame.
                -- the CFrame bend no longer collapses to the click window, EXCEPT for
                -- learned camera WRITERS (writer-detector set), which stay window-gated
                -- so custom-camera games can't freeze/crash under continuous spoofing
                -- (v0.0.89 lesson) while every pure-reader weapon script gets the
                -- always-on bend RequireLMB-off promises.
                if Combat.Silent.RequireLMB then
                    scCam = lmbDown or (os.clock() - lmbClickAt) < 0.12
                else
                    local msrc = getCS and getCS()
                    local mset = (msrc and genv) and genv[KID.ctx.keys.ctrl]
                    if mset and rawget(mset, msrc) then
                        scCam = lmbDown or (os.clock() - lmbClickAt) < 0.12
                    else
                        scCam = true
                    end
                end
            end
            if scCam then
                -- Camera.CFrame spoof, scoped by spoofAim (never the camera system).
                --   default (Forced MB): origin stays REAL, look-direction bends to target.
                --   Pos Spoof + fire frame: camera moves to 3 studs in FRONT of the target,
                --     looking at it, so a camera-origin gun raycasts into them through the wall
                --     (WALLBANG). Only on the shot frame, so the viewmodel stays normal.
                if key == "CFrame" and self == SR.cam and SR.camPos and silentPos then
                    if SR.spoofAim(getCS and getCS()) then
                        -- crash-safety: skip spoof if SR.camPos and silentPos coincide
                        -- (CFrame.new(pos, look) with pos == look produces NaN orientation
                        -- which can crash renderers / game scripts consuming the result).
                        if (silentPos - SR.camPos).Magnitude > 1e-3 then
                            dbg("Camera.CFrame")
                            if posFire() then
                                local o, d = wallShot(); return true, CFrame.new(o, o + d)
                            end
                            return true, CFrame.new(SR.camPos, silentPos)
                        end
                    end
                end
            end
            -- v0.2.0: Mouse.X/Y is a Forced-MB/Second-Camera fire read (cursor spoof).
            -- Not raycast-flavored -- skipped under the Raycast method.
            if isArmed() and Combat.Silent.Method ~= "Raycast" then
                if (key == "X" or key == "Y") and self == SR.mouse and SR.screen then
                    if SR.spoofAim(getCS and getCS()) then
                        return true, (key == "X") and SR.screen.X or SR.screen.Y
                    end
                end
            end
            -- (C) v0.0.64/65 POS SPOOF: report YOUR character/tool part + attachment positions
            -- as the target's, so the game's fire code builds the shot ORIGIN from inside the
            -- enemy (wallbang -- the server ray starts inside them, no wall in the way, any
            -- range). Broad set = all character descendants incl. the gun's muzzle parts /
            -- attachments, so guns reading the tool position (not just HRP) land too. Real
            -- parts never move. Scoped by spoofAim (camera + Koffee excluded); no LMB gate.
            -- v0.2.0: Raycast method owns origin manipulation via workspace:Raycast ONLY --
            -- character/tool part reads stay honest so animations, IK and non-fire game
            -- systems that peek at those parts see truth. This block is legacy for the
            -- (now-dormant) Forced MB Pos Spoof; posFire() is already Raycast-gated but the
            -- explicit method guard keeps the intent readable.
            if posFire() and Combat.Silent.Method ~= "Raycast" then
                local sp = SR.spoofParts
                if sp and sp[self] then
                    if key == "Position" or key == "WorldPosition" then
                        if SR.spoofAim(getCS and getCS()) then dbg("part.Position"); return true, silentPos end
                    elseif key == "CFrame" or key == "WorldCFrame" then
                        if SR.spoofAim(getCS and getCS()) then dbg("part.CFrame"); return true, CFrame.new(silentPos) end
                    end
                elseif self == SR.mouse and key == "Origin" then
                    if SR.spoofAim(getCS and getCS()) then return true, CFrame.new(silentPos) end
                end
            end
            return PASS_H, PASS_V
        end
        local function resolveNamecall(self, method, args)
            -- v0.3.0: External method offloads everything to KoffeeHelper (see
            -- resolveIndex head comment). Every namecall passes through vanilla.
            if Combat.Silent.Method == "External" then return PASS_H, PASS_V end
            -- v0.0.39 fire-read universal path (always on -- "Forced Magic-Bullet").
            -- CRITICAL: NOTHING in here may perform a Roblox namecall (a `:` method
            -- call). getnamecallmethod reads one shared C state, so a nested namecall
            -- while a real FireServer is dispatching corrupts it and bricks the weapon
            -- after one shot (this was the "one bullet then the gun dies" bug). Only
            -- global-fn calls, plain-table reads, property (__index) reads, equality
            -- and constructors are used below -- no namecalls.
            -- v0.0.64 POS SPOOF: Character:GetPivot()/GetPrimaryPartCFrame -> target CFrame,
            -- BEFORE the LMB gate (Pos Spoof doesn't require left-click). Namecall-free.
            -- v0.2.0: legacy Forced-MB spoof -- Raycast method skips this (same reasoning
            -- as the part.Position block: origin manipulation is workspace:Raycast-only).
            if method == "GetPivot" or method == "GetPrimaryPartCFrame" then
                if posFire() and Combat.Silent.Method ~= "Raycast"
                   and self == SR.char and SR.spoofAim(getCS and getCS()) then
                    return true, CFrame.new(silentPos)
                end
                return PASS_H, PASS_V
            end
            -- v0.1.6 OUTBOUND REWRITE (Second-Camera only): games whose weapon script
            -- WRITES the camera while firing (recoil / ADS / sway) can't have their reads
            -- bent at ALL without dragging the view (the writer-detector excludes them
            -- absolutely -- a click-window waiver was tried and ripped same-day: bending a
            -- writer's reads at ANY time bends the view, because it writes back what it
            -- read). So for those scripts the reads stay REAL forever and the shot
            -- direction is rewritten inside the OUTGOING remote args instead: the client
            -- sees truth, the wire carries the lock. Surgical rules (v0.0.43/72 lesson --
            -- never clobber blind):
            --   * only callers already in the learned controller set are touched
            --   * direction-shaped Vector3s (sub-8 magnitude, within ~41 deg of the real
            --     look dir) rotate to aim at the target from the shooter's root; the
            --     original magnitude is preserved
            --   * point-shaped Vector3s (>50 studs out, within 12 studs of the look ray)
            --     move onto the target's hit point
            --   * Rays keep their EXACT origin; only the direction rotates
            --   * everything else passes untouched -- args are never dropped/reordered/
            --     invented, so unmatched schemas behave exactly vanilla
            -- Namecall-safe: typeof / component math / constructors only -- no :Dot(),
            -- :Unit() etc. on vectors (same shared-C-state rule as everything else here).
            if method == "FireServer" or method == "InvokeServer" then
                if Combat.Silent.Method ~= "Second-Camera" then return PASS_H, PASS_V end
                if not (silentPos and silentTarget and SR.camLook) then return PASS_H, PASS_V end
                if Combat.Silent.ActivationKey and not silentHeld then return PASS_H, PASS_V end
                local src = getCS and getCS()
                local set = (src and genv) and genv[KID.ctx.keys.ctrl]
                if not (set and rawget(set, src)) then return PASS_H, PASS_V end
                local origin = SR.rootPos or SR.camPos
                local lk = SR.camLook
                if not (origin and lk) then return PASS_H, PASS_V end
                local changed = false
                local matched = ""
                local touched = nil
                for i = 1, args.n do
                    local a = args[i]
                    local t = typeof(a)
                    if t == "Vector3" then
                        local m = a.Magnitude
                        if m > 1e-4 and m < 8 then
                            -- direction-shaped: near the real look direction?
                            if (a.X * lk.X + a.Y * lk.Y + a.Z * lk.Z) / m > 0.75 then
                                local nd = silentPos - origin
                                local nl = (nd.X * nd.X + nd.Y * nd.Y + nd.Z * nd.Z) ^ 0.5
                                if nl > 1e-3 then
                                    local s = m / nl
                                    args[i] = Vector3.new(nd.X * s, nd.Y * s, nd.Z * s)
                                    changed = true
                                    matched = matched .. i .. "(dir) "
                                end
                            end
                        elseif m >= 50 and SR.camPos then
                            -- point-shaped: far away AND hugging the look ray?
                            local rx, ry, rz = a.X - SR.camPos.X, a.Y - SR.camPos.Y, a.Z - SR.camPos.Z
                            local proj = rx * lk.X + ry * lk.Y + rz * lk.Z
                            if proj > 10 then
                                local px, py, pz = rx - lk.X * proj, ry - lk.Y * proj, rz - lk.Z * proj
                                if (px * px + py * py + pz * pz) ^ 0.5 < 12 then
                                    args[i] = silentPos
                                    changed = true
                                    matched = matched .. i .. "(pt) "
                                end
                            end
                        end
                    elseif t == "Ray" then
                        local o = a.Origin
                        local nd = silentPos - o
                        local nl = (nd.X * nd.X + nd.Y * nd.Y + nd.Z * nd.Z) ^ 0.5
                        if nl > 1e-3 then
                            local s = a.Direction.Magnitude / nl
                            args[i] = Ray.new(o, Vector3.new(nd.X * s, nd.Y * s, nd.Z * s))
                            changed = true
                            matched = matched .. i .. "(ray) "
                        end
                    end
                end
                if genv and genv.KoffeePosDebug then
                    local now2 = os.clock()
                    if now2 - lastOutDbg > 0.5 then
                        lastOutDbg = now2
                        local types = {}
                        for i = 1, args.n do types[i] = typeof(args[i]) end
                        print("[koffee][pos] outbound src=" .. tostring(src)
                            .. " n=" .. tostring(args.n)
                            .. " types=" .. table.concat(types, ",")
                            .. " matched=" .. (matched ~= "" and matched or "none"))
                    end
                end
                if changed then return "call", args end
                return PASS_H, PASS_V
            end
            -- v0.0.81: Wallbang Raycast REMOVED (as an always-on Forced-MB add-on). Was
            -- detected by some ACs, didn't work on Gun Grounds FFA (camera-baked-arg class
            -- -- see v0.0.42/74 history), and didn't cover Jack's tested game (the
            -- KoffeePosDebug log from v0.0.78 showed only Camera.CFrame spoofs + one stray
            -- raycast intercept -- the weapon doesn't call workspace raycasts at fire time).
            -- v0.2.0: RE-ADDED, opt-in, as the "Raycast" method (see branch below). Now it
            -- is a top-level Method choice instead of an always-on cascade -- users pick it
            -- specifically for FE FPS raycast weapons (Phantom Forces / Arsenal / Aimblox
            -- class). Wallbang rides on this method exclusively.
            if not isArmed() then return PASS_H, PASS_V end
            -- v0.2.0 RAYCAST METHOD: universal workspace:Raycast rewrite for games whose
            -- weapon builds its own ray (muzzle attachment / camera vector) and passes it
            -- straight into workspace:Raycast -- these skip every Mouse/Camera read the
            -- Forced-MB spoofs catch. Direction rotates to point at the target from the
            -- caller's real origin; magnitude preserved so range checks pass. Wallbang
            -- (posFire) additionally moves the origin to 3 studs in FRONT of the target so
            -- the client ray reaches them through any wall. Gate order (namecall-safe: only
            -- constructors + component math, zero `:` calls):
            --   * dir.Magnitude > 20  -- skip probe/occlusion/IK rays
            --   * dir approx aligned with camLook OR with (target - origin)  -- fire-shaped only
            -- Cheap comparisons short-circuit the 99% pass-through case.
            if method == "Raycast" and self == Workspace then
                if Combat.Silent.Method ~= "Raycast" then return PASS_H, PASS_V end
                if not silentPos then return PASS_H, PASS_V end
                local origin, dir, rparams = args[1], args[2], args[3]
                if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" then return PASS_H, PASS_V end
                local mag = dir.Magnitude
                if mag < 20 then return PASS_H, PASS_V end
                local unit = dir / mag
                local aim = silentPos - origin
                local aimMag = aim.Magnitude
                if aimMag < 1e-3 then return PASS_H, PASS_V end
                local aimUnit = aim / aimMag
                local look = SR.camLook
                local dotLook = look and (look.X*unit.X + look.Y*unit.Y + look.Z*unit.Z) or -1
                local dotAim  = aimUnit.X*unit.X + aimUnit.Y*unit.Y + aimUnit.Z*unit.Z
                if dotLook < 0.5 and dotAim < 0.5 then return PASS_H, PASS_V end
                if posFire() then
                    local wo = silentPos - aimUnit * 3
                    dbg("workspace:Raycast (wallbang)")
                    return "call", { wo, aimUnit * mag, rparams }
                end
                dbg("workspace:Raycast")
                return "call", { origin, aimUnit * mag, rparams }
            end
            -- v0.2.0: ViewportPointToRay/ScreenPointToRay + GetMouseLocation are
            -- Forced-MB/Second-Camera fire reads. Skipped under Raycast method (that
            -- method deliberately touches ONLY Mouse.Hit reads + workspace:Raycast).
            if Combat.Silent.Method == "Raycast" then return PASS_H, PASS_V end
            -- camera-ray / cursor methods the game uses to build its shot. Direction bends to
            -- the target; on the Pos Spoof fire frame the ORIGIN moves in front of the target
            -- (wallbang), else real (SR.camPos). spoofAim excludes the camera + Koffee. Namecall-free.
            if method == "ViewportPointToRay" or method == "ScreenPointToRay" then
                if silentPos and SR.camPos and SR.spoofAim(getCS and getCS()) then
                    if posFire() then local o, d = wallShot(); return true, Ray.new(o, d) end
                    return true, Ray.new(SR.camPos, (silentPos - SR.camPos).Unit)
                end
            elseif method == "GetMouseLocation" then
                if SR.screen and SR.spoofAim(getCS and getCS()) then
                    return true, SR.screen
                end
            end
            return PASS_H, PASS_V
        end
        -- publish resolvers under obfuscated session-stable keys (no static "Koffee*" in getgenv)
        local K = KID.ctx.keys
        if genv then
            genv[K.ri]  = resolveIndex
            genv[K.nc]  = resolveNamecall
            genv[K.res] = function() return silentPos, silentTarget end
            -- v0.1.5: learned camera-controller set (weak keys -> destroyed scripts GC out).
            -- Session-stable: survives re-exec so what a game taught us isn't unlearned.
            if not genv[K.ctrl] then
                genv[K.ctrl] = setmetatable({}, { __mode = "k" })
            end
        end

        -- HOOK BODY: installed once per session, forever. Delegates to the repointable
        -- resolvers above so re-exec rewires behaviour without reinstalling the hook.
        if genv and genv[K.hooked] then return end
        if genv then genv[K.hooked] = true end
        pcall(function()
            local hookmm   = hookmetamethod
            local ncmethod = getnamecallmethod
            local ccaller  = checkcaller   -- true => called from our own executor thread
            if not hookmm then return end

            -- v0.0.96 SAFE MODE branch. On runtimes flagged by the load-time exec
            -- prompt (anything not on the known-good list), silent aim installs
            -- ONLY the __index hook, without newcclosure wrapping, without the
            -- __namecall hook, and the resolver never runs the Camera.CFrame /
            -- pos-spoof / wallshot paths (see Combat.Silent._safe checks inside
            -- resolveIndex). This avoids the newcclosure+__namecall pairing that
            -- freezes lightweight runtimes when a weapon triggers a FireServer
            -- redirect. Result: less powerful silent aim (no wallbang, no server-
            -- side forced-mb via namecall), but the game doesn't crash. Trade-off
            -- is what the popup asked the user about.
            local safe = Koffee._safeMode == true
            Combat.Silent._safe = safe
            local wrap = safe and function(f) return f end
                                or (newcclosure or function(f) return f end)

            local oldIndex
            oldIndex = hookmm(game, "__index", wrap(function(self, key)
                -- our own reads are never spoofed; also defeats trap-callbacks that
                -- run in our context and probe the hook behaviorally.
                if ccaller and ccaller() then return oldIndex(self, key) end
                local r = genv and genv[K.ri]
                if r then
                    local ok, handled, value = pcall(r, self, key)
                    if ok and handled then return value end
                end
                return oldIndex(self, key)
            end))

            if not safe then
                local oldNc
                oldNc = hookmm(game, "__namecall", wrap(function(self, ...)
                    -- Capture method BEFORE anything else. NEVER do a nested namecall here --
                    -- getnamecallmethod reads one shared C state; a nested namecall while a
                    -- real FireServer is dispatching corrupts it and bricks the weapon after
                    -- one shot ("one bullet then the gun dies" bug, fixed in v0.0.40).
                    local m = ncmethod and ncmethod() or ""
                    if ccaller and ccaller() then return oldNc(self, ...) end
                    local r = genv and genv[K.nc]
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

                -- v0.1.5 Second-Camera WRITER-DETECTOR: any game script that writes
                -- Camera.CFrame is a camera RENDERER/CONTROLLER (FpsController, custom
                -- orbit cams...). Recorded session-stable under K.ctrl (weak keys --
                -- destroyed scripts GC out) and excluded from spoofing by SR.spoofAim.
                -- Two cheap comparisons short-circuit the 99.9% case; only CFrame writes
                -- on the current camera do work. getcallingscript is a plain read here
                -- (no namecall involved), so this is hook-body safe.
                local gcs = getcallingscript
                local oldWi
                oldWi = hookmm(game, "__newindex", wrap(function(self, k, v)
                    if Combat.Silent.Method == "Second-Camera"
                        and k == "CFrame" and self == SR.cam then
                        if ccaller and ccaller() then return oldWi(self, k, v) end
                        if gcs then
                            local src = gcs()
                            if src and src ~= SR.own then
                                local set = genv[K.ctrl]
                                if set then set[src] = true end
                            end
                        end
                    end
                    return oldWi(self, k, v)
                end))
            end
        end)
    end

    --== render loops ==--
    -- aimbot: run AFTER every camera controller in the game (Last+1) so our
    -- CFrame is the final write before render -- fast mouse movement can't shake
    -- a Perfect Lock. cold-start safety: a prior run's binding survives re-exec
    -- and re-binding the same name throws -- unbind first so the loader can be
    -- re-run cleanly.
    pcall(function() RunService:UnbindFromRenderStep(KID.ctx.bind) end)
    RunService:BindToRenderStep(KID.ctx.bind, Enum.RenderPriority.Last.Value + 1, function()
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
        -- v0.0.97 true sticky: hold the locked player across FOV / off-screen, only
        -- drop when the player dies / respawns / leaves. The aim math (lookAt /
        -- aimCFrame) handles a target behind the camera by rotating back toward it,
        -- so the locked victim is chased off-screen too -- not replaced the moment
        -- they leave the FOV circle. Falls through to getBestTarget for a fresh lock
        -- only when there's no valid held target.
        if Combat.Aim.Sticky and Combat.Aim._target then
            local t = Combat.Aim._target
            local char = t.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local p = aimPart(char, Combat.Aim.HitPart)
                -- v0.0.97: respect the Distance rule even for a held sticky target --
                -- if they run beyond Combat.Aim.Distance the lock releases and a fresh
                -- target is acquired inside range.
                if p then
                    local distOk = (not Combat.Aim.Distance)
                                or ((p.Position - cam.CFrame.Position).Magnitude <= Combat.Aim.Distance)
                    if distOk then
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
        -- v0.0.86 sensitivity curve reshape. Was linear 0.01..1 -- 0.08 was already
        -- fast because 8% per frame converges to target in a few frames. Now sens^1.5
        -- pushes the low end down without touching the max: 1.0 -> 1.0 (perfect lock),
        -- 0.5 -> 0.354 (moderate), 0.08 -> 0.023 (smooth pull), 0.01 -> 0.001 (glacial).
        -- Endpoints preserved so users' existing feel at max/near-max is unchanged.
        local rawSens = math.clamp(Combat.Aim.Sensitivity, 0.01, 1)
        local sens = rawSens * math.sqrt(rawSens)   -- sens^1.5
        local aX, aY = sens, sens
        if Combat.Aim.Smooth.Enabled then
            aX = math.clamp(sens / math.max(Combat.Aim.Smooth.X, 0.01), 0, 1)
            aY = math.clamp(sens / math.max(Combat.Aim.Smooth.Y, 0.01), 0, 1)
        end

        if Combat.Aim.PerfectLock then
            -- v0.0.97 Perfect Lock: mode-aware. Camera aim type = snap camera
            -- angles straight to the target via aimCFrame with aX=aY=1 (full 1:1
            -- interpolation, no sensitivity / smoothing). Mouse / Third-Person =
            -- move the real mouse cursor straight onto the target's screen point.
            if Combat.Aim.AimType == "Camera" and not Combat.Aim.ThirdPerson then
                cam.CFrame = aimCFrame(cam, cam.CFrame.Position, tpos, 1, 1)
            elseif mousemoverel then
                local sp = cam:WorldToViewportPoint(tpos)
                if sp.Z > 0 then
                    local ml = UserInputService:GetMouseLocation()
                    pcall(mousemoverel, sp.X - ml.X, sp.Y - ml.Y)
                end
            end
        elseif Combat.Aim.ThirdPerson then
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

    -- custom multi-point gradient: Colors/Alphas map LEFT-TO-RIGHT (swatch 1..n).
    -- STATIC: plain linear ramp c1..cn evenly spaced across 0..1.
    -- MOVING: seamless cyclic scroll -- palette is a ring (cn wraps to c1), sampled
    -- at fixed screen positions offset by a phase. pos 0 + pos 1 sample the same
    -- ring point, so no seam and no snap (fixes the "bounce" + stretch).
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
            if Combat.Trigger.TeamCheck and isTeammate(plr) then return nil end
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
    -- v0.0.78: through-walls crosshair check. Iterates players, projects their key
    -- parts (Head/Torso/HRP variants for R6+R15) to screen space via WorldToViewportPoint,
    -- fires if any lands within HitboxMul*5 pixels of the crosshair -- NO occlusion
    -- raycast, so walls between camera and enemy don't block. This is the "trigger
    -- whenever someone goes in the crosshair even through a wall" mode Jack asked for.
    local TRIG_PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }
    local function crosshairEnemyNoOcclusion()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local vp = cam.ViewportSize
        local cx, cy = vp.X * 0.5, vp.Y * 0.5
        local mul = math.max(Combat.Trigger.HitboxMul, 1)
        local r = 5 * mul
        local r2 = r * r
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0
                       and not (Combat.Trigger.TeamCheck and isTeammate(plr))
                       and not (Shared.IgnoreFriends and isFriend(plr)) then
                        for _, name in ipairs(TRIG_PARTS) do
                            local part = char:FindFirstChild(name)
                            if part then
                                local sp = cam:WorldToViewportPoint(part.Position)
                                if sp.Z > 0 then
                                    local dx, dy = sp.X - cx, sp.Y - cy
                                    if (dx * dx + dy * dy) <= r2 then return plr end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end
    -- v0.0.86: silent-link now respects Visible Check. Was firing regardless (v0.0.78)
    -- so with Visible Check ON + Silent Aim armed, trigger fired even when the silent
    -- target was behind a wall -- broke the "visible only" expectation. Now Visible
    -- Check gates BOTH the crosshair path AND the silent-link path.
    --   Visible Check ON  -> only fires if target has line-of-sight (raycast from
    --                        camera to silent target passes; crosshair enemy raycast passes)
    --   Visible Check OFF -> through-walls trigger (silent target OR nearest enemy in
    --                        screen-space crosshair area)
    -- silentHasLOS = camera-to-target raycast that ignores our character. If no wall
    -- between camera and target, it's visible.
    local trigLOSParams = RaycastParams.new()
    trigLOSParams.FilterType = Enum.RaycastFilterType.Exclude
    local function silentHasLOS()
        if not (silentTarget and silentTarget.Parent) then return false end
        local cam = Workspace.CurrentCamera
        if not cam then return false end
        local origin = cam.CFrame.Position
        local target = silentTarget.Position
        trigLOSParams.FilterDescendantsInstances = {
            LocalPlayer.Character, silentTarget.Parent
        }
        local res = Workspace:Raycast(origin, target - origin, trigLOSParams)
        return res == nil   -- nil = ray reached target unobstructed
    end
    local function triggerShouldFire()
        if Combat.Trigger.VisibleCheck then
            -- silent link only fires when target is actually visible
            if silentTarget and silentTarget.Parent and Combat.Silent.Enabled and silentHasLOS() then
                return true
            end
            return crosshairEnemy() ~= nil
        end
        -- through-walls mode: any locked silent target fires
        if silentTarget and silentTarget.Parent and Combat.Silent.Enabled then return true end
        return crosshairEnemyNoOcclusion() ~= nil
    end
    RunService.Heartbeat:Connect(function()
        if not Combat.Trigger.Enabled then return end
        if Combat.Trigger.UseKey and not trigHeld then return end
        if trigBusy then return end
        if not triggerShouldFire() then return end
        trigBusy = true
        task.spawn(function()
            if Combat.Trigger.Delay > 0 then task.wait(Combat.Trigger.Delay / 1000) end
            -- re-confirm right before firing (silent target might have died / crosshair moved)
            if Combat.Trigger.Enabled and triggerShouldFire() then clickMouse() end
            if Combat.Trigger.Release > 0 then task.wait(Combat.Trigger.Release / 1000) end
            trigBusy = false
        end)
    end)

    -- v0.0.88 Hit/Kill sound engine. Universal per-player Humanoid.Health drop
    -- watcher; attribution via the screen-space mouse-target lock (LMB-held
    -- nearest-to-cursor sampling, kept fresh every heartbeat). Cooldowns per
    -- type; suppressed while the menu is open. Presets are <exec>/Koffee/sounds/
    -- mp3 names (getcustomasset per play; CustomId > 0 overrides with a
    -- rbxassetid://). Sound silently no-ops on executors without the API.
    local SND_PRESETS = {
        "12", "agpa2", "basshit", "bell", "blizzard", "bubble", "chockpro",
        "cod", "copperbell", "crowbar", "headshot", "hit", "knob",
        "minecraft orb", "neverlose", "rust", "skeet",
    }
    local SoundService = game:GetService("SoundService")
    local hitSnd = Instance.new("Sound"); hitSnd.Name = "KHitSnd"; hitSnd.Parent = SoundService
    local killSnd = Instance.new("Sound"); killSnd.Name = "KKillSnd"; killSnd.Parent = SoundService
    local lastHitAt, lastKillAt = 0, 0
    local function windowIsOpen()
        return window and window.GroupTransparency < 1
    end
    local function resolveSoundId(cfg)
        if cfg.CustomId and cfg.CustomId > 0 then
            return "rbxassetid://" .. tostring(cfg.CustomId)
        end
        if cfg.Preset and cfg.Preset ~= "" and getcustomasset then
            local ok, id = pcall(getcustomasset, "Koffee/sounds/" .. cfg.Preset .. ".mp3")
            if ok and type(id) == "string" and #id > 0 then return id end
        end
        return nil
    end
    local function playSound(snd, cfg, lastRef)
        if not cfg.Enabled then return lastRef end
        if windowIsOpen() then return lastRef end
        local now = os.clock()
        if (now - lastRef) * 1000 < cfg.Cooldown then return lastRef end
        local id = resolveSoundId(cfg)
        if not id then return lastRef end
        -- v0.0.91 REAL Overlap. v0.0.89's `:Play()` on the same Sound didn't
        -- overlap -- Roblox restarts the sound from TimePosition instead of layering.
        -- Overlap ON now clones the Sound per play (parallel playback stacks),
        -- Ended:Once cleans the clone up. Overlap OFF stops+replays the shared
        -- instance (single-track, no layering).
        if Combat.HitSounds.Overlap then
            local clone = snd:Clone()
            clone.SoundId       = id
            clone.Volume        = cfg.Volume
            clone.PlaybackSpeed = cfg.Pitch
            clone.TimePosition  = 0
            clone.Parent        = SoundService
            pcall(function() clone:Play() end)
            clone.Ended:Once(function() clone:Destroy() end)
        else
            pcall(function() snd:Stop() end)
            snd.SoundId       = id
            snd.Volume        = cfg.Volume
            snd.PlaybackSpeed = cfg.Pitch
            snd.TimePosition  = 0
            pcall(function() snd:Play() end)
        end
        return now
    end
    -- mouse-target tracker: per-Heartbeat sweep of all enemies, pick the one whose
    -- screen point is closest to the mouse cursor within MouseRadius pixels.
    -- Only runs while LMB is held (accurate attribution for both single-shot AND
    -- auto weapons -- per-shot in bursts each contributes its own held-LMB frame).
    SR.mouseTgt = nil
    -- v0.0.92 mouse-target lock. Replaces single SR.mouseTgt with a SET of recently-
    -- aimed-at enemies (SR.recentTargets[char] = timestamp). Any Health drop on a
    -- char in the set within AttrWindow seconds counts as YOUR hit. Fixes sniper
    -- case: fast-tap LMB, damage lands 200ms later after `lmbDown` already flipped
    -- back to false. Also handles multiple in-flight shots in FFA (each captured
    -- target ages independently).
    -- Sampling: `sampleMouseEnemy()` finds closest enemy to cursor in front of camera
    -- (no radius filter -- v0.0.91). Called on Heartbeat while LMB held (auto-fire)
    -- + on LMB press edge (guaranteed sample at press moment even for sub-frame taps).
    SR.recentTargets = {}
    local function sampleMouseEnemy()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local ml = UserInputService:GetMouseLocation()
        local mx, my = ml.X, ml.Y
        local best, bestD = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char and not (Shared.IgnoreFriends and isFriend(plr)) then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local part = char:FindFirstChild("Head")
                                  or char:FindFirstChild("HumanoidRootPart")
                                  or char:FindFirstChild("UpperTorso")
                                  or char:FindFirstChild("Torso")
                        if part then
                            local sp = cam:WorldToViewportPoint(part.Position)
                            if sp.Z > 0 then
                                local dx, dy = sp.X - mx, sp.Y - my
                                local d = dx * dx + dy * dy
                                if d < bestD then best, bestD = char, d end
                            end
                        end
                    end
                end
            end
        end
        return best
    end
    local function markMouseTarget()
        local char = sampleMouseEnemy()
        if char then SR.recentTargets[char] = os.clock() end
    end
    local function updateMouseTarget()
        if lmbDown then markMouseTarget() end
        -- cleanup stale entries so the table doesn't grow forever
        local now, window = os.clock(), Combat.HitSounds.AttrWindow
        for c, at in pairs(SR.recentTargets) do
            if now - at > window then SR.recentTargets[c] = nil end
        end
    end
    -- v0.0.93 MULTI-SOURCE HP WATCHER + damage-time buffer for pre-click attribution.
    -- Some games don't use standard Humanoid.Health for their real HP system --
    -- they store it in a NumberValue child ("Health"/"HP"), a character/humanoid
    -- attribute, or both. We scan for all known HP sources on character setup and
    -- watch each. ANY decrement is a hit event, dedup'd per-char (50ms cooldown so
    -- one damage tick that ripples through multiple sources fires ONE sound).
    -- SR.recentDamage[char] = last-drop timestamp. Used by the LMB press-edge
    -- handler to see if the target took damage in the last BeforeClick ms --
    -- bypasses the "you clicked but Koffee's input registered late" delay.
    SR.recentDamage = {}
    local plrHP = {}
    local HP_NUMBERVALUE_NAMES = { "Health", "HP", "Hp", "hp", "CurrentHealth", "health" }
    local HP_ATTRIBUTE_NAMES   = { "Health", "HP", "Hp", "hp", "CurrentHealth" }
    local function untrackHP(plr)
        local st = plrHP[plr]; if not st then return end
        for _, c in ipairs(st.conns) do pcall(function() c:Disconnect() end) end
        if plr.Character then SR.recentDamage[plr.Character] = nil end
        plrHP[plr] = nil
    end
    local function onHpDropped(char, dropped, nowZero)
        -- dedup: ignore if last hit event for this char was <50ms ago (multi-source ripple)
        local last = SR.recentDamage[char]
        local now = os.clock()
        if last and (now - last) < 0.05 then return end
        SR.recentDamage[char] = now

        -- normal attribution path (v0.0.92): check recentTargets + AttrWindow
        local at = SR.recentTargets[char]
        if at and (now - at) <= Combat.HitSounds.AttrWindow then
            SR.recentTargets[char] = nil
            if nowZero then lastKillAt = playSound(killSnd, Combat.HitSounds.Kill, lastKillAt)
            else lastHitAt = playSound(hitSnd, Combat.HitSounds.Hit, lastHitAt) end
        end
    end
    local function bindHumanoid(plr, char)
        local st = plrHP[plr]; if not st then return end
        for i = #st.conns, 2, -1 do
            pcall(function() st.conns[i]:Disconnect() end); st.conns[i] = nil
        end
        st.lastHealth = 100    -- Humanoid.Health baseline; may be unused if the game uses another source
        st.altValues  = {}     -- [Instance] = last-observed .Value for NumberValue sources
        st.altAttrs   = {}     -- [name] = last-observed attribute value

        -- 1. Standard Humanoid.Health
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            task.spawn(function()
                hum = char:WaitForChild("Humanoid", 5)
                if hum and plrHP[plr] then bindHumanoid(plr, char) end
            end)
            return
        end
        st.lastHealth = hum.Health
        table.insert(st.conns, hum:GetPropertyChangedSignal("Health"):Connect(function()
            local nh, old = hum.Health, st.lastHealth
            st.lastHealth = nh
            if nh < old then onHpDropped(char, old - nh, nh <= 0) end
        end))

        -- 2. NumberValue / IntValue children named Health/HP/etc. (recursive scan)
        for _, name in ipairs(HP_NUMBERVALUE_NAMES) do
            local nv = char:FindFirstChild(name, true)
            if nv and (nv:IsA("NumberValue") or nv:IsA("IntValue")) then
                st.altValues[nv] = nv.Value
                table.insert(st.conns, nv:GetPropertyChangedSignal("Value"):Connect(function()
                    local newV = nv.Value
                    local oldV = st.altValues[nv] or newV
                    st.altValues[nv] = newV
                    if newV < oldV then onHpDropped(char, oldV - newV, newV <= 0) end
                end))
            end
        end

        -- 3. Character attributes named Health/HP/etc.
        for _, name in ipairs(HP_ATTRIBUTE_NAMES) do
            local v = char:GetAttribute(name)
            if type(v) == "number" then
                st.altAttrs[name] = v
                table.insert(st.conns, char:GetAttributeChangedSignal(name):Connect(function()
                    local newV = char:GetAttribute(name)
                    if type(newV) ~= "number" then return end
                    local oldV = st.altAttrs[name] or newV
                    st.altAttrs[name] = newV
                    if newV < oldV then onHpDropped(char, oldV - newV, newV <= 0) end
                end))
            end
        end

        -- 4. Humanoid attributes named Health/HP/etc.
        for _, name in ipairs(HP_ATTRIBUTE_NAMES) do
            local v = hum:GetAttribute(name)
            if type(v) == "number" then
                st.altAttrs["hum_" .. name] = v
                table.insert(st.conns, hum:GetAttributeChangedSignal(name):Connect(function()
                    local newV = hum:GetAttribute(name)
                    if type(newV) ~= "number" then return end
                    local oldV = st.altAttrs["hum_" .. name] or newV
                    st.altAttrs["hum_" .. name] = newV
                    if newV < oldV then onHpDropped(char, oldV - newV, newV <= 0) end
                end))
            end
        end
    end
    local function trackHP(plr)
        if plr == LocalPlayer or plrHP[plr] then return end
        plrHP[plr] = { lastHealth = 100, conns = {}, altValues = {}, altAttrs = {} }
        table.insert(plrHP[plr].conns, plr.CharacterAdded:Connect(function(char) bindHumanoid(plr, char) end))
        if plr.Character then bindHumanoid(plr, plr.Character) end
    end
    for _, plr in ipairs(Players:GetPlayers()) do trackHP(plr) end
    Players.PlayerAdded:Connect(trackHP)
    Players.PlayerRemoving:Connect(untrackHP)
    RunService.Heartbeat:Connect(updateMouseTarget)

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
        -- v0.0.39: resolve PlayerModule here (namecall-safe) so isView never has to
        -- FindFirstChild inside a hook (a nested namecall would brick the weapon).
        if not SR.pm then
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            SR.pm = ps and ps:FindFirstChild("PlayerModule")
        end
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
            -- v0.0.39: cache the real camera + target's screen point so the fire-read
            -- resolvers never re-read Camera.* inside the __index hook (recursion).
            local cam = Workspace.CurrentCamera
            local cf
            if cam then
                SR.cam = cam
                cf = cam.CFrame
                SR.camPos = cf.Position
                -- v0.1.6: real look direction, cached namecall-safe (outbound arg-rewrite)
                SR.camLook = cf.LookVector
                local sp = cam:WorldToViewportPoint(silentPos)
                SR.screen = Vector2.new(sp.X, sp.Y)
            end
            -- v0.0.64/65: cache the character + a SET of every part/attachment whose position
            -- reads Pos Spoof should fake (all character descendants incl. the equipped tool's
            -- muzzle parts + attachments -- not just HRP, so guns that build their origin from
            -- the gun/muzzle land too). Built here (namecall-safe) so the hooks only do a table
            -- lookup, never a namecall.
            local ch = LocalPlayer.Character
            SR.char = ch
            -- v0.1.6: own root position cached namecall-safe (outbound arg-rewrite origin)
            local rt = ch and (ch:FindFirstChild("HumanoidRootPart") or (findTorso and findTorso(ch)))
            if rt then SR.rootPos = rt.Position else SR.rootPos = nil end
            local sp = {}
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("Attachment") or d:IsA("Bone") then sp[d] = true end
                end
            end
            SR.spoofParts = sp
        else
            silentTarget = nil; silentPos = nil
            SR.camPos = nil; SR.screen = nil
            SR.camLook = nil; SR.rootPos = nil
        end
    end)


    --== input: rebind capture + activation ==--
    UserInputService.InputBegan:Connect(function(input, gpe)
        -- v0.0.35: track LMB regardless of gpe so the silent redirect's RequireLMB
        -- gate is accurate (this flag replaces IsMouseButtonPressed polling).
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            lmbDown = true; lmbClickAt = os.clock()
            -- v0.0.92 sample the mouse target IMMEDIATELY on press edge, not just
            -- on the next Heartbeat -- catches sub-frame LMB taps (fast snipers)
            -- where the button's released before another Heartbeat can sample.
            if markMouseTarget then pcall(markMouseTarget) end
            -- v0.0.93 PRE-CLICK check: if the current mouse target has dropped
            -- Health in the last BeforeClick ms (bypasses the "your click
            -- registered after the game's own damage tick" delay), fire the
            -- sound on THIS press even though the drop already happened.
            if sampleMouseEnemy and playSound then
                local char = sampleMouseEnemy()
                if char and SR.recentDamage and SR.recentDamage[char] then
                    local ago = os.clock() - SR.recentDamage[char]
                    if ago <= (Combat.HitSounds.BeforeClick / 1000) then
                        SR.recentDamage[char] = nil   -- consume so heartbeat handler doesn't double-fire
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then
                            lastKillAt = playSound(killSnd, Combat.HitSounds.Kill, lastKillAt)
                        else
                            lastHitAt = playSound(hitSnd, Combat.HitSounds.Hit, lastHitAt)
                        end
                    end
                end
            end
        end
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
        -- v0.0.97 TARGET LOCK toggle key: armed + key pressed -> flip the lock.
        if Shared.TargetLock.Enabled and Shared.TargetLock.Key
        and inputMatches(input, Shared.TargetLock.Key) then
            Shared.TargetLock._active = not Shared.TargetLock._active
            if tlStatusUpdater then tlStatusUpdater() end
            return
        end
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
    -- v0.0.69: a SECOND click signal off the PlayerMouse. It fires in a different order than
    -- UserInputService.InputBegan, so on games where the weapon's InputBegan runs before ours
    -- this may set lmbDown earlier (helps single-shot pistols/snipers where the game processes
    -- the click first). Not a full fix -- true pre-arming needs the external program.
    pcall(function()
        local m = LocalPlayer:GetMouse()
        m.Button1Down:Connect(function() lmbDown = true; lmbClickAt = os.clock() end)
        m.Button1Up:Connect(function() lmbDown = false end)
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
    local pXB = { false, false }   -- last two locals this frame may hold
    RunService.Heartbeat:Connect(function()
        local xb1, xb2 = Helper.XB1, Helper.XB2
        local e1, e2 = (xb1 and not pXB[1]), (xb2 and not pXB[2])   -- press edges
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
        -- v0.0.97 TARGET LOCK: toggle the lock on a virtual XButton edge
        if type(Shared.TargetLock.Key) == "string" then
            if Shared.TargetLock.Enabled and edge(Shared.TargetLock.Key) then
                Shared.TargetLock._active = not Shared.TargetLock._active
                if tlStatusUpdater then tlStatusUpdater() end
            end
        end

        pXB[2], pXB[1] = xb2, xb1
    end)

    --== modules (arraylist + master toggles) ==--
    registerModule("aimbot", "Aimbot",
        function() Combat.Aim.Enabled = true end,
        function() Combat.Aim.Enabled = false; aimHeld = false; Combat.Aim._target = nil; Combat.Aim._rageLock = nil end)
    -- v0.0.79: diagnostic prints on trigger enable/disable so we can see WHO is
    -- toggling it if the checkbox "immediately turns off" -- caller stack tells us
    -- if it's the click, a config load, a keybind, or something else.
    registerModule("triggerbot", "Trigger Bot",
        function()
            Combat.Trigger.Enabled = true
            if getgenv and getgenv().KoffeeTrigDebug then
                print("[koffee][trig] ENABLE @ " .. tostring(os.clock()) .. "  stack=" .. tostring(debug.traceback and debug.traceback("", 2) or "?"))
            end
        end,
        function()
            Combat.Trigger.Enabled = false; trigHeld = false
            if getgenv and getgenv().KoffeeTrigDebug then
                print("[koffee][trig] DISABLE @ " .. tostring(os.clock()) .. "  stack=" .. tostring(debug.traceback and debug.traceback("", 2) or "?"))
            end
        end)
    -- v0.3.0 EXTERNAL METHOD BRIDGE. koffee.lua speaks to KoffeeHelper.exe
    -- (native C++ helper, source at helper/native/) over localhost HTTP.
    -- Under Silent Aim's "External" method, all Lua-side spoof paths short-
    -- circuit (see resolveIndex / resolveNamecall heads) and the helper does
    -- the actual work via a raycast inline hook inside the Roblox process.
    --
    -- Wire contract:
    --   * fixed local port 27374 (mirrored in helper/native/src/main.cpp).
    --   * dev key from Koffee.md's Round-1 auth section, sent as
    --     X-Koffee-Key on POST /config + POST /clear.
    --   * every ~2s while External is the active method AND Silent.Enabled,
    --     push the current silent config to /config as a keepalive. The
    --     helper auto-disarms if the keepalive stops arriving (its own 5s
    --     TTL -- see aim/silentaim.cpp kKeepaliveMax).
    --   * on External -> non-External transition (or Silent disable), POST
    --     /clear so the helper drops the target immediately instead of
    --     waiting out its keepalive TTL.
    Koffee.External = (function()
        local M = {}
        local URL = "http://127.0.0.1:27374"
        local KEY = "KoffeeBetaDevelopmentTesting"

        local function pickReq()
            return (syn and syn.request) or (http and http.request)
                or http_request or request
        end

        local function call(method, path, body)
            local req = pickReq()
            if not req then return false, "no_http_api" end
            local ok, res = pcall(req, {
                Url = URL .. path,
                Method = method,
                Headers = {
                    ["X-Koffee-Key"] = KEY,
                    ["Content-Type"] = "application/json",
                },
                Body = body,
            })
            if not ok then return false, tostring(res) end
            local status = res and (res.StatusCode or res.status_code)
            local success = (status == 200) or (res and res.Success == true)
            return success, res and res.Body or ""
        end

        function M.healthOk()
            local ok = call("GET", "/health", nil)
            return ok == true
        end

        -- Build the JSON body from the current Combat.Silent state. Kept in
        -- lock-step with helper/native/src/http.cpp `parse_config` so adding
        -- a field is a one-side change per side.
        local function buildConfigBody()
            local s = Combat.Silent
            local HttpService = game:GetService("HttpService")
            return HttpService:JSONEncode({
                silent = {
                    enabled      = s.Enabled == true,
                    wallbang     = s.Wallbang == true,
                    hit_part     = tostring(s.HitPart or "Head"),
                    team_check   = s.TeamCheck == true,
                    health_check = s.HealthCheck == true,
                    distance     = tonumber(s.Distance) or 1500,
                    fov_enabled  = s.FOV and s.FOV.Enabled or false,
                    fov_radius   = (s.FOV and s.FOV.Size) or 150,
                },
            })
        end

        function M.pushConfig()
            local body = buildConfigBody()
            local ok = call("POST", "/config", body)
            return ok
        end

        function M.clear() call("POST", "/clear", "") end

        -- Keepalive loop. Fires while (Silent.Enabled AND Method == External).
        -- On enable transition, probes /health and warns if the helper isn't
        -- reachable (once per enable cycle, not spammed).
        local warned = false
        local wasActive = false
        task.spawn(function()
            while true do
                local isActive = Combat.Silent.Enabled
                    and Combat.Silent.Method == "External"
                if isActive then
                    if not wasActive then
                        if not M.healthOk() then
                            if not warned then
                                warned = true
                                warn("[koffee] external method selected but helper is not reachable at " .. URL)
                            end
                        else
                            warned = false
                        end
                    end
                    M.pushConfig()
                elseif wasActive then
                    M.clear()
                    warned = false
                end
                wasActive = isActive
                task.wait(2)
            end
        end)

        -- Called by the Method dropdown on change. Immediate response so the
        -- helper disarms right away instead of on the next 2s keepalive tick.
        function M.onMethodChange(newMethod)
            if newMethod ~= "External" then M.clear() end
        end

        return M
    end)()

    registerModule("silentaim", "Silent Aim",
        function() installSilentHooks(); Combat.Silent.Enabled = true end,
        function()
            Combat.Silent.Enabled = false
            silentTarget = nil
            -- If we were on External, tell the helper to disarm immediately.
            if Combat.Silent.Method == "External" and Koffee.External then
                Koffee.External.clear()
            end
        end)
    -- v0.0.73: arraylist "on" indicator -- active = held by the activation key, OR (no key
    -- bound) always-active while enabled. Mirrors each feature's real arm gate.
    Modules.aimbot.IsActive     = function() return (not Combat.Aim.ActivationKey)    or aimHeld end
    Modules.triggerbot.IsActive = function() return (not Combat.Trigger.ActivationKey) or trigHeld end
    Modules.silentaim.IsActive  = function() return (not Combat.Silent.ActivationKey)  or silentHeld end
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
        rightClickSettings(configCheckbox(L.Aimbot, "Team Check", Combat.Aim.TeamCheck, function(v) Combat.Aim.TeamCheck = v end).row, "team check", teamCheckSettings)
        configCheckbox(L.Aimbot, "Visible Check", Combat.Aim.VisibleCheck, function(v) Combat.Aim.VisibleCheck = v end)
        configCheckbox(L.Aimbot, "Health Check", Combat.Aim.HealthCheck, function(v) Combat.Aim.HealthCheck = v end)
        configCheckbox(L.Aimbot, "Sticky Aim", Combat.Aim.Sticky, function(v) Combat.Aim.Sticky = v end)
        -- v0.0.36: third-person cursor aim (move mouse, not camera). Bind aimbot to a
        -- non-RMB key (e.g. XButton2) so it doesn't clash with the game's shift-lock.
        configCheckbox(L.Aimbot, "Third Person", Combat.Aim.ThirdPerson, function(v) Combat.Aim.ThirdPerson = v end)
        slider(L.Aimbot, "Distance", 50, 5000, Combat.Aim.Distance, 0, function(v) Combat.Aim.Distance = v end, { infinite = true })
        slider(L.Aimbot, "Sensitivity", 0.01, 1, Combat.Aim.Sensitivity, 2, function(v) Combat.Aim.Sensitivity = v end)
        configCheckbox(L.Aimbot, "Perfect Lock", Combat.Aim.PerfectLock, function(v) Combat.Aim.PerfectLock = v end)
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

        -- v0.0.88 Sounds panel. Hit + Kill each have Enabled, Preset dropdown,
        -- Custom Sound Id (0 = use preset), Volume, Pitch, Cooldown. Also a
        -- shared Mouse Radius slider that tunes the mouse-target lock threshold.
        -- v0.0.89: preset list = filenames from <exec>/Koffee/sounds/*.mp3.
        -- Loader ships these files (or user copies once). See getcustomasset resolver.
        local SND_PRESETS_LIST = {
            "12", "agpa2", "basshit", "bell", "blizzard", "bubble", "chockpro",
            "cod", "copperbell", "crowbar", "headshot", "hit", "knob",
            "minecraft orb", "neverlose", "rust", "skeet",
        }
        local soundCard = panel(leftCol, "Sounds")
        configCheckbox(soundCard, "Hit Sound", Combat.HitSounds.Hit.Enabled, function(v) Combat.HitSounds.Hit.Enabled = v end)
        dropdown(soundCard, "Hit Preset", SND_PRESETS_LIST, Combat.HitSounds.Hit.Preset, function(v) Combat.HitSounds.Hit.Preset = v end)
        slider(soundCard, "Hit Custom Id", 0, 9999999999, Combat.HitSounds.Hit.CustomId, 0, function(v) Combat.HitSounds.Hit.CustomId = math.floor(v) end)
        slider(soundCard, "Hit Volume",    0, 5,           Combat.HitSounds.Hit.Volume,   2, function(v) Combat.HitSounds.Hit.Volume   = v end)
        slider(soundCard, "Hit Pitch",     0.5, 2,         Combat.HitSounds.Hit.Pitch,    2, function(v) Combat.HitSounds.Hit.Pitch    = v end)
        slider(soundCard, "Hit Cooldown",  0, 1000,        Combat.HitSounds.Hit.Cooldown, 0, function(v) Combat.HitSounds.Hit.Cooldown = math.floor(v) end)
        configCheckbox(soundCard, "Kill Sound", Combat.HitSounds.Kill.Enabled, function(v) Combat.HitSounds.Kill.Enabled = v end)
        dropdown(soundCard, "Kill Preset", SND_PRESETS_LIST, Combat.HitSounds.Kill.Preset, function(v) Combat.HitSounds.Kill.Preset = v end)
        slider(soundCard, "Kill Custom Id", 0, 9999999999, Combat.HitSounds.Kill.CustomId, 0, function(v) Combat.HitSounds.Kill.CustomId = math.floor(v) end)
        slider(soundCard, "Kill Volume",    0, 5,           Combat.HitSounds.Kill.Volume,   2, function(v) Combat.HitSounds.Kill.Volume   = v end)
        slider(soundCard, "Kill Pitch",     0.5, 2,         Combat.HitSounds.Kill.Pitch,    2, function(v) Combat.HitSounds.Kill.Pitch    = v end)
        slider(soundCard, "Kill Cooldown",  0, 1000,        Combat.HitSounds.Kill.Cooldown, 0, function(v) Combat.HitSounds.Kill.Cooldown = math.floor(v) end)
        configCheckbox(soundCard, "Overlap Sounds", Combat.HitSounds.Overlap, function(v) Combat.HitSounds.Overlap = v end)
        slider(soundCard, "Attr Window (s)", 0.5, 5, Combat.HitSounds.AttrWindow, 2, function(v) Combat.HitSounds.AttrWindow = v end)
        slider(soundCard, "Before Click (ms)", 1, 500, Combat.HitSounds.BeforeClick, 0, function(v) Combat.HitSounds.BeforeClick = math.floor(v) end)

        --== v0.0.97 TARGET LOCK -- type a name, arm the toggle, hit the keybind to
        -- engage. While engaged, only that named player is a valid target for aimbot /
        -- silent aim / trigger, and ESP renders only them. Hit the keybind again
        -- (or un-arm) to release back to "everyone".
        local tlCard = panel(leftCol, "Target Lock")
        local tlArm = configCheckbox(tlCard, "Armed", Shared.TargetLock.Enabled, function(v)
            Shared.TargetLock.Enabled = v
            if not v then Shared.TargetLock._active = false end
        end)
        -- name input row
        local tlNameRow = new("Frame", {
            Size = UDim2.new(1, 0, 0, CBOX.h),
            BackgroundTransparency = 1, ZIndex = 34,
            LayoutOrder = 2, Parent = tlCard,
        })
        new("TextLabel", {
            Text = "Target Name", FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
            TextColor3 = Theme.Palette.Text, BackgroundTransparency = 1,
            Position = UDim2.new(0, CBOX.off, 0, 0),
            Size = UDim2.new(1, -CBOX.off - 90, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 35, Parent = tlNameRow,
        })
        local tlBox = new("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 80, 0, CBOX.h - 8),
            Text = Shared.TargetLock.Name or "", PlaceholderText = "username...",
            ClearTextOnFocus = false, FontFace = Theme.Fonts.Mono, TextSize = Theme.Text.Tiny,
            TextColor3 = Theme.Palette.Text, PlaceholderColor3 = Theme.Palette.TextFaint,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, ZIndex = 36, Parent = tlNameRow,
        }, { corner(5), stroke(Theme.Palette.BorderSubtle),
            new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) })
        tlBox.FocusLost:Connect(function(enter)
            Shared.TargetLock.Name = tlBox.Text
            tlStatusUpdater()
        end)
        -- activation keybind row
        local tlKeyRow = new("Frame", {
            Size = UDim2.new(1, 0, 0, CBOX.h),
            BackgroundTransparency = 1, ZIndex = 34, LayoutOrder = 3, Parent = tlCard,
        })
        new("TextLabel", {
            Text = "Activate Key", FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
            TextColor3 = Theme.Palette.Text, BackgroundTransparency = 1,
            Position = UDim2.new(0, CBOX.off, 0, 0),
            Size = UDim2.new(1, -CBOX.off - 90, 100, 0),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 35, Parent = tlKeyRow,
        })
        local tlKeyPill = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 34, 0, 15), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, AutoButtonColor = false,
            Text = keyLabel(Shared.TargetLock.Key) or "set", FontFace = Theme.Fonts.Mono,
            TextSize = Theme.Text.Tiny, TextColor3 = Theme.Palette.TextMuted, ZIndex = 38, Parent = tlKeyRow,
        }, { pillCorner(), stroke(Theme.Palette.BorderSubtle),
            new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
        popFx(tlKeyPill)   -- v0.0.98: target-lock key pill squashes too
        tlKeyPill.MouseButton1Click:Connect(function()
            if pendingActivation then pendingActivation.refresh() end
            tlKeyPill.Text = "..."
            tween(tlKeyPill, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Accent })
            -- proxy cfg: the rebind commit writes cfg.ActivationKey (InputBegan +
            -- XButton poll both do this) -- mirror into Shared.TargetLock.Key so the
            -- runtime key reader picks it up.
            local proxy = {}
            pendingActivation = { pill = tlKeyPill, cfg = proxy, refresh = function()
                tlKeyPill.Text = keyLabel(Shared.TargetLock.Key) or "-"
            end }
            local _g = proxy
            setmetatable(proxy, { __index = function() end, __newindex = function(self, k, v)
                if k == "ActivationKey" then
                    Shared.TargetLock.Key = v
                    tlKeyPill.Text = keyLabel(v) or "-"
                end
                _g[k] = v
            end })
        end)
        -- live status label: shows who is locked / none
        local tlStatus = new("TextLabel", {
            Text = "", FontFace = Theme.Fonts.Mono, TextSize = Theme.Text.Tiny,
            TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 4, ZIndex = 35, Parent = tlCard,
        })
        -- status updater -- also auto-releases when the locked player leaves / dies
        -- (the lock cannot dangle on a ghost). Set into the combat IIFE-local slot the
        -- key-toggle handler already calls.
        tlStatusUpdater = function()
            local engaged = Shared.TargetLock.Enabled and Shared.TargetLock._active
            if not engaged then
                tlStatus.Text = "idle -- press key to lock"
                return
            end
            local t = Shared.targetLockPlayer()
            if not t then
                tlStatus.Text = "locked -- target not found"
                return
            end
            tlStatus.Text = "locked -> " .. t.Name
        end
        tlStatusUpdater()
        RunService.Heartbeat:Connect(function()
            if not (Shared.TargetLock.Enabled and Shared.TargetLock._active) then return end
            if not Shared.targetLockPlayer() then
                Shared.TargetLock._active = false
                tlStatusUpdater()
            end
        end)

        --== RIGHT COLUMN ==--
        local rightCard = panel(rightCol)
        local R = subTabs(rightCard, { "Silent Aim", "Prediction", "FOV" })

        -- Silent Aim
        local sRow = moduleCheckbox(R["Silent Aim"], "Enabled", "silentaim")
        activationPill(sRow.row, Combat.Silent)
        rightClickSettings(configCheckbox(R["Silent Aim"], "Team Check", Combat.Silent.TeamCheck, function(v) Combat.Silent.TeamCheck = v end).row, "team check", teamCheckSettings)
        configCheckbox(R["Silent Aim"], "Visible Check", Combat.Silent.VisibleCheck, function(v) Combat.Silent.VisibleCheck = v end)
        configCheckbox(R["Silent Aim"], "Health Check", Combat.Silent.HealthCheck, function(v) Combat.Silent.HealthCheck = v end)
        configCheckbox(R["Silent Aim"], "Sticky Aim", Combat.Silent.Sticky, function(v) Combat.Silent.Sticky = v end)
        slider(R["Silent Aim"], "Distance", 50, 5000, Combat.Silent.Distance, 0, function(v) Combat.Silent.Distance = v end, { infinite = true })
        dropdown(R["Silent Aim"], "Hit Part", HITPARTS, Combat.Silent.HitPart, function(v) Combat.Silent.HitPart = v end)
        dropdown(R["Silent Aim"], "Method", { "Forced Magic-Bullet", "Second-Camera", "Raycast", "External" }, Combat.Silent.Method,
            function(v) Combat.Silent.Method = v; if Koffee.External then Koffee.External.onMethodChange(v) end end)
        configCheckbox(R["Silent Aim"], "Require Left-Click", Combat.Silent.RequireLMB, function(v) Combat.Silent.RequireLMB = v end)
        -- v0.2.0/v0.3.0: Wallbang is honoured under Raycast (Lua-side origin
        -- rewrite) AND External (helper-side inline-hook wallbang). Silently
        -- no-ops under Forced MB / Second-Camera.
        configCheckbox(R["Silent Aim"], "Wallbang", Combat.Silent.Wallbang, function(v) Combat.Silent.Wallbang = v end)
        -- v0.0.45: Forced Magic-Bullet is universal by default (fire-read always on) --
        -- spoofs mouse.Hit + Camera.CFrame + camera-rays, scoped so the real view/Popper
        -- are never touched. Spoof Scope is the caller-identification strategy (both
        -- exclude the PlayerModule camera); Caller-Class is the plain fallback.
        dropdown(R["Silent Aim"], "Spoof Scope", { "Auto (Learn)", "Caller-Class" }, Combat.Silent.SpoofScope, function(v) Combat.Silent.SpoofScope = v end)
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
        rightClickSettings(configCheckbox(trigCard, "Team Check", Combat.Trigger.TeamCheck, function(v) Combat.Trigger.TeamCheck = v end).row, "team check", teamCheckSettings)
        configCheckbox(trigCard, "Use Key", Combat.Trigger.UseKey, function(v) Combat.Trigger.UseKey = v end)
        slider(trigCard, "Hitbox Mul", 1, 10, Combat.Trigger.HitboxMul, 2, function(v) Combat.Trigger.HitboxMul = v end)
        slider(trigCard, "Delay (ms)", 0, 500, Combat.Trigger.Delay, 0, function(v) Combat.Trigger.Delay = v end)
        slider(trigCard, "Release (ms)", 0, 500, Combat.Trigger.Release, 0, function(v) Combat.Trigger.Release = v end)
    end)
    -- v0.1.0: the Options tab (built in this file's shared scope, outside this
    -- IIFE) reads Combat state + the sound instances during unload; hand them up
    -- through Shared so that path sees the same tables, not nil globals.
    Shared.Combat = Combat
    Shared.CombatSounds = { hit = hitSnd, kill = killSnd }
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
    local espPanel = panel(leftCol, "ESP")
    local master = moduleCheckbox(espPanel, "Enabled", "esp")
    -- v0.0.34: ESP ships with NO keybind by default (pill reads "no keybind").
    keybindPill(master.row, "esp", nil)
    rightClickSettings(configCheckbox(espPanel, "Team Check", ESP.Config.TeamCheck, function(v) ESP.Config.TeamCheck = v end).row, "team check", teamCheckSettings)
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
        function(v) ESP.Config.RenderDistance = v end, { infinite = true })
    -- v0.0.22: global Feature-Interface thickness; v0.0.23: sub-1 down to 0.1.
    -- v0.0.28: Equal Size removed (broke distance-scaled features) -- pinned ON permanently.
    slider(espPanel, "Thickness", 0.1, 8, ESP.Render.Thickness, 1,
        function(v) ESP.Render.Thickness = v end)

    --------------------------------------------------------------- Box
    local boxesPanel = panel(leftCol, "Box")
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
    local namePanel = panel(leftCol, "Name")
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
    local indPanel = panel(rightCol, "Indicators")
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
    local healthPanel = panel(rightCol, "Health")
    local hbRow = configCheckbox(healthPanel, "Health Bar", ESP.Health.Bar.Enabled, function(v) ESP.Health.Bar.Enabled = v end)
    attachSingleSwatch(hbRow.row, ESP.Health.Bar.Color, function(c) ESP.Health.Bar.Color = c end)
    configCheckbox(healthPanel, "Health Based", ESP.Health.Based, function(v) ESP.Health.Based = v end)
    configCheckbox(healthPanel, "Health Text", ESP.Health.Text, function(v) ESP.Health.Text = v end)
    dropdown(healthPanel, "Text Pos", { "Above Name", "On Health Bar" }, ESP.Health.TextPos, function(v) ESP.Health.TextPos = v end)

    --------------------------------------------------------------- Tracer
    local tracerPanel = panel(rightCol, "Tracers")
    local trRow = configCheckbox(tracerPanel, "Enabled", ESP.Tracer.Enabled, function(v) ESP.Tracer.Enabled = v end)
    attachSingleSwatch(trRow.row, ESP.Tracer.Color, function(c) ESP.Tracer.Color = c end)
    dropdown(tracerPanel, "Origin", { "Mouse", "Bottom", "Middle", "Top" }, ESP.Tracer.Origin, function(v) ESP.Tracer.Origin = v end)
    dropdown(tracerPanel, "Location", { "Below", "Middle", "Above" }, ESP.Tracer.Location, function(v) ESP.Tracer.Location = v end)
end)

addTab("World", function(root)
    local lighting = panel(root, "World Lighting")
    moduleCheckbox(lighting, "Fullbright",  "fullbright")
    moduleCheckbox(lighting, "No Fog",      "nofog")
    moduleCheckbox(lighting, "Custom Time", "customtime")
    slider(lighting, "Clock Time", 0, 24, World.Time.Target, 1, function(v)
        World.Time.Target = v
        if Modules.customtime and Modules.customtime.Enabled then
            Lighting.ClockTime = v
        end
    end)

    -- v0.0.100: effects batch
    local fx = panel(root, "Effects")
    local cc = moduleCheckbox(fx, "Color Correction", "colorcorrection")
    attachSingleSwatch(cc.row, World.CC.Tint, function(c) World.CC.Tint = c end)
    slider(fx, "Saturation", -1, 1, World.CC.Saturation, 2, function(v) World.CC.Saturation = v end)
    slider(fx, "Contrast",   -1, 1, World.CC.Contrast,   2, function(v) World.CC.Contrast   = v end)
    slider(fx, "Brightness", -1, 1, World.CC.Brightness, 2, function(v) World.CC.Brightness = v end)
    local amb = moduleCheckbox(fx, "Ambient Color", "ambientcolor")
    attachSingleSwatch(amb.row, World.Light.Color, function(c) World.Light.Color = c end)
    slider(fx, "Ambient Intensity", 0, 2, World.Light.Intensity, 2, function(v) World.Light.Intensity = v end)
    moduleCheckbox(fx, "Remove Sky",     "removesky")
    moduleCheckbox(fx, "Disable Clouds", "noclouds")
    moduleCheckbox(fx, "Low Graphics",   "lowgfx")
end)

addTab("Character", function(root) Koffee._characterTab(root) end)

-- v0.0.96: options state (arraylist preferences) rides the config system too.
registerConfig("options", KoffeeOptions)

-- OPTIONS TAB (v0.0.34)
addTab("Options", function(root)
    local card = panel(root, "Options")

    local uiPanel = panel(root, "Interface")
    local arrRow = configCheckbox(uiPanel, "Arraylist", KoffeeOptions.Arraylist, function(v)
        KoffeeOptions.Arraylist = v
        labelsColumn.Visible = v
    end)
    rightClickSettings(arrRow.row, "arraylist", function(menu)
        menu:toggle("Overwrite Outline", KoffeeOptions.ArraylistOutline, function(v)
            KoffeeOptions.ArraylistOutline = v
        end)
        menu:slider("Outline Size", 1, 5, KoffeeOptions.ArraylistOutlineSize, 0, function(v)
            KoffeeOptions.ArraylistOutlineSize = v
        end)
    end)

    -- v0.0.97 CUSTOM FONT -- applies a user-chosen font to everything that isn't
    -- the main Koffee window (arraylist, ESP name / distance / health text, HUD
    -- stats, etc.). The dropdown lists the fonts hosted on koffee-assets (see
    -- FONTS_CATALOG); right-click the row to tune the global text size used while
    -- the custom font is on -- so the pixel fonts don't render too big / small.
    -- Default off + "None" -- feature interface looks exactly like before.
    local fontOptions = { "None", "Minecraft Bold", "Minecraft Regular", "ImGui" }
    -- user-dropped fonts land in the workspace as koffee_<name>.otf; surface any
    -- extra cached entries the catalog doesn't know so they're selectable too.
    local fontRow = configCheckbox(uiPanel, "Custom Font", KoffeeOptions.CustomFontOn, function(v)
        KoffeeOptions.CustomFontOn = v
        Theme.setFeiOn(v)
        if v then Theme.setFeiFont(KoffeeOptions.CustomFontName) end
    end)
    rightClickSettings(fontRow.row, "custom font", function(menu)
        menu:slider("Font Size", 8, 28, KoffeeOptions.CustomFontSize, 0, function(v)
            KoffeeOptions.CustomFontSize = v
            Theme.setFeiSize(v)
        end)
    end)
    dropdown(uiPanel, "Font", fontOptions, KoffeeOptions.CustomFontName, function(v)
        KoffeeOptions.CustomFontName = v
        Theme.setFeiFont(v)
    end)
    -- v0.1.0: "Custom Font (MI)" is its own surface now -- separate catalog pick
    -- (MIFontName, independent of the feature font) + own size via the row's
    -- right-click. Toggle snapshots + restores the main window's text.
    local miRow = configCheckbox(uiPanel, "Custom Font (MI)", KoffeeOptions.MIFontOn, function(v)
        KoffeeOptions.MIFontOn = v
        Theme.applyMIFont(window, v and Theme.loadFeiFont(KoffeeOptions.MIFontName) or nil,
            v and KoffeeOptions.MIFontSize or nil)
    end)
    rightClickSettings(miRow.row, "custom font MI", function(menu)
        menu:slider("Font Size", 8, 28, KoffeeOptions.MIFontSize, 0, function(v)
            KoffeeOptions.MIFontSize = v
            if KoffeeOptions.MIFontOn then
                Theme.applyMIFont(window, Theme.loadFeiFont(KoffeeOptions.MIFontName), v)
            end
        end)
    end)
    dropdown(uiPanel, "MI Font", fontOptions, KoffeeOptions.MIFontName, function(v)
        KoffeeOptions.MIFontName = v
        if KoffeeOptions.MIFontOn then
            Theme.applyMIFont(window, Theme.loadFeiFont(v), KoffeeOptions.MIFontSize)
        end
    end)
    -- Ignore Friends: friends are excluded from ESP + aimbot + silent + trigger.
    configCheckbox(card, "Ignore Friends", Shared.IgnoreFriends, function(v)
        Shared.IgnoreFriends = v
    end)

    -- v0.0.95 UNLOAD KOFFEE. Confirm popup then a clean tear-down: disables
    -- every module (their OnDisable fires so state restores), destroys the UI
    -- + toast + hud + background (blur/dim/snow), destroys sound instances,
    -- restores camera + mouse, unbinds our RenderStep binds, and flips a
    -- global unloaded flag so any residual loops early-return.
    local function unloadKoffee()
        -- 1. flip every enabled module OFF so their OnDisable cleanup runs
        for id, m in pairs(Modules) do
            if m.Enabled then pcall(toggleModule, id) end
        end
        -- 2. explicit combat state reset (silent hook stays installed for the
        -- session -- can't un-hookmetamethod -- but its body early-returns on
        -- Combat.Silent.Enabled = false, so it becomes a no-op).
        -- v0.1.0: Combat lives in its own IIFE; reach it via the Shared export.
        local combat = Shared.Combat
        if combat then
            combat.Silent.Enabled  = false
            combat.Aim.Enabled     = false
            combat.Trigger.Enabled = false
        end
        -- 3. unbind our RenderStep bindings
        pcall(function() RunService:UnbindFromRenderStep(KID.ctx.bind) end)
        pcall(function() RunService:UnbindFromRenderStep("KSpinbot") end)
        pcall(function() RunService:UnbindFromRenderStep("KThirdPerson") end)
        -- 4. destroy every UI surface we own
        pcall(function() screen:Destroy() end)
        pcall(function() popupScreen:Destroy() end)
        pcall(function() blur:Destroy() end)
        -- 5. destroy any sound instances we created
        local combatSounds = Shared.CombatSounds
        pcall(function() if combatSounds then combatSounds.hit:Destroy() end end)
        pcall(function() if combatSounds then combatSounds.kill:Destroy() end end)
        -- 6. restore camera + mouse to game defaults
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then cam.CameraType = Enum.CameraType.Custom end
        end)
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        -- 7. global unloaded flag -- surviving Heartbeat/RenderStep connections
        -- read this and early-return.
        if getgenv then getgenv().KoffeeUnloaded = true end
        Koffee._unloaded = true
    end
    -- confirm popup: centered on popupScreen so it survives the window fade
    -- + can be seen even if the user closes the menu underneath.
    local function showUnloadConfirm()
        local pS = popupScreen
        if not (pS and pS.Parent) then return end
        local dim = new("Frame", {
            Name = "KUnloadDim",
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55, BorderSizePixel = 0,
            ZIndex = 100, Parent = pS,
        })
        local box = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 320, 0, 148),
            BackgroundColor3 = Theme.Palette.Panel, BorderSizePixel = 0,
            ZIndex = 101, Parent = dim,
        }, { corner(Theme.Radius.Medium), stroke(Theme.Palette.BorderSubtle) })
        new("TextLabel", {
            Text = "unload koffee?", FontFace = Theme.Fonts.Bold, TextSize = Theme.Text.Header,
            TextColor3 = Theme.Palette.Text, BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -32, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102, Parent = box,
        })
        new("TextLabel", {
            Text = "every feature disables, the ui is removed. re-run the loader to bring koffee back.",
            FontFace = Theme.Fonts.Regular, TextSize = Theme.Text.Small,
            TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 36), Size = UDim2.new(1, -32, 0, 44),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, ZIndex = 102, Parent = box,
        })
        local cancel = new("TextButton", {
            Text = "cancel", FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
            AutoButtonColor = false, TextColor3 = Theme.Palette.TextMuted,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -108, 1, -14),
            Size = UDim2.new(0, 88, 0, 28), ZIndex = 102, Parent = box,
        }, { corner(5), stroke(Theme.Palette.BorderSubtle) })
        local confirm = new("TextButton", {
            Text = "unload", FontFace = Theme.Fonts.Bold, TextSize = Theme.Text.Small,
            AutoButtonColor = false, TextColor3 = Theme.Palette.Danger or Color3.fromRGB(220, 90, 90),
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
            Size = UDim2.new(0, 88, 0, 28), ZIndex = 102, Parent = box,
        }, { corner(5), stroke(Theme.Palette.BorderSubtle) })
        cancel.MouseButton1Click:Connect(function() dim:Destroy() end)
        confirm.MouseButton1Click:Connect(function() dim:Destroy(); pcall(unloadKoffee) end)
    end
    local unloadBtn = new("TextButton", {
        Text = "unload koffee", FontFace = Theme.Fonts.Bold, TextSize = Theme.Text.Small,
        AutoButtonColor = false, TextColor3 = Theme.Palette.Danger or Color3.fromRGB(220, 90, 90),
        BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30), ZIndex = 36, Parent = card,
    }, { corner(5), stroke(Theme.Palette.BorderSubtle) })
    unloadBtn.MouseButton1Click:Connect(showUnloadConfirm)
end)

-- CONFIGS TAB (v0.0.34) -- save / load / delete / auto-load per game
addTab("Configs", function(root)
    local CIO = Koffee.Config

    -- v0.0.47: pill button whose resting colour can flip at runtime (the `auto`
    -- button toggles accent/muted). Base colour is stored as an attribute so the
    -- MouseLeave handler always restores the CURRENT base, not the creation-time one.
    local function mkBtn(parent, text, width, onClick, accent)
        local b = new("TextButton", {
            Text = text, AutoButtonColor = false,
            FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Small,
            BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, Size = UDim2.new(0, width, 0, 26),
            ZIndex = 36, Parent = parent,
        }, { corner(5), stroke(Theme.Palette.BorderSubtle) })
        b:SetAttribute("accentBase", accent and true or false)
        local function base()
            return b:GetAttribute("accentBase") and Theme.Palette.Accent or Theme.Palette.TextMuted
        end
        b.TextColor3 = base()
        b.MouseEnter:Connect(function() tween(b, Theme.Animation.Fast, { TextColor3 = Theme.Palette.Text }) end)
        b.MouseLeave:Connect(function() tween(b, Theme.Animation.Fast, { TextColor3 = base() }) end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    --== manager card ==--
    local card = panel(root, "Config Manager")

    local status = new("TextLabel", {
        Text = "select a config, or type a name to create one",
        FontFace = Theme.Fonts.Regular, TextSize = Theme.Text.Small,
        TextColor3 = Theme.Palette.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, ZIndex = 35, Parent = card,
    })
    local function setStatus(msg, ok)
        status.Text = msg
        status.TextColor3 = ok and Theme.Palette.Success or Theme.Palette.Danger
    end

    -- selected-config state. The dropdown is REBUILT from disk on any data change
    -- (create / delete / refresh) so it always mirrors what's actually saved.
    local selectedName, hasConfigs, currentDD = nil, false, nil
    local rebuildManager   -- fwd decl

    local ddHolder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1,
        LayoutOrder = 2, ZIndex = 35, Parent = card,
    })

    -- action row for the SELECTED config
    local actionRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        LayoutOrder = 3, ZIndex = 35, Parent = card,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder }) })

    -- new-config row
    local newRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
        LayoutOrder = 4, ZIndex = 35, Parent = card,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder }) })
    local nameBox = new("TextBox", {
        Text = "", PlaceholderText = "new config name...", ClearTextOnFocus = false,
        FontFace = Theme.Fonts.Medium, TextSize = Theme.Text.Body,
        TextColor3 = Theme.Palette.Text, PlaceholderColor3 = Theme.Palette.TextFaint,
        BackgroundColor3 = Theme.Palette.PanelElevated, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Size = UDim2.new(1, -150, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 36, Parent = newRow,
    }, { corner(5), stroke(Theme.Palette.BorderSubtle),
        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })

    -- the `auto` button reflects whether the selected config is the auto-load one
    local autoBtn
    local function refreshAutoLabel()
        if not autoBtn then return end
        local isAuto = selectedName ~= nil and CIO.getAuto() == selectedName
        autoBtn.Text = isAuto and "auto*" or "auto"
        autoBtn:SetAttribute("accentBase", isAuto)
        autoBtn.TextColor3 = isAuto and Theme.Palette.Accent or Theme.Palette.TextMuted
    end

    local function needSel()
        if hasConfigs and selectedName then return true end
        setStatus("no config selected", false)
        return false
    end

    -- selected-config actions (read selectedName live)
    mkBtn(actionRow, "load", 60, function()
        if not needSel() then return end
        local ok, msg = CIO.load(selectedName)
        if ok then setStatus("loaded: " .. tostring(selectedName), true)
        else setStatus("load failed: " .. tostring(msg), false) end
    end, true).LayoutOrder = 1
    mkBtn(actionRow, "overwrite", 90, function()
        if not needSel() then return end
        local ok, msg = CIO.save(selectedName)   -- same filename -> overwrites in place
        if ok then setStatus("overwrote: " .. tostring(selectedName), true)
        else setStatus("overwrite failed: " .. tostring(msg), false) end
    end).LayoutOrder = 2
    mkBtn(actionRow, "delete", 66, function()
        if not needSel() then return end
        local nm = selectedName
        -- v0.0.50 fix (two bugs):
        --   1. CIO.delete's return was discarded -- a failed/unavailable delfile
        --      still reported "deleted", and the name stayed on disk.
        --   2. deleting the auto-load config left the _auto_<PlaceId> marker
        --      pointing at a file that no longer exists, so auto-load silently
        --      did nothing every session with no way to notice from the UI.
        local ok = CIO.delete(nm)
        if ok and CIO.getAuto() == nm then CIO.setAuto(nil) end
        selectedName = nil
        rebuildManager()
        if ok then setStatus("deleted: " .. nm, true)
        else setStatus("delete failed: " .. nm, false) end
    end).LayoutOrder = 3
    autoBtn = mkBtn(actionRow, "auto", 58, function()
        if not needSel() then return end
        if CIO.getAuto() == selectedName then CIO.setAuto(nil); setStatus("auto-load cleared", true)
        else CIO.setAuto(selectedName); setStatus("auto-load: " .. selectedName, true) end
        refreshAutoLabel()
    end)
    autoBtn.LayoutOrder = 4

    -- new-config actions
    mkBtn(newRow, "create", 66, function()
        local ok, msg = CIO.save(nameBox.Text)
        if ok then
            selectedName = msg
            nameBox.Text = ""
            rebuildManager()
            setStatus("created: " .. tostring(msg), true)
        else setStatus("create failed: " .. tostring(msg), false) end
    end, true).LayoutOrder = 2
    mkBtn(newRow, "refresh", 66, function() rebuildManager(); setStatus("refreshed", true) end).LayoutOrder = 3

    -- (re)build the selector from disk, keeping the current selection valid.
    rebuildManager = function()
        local names = CIO.list()
        hasConfigs = (#names > 0)
        if selectedName then
            local found = false
            for _, n in ipairs(names) do if n == selectedName then found = true; break end end
            if not found then selectedName = nil end
        end
        if not selectedName and hasConfigs then selectedName = names[1] end

        if currentDD then currentDD.destroy(); currentDD = nil end
        local options = hasConfigs and names or { "no saved configs" }
        currentDD = dropdown(ddHolder, "saved configs", options,
            selectedName or "no saved configs", function(v)
                if hasConfigs then selectedName = v; refreshAutoLabel() end
            end)
        refreshAutoLabel()
    end

    rebuildManager()
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

-- v0.0.97: the bottom-right session toast was removed entirely (the user
-- asked to drop the widget, not just the headline label). nothing replaces it.

-- WINDOW TOGGLE + BACKGROUND SYNC
-- Delete key toggles. Everything (window + snow + dim + blur) fades
-- with the same linear timing so they leave together, cleanly.
-- IIFE: own register budget. The main chunk rides Luau's 200-local ceiling
-- (same pattern as the Combat IIFE further up).
;(function()
local windowOpen = true

-- v0.0.95: track pre-open mouse state so we can restore what the game (or 3rd
-- Person, or shift-lock, etc.) was doing after the user closes the menu.
local _preMenuMouseBehavior, _preMenuMouseIcon = nil, nil
local function setWindowOpen(open)
    if windowOpen == open then return end
    windowOpen = open
    if open then
        window.Visible = true
        window.GroupTransparency = 1
        local wsc = uScaleOf(window)   -- v0.0.98: window pops open (fade + grow)
        wsc.Scale = 0.90
        tween(window, Theme.Animation.WindowFade, { GroupTransparency = 0 })
        tween(wsc,   Theme.Animation.WindowFade, { Scale = 1 })
        -- v0.0.95: force the cursor UNLOCKED + visible while the menu is up so
        -- the user can click Koffee widgets without having to open the Roblox
        -- menu (Esc) first. Restore whatever the game/3rd-Person had set on close.
        _preMenuMouseBehavior = UserInputService.MouseBehavior
        _preMenuMouseIcon     = UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior   = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        -- v0.0.22: popups live in a SEPARATE ScreenGui, so the window's fade
        -- doesn't touch them. Dismiss any open color picker + dropdowns on close
        -- so they don't linger over the game after the menu is hidden.
        closeColorPicker()
        for _, closer in pairs(openDropdowns) do closer(true) end
        for _, closer in pairs(openSettingsPopups) do closer() end
        tween(window, Theme.Animation.WindowFade, { GroupTransparency = 1 })
        -- v0.0.98: sink slightly as it goes, with the fade.
        if _us_cache[window] then
            tween(_us_cache[window], Theme.Animation.WindowFade, { Scale = 0.96 })
        end
        task.delay(0.2, function()
            if not windowOpen then window.Visible = false end
        end)
        -- restore prior mouse state (3rd Person etc. re-locks on its own next
        -- frame if it's still enabled; otherwise game gets whatever it had)
        if _preMenuMouseBehavior then
            UserInputService.MouseBehavior = _preMenuMouseBehavior
        end
        if _preMenuMouseIcon ~= nil then
            UserInputService.MouseIconEnabled = _preMenuMouseIcon
        end
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
    -- v0.0.94 combo bind: { mod = KeyCode, key = KeyCode } -- fires only when
    -- the target key is pressed AND the modifier is currently held.
    if type(bind) == "table" and bind.mod and bind.key then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return false end
        if input.KeyCode ~= bind.key then return false end
        return UserInputService:IsKeyDown(bind.mod)
    end
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
        -- v0.0.94: pressing JUST a modifier alone (Shift/Ctrl/Alt without another key)
        -- doesn't complete the rebind -- user needs to press the actual key while
        -- holding the modifier. Otherwise the modifier itself gets bound as the key.
        if it == Enum.UserInputType.Keyboard then
            local kc = input.KeyCode
            if kc == Enum.KeyCode.LeftShift  or kc == Enum.KeyCode.RightShift
            or kc == Enum.KeyCode.LeftControl or kc == Enum.KeyCode.RightControl
            or kc == Enum.KeyCode.LeftAlt    or kc == Enum.KeyCode.RightAlt then
                return   -- wait for a real key
            end
        end
        local bind
        if it == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            -- v0.0.94: capture combo if any modifier is currently held.
            local heldMod
            if     UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)   then heldMod = Enum.KeyCode.LeftShift
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then heldMod = Enum.KeyCode.LeftControl
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)     then heldMod = Enum.KeyCode.LeftAlt
            elseif UserInputService:IsKeyDown(Enum.KeyCode.RightShift)  then heldMod = Enum.KeyCode.RightShift
            elseif UserInputService:IsKeyDown(Enum.KeyCode.RightControl)then heldMod = Enum.KeyCode.RightControl
            elseif UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)    then heldMod = Enum.KeyCode.RightAlt
            end
            if heldMod then bind = { mod = heldMod, key = input.KeyCode }
            else bind = input.KeyCode end
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
;(function()
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
end)()

-- v0.0.37: poll the Koffee Helper for OS-level input (XButton1/2). It serves live
-- button state over localhost; we cache it in `Helper` for the virtual-bind drivers.
-- Degrades silently on a slow backoff when the helper isn't running.
;(function()
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
end)()

-- v0.0.34: auto-load this game's saved config (if one is pinned). Deferred +
-- pcall'd so a bad/locked config never blocks the UI from coming up.
task.spawn(function()
    local auto = Koffee.Config.getAuto()
    if not auto then return end
    task.wait(0.25)
    pcall(function() Koffee.Config.load(auto) end)
end)
end)()

return Koffee
