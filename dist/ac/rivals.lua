-- RIVALS disabler, standalone. Detection gated, no place id.
-- Scan for LocalScript3, then weak table guard plus anti kick.
local ok, err = pcall(function()
    local rf = game:GetService("ReplicatedFirst")
    if not (rf and rf:FindFirstChild("LocalScript3")) then return end
    local hookfn = hookfunction or replaceclosure
    if not (hookfn and getrenv and debug and debug.traceback) then return end
    local G = getgenv and getgenv()
    if G and G["\6_rt_rv_ctx"] then return end
    if G then G["\6_rt_rv_ctx"] = true end
    local wrap = newcclosure or function(f) return f end
    local players = game:GetService("Players")
    local lp = nil
    pcall(function()
        if cloneref then
            lp = cloneref(players).LocalPlayer
        else
            lp = players.LocalPlayer
        end
    end)
    if lp == nil then return end
    local mtHook = nil
    mtHook = hookfn(getrenv().setmetatable, wrap(function(t, mt)
        if type(mt) == "table" and rawget(mt, "__mode") then
            local mode = rawget(mt, "__mode")
            if mode == "kv" or mode == "v" or mode == "k" then
                local tr = ""
                pcall(function() tr = debug.traceback() end)
                if tr:find("MiscellaneousController", 1, true) then
                    return mtHook({ 1, 2, 3 }, {})
                end
                if tr:find("CameraSecurity", 1, true) then
                    return mtHook({ 1, 2, 3 }, {})
                end
                if tr:find("AnalyticsPipelineController", 1, true) then
                    return mtHook({ 1, 2, 3 }, {})
                end
            end
        end
        return mtHook(t, mt)
    end))
    local oldKick = nil
    pcall(function() oldKick = lp.Kick end)
    if oldKick == nil then return end
    pcall(hookfn, oldKick, wrap(function(self, ...)
        if self == lp then return end
        return oldKick(self, ...)
    end))
end)

if not ok then
    local G = getgenv and getgenv()
    if G then G["\6_rt_rv_ctx"] = nil end
end
