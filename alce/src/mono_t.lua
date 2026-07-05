local fn = require("alce.src.fn").fn
local member_fn = require("alce.src.fn").member_fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local T = {}

T.List = {
    indexFrom = 0x20,
    indexBy = 0x8,
    offset = {
        items = 0x10,
        size = 0x18
    },

    new = member_fn({
        doc = "Creates a new T.List representation at the given baseAddress.",
        code = function(self, baseAddress, optional_indexFrom, optional_indexBy, optional_offsetItems, optional_offsetSize)
            assert(validators.isAddresslike(baseAddress), 'alce.mono.T.List.new(): invalid argument: baseAddress: ' .. tostring(baseAddress))
            assert((not optional_indexFrom) or validators.isOffsetlike(optional_indexFrom), 'alce.mono.T.List.new(): invalid argument: optional_indexFrom')
            assert((not optional_indexBy) or validators.isOffsetlike(optional_indexBy), 'alce.mono.T.List.new(): invalid argument: optional_indexBy')
            assert((not optional_offsetItems) or validators.isOffsetlike(optional_offsetItems), 'alce.mono.T.List.new(): invalid argument: optional_offsetItems')
            assert((not optional_offsetSize) or validators.isOffsetlike(optional_offsetSize), 'alce.mono.T.List.new(): invalid argument: optional_offsetSize')

            local instance = {
                baseAddress = baseAddress,
                indexFrom = optional_indexFrom or self.indexFrom,
                indexBy = optional_indexBy or self.indexBy,
                offset = {
                    items = optional_offsetItems or self.offset.items,
                    size = optional_offsetSize or self.offset.size
                }
            }
            setmetatable(instance, { __index = self, __call = self.at })
            return instance
        end,
    }),

    newFromChain = member_fn({
        doc = "Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`",
        code = function(self, ...)
            return self:new(alce.readPointerChain(...))
        end,
    }),

    size = member_fn({
        doc = "Returns the number of items in the list.",
        code = function(self)
            assert(validators.isAddresslike(self.baseAddress), 'alce.mono.T.List.size(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
            return readInteger(self.baseAddress + self.offset.size)
        end,
    }),

    atUnsafe = member_fn({
        doc = "Returns address of the Nth element at index (starting from zero) without bounds checking.",
        code = function(self, index)
            local itemBase = readPointer(self.baseAddress + self.offset.items)
            return readPointer(itemBase + self.indexFrom + (index * self.indexBy))
        end,
    }),

    at = member_fn({
        doc = "Returns address of the Nth element at index (starting from zero) with bounds checking.",
        code = function(self, index)
            assert(validators.isAddresslike(self.baseAddress), 'alce.mono.T.List.at(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
            assert(validators.isNonNegativeInteger(index), 'alce.mono.T.List.at(): invalid argument: index: ' .. tostring(index))
            assert(index < self:size(), 'alce.mono.T.List.at(): invalid argument: index is out of bounds')
            return self:atUnsafe(index)
        end,
    }),

    iterator = member_fn({
        doc = "Returns an iterator which returns the value of the list item from optional_start to optional_end.",
        code = function(self, optional_start, optional_end)
            local i = optional_start or 0
            local size = self:size()
            local e = optional_end or size
            assert(validators.isOffsetlike(i), 'alce.mono.T.List.iterator(): invalid argument: optional_start: ' .. tostring(optional_start))
            assert(validators.isOffsetlike(e), 'alce.mono.T.List.iterator(): invalid argument: optional_end: ' .. tostring(optional_end))
            assert(e <= size, 'alce.mono.T.List.iterator(): invalid argument: optional_end was out of bounds: ' .. tostring(optional_end))

            local info = debug.getinfo(2, "Sl")
            return function()
                if i < e then
                    assert(i < self:size(), 'line ' .. tostring(info.currentline) .. ': alce.mono.T.List.iterator(): iterator went out of bounds during iteration... Size changed?')
                    i = i + 1
                    return i, self:atUnsafe(i - 1)
                end
            end
        end,
    }),

    instanceIterator = member_fn({
        doc = "Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses.",
        code = function(self, alceClass, optional_start, optional_end)
            assert(alce.isCallable(alceClass.instance), 'alce.mono.T.List.instanceIterator(): invalid argument: alceClass must have an Instance method.')
            local iter = self:iterator(optional_start, optional_end)
            return function()
                local i, r = iter()
                if r then return i, alceClass:instance(r)
                else return nil end
            end
        end,
    }),
}

return T
