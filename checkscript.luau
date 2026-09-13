-- Static gate for koffee.lua. Real Luau compiler, so this also catches the
-- register / local-count limits that a plain parse never sees.
-- v0.58.0: compile at optimizationLevel 0 -- executors compile UNOPTIMIZED, which
-- has the highest register pressure. O1/O2 coalesce registers and HID a real
-- "Out of local registers > 200" overflow that only blew up in-game. Gate at O0.
local process = require("@lune/process")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local ok, err = pcall(function()
    return luau.compile(fs.readFile("dist/koffee.lua"), { optimizationLevel = 0, debugLevel = 1 })
end)
if ok then
    print("LUAU COMPILE OK")
else
    print("LUAU COMPILE FAIL:\n" .. tostring(err))
    process.exit(1)
end
