local fn = require("alce.src.fn").fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local T = {}

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
