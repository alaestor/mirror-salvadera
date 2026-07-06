local fn = require("./fn").fn
local alce = require("./globals")

local validators = {}

validators.isInteger = fn({
    doc = "checks if value is an integer",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer'
    end
})

validators.isPositiveInteger = fn({
    doc = "checks if value is a positive integer",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer' and value > 0
    end
})

validators.isNonNegativeInteger = fn({
    doc = "checks if value is a non-negative integer",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer' and value >= 0
    end
})

validators.isFloat = fn({
    doc = "checks if value is a float",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'float'
    end
})

validators.isNonNegativeFloat = fn({
    doc = "checks if value is a non-negative float",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'float' and value >= 0.0
    end
})

validators.isFiniteNumber = fn({
    doc = "checks if value is a finite number",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
    end
})

validators.isNonEmptyString = fn({
    doc = "checks if value is a non-empty string",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'string' and value ~= ''
    end
})

validators.isNonBlankString = fn({
    doc = "checks if value is a non-blank string",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'string' and string.find(value, '%S') ~= nil
    end
})

validators.isTable = fn({
    doc = "checks if value is a table",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'table'
    end
})

validators.isEmptyTable = fn({
    doc = "checks if value is an empty table",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'table' and next(value) == nil
    end
})

validators.isNonEmptyTable = fn({
    doc = "checks if value is a non-empty table",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        return type(value) == 'table' and next(value) ~= nil
    end
})

validators.isZeroEmptyOrNil = fn({
    doc = "checks if value is zero, empty table, blank string, or nil",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        local t = type(value)
        return t == nil or (t == 'number' and value == 0) or self.isEmptyTable(value) or (not self.isNonBlankString(value))
    end
})

validators.isCallable = fn({
    doc = "checks if value is callable",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" } },
    code = function(self, value)
        if type(value) == 'function' then return true end
        local mt = getmetatable(value)
        return mt ~= nil and type(mt.__call) == 'function'
    end
})

validators.isBetween = fn({
    doc = "checks if value is between minimum and maximum",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" }, minimum = { type = "number" }, maximum = { type = "number" } },
    code = function(self, value, minimum, maximum)
        return value > minimum and value < maximum
    end
})

validators.isSignedOffsetlike = fn({
    doc = "checks that the value isInteger and within positive and negative optional_tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" }, optional_tooFarBoundary = { type = "number", default = nil } },
    code = function(self, value, optional_tooFarBoundary)
        local boundary = (optional_tooFarBoundary or alce.cfg.isOffset_tooFarBoundary)
        return self.isInteger(value) and value > -boundary and value < boundary
    end
})

validators.isOffsetlike = fn({
    doc = "checks that the value isNonNegativeInteger and less than optional_tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" }, optional_tooFarBoundary = { type = "number", default = nil } },
    code = function(self, value, optional_tooFarBoundary)
        return self.isNonNegativeInteger(value) and value < (optional_tooFarBoundary or alce.cfg.isOffset_tooFarBoundary)
    end
})

validators.isAddresslike = fn({
    doc = "checks that the value isInteger and greater than optional_nearNullBoundary (or alce.cfg.isAddress_nearNullBoundary) and less than optional_userspaceBoundary (or alce.cfg.isAddress_userspaceBoundary)",
    returns = "boolean",
    positional = true,
    schema = { value = { type = "any" }, optional_nearNullBoundary = { type = "number", default = nil }, optional_userspaceBoundary = { type = "number", default = nil } },
    code = function(self, value, optional_nearNullBoundary, optional_userspaceBoundary)
        return self.isInteger(value) and value > (optional_nearNullBoundary or alce.cfg.isAddress_nearNullBoundary) and value < (optional_userspaceBoundary or (targetIs64Bit() and alce.cfg.isAddress_userspaceBoundary64 or alce.cfg.isAddress_userspaceBoundary32))
    end
})

validators.hasFlag = fn({
    doc = "equivalent to (flags & flag) == flag",
    returns = "boolean",
    positional = true,
    schema = { flag = { type = "number" }, flags = { type = "number" } },
    code = function(self, flag, flags)
        return (flags & flag) == flag
    end
})

validators.check = fn({
    doc = "passthru assert with source line (checks positive, e.g. assert(value) or assert(optional_checker(value)))",
    returns = "any",
    positional = true,
    schema = { value = { type = "any" }, optional_checker = { type = "any", default = nil } },
    code = function(self, value, optional_checker)
        local info = debug.getinfo(2, "Sl")
        assert(optional_checker == nil or self.isCallable(optional_checker), 'line ' .. tostring(info.currentline) .. ': alce.check: invalid argument: optional_checker not callable.')
        assert(optional_checker and optional_checker(value) or value, 'line ' .. tostring(info.currentline) .. ': alce.check( ' .. tostring(value) .. ' )')
        return value
    end
})

validators.ncheck = fn({
    doc = "passthru negation-assert with source line (checks negative, e.g. assert(not value) or assert(not optional_checker(value)))",
    returns = "any",
    positional = true,
    schema = { value = { type = "any" }, optional_checker = { type = "any", default = nil } },
    code = function(self, value, optional_checker)
        local info = debug.getinfo(2, "Sl")
        assert(optional_checker == nil or self.isCallable(optional_checker), 'line ' .. tostring(info.currentline) .. ': alce.check: invalid argument: optional_checker not callable.')
        assert(not (optional_checker and optional_checker(value) or value), 'line ' .. tostring(info.currentline) .. ': alce.ncheck( ' .. tostring(value) .. ' )')
        return value
    end
})

return validators
