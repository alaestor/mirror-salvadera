local fn = require("alce.src.fn").fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")
local vt = require("alce.src.vt")

local T = {
    __doc = [[
    A convenient table that can be indexed by CE vartype value (`vtDword`), basic type string (`'dword'`), or CE vartype string (`'vtDword'`) to get a corresponding `alce.vt.VTypeHelper`. Useful for quick conversions, creating arguments, or doing type-appropriate reads/writes programmatically.

    Example usage:
    ```lua
    -- read and write values
    local x = alce.T[vtDword]:read(x_addr)
    alce.T[vtDword]:write(y_addr, x)

    -- easy conversions
    local t = alce.T.(something.type)
    print('The type is ' .. t.name) -- basic lowercase type name without the vartype `vt` prefix
    assert(alce.T[t.name] == alce.T[t.vType])
    print('That type is used for the following monotypes: ' .. alce.fmt.table(t:getMonotypes)) -- prints integer

    -- creating `{type=,value=}` dict pairs (calling is just a shorthand for `asInvokeArgument`)
    invoke(method, {
        alce.T[vtPointer]:asInvokeArgument(instance),
        alce.T[vtString]('my string'), -- lookup by vartype integer ID
        alce.T['single'](3.14159), -- lookup by basic type name
        alce.T['vtSingle'](6.28318) -- lookup by vartype string
    })
    ```
    ]],
}

-- Populate T with VTypeHelpers
for _, v in pairs(vt.basicTypeStrings) do
    local t = vt.VTypeHelper:new(v)
    for _, lookupKey in pairs({t.name, t.vtName, t.vType}) do
        assert(not T[lookupKey], 'alce.T: key already exists: ' .. tostring(lookupKey))
        T[lookupKey] = t
    end
end

-- Calculate the maximum monotype key and store it in config
local max_key = -math.huge
if monoTypeToVartypeLookup then
    for k, _ in pairs(monoTypeToVartypeLookup) do
        if type(k) == 'number' and k > max_key then
            max_key = k
        end
    end
end
alce.cfg.monotype_max_key = max_key

-- Export T back to the global alce table for backward compatibility and general access
alce.T = T

T.unsafeFromMono = fn({
    doc = "returns a VTypeHelper from a monoType, with a warning if it exceeds the lookup key limit",
    returns = "VTypeHelper",
    schema = {
        monoType = { type = "any" }
    },
    code = function(self, args)
        local monoType = args.monoType
        if (not validators.isInteger(monoType)) or monoType > alce_monotype_max_key then
            alce.warn('alce.T.unsafeFromMono(): monoType (' .. tostring(monoType) .. ') is bigger than the largest monoTypeToVartypeLookup key. Monoscript defaults to vtDword.')
        end
        return alce.T[monoTypeToVarType(monoType)]
    end
})

T.fromMono = fn({
    doc = "returns a VTypeHelper from a monoType with a bounds-checking assertion",
    returns = "VTypeHelper",
    schema = {
        monoType = { type = "any" }
    },
    code = function(self, args)
        local monoType = args.monoType
        assert(validators.isInteger(monoType) and monoType <= alce_monotype_max_key, 'alce.T.fromMono(): monoType (' .. tostring(monoType) .. ') is bigger than the largest monoTypeToVartypeLookup key.')
        return alce.T[monoTypeToVartypeLookup[monoType]]
    end
})

return T
