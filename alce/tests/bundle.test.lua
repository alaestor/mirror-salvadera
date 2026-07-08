require("tools.env_mock")
local alce = require("alce")

assert(type(alce) == "table", "alce should be a table")

-- Check for key modules that should be bundled into the single file
local expected_modules = {
    "fmt",
    "utils",
    "fn",
    "memory",
    "mono",
    "validators"
}

for _, module_name in ipairs(expected_modules) do
    assert(alce[module_name] ~= nil, "Module alce." .. module_name .. " is missing from the bundled library")
end

print("Bundle test passed: all key modules are present in the bundled alce.lua")
