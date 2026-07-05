local function fn(config)
    local func = {
        _type = "fn_structured_function",
        code = config.code,
        doc = config.doc or "",
        debug = config.debug or {},
        schema = config.schema or {}
    }

    -- Automatically add line number to debug info if not provided
    if func.debug.line == nil then
        local info = debug.getinfo(2, "S")
        func.debug.line = info and info.currentline or -1
    end

    setmetatable(func, {
        __call = function(self, args)
            -- Integration point for arg_parser
            local alce = require("alce.src.globals")
            local arg_parser = require("alce.src.arg_parser")

            local parsed_args
            if alce.cfg.strict then
                -- Full validation path
                parsed_args = arg_parser.parse_args(self, args)
            else
                -- Fast path: only handle defaults/presence
                parsed_args = {}
                for key, spec in pairs(self.schema) do
                    local exists = false
                    for k in pairs(args) do
                        if k == key then
                            exists = true
                            break
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

return {
    fn = fn
}
