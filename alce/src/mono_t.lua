local fn = require("alce.src../fn").fn
local member_fn = require("alce.src../fn").member_fn
local validators = require("alce.src../validators")
local alce = require("alce.src../globals")

local T = {}

T.List = {
    indexFrom = 0x20,
    indexBy = 0x8,
    offset = {
        items = 0x10,
        size = 0x18
    },

    new = member_fn({
        __doc = [[Creates a new T.List representation at the given baseAddress.]],
        __doc_returns = [[T.List: a new T.List instance]],
        schema = {
            baseAddress = { __doc = [[address: the base address]], required = true },
            indexFrom = { __doc = [[offset: starting index]] },
            indexBy = { __doc = [[offset: index increment]] },
            offsetItems = { __doc = [[offset: offset to items]] },
            offsetSize = { __doc = [[offset: offset to size]] },
        },
        code = function(self, args)
            local baseAddress = args.baseAddress
            local indexFrom = args.indexFrom
            local indexBy = args.indexBy
            local offsetItems = args.offsetItems
            local offsetSize = args.offsetSize

            assert(validators.isAddresslike(baseAddress), 'alce.mono.T.List.new(): invalid argument: baseAddress: ' .. tostring(baseAddress))
            assert((not indexFrom) or validators.isOffsetlike(indexFrom), 'alce.mono.T.List.new(): invalid argument: indexFrom')
            assert((not indexBy) or validators.isOffsetlike(indexBy), 'alce.mono.T.List.new(): invalid argument: indexBy')
            assert((not offsetItems) or validators.isOffsetlike(offsetItems), 'alce.mono.T.List.new(): invalid argument: offsetItems')
            assert((not offsetSize) or validators.isOffsetlike(offsetSize), 'alce.mono.T.List.new(): invalid argument: offsetSize')

            local instance = {
                baseAddress = baseAddress,
                indexFrom = indexFrom or self.indexFrom,
                indexBy = indexBy or self.indexBy,
                offset = {
                    items = offsetItems or self.offset.items,
                    size = offsetSize or self.offset.size
                }
            }
            setmetatable(instance, { __index = self, __call = self.at })
            return instance
        end,
    }),

    newFromChain = member_fn({
        __doc = [[Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`]],
        __doc_returns = [[T.List: a new T.List instance]],
        positional = true,
        code = function(self, ...)
            return self:new(alce.readPointerChain(...))
        end,
    }),

    size = member_fn({
        __doc = [[Returns the number of items in the list.]],
        __doc_returns = [[integer: the number of items in the list]],
        code = function(self)
            assert(validators.isAddresslike(self.baseAddress), 'alce.mono.T.List.size(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
            return readInteger(self.baseAddress + self.offset.size)
        end,
    }),

    atUnsafe = member_fn({
        __doc = [[Returns address of the Nth element at index (starting from zero) without bounds checking.]],
        __doc_returns = [[address: the address of the Nth element]],
        schema = {
            index = { __doc = [[integer: the index of the element]], required = true }
        },
        code = function(self, args)
            local index = args.index
            local itemBase = readPointer(self.baseAddress + self.offset.items)
            return readPointer(itemBase + self.indexFrom + (index * self.indexBy))
        end,
    }),

    at = member_fn({
        __doc = [[Returns address of the Nth element at index (starting from zero) with bounds checking.]],
        __doc_returns = [[address: the address of the Nth element]],
        schema = {
            index = { __doc = [[integer: the index of the element]], required = true }
        },
        code = function(self, args)
            local index = args.index
            assert(validators.isAddresslike(self.baseAddress), 'alce.mono.T.List.at(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
            assert(validators.isNonNegativeInteger(index), 'alce.mono.T.List.at(): invalid argument: index: ' .. tostring(index))
            assert(index < self:size(), 'alce.mono.T.List.at(): invalid argument: index is out of bounds')
            return self:atUnsafe({ index = index })
        end,
    }),

    iterator = member_fn({
        __doc = [[Returns an iterator which returns the value of the list item from start to end.]],
        __doc_returns = [[function: an iterator over the list]],
        schema = {
            first = { __doc = [[offset: starting index]] },
            last = { __doc = [[offset: ending index]] },
        },
        code = function(self, args)
            local first = args.first
            local last = args.last
            local i = first or 0
            local size = self:size()
            local e = last or size
            assert(validators.isOffsetlike(i), 'alce.mono.T.List.iterator(): invalid argument: first: ' .. tostring(first))
            assert(validators.isOffsetlike(e), 'alce.mono.T.List.iterator(): invalid argument: last: ' .. tostring(last))
            assert(e <= size, 'alce.mono.T.List.iterator(): invalid argument: last was out of bounds: ' .. tostring(last))

            local info = debug.getinfo(2, "Sl")
            return function()
                if i < e then
                    assert(i < self:size(), 'line ' .. tostring(info.currentline) .. ': alce.mono.T.List.iterator(): iterator went out of bounds during iteration... Size changed?')
                    i = i + 1
                    return i, self:atUnsafe({ index = i - 1 })
                end
            end
        end,
    }),

    instanceIterator = member_fn({
        __doc = [[Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses.]],
        __doc_returns = [[function: an iterator over object instances]],
        schema = {
            alceClass = { __doc = [[table: the alce class with an instance method]], required = true },
            first = { __doc = [[offset: starting index]] },
            last = { __doc = [[offset: ending index]] },
        },
        code = function(self, args)
            local alceClass = args.alceClass
            local first = args.first
            local last = args.last
            assert(alce.isCallable(alceClass.instance), 'alce.mono.T.List.instanceIterator(): invalid argument: alceClass must have an Instance method.')
            local iter = self:iterator({ first = first, last = last })
            return function()
                local i, r = iter()
                if r then return i, alceClass:instance(r)
                else return nil end
            end
        end,
    }),
}

return T
