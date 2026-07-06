local alce = require("./globals")

alce.monoscript = {
    __doc = [[
Collection related to global constants defined in CE's `monoscript.lua`

Groups:
- `monotype`
- `fieldAttribute`
- `methodAttribute`

Each group's dict contains the string `prefix` of the global constants, an array of `names` and a `nameLookup` dict of names keyed by their value.

Note: For each name string, you can get its value by `_G[name]`. For some monoTypes, `monoscript.lua` provides C-style type names via `monoTypeToCStringLookup[name]`
]]
}

-- declare groups
for _,v in pairs({
    {name = 'monotype', prefix = 'MONO_TYPE_'},
    {name = 'fieldAttribute', prefix = 'FIELD_ATTRIBUTE_'},
    {name = 'methodAttribute', prefix = 'METHOD_ATTRIBUTE_'}
}) do
    alce.monoscript[v.name] = {}
    local t = alce.monoscript[v.name]
    t.prefix = v.prefix
    t.prefixLen = string.len(t.prefix)
    t.names = {}
    t.nameLookup = {}
end

-- map globals to groups
for k, v in pairs(_G) do
    if type(k) == 'string' then
        for _,group in pairs(alce.monoscript) do
            if k:sub(1,group.prefixLen) == group.prefix then
                table.insert(group.names, k)
                group.nameLookup[v] = k
            end
        end
    end
end

-- sort name arrays alphabetically
for _,group in pairs(alce.monoscript) do
    if type(group) == 'table' and group.names then
        table.sort(group.names)
    end
end

return alce.monoscript
