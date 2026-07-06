local fn = require("./fn").fn
local validators = require("./validators")
local alce = require("./globals")

local utils = {}

utils.readPointerChain = fn({
    doc = "reads a chain of pointers starting from the given pointer and following the provided offsets",
    returns = "nil|address",
    positional = true,
    schema = {
        pointer = { type = "address", required = true },
        offsets = { type = "number...", required = false }
    },
    code = function(self, pointer, ...)
        assert(validators.isAddresslike(pointer), 'alce.readPointerChain(): invalid argument: pointer')
        local currentPtr = readPointer(pointer)
        local offsets = {...}
        for _, offset in ipairs(offsets) do
            if not validators.isOffsetlike(offset) then
                alce.warn('alce.readPointerChain(): suspicious offset: ' .. tostring(offset))
            end
            currentPtr = readPointer(currentPtr + offset)
            if not validators.isAddresslike(currentPtr) then
                alce.warn('alce.readPointerChain(): invalid address when trying to chain the following:\n' .. alce.fmt.table({pointer = pointer, offsets = offsets}))
                return nil
            end
        end
        return currentPtr
    end
})

utils.safeChain = fn({
    doc = "reads a chain of pointers and asserts the resulting address isAddressLike",
    returns = "address",
    positional = true,
    schema = {
        pointer = { type = "address", required = true },
        offsets = { type = "number...", required = false }
    },
    code = function(self, pointer, ...)
        local info = debug.getinfo(2, "Sl")
        local result = self.readPointerChain(pointer, ...)
        assert(validators.isAddresslike(result), 'line ' .. tostring(info.currentline) .. ': alce.safeChain(): resulting pointer was invalid:\n' .. alce.fmt.table({pointer = pointer, offsets = {...}, result = result}))
        return result
    end
})

utils.enumerate = fn({
    doc = "enumerates an iterator, providing an index starting from optional_startFrom",
    returns = "integer, any",
    schema = {
        iterator = { validate = validators.isCallable, required = true },
        startFrom = { type = "number", default = 1 }
    },
    code = function(self, args)
        local count = args.startFrom
        return function()
            local value = args.iterator()
            if value == nil then return nil end
            local index = count
            count = count + 1
            return index, value
        end
    end
})

utils.prune = fn({
    doc = "recursively nils keys with empty tables",
    returns = "nil",
    positional = true,
    schema = {
        tbl = { type = "table", required = true }
    },
    code = function(self, tbl)
        local function prune_recursive(tbl)
            if type(tbl) ~= "table" then return end
            for k, v in pairs(tbl) do
                if type(v) == "table" then
                    prune_recursive(v)
                    if next(v) == nil then tbl[k] = nil end
                end
            end
        end
        prune_recursive(tbl)
    end
})

utils.keyFromValue = fn({
    doc = "returns the first key associated with a given value",
    returns = "any|nil",
    schema = {
        value = { type = "any", required = true },
        tbl = { type = "table", required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.tbl) do
            if v == args.value then return k end
        end
    end
})

utils.keysFromValue = fn({
    doc = "returns an array of all keys associated with a given value",
    returns = "table|nil",
    schema = {
        value = { type = "any", required = true },
        tbl = { type = "table", required = true, validate = validators.isTable }
    },
    code = function(self, args)
        local keys = {}
        for k, v in pairs(args.tbl) do
            if v == args.value then table.insert(keys, k) end
        end
        table.sort(keys)
        return next(keys) and keys or nil
    end
})

utils.unsafeExtend = fn({
    doc = "assigns k,v pairs from one table to another, silently overwriting duplicate keys",
    returns = "nil",
    schema = {
        to = { type = "table", required = true, validate = validators.isTable },
        from = { type = "table", required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.from) do
            args.to[k] = v
        end
    end
})

utils.extend = fn({
    doc = "assigns k,v pairs from one table to another, asserting that the keys do not already exist",
    returns = "nil",
    schema = {
        to = { type = "table", required = true, validate = validators.isTable },
        from = { type = "table", required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.from) do
            assert(not args.to[k], 'alce.extend(): key already exists: ' .. tostring(k))
            args.to[k] = v
        end
    end
})

return utils
