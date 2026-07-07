local function parse_args(self, input)
    input = input or {}
    local schema = self.schema or {}
    local out = {}

    for key, spec in pairs(schema) do
        local exists = false
        for k in pairs(input) do
            if k == key then
                exists = true
                break
            end
        end

        if exists then
            local val = input[key]
            -- Validate
    -- Validate
    if spec.validate then
        local ok, err = spec.validate(val)
        if not ok then
            error(string.format("invalid arg '%s': %s", key, tostring(err)))
        end
    end
    out[key] = val
        elseif spec.default ~= nil then
            -- Handle lazy defaults
            if type(spec.default) == "function" then
                out[key] = spec.default()
            else
                out[key] = spec.default
            end
        elseif spec.required then
            error(string.format("missing required arg '%s'", key))
        end
    end

    -- Check for unexpected keys
    for key, _ in pairs(input) do
        if schema[key] == nil then
            error(string.format("unexpected arg '%s'", key))
        end
    end

    -- Transform
    for key, spec in pairs(schema) do
        if out[key] ~= nil and spec.transform then
            out[key] = spec.transform(out[key])
        end
    end

    return out
end

return {
    parse_args = parse_args
}
