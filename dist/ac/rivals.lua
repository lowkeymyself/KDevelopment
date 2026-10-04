-- RIVALS bypass, standalone. Detection gated, no place id.
-- Scan for LocalScript3, then setmetatable guard plus stall of AC closures.
local ok, err = pcall(function()
    local rf = game:GetService("ReplicatedFirst")
    if not (rf and rf:FindFirstChild("LocalScript3")) then return end
    local hookfn = hookfunction or replaceclosure
    if not (hookfn and getgc and getrenv and debug and debug.info and debug.traceback) then return end
    local G = getgenv and getgenv()
    if G and G["\6_rt_rv_ctx"] then return end
    if G then G["\6_rt_rv_ctx"] = true end
    local wrap = newcclosure or function(f) return f end
    local oldSet
    oldSet = hookfn(getrenv().setmetatable, wrap(function(t, mt)
        if type(mt) == "table" and rawget(mt, "__mode") == "kv" then
            local tr = ""
            pcall(function() tr = debug.traceback() end)
            if tr:find("LocalScript3", 1, true) or tr:find("MiscellaneousController", 1, true) then
                return oldSet({ 1, 2, 3 }, {})
            end
        end
        return oldSet(t, mt)
    end))
    local gcNow = getgc
    pcall(function()
        for _, v in ipairs(gcNow()) do
            if type(v) == "function" then
                local ok3, src = pcall(debug.info, v, "s")
                if ok3 and src and (src:find("LocalScript3", 1, true) or src:find("MiscellaneousController", 1, true)) then
                    pcall(hookfn, v, wrap(function() return task.wait(9e9) end))
                end
            end
        end
    end)
end)

if not ok then
    local G = getgenv and getgenv()
    if G then G["\6_rt_rv_ctx"] = nil end
end
