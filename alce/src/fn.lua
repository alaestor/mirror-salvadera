local alce = require("alce.src.globals")
local arg_parser = require("alce.src.arg_parser")

local function fn(config)
    local func = {
        _type = "fn_structured_function",
        code = config.code,
        __doc = config.__doc or "",
        __doc_returns = config.__doc_returns or "",
        positional = config.positional or false,
        member = config.member or false,
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
            local varargs = {...}

            if self.positional then
                return self.code(self, ...)
            end

            local instance = nil
            local args = nil

            if self.member then
                local arg_count = select('#', ...)
                if arg_count >= 2 then
                    instance = varargs[1]
                    args = varargs[2]
                elseif arg_count == 1 then
                    local first = varargs[1]
                    if type(first) == 'table' then
                        local is_args = false
                        for k, _ in pairs(self.schema) do
                            if first[k] ~= nil then
                                is_args = true
                                break
                            end
                        end
                        if is_args then
                            instance = nil
                            args = first
                        else
                            instance = first
                            args = nil
                        end
                    else
                        instance = first
                        args = nil
                    end
                else
                    instance = nil
                    args = nil
                end
            else
                -- Standalone: the first arg (if any) is the args table
                args = varargs[1]
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

            if self.member then
                -- Execute the code with instance and parsed arguments
                return self.code(self, instance, parsed_args)
            else
                -- Execute the code with parsed arguments
                return self.code(self, parsed_args)
            end
        end
    })

    return func
end

local function member_fn(config)
    -- member_fn is designed to be used as a method (e.g. object:method()).
    return fn({
        member = true,
        positional = config.positional or false,
        code = function(self, instance, ...)
            return config.code(instance, ...)
        end,
        __doc = config.__doc,
        __doc_returns = config.__doc_returns,
        schema = config.schema
    })
end

return {
    fn = fn,
    member_fn = member_fn
}
