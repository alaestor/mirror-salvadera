require = function(c)
return __M[c]()
end
__M={["mfd20"]=function()local math_helper = require("mcb34")
local M = {}
function M.greet(name)
    return "Hello, " .. name .. "! 2 squared is " .. math_helper.square(2)
end
return M
end,["mcb34"]=function()local M = {}
function M.square(n)
    return n * n
end
return M
end}local utils = require("mfd20")
print("Main: " .. utils.greet("LuaPack"))
