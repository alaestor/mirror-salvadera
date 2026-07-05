local fn = require("alce.src.fn").fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local memory = {}

memory.AllocateSymbols_register = fn({
    doc = "Registers symbols defined in a context, optionally filtered by a list of names.",
    returns = "nil",
    schema = {
        context = { type = "table", required = true, validate = function(v) return validators.isNonEmptyTable(v) end },
        optional_names = { type = "table", default = nil, validate = function(v) return v == nil or validators.isNonEmptyTable(v) end }
    },
    code = function(self, args)
        local context = args.context
        local optional_names = args.optional_names
        local namesToRegister = optional_names or context.names

        for _, name in ipairs(namesToRegister) do
            assert(context.addresses[name], "alce.memory.AllocateSymbols.register(): invalid argument: invalid name: " .. tostring(name))
            if not context.registered[name] then
                local symbol = context.symbolNames[name]
                local address = context.addresses[name]
                registerSymbol(symbol, address, true)
                context.registered[name] = symbol
            end
        end
    end
})

memory.AllocateSymbols_unregister = fn({
    doc = "Unregisters symbols defined in a context, optionally filtered by a list of names.",
    returns = "nil",
    schema = {
        context = { type = "table", required = true, validate = function(v) return validators.isNonEmptyTable(v) end },
        optional_names = { type = "table", default = nil, validate = function(v) return v == nil or validators.isNonEmptyTable(v) end }
    },
    code = function(self, args)
        local context = args.context
        local optional_names = args.optional_names
        local namesToUnregister = {}

        if optional_names == nil then
            for name, _ in pairs(context.registered) do
                table.insert(namesToUnregister, name)
            end
        else
            namesToUnregister = optional_names
        end

        for _, name in ipairs(namesToUnregister) do
            assert(context.registered[name], "alce.memory.AllocateSymbols.unregister(): invalid argument: symbol not registered: " .. tostring(name))
            local symbol = context.registered[name]
            unregisterSymbol(symbol)
            context.registered[name] = nil
        end
    end
})

memory.AllocateSymbols = fn({
    doc = [[Allocates contiguous memory aliased by name calculated by type size and provides easy read/write access to them. Also lets you register/unregister the names as global symbols with an optional prefix.

> **Note:** the registered symbols will have all non-alphanumeric characters replaced with underscores. Symbols will be registered by default at creation unless you the optional parameter `doNotRegister` is true.

Exposes methods `register(optional_names)` and `unregister(optional_names)`. `optional_names` may be nil or an array of valid and unprefixed names. If nil, the functions perform the action for all symbols for all symbols not already registered/unregistered.

The object also exposes internal state through __ prefixed keys. You probably shouldn't write to these but I'm a line of documentation, not a cop.
- `__size` - the total size of the memory region in bytes.
- `__memory` - base address of the memory region.
- `__names` - array of names as they would be accessed for reading/writing.
- `__symbolPrefix` - the string to be prefixed to names when registering and unregistering symbols.
- `__symbolNames` - dict of names to (optionally-prefixed) symbol names as they would be globally registered.
- `__addresses` - dict of name keys to integer addresses in the memory region.
- `__types` - dict of name string keys to alce.vt.VTypeHelper objects.
- `__registered` - dict of names to registered symbolnames; presense in table means that the symbols are registered.

Example usage:
```lua
-- this is important, and it should be global to persist state.
region = region or MemoryRegion({
    alce.T[vtDword]('level'), -- or { type = vtDword, name = 'level' },
    alce.T[vtSingle]('health'),
  },{
    doNotRegister = true,
    symbolPrefix = 'PTR_'
})
[ENABLE]
-- write to aliased memory by using the unprefixed names
region.level = 99
region.health = 100.0
assert(region:register(), 'failed: already registered?') -- manually, since we set `doNotRegister`

-- access the registered CE symbols from anywhere
print(string.format('health is stored at address: 0x%X', PTR_health))

-- get type information from an internal table (VTypeHelper)
print('level is a ' .. region.__types['health'].name)

[DISABLE]
-- read from aliased memory
print('ending health: ', region.health)
region:unregister()
```]],
    returns = "table (proxy)",
    schema = {
        packets = { type = "table", required = true, validate = function(v) return validators.isNonEmptyTable(v) end },
        doNotRegister = { type = "boolean", default = false },
        symbolPrefix = { type = "string", default = "", validate = function(v) return validators.isNonBlankString(v) or v == "" end },
        baseAddress = { type = "address", default = nil, validate = function(v) return v == nil or validators.isAddresslike(v) end },
        protection = { type = "boolean", default = nil, validate = function(v) return v == nil or type(v) == "boolean" end },
    },
    code = function(self, args)
        local packets = args.packets
        local doNotRegister = args.doNotRegister
        local symbolPrefix = args.symbolPrefix
        local baseAddress = args.baseAddress

        local internal = {
            size = 0,
            memory = nil,
            names = {},
            symbolPrefix = symbolPrefix,
            symbolNames = {},
            addresses = {},
            types = {},
            registered = {},
        }

        for i, packet in ipairs(packets) do
            assert(validators.isNonEmptyTable(packet), 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] must be a table of {type=,value=}')
            local name = packet.value
            assert(validators.isNonBlankString(name), 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] name must be a non-blank string')
            table.insert(internal.names, name)
            local t = alce.T[packet.type]
            assert(t, 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] type must be a key compatible with alce.T (e.g. a CE vartype like `vtSingle`)')
            internal.types[name] = t
            internal.symbolNames[name] = alce.fmt.sanitizeSymbolName(internal.symbolPrefix .. name)
            internal.size = internal.size + t.size
        end

        internal.memory = allocateMemory(internal.size, baseAddress)
        assert(validators.isAddresslike(internal.memory), 'alce.memory.AllocateSymbols(): failed to allocate memory...')

        local cursor = internal.memory
        for _, name in ipairs(internal.names) do
            internal.addresses[name] = cursor
            cursor = cursor + internal.types[name].size
        end

        if not doNotRegister then memory.AllocateSymbols_register({ context = internal }) end

        local proxy = {}
        setmetatable(proxy, {
            __name = 'AllocateSymbolsProxy: ' .. alce.fmt.address(internal.memory),

            __pairs = function(_) error("alce.memory.AllocateSymbols.__pairs(): doesn't support iteration") end,

            __eq = function(a, b)
                local ameta = getmetatable(a)
                local bmeta = getmetatable(b)
                return ameta == bmeta and rawequal(ameta.__index, bmeta.__index)
            end,

            -- __index handles reads and internal access
            __index = function(tbl, key)
                if key:sub(1, 2) == "__" then return internal[key:sub(3)]
                elseif key == 'register' then return function(optional_self, ...) -- self is unnecessary: workaround to allow both `:` and `.` calling
                        if optional_self == tbl then return memory.AllocateSymbols_register({ context = internal, optional_names = ... })
                        else return memory.AllocateSymbols_register({ context = internal, optional_names = optional_self, ... }) end
                    end
                elseif key == 'unregister' then return function(optional_self, ...) -- self is unnecessary: workaround to allow both `:` and `.` calling
                        if optional_self == tbl then return memory.AllocateSymbols_unregister({ context = internal, optional_names = ... })
                        else return memory.AllocateSymbols_unregister({ context = internal, optional_names = optional_self, ... }) end
                    end
                else
                    local t = internal.types[key]
                    assert(t, "alce.memory.AllocateSymbols.__index(): couldn't find type for key: " .. tostring(key))
                    local a = internal.addresses[key]
                    assert(a, "alce.memory.AllocateSymbols.__index(): couldn't find address for key: " .. tostring(key))
                    return t:read(a)
                end
            end,

            -- __newindex handles writes
            __newindex = function(_, key, value)
                local t = internal.types[key]
                assert(t, "alce.memory.AllocateSymbols.__newindex(): couldn't find type for key: " .. tostring(key))
                local a = internal.addresses[key]
                assert(a, "alce.memory.AllocateSymbols.__newindex(): couldn't find address for key: " .. tostring(key))
                return t:write(a, value)
            end,
        })
        return proxy
    end
})

return memory
