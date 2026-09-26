-- RIVALS AC filter. PlaceId-gated, read-mostly, one hook.
-- Findings it is built on (2026-09-26, read-only scan of the live client):
--   ReplicatedFirst.LocalScript3 (virtualized) reports every uncaught error through
--   ScriptContext.Error, and answers a ~3s server nonce over
--   ReplicatedStorage.Remotes.AnalyticsPipeline. game.DescendantAdded is watched by a
--   separate chunk that only reacts to LuaSourceContainer, so ordinary instances are fine.
-- Design: never kill LocalScript3, never touch the pipeline, never disable a connection
-- (a disabled connection reads back as disconnected). Hook the reporter closure instead and
-- forward every genuine game error, dropping only errors that came from outside the game.
local PLACE = 17625359962

local ok, err = pcall(function()
    if game.PlaceId ~= PLACE then return end
    local G = getgenv()
    if G.__KRIV and G.__KRIV.active then return end

    local hookfn = hookfunction or replaceclosure
    if not hookfn then
        G.__KRIV = { active = false, reason = "no hookfunction" }
        return
    end

    local ScriptContext = game:GetService("ScriptContext")
    local state = { active = false, hooked = 0, passed = 0, dropped = 0, lastDrop = nil, originals = {},
        selfScripts = {}, forwardErrors = 0, inForward = false, windowAt = 0, windowN = 0 }

    -- resolve the script instance that owns a closure, so the AC's own errors can be told apart
    local function ownerOf(src)
        local name = tostring(src):match("([^%.]+)$")
        if not name then return nil end
        local found
        pcall(function()
            for _, root in ipairs({ game:GetService("ReplicatedFirst"), game:GetService("Players").LocalPlayer }) do
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("LuaSourceContainer") and d.Name == name then found = d; return end
                end
            end
        end)
        return found
    end

    -- An error belongs to the game only when its script argument is a live descendant of
    -- the DataModel. Executor chunks report a nil or detached script, so they never match.
    local function isGameError(scriptArg)
        if typeof(scriptArg) ~= "Instance" then return false end
        local good = false
        pcall(function() good = scriptArg:IsDescendantOf(game) end)
        return good
    end

    local function wrap(target)
        local original
        local function filtered(message, trace, scriptArg, ...)
            -- never let this hook be the thing that throws
            local pass = true
            pcall(function() pass = isGameError(scriptArg) end)
            -- the AC's own errors must never be handed back to the AC. That recursed until the
            -- engine hit its ScriptContext.Error re-entrancy cap and the VM decoder broke.
            if pass and state.selfScripts[scriptArg] then pass = false end
            -- already inside a forward: drop rather than nest
            if pass and state.inForward then pass = false end
            -- and a ceiling, so a game-side error storm can never become a recursion storm
            if pass then
                local now = os.clock()
                if now - state.windowAt >= 1 then state.windowAt, state.windowN = now, 0 end
                state.windowN += 1
                if state.windowN > 12 then pass = false end
            end
            -- original is assigned just after the hook lands; never call a nil in that window
            if pass and original then
                state.passed += 1
                state.inForward = true
                -- pcall so a throw inside their handler cannot become a fresh engine error
                local okf = pcall(original, message, trace, scriptArg, ...)
                state.inForward = false
                if not okf then state.forwardErrors += 1 end
                return nil
            end
            state.dropped += 1
            pcall(function() state.lastDrop = tostring(message):sub(1, 120) end)
            return nil
        end
        local candidates = { filtered }
        if newcclosure then
            local okc, c = pcall(newcclosure, filtered)
            if okc and c then table.insert(candidates, 1, c) end
        end
        for _, fn in ipairs(candidates) do
            local okh, res = pcall(hookfn, target, fn)
            if okh and res then
                original = res
                return res
            end
        end
        return nil
    end

    local function apply()
        local okc, conns = pcall(getconnections, ScriptContext.Error)
        if not okc or type(conns) ~= "table" then return end
        for _, c in ipairs(conns) do
            -- skip the foreign-state CoreScript listener: it is Roblox's, not the game's
            if c.ForeignState ~= true then
                local f = c.Function
                if f and not state.originals[f] then
                    local src = ""
                    pcall(function() src = tostring(debug.info(f, "s")) end)
                    -- only the game's own reporter, identified by its source chunk
                    if src:find("LocalScript3", 1, true) then
                        local owner = ownerOf(src)
                        if owner then state.selfScripts[owner] = true end
                        local orig = wrap(f)
                        if orig then
                            state.originals[f] = orig
                            state.hooked += 1
                            state.active = true
                        end
                    end
                end
            end
        end
    end

    function state.revert()
        local r = restorefunction
        if not r then return false end
        local n = 0
        for f in pairs(state.originals) do
            if pcall(r, f) then n += 1 end
        end
        state.originals = {}
        state.active = false
        G.__KRIV = nil
        return n
    end

    G.__KRIV = state
    apply()

    -- the AC may reconnect after a respawn or teleport; re-check occasionally.
    -- A hooked closure survives a reconnect, so this only catches a brand new closure.
    task.spawn(function()
        while G.__KRIV == state do
            task.wait(10)
            if G.__KRIV ~= state then break end
            pcall(apply)
        end
    end)
end)

if not ok then
    getgenv().__KRIV = { active = false, reason = tostring(err) }
end
