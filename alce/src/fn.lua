local alce = require("./globals")
local arg_parser = require("./arg_parser")

-- Define the expected arguments for the function.
-- parameters is a table where keys are argument names and values are specs:
-- {
--     __doc = "<type><: description>", -- Colloquial argument type and an optional description
--     default = value or function,     -- Default value if not provided
--     required = true|false,           -- Whether the argument must be present
--     validate = function(v),          -- Validation function returning ok, err
--     transform = function(v),         -- Transformation function
-- }
--

local function normalize_config(config)
    local defaults = {
        __doc = "",
        __doc_returns = "",
        positional = false,
        member = false,
        debug = {},
        parameters = {},
    }

    local normalized = {}
    for k, v in pairs(defaults) do normalized[k] = v end
    for k, v in pairs(config) do normalized[k] = v end

    if type(normalized.code) ~= "function" then
        error("alce.fn: 'code' must be a function")
    end

    return normalized
end

local function fn(config)
    local func = normalize_config(config)
    func._type = "fn_structured_function"

    -- Automatically add line number to debug info if not provided
    if func.debug.line == nil then
        local info = debug.getinfo(2, "S")
        func.debug.line = info and info.currentline or -1
    end

    setmetatable(func, {
        __call = function(self, ...)
            if self.positional then
                if self.member then
                    return self.code(...)
                else
                    return self.code(self, ...)
                end
            end

            local varargs = {...}
            local instance = self.member and varargs[1] or self
            local args = self.member and varargs[2] or varargs[1]

            local parsed_args = arg_parser.parse_args(self, args, alce.cfg.strict)
            return self.code(instance, parsed_args)
        end
    })

    return func
end

local function member_fn(config)
    -- member_fn is designed to be used as a method (e.g., object:method()).
    local new_config = {
        member = true,
    }
    for k, v in pairs(config) do
        new_config[k] = v
    end
    return fn(new_config)
end

return {
    fn = fn,
    member_fn = member_fn
}
