local math_helper = require("./math_helper")
local M = {}
function M.greet(name)
    return "Hello, " .. name .. "! 2 squared is " .. math_helper.square(2)
end
return M
