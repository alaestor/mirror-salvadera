local fn = require("fn").fn
local validators = require("validators")
local alce = require("globals")

local utils = {}

utils.readPointerChain = fn({
    __doc = [[reads a chain of pointers starting from the given pointer and following the provided offsets]],
    __doc_returns = [[address|nil: the resulting address if successful, otherwise nil]],
    positional = true,
    schema = {
        pointer = { __doc = [[address: the starting address to read from]], required = true },
        offsets = { __doc = [[number...: a sequence of offsets to follow]] }
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
    __doc = [[reads a chain of pointers and asserts the resulting address isAddressLike]],
    __doc_returns = [[address: the resulting address]],
    positional = true,
    schema = {
        pointer = { __doc = [[address: the starting address to read from]], required = true },
        offsets = { __doc = [[number...: a sequence of offsets to follow]] }
    },
    code = function(self, pointer, ...)
        local info = debug.getinfo(2, "Sl")
        local result = self.readPointerChain(pointer, ...)
        assert(validators.isAddresslike(result), 'line ' .. tostring(info.currentline) .. ': alce.safeChain(): resulting pointer was invalid:\n' .. alce.fmt.table({pointer = pointer, offsets = {...}, result = result}))
        return result
    end
})

utils.enumerate = fn({
    __doc = [[enumerates an iterator, providing an index starting from startFrom]],
    __doc_returns = [[integer, any: the current index and the value from the iterator]],
    schema = {
        iterator = { __doc = [[function: the iterator to enumerate]], validate = validators.isCallable, required = true },
        startFrom = { __doc = [[number: the index to start from (defaults to 1)]], default = 1 }
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
    __doc = [[recursively nils keys with empty tables]],
    positional = true,
    schema = {
        tbl = { __doc = [[table: the table to prune]], required = true }
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
    __doc = [[returns the first key associated with a given value]],
    __doc_returns = [[any|nil: the first key associated with the value, or nil if not found]],
    schema = {
        value = { __doc = [[any: the value to search for]], required = true },
        tbl = { __doc = [[table: the table to search in]], required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.tbl) do
            if v == args.value then return k end
        end
    end
})

utils.keysFromValue = fn({
    __doc = [[returns an array of all keys associated with a given value]],
    __doc_returns = [[table|nil: a sorted array of keys associated with the value, or nil if none]],
    schema = {
        value = { __doc = [[any: the value to search for]], required = true },
        tbl = { __doc = [[table: the table to search in]], required = true, validate = validators.isTable }
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
    __doc = [[assigns k,v pairs from one table to another, silently overwriting duplicate keys]],
    schema = {
        to = { __doc = [[table: the destination table]], required = true, validate = validators.isTable },
        from = { __doc = [[table: the source table]], required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.from) do
            args.to[k] = v
        end
    end
})

utils.extend = fn({
    __doc = [[assigns k,v pairs from one table to another, asserting that the keys do not already exist]],
    schema = {
        to = { __doc = [[table: the destination table]], required = true, validate = validators.isTable },
        from = { __doc = [[table: the source table]], required = true, validate = validators.isTable }
    },
    code = function(self, args)
        for k, v in pairs(args.from) do
            assert(not args.to[k], 'alce.extend(): key already exists: ' .. tostring(k))
            args.to[k] = v
        end
    end
})

return utils
