local fn = require("alce.src../fn").fn
local alce = require("alce.src../globals")

local validators = {}

validators.isInteger = fn({
    __doc = [[any: checks if value is an integer]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer'
    end
})

validators.isPositiveInteger = fn({
    __doc = [[any: checks if value is a positive integer]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer' and value > 0
    end
})

validators.isNonNegativeInteger = fn({
    __doc = [[any: checks if value is a non-negative integer]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'integer' and value >= 0
    end
})

validators.isFloat = fn({
    __doc = [[any: checks if value is a float]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'float'
    end
})

validators.isNonNegativeFloat = fn({
    __doc = [[any: checks if value is a non-negative float]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and math.type(value) == 'float' and value >= 0.0
    end
})

validators.isFiniteNumber = fn({
    __doc = [[any: checks if value is a finite number]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
    end
})

validators.isNonEmptyString = fn({
    __doc = [[any: checks if value is a non-empty string]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'string' and value ~= ''
    end
})

validators.isNonBlankString = fn({
    __doc = [[any: checks if value is a non-blank string]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'string' and string.find(value, '%S') ~= nil
    end
})

validators.isTable = fn({
    __doc = [[any: checks if value is a table]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'table'
    end
})

validators.isEmptyTable = fn({
    __doc = [[any: checks if value is an empty table]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'table' and next(value) == nil
    end
})

validators.isNonEmptyTable = fn({
    __doc = [[any: checks if value is a non-empty table]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        return type(value) == 'table' and next(value) ~= nil
    end
})

validators.isZeroEmptyOrNil = fn({
    __doc = [[any: checks if value is zero, empty table, blank string, or nil]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        local t = type(value)
        return t == nil or (t == 'number' and value == 0) or self.isEmptyTable(value) or (not self.isNonBlankString(value))
    end
})

validators.isCallable = fn({
    __doc = [[any: checks if value is callable]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true } },
    code = function(self, value)
        if type(value) == 'function' then return true end
        local mt = getmetatable(value)
        return mt ~= nil and type(mt.__call) == 'function'
    end
})

validators.isBetween = fn({
    __doc = [[any: checks if value is between minimum and maximum]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, minimum = { __doc = [[number: the minimum value]], required = true }, maximum = { __doc = [[number: the maximum value]], required = true } },
    code = function(self, value, minimum, maximum)
        return value > minimum and value < maximum
    end
})

validators.isSignedOffsetlike = fn({
    __doc = [[any: checks that the value isInteger and within positive and negative tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, tooFarBoundary = { __doc = [[number: the boundary value]], default = nil } },
    code = function(self, value, tooFarBoundary)
        local boundary = (tooFarBoundary or alce.cfg.isOffset_tooFarBoundary)
        return self.isInteger(value) and value > -boundary and value < boundary
    end
})

validators.isOffsetlike = fn({
    __doc = [[any: checks that the value isNonNegativeInteger and less than tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, tooFarBoundary = { __doc = [[number: the boundary value]], default = nil } },
    code = function(self, value, tooFarBoundary)
        return self.isNonNegativeInteger(value) and value < (tooFarBoundary or alce.cfg.isOffset_tooFarBoundary)
    end
})

validators.isAddresslike = fn({
    __doc = [[any: checks that the value isInteger and greater than nearNullBoundary (or alce.cfg.isAddress_nearNullBoundary) and less than userspaceBoundary (or alce.cfg.isAddress_userspaceBoundary)]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, nearNullBoundary = { __doc = [[number: the near-null boundary]], default = nil }, userspaceBoundary = { __doc = [[number: the userspace boundary]], default = nil } },
    code = function(self, value, nearNullBoundary, userspaceBoundary)
        return self.isInteger(value) and value > (nearNullBoundary or alce.cfg.isAddress_nearNullBoundary) and value < (userspaceBoundary or (targetIs64Bit() and alce.cfg.isAddress_userspaceBoundary64 or alce.cfg.isAddress_userspaceBoundary32))
    end
})

validators.hasFlag = fn({
    __doc = [[any: equivalent to (flags & flag) == flag]],
    __doc_returns = [[boolean]],
    positional = true,
    schema = { flag = { __doc = [[number: the flag to check for]], required = true }, flags = { __doc = [[number: the bit-flags to check]], required = true } },
    code = function(self, flag, flags)
        return (flags & flag) == flag
    end
})

validators.check = fn({
    __doc = [[any: passthru assert with source line (checks positive, e.g. assert(value) or assert(checker(value)))]],
    __doc_returns = [[any]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, checker = { __doc = [[any: the checker function]], default = nil } },
    code = function(self, value, checker)
        local info = debug.getinfo(2, "Sl")
        assert(checker == nil or self.isCallable(checker), 'line ' .. tostring(info.currentline) .. ': alce.check: invalid argument: checker not callable.')
        assert(checker and checker(value) or value, 'line ' .. tostring(info.currentline) .. ': alce.check( ' .. tostring(value) .. ' )')
        return value
    end
})

validators.ncheck = fn({
    __doc = [[any: passthru negation-assert with source line (checks negative, e.g. assert(not value) or assert(not checker(value)))]],
    __doc_returns = [[any]],
    positional = true,
    schema = { value = { __doc = [[any: the value to check]], required = true }, checker = { __doc = [[any: the checker function]], default = nil } },
    code = function(self, value, checker)
        local info = debug.getinfo(2, "Sl")
        assert(checker == nil or self.isCallable(checker), 'line ' .. tostring(info.currentline) .. ': alce.check: invalid argument: checker not callable.')
        assert(not (checker and checker(value) or value), 'line ' .. tostring(info.currentline) .. ': alce.ncheck( ' .. tostring(value) .. ' )')
        return value
    end
})

return validators
