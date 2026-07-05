local function fn(config)
    local func = {
        _type = "fn_structured_function",
        code = config.code,
        doc = config.doc or "",
        returns = config.returns or "",
        positional = config.positional or false,
        debug = config.debug or {},
        schema = config.schema or {}
    }

    -- Automatically add line number to debug info if not provided
    if func.debug.line == nil then
        local info = debug.getinfo(2, "S")
        func.debug.line = info and info.currentline or -1
    end

    setmetatable(func, {
        __call = function(self, ...)
            local args = ...
            -- Integration point for arg_parser
            local alce = require("alce.src.globals")
            local arg_parser = require("alce.src.arg_parser")

            if self.positional then
                return self.code(self, ...)
            end

            local parsed_args
            if alce.cfg.strict then
                -- Full validation path
                parsed_args = arg_parser.parse_args(self, args)
            else
                -- Fast path: only handle defaults/presence
                parsed_args = {}
                for key, spec in pairs(self.schema) do
                    local exists = false
                    if type(args) == 'table' then
                        if args[key] ~= nil then
                            exists = true
                        end
                    end

                    if exists then
                        parsed_args[key] = args[key]
                    elseif spec.default ~= nil then
                        parsed_args[key] = type(spec.default) == "function" and spec.default() or spec.default
                    end
                end
            end

            -- Execute the code with parsed arguments
            return self.code(self, parsed_args)
        end
    })

    return func
end

local function member_fn(config)
    -- member_fn is designed to be used as a method (e.g. object:method()).
    -- The __call handler assumes that 'self' (the first argument) is the object instance.
    return fn({
        positional = true,
        code = function(fn_obj, instance, ...)
            -- In member_fn, the 'instance' is passed explicitly as the second argument.
            -- We wrap the original code to ensure it receives the instance.
            return config.code(instance, ...)
        end,
        doc = config.doc,
        returns = config.returns,
        schema = config.schema
    })
end

return {
    fn = fn,
    member_fn = member_fn
}
