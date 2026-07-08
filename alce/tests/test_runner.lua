-- Wrapper to handle relative requires and environment mocking for raw tests
require("tools.env_mock")

local old_req = require
require = function(m)
    if type(m) == "string" then
        -- Handle relative requires for luapack compatibility
        if m:sub(1, 2) == "./" then
            return old_req(m:sub(3))
        end
        -- Handle "alce.src.x" or "alce.tests.x" by stripping "alce."
        if m:sub(1, 5) == "alce." then
            return old_req(m:sub(6))
        end
    end
    return old_req(m)
end

if not arg or not arg[1] then
    print("Usage: lua test_runner.lua <test_file>")
    os.exit(1)
end

dofile(arg[1])
