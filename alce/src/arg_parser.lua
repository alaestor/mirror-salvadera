local function parse_args(self, input, strict)
    input = input or {}
    local parameters = self.parameters or {}
    local out = {}

    for key, spec in pairs(parameters) do
        local val = input[key]
        local exists = (val ~= nil)

        if exists then
            if strict and spec.validate then
                local ok, err = spec.validate(val)
                if not ok then
                    error(string.format("invalid arg '%s': %s", key, tostring(err)))
                end
            end

            if spec.transform then
                val = spec.transform(val)
            end
            out[key] = val
        elseif spec.default ~= nil then
            local def = type(spec.default) == "function" and spec.default() or spec.default
            if spec.transform then
                def = spec.transform(def)
            end
            out[key] = def
        elseif strict and spec.required then
            error(string.format("missing required arg '%s'", key))
        end
    end

    if strict then
        for key, _ in pairs(input) do
            if parameters[key] == nil then
                error(string.format("unexpected arg '%s'", key))
            end
        end
    end

    return out
end

return {
    parse_args = parse_args
}
