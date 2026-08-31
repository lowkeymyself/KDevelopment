-- Static gate for koffee.lua. Real Luau compiler, so this also catches the
-- register / local-count limits that a plain parse never sees.
local process = require("@lune/process")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local ok, err = pcall(function()
    return luau.compile(fs.readFile("dist/koffee.lua"), { optimizationLevel = 1, debugLevel = 1 })
end)
if ok then
    print("LUAU COMPILE OK")
else
    print("LUAU COMPILE FAIL:\n" .. tostring(err))
    process.exit(1)
end
