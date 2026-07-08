local fn = require("./fn").fn
local member_fn = require("./fn").member_fn
local validators = require("./validators")
local alce = require("./globals")

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
        parameters = {
            baseAddress = {
                __doc = [[address: the base address]],
                required = true,
                validate = function(v) return validators.isAddresslike(v) end
            },
            indexFrom = {
                __doc = [[offset: starting index]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
            indexBy = {
                __doc = [[offset: index increment]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
            offsetItems = {
                __doc = [[offset: offset to items]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
            offsetSize = {
                __doc = [[offset: offset to size]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
        },
        code = function(self, args)
            local instance = {
                baseAddress = args.baseAddress,
                indexFrom = args.indexFrom or self.indexFrom,
                indexBy = args.indexBy or self.indexBy,
                offset = {
                    items = args.offsetItems or self.offset.items,
                    size = args.offsetSize or self.offset.size
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
        parameters = {
            index = {
                __doc = [[integer: the index of the element]],
                required = true
            }
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
        parameters = {
            index = {
                __doc = [[integer: the index of the element]],
                required = true,
                validate = function(v) return validators.isNonNegativeInteger(v) end
            }
        },
        code = function(self, args)
            local index = args.index
            assert(validators.isAddresslike(self.baseAddress), 'alce.mono.T.List.at(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
            assert(index < self:size(), 'alce.mono.T.List.at(): invalid argument: index is out of bounds')
            return self:atUnsafe({ index = index })
        end,
    }),

    iterator = member_fn({
        __doc = [[Returns an iterator which returns the value of the list item from first to end.]],
        __doc_returns = [[function: an iterator over the list]],
        parameters = {
            first = {
                __doc = [[offset: starting index]],
                default = 0,
                validate = function(v) return validators.isOffsetlike(v) end
            },
            last = {
                __doc = [[offset: ending index]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
        },
        code = function(self, args)
            local i = args.first
            local size = self:size()
            local last = args.last
            local e = last or size
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
        parameters = {
            alceClass = {
                __doc = [[table: the alce class with an instance method]],
                required = true,
                validate = function(v) return alce.isCallable(v.instance) end
            },
            first = {
                __doc = [[offset: starting index]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
            last = {
                __doc = [[offset: ending index]],
                validate = function(v) return validators.isOffsetlike(v) end
            },
        },
        code = function(self, args)
            local alceClass = args.alceClass
            local iter = self:iterator({ first = args.start, last = args.last })
            return function()
                local i, r = iter()
                if r then return i, alceClass:instance(r)
                else return nil end
            end
        end,
    }),
}

return T
