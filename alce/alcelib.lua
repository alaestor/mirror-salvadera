--[[
--------------------------------------------------------------------------------
Copyright (C) 2026 Alaestor Weissman

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------
--]]

-----------------------------
-----< CE helpers ------
-----------------------------
--- # CE Helpers

--- **NOTE:** `vtUnicodeString` is currently unsupported, and not included in any of the tables.

--- ## Plumbing

--[[{
    Collection related to global constants defined in CE's `monoscript.lua`

    Groups:
    - `monotype`
    - `fieldAttribute`
    - `methodAttribute`

    Each group's dict contains the string `prefix` of the global constants, an array of `names` and a `nameLookup` dict of names keyed by their value.

    **Note:** For each name string, you can get its value by `_G[name]`. For some monoTypes, `monoscript.lua` provides C-style type names via `monoTypeToCStringLookup[name]`
--}]]
alce.monoscript = {}

-- declare groups
for _,v in pairs({
    {name = 'monotype', prefix = 'MONO_TYPE_'},
    {name = 'fieldAttribute', prefix = 'FIELD_ATTRIBUTE_'},
    {name = 'methodAttribute', prefix = 'METHOD_ATTRIBUTE_'}
}) do
    alce.monoscript[v.name] = {}
    local t = alce.monoscript[v.name]
    t.prefix = v.prefix
    t.prefixLen = string.len(t.prefix)
    t.names = {}
    t.nameLookup = {}
end

-- map globals to groups
for k, v in pairs(_G) do
    if type(k) == 'string' then
        for _,group in pairs(alce.monoscript) do
            if k:sub(1,group.prefixLen) == group.prefix then
                table.insert(group.names, k)
                group.nameLookup[v] = k
            end
        end
    end
end

-- sort name arrays alphabetically
for _,group in pairs(alce.monoscript) do table.sort(group.names) end

--- a table of various CE type helpers. They can be useful on their own, but they mainly exist to be utilized by the user-friendly `alce.vt.VTypeHelper` instances in `alce.T`
alce.vt = {}

--- array of fundamental type strings (e.g. string `'byte'`, `'dword'`, `'pointer'`)
alce.vt.basicTypeStrings = {
    --'unicodeString',
    'byte',
    'word',
    'dword',
    'qword',
    'single',
    'double',
    'pointer',
}

--- array of CE type strings (e.g. string `'vtByte'`, `'vtDword'`, `'vtPointer'`)
alce.vt.typeStrings = {}
for _,v in ipairs(alce.vt.basicTypeStrings) do table.insert(alce.vt.typeStrings, 'vt' .. v:sub(1,1):upper() .. v:sub(2)) end

--- dict mapping CE's vt types and their respective sizes in bytes (accounts for 32/64bit processes; no support for 16bit addressing)
alce.vt.size = {
    --[vtUnicodeString] = 1,
    [vtByte]          = 1,
    [vtWord]          = 2,
    [vtDword]         = 4,
    [vtQword]         = 8,
    [vtSingle]        = 4,
    [vtDouble]        = 8,
    [vtString]        = targetIs64Bit() and 8 or 4,
    [vtPointer]       = targetIs64Bit() and 8 or 4,
}

--- dict mapping CE's vt types and their respective read functions (e.g. `[vdDword]` is `readInteger`)
alce.vt.read = {
    --[vtUnicodeString] = readString, --? should this be readBytes looking nullterm? just niling for now
    [vtByte]          = function(addr) return readBytes(addr, 1, false) end,
    [vtWord]          = readSmallInteger,
    [vtDword]         = readInteger,
    [vtQword]         = readQword,
    [vtSingle]        = readFloat,
    [vtDouble]        = readDouble,
    [vtString]        = readString,
    [vtPointer]       = readPointer,
}

--- mapping of CE's vt types and their respective write functions (e.g. `[vdDword]` is `writeInteger`)
alce.vt.write = {
    --[vtUnicodeString] = writeString, --? see read
    [vtByte]          = function(addr, val) return writeBytes(addr, {val & 0xFF}) end,
    [vtWord]          = writeSmallInteger,
    [vtDword]         = writeInteger,
    [vtQword]         = writeQword,
    [vtSingle]        = writeFloat,
    [vtDouble]        = writeDouble,
    [vtString]        = writeString,
    [vtPointer]       = function(addr, val) return (targetIs64Bit() and writeQword or writeInteger)(addr, val) end,
}

--- for working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.
alce.vt.VTypeHelper = {
    new = function(self, basicTypeString) --> a newly created VType
        assert(alce.isNonBlankString(basicTypeString), 'alce.T.VType(): invalid argument: typeString: ' .. tostring(typeString))
        local vts = 'vt' .. basicTypeString:sub(1,1):upper() .. basicTypeString:sub(2)
        local vt = _G[vts]
        assert(alce.isInteger(vt), 'alce.T.VType(): invalid argument: basicTypeString: no global variable named ' .. tostring(vts) )
        local instance = {
            name = basicTypeString,
            vtName = vts,
            vType = vt,
            size = alce.vt.size[vt],
            readUnsafe = alce.vt.read[vt],
            writeUnsafe = alce.vt.write[vt],
        }
        setmetatable(instance, { __index = self, __call = self.asInvokeArgument, __name ='VTypeHelper: ' .. basicTypeString })
        return instance
    end,

    getMonotypes = function(self) --> nil or array of integers
        return alce.keysFromValue(self.vType, monoTypeToVartypeLookup)
    end,

    getMonotypesAsStrings = function(self) --> nil or a sorted array of strings representing the monotypes: *(note: use `monoTypeToCStringLookup[]` if you want basic type strings; but not all are represented)*
        local keys = alce.keysFromValue(self.vType, monoTypeToVartypeLookup)
        local r = {}
        for _,v in ipairs(keys) do table.insert(r, alce.monoscript.monotype.nameLookup[v]) end
        table.sort(r)
        return next(r) and r or nil
    end,

    asInvokeArgument = function(self, value) --> dict formatted for invoking methods e.g. `{type=, value=}`
        return {type = self.vType, value = value}
    end,

    read = function(self, address) --> nil or the value
        assert(self.readUnsafe, 'alce.T.VType.read(): no read function for type ' .. self.name)
        assert(alce.isAddresslike(address), 'alce.T.VType.read(): invalid address')
        return self.readUnsafe(address)
    end,

    write = function(self, address, value) --> boolean: whether or not it succeeded
        assert(self.writeUnsafe, 'alce.T.VType.write(): no write function for type ' .. self.name)
        assert(alce.isAddresslike(address), 'alce.T.VType.write(): invalid address')
        return self.writeUnsafe(address, value)
    end,
}

--- ## Porcelain

--[[{
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
--}]]
alce.T = {}
for _,v in pairs(alce.vt.basicTypeStrings) do
    local t = alce.vt.VTypeHelper:new(v)
    for _,lookupKey in pairs({t.name, t.vtName, t.vType}) do
        assert(not alce.T[lookupKey], 'alce.T: key already exists: ' .. tostring(lookupKey))
        alce.T[lookupKey] = t
    end
end
-- find the max key
local alce_monotype_max_key = -math.huge
for k,_ in pairs(monoTypeToVartypeLookup) do if type(k) == 'number' and k > alce_monotype_max_key then alce_monotype_max_key = k end end

--- Equivalent to `alce.T[monoTypeToVarType(monoType)]` with warning message when it will fail and return the `vtDword` fallback.
-- T and Mono utilities have been moved to alce/src/t.lua and alce/src/mono.lua
-- TODO: Remove these once fully migrated and verified.

local function AllocateSymbols_register(context, optional_names)
    assert(optional_names == nil or type(optional_names) == 'table', 'alce.memory.AllocateSymbols.unregister(): invalid argument: optional_names must be an array of strings or nil.')
    local namesToRegister = optional_names or context.names
    for _, name in ipairs(namesToRegister) do
        assert(context.addresses[name], "alce.memory.AllocateSymbols.unregister(): invalid argument: invalid name: " .. tostring(name))
        if not context.registered[name] then
            local symbol = context.symbolNames[name]
            local address = context.addresses[name]
            registerSymbol(symbol, address, true)
            context.registered[name] = symbol
        end
    end
end

local function AllocateSymbols_unregister(context, optional_names)
    assert(optional_names == nil or type(optional_names) == 'table', 'alce.memory.AllocateSymbols.unregister(): invalid argument: optional_names must be an array of strings or nil.')
    local namesToUnregister = {}
    if optional_names == nil then for name, _ in pairs(context.registered) do table.insert(namesToUnregister, name) end
    else namesToUnregister = optional_names end
    for _, name in ipairs(namesToUnregister) do
        assert(context.registered[name], "alce.memory.AllocateSymbols.unregister(): invalid argument: symbol not registered: " .. tostring(name))
        local symbol = context.registered[name]
        unregisterSymbol(symbol)
        context.registered[name] = nil
    end
end

--[[{
    Allocates contiguous memory aliased by name calculated by type size and provides easy read/write access to them. Also lets you register/unregister the names as global symbols with an optional prefix.

    > **Note:** the registered symbols will have all non-alphanumeric characters replaced with underscores. Symbols will be registered by default at creation unless you the optional parameter `doNotRegister` is true.

    Optional parameters: `doNotRegister` boolean, `symbolPrefix` string, and `baseAddress` which would be forwarded to `allocateMemory`.

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
      },{ -- optionals
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
    ```
--}]]
function alce.AllocateSymbols(packets, optional) --> proxy object
    assert(alce.isNonEmptyTable(packets), 'alce.memory.AllocateSymbols(): invalid argument: packets must be a non-empty table')
    assert(optional == nil or alce.isNonEmptyTable(optional), 'alce.memory.AllocateSymbols(): invalid argument: optional must be nil or a non-empty table')
    assert(optional == nil or optional.symbolPrefix == nil or alce.isNonBlankString(optional.symbolPrefix), 'alce.memory.AllocateSymbols(): invalid argument: optional.symbolPrefix must be nil or a non-blank string')
    assert(optional == nil or optional.baseAddress == nil or alce.isAddresslike(optional.baseAddress), 'alce.memory.AllocateSymbols(): invalid argument: optional.baseAddress must be nil or addresslike')
    assert(optional == nil or optional.protection == nil or type(optional.protection) == 'boolean', 'alce.memory.AllocateSymbols(): invalid argument: optional.protection must be nil or a boolean value')
    local doNotReigster = optional and optional.doNotRegister == true or false
    local internal = {
        size = 0,
        memory = nil,
        names = {},
        symbolPrefix = optional and optional.symbolPrefix or '',
        symbolNames = {},
        addresses = {},
        types = {},
        registered = {},
    }
    for i, packet in ipairs(packets) do
        assert(alce.isNonEmptyTable(packet), 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] must be a table of {type=,value=}')
        local name = packet.value
        assert(alce.isNonBlankString(name), 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] name must be a non-blank string')
        table.insert(internal.names, name)
        local t = alce.T[packet.type]
        assert(t, 'alce.memory.AllocateSymbols(): invalid argument: packets[' .. tostring(i) .. '] type must be a key compatible with alce.T (e.g. a CE vartype like `vtSingle`)')
        internal.types[name] = t
        internal.symbolNames[name] = alce.fmt.sanitizeSymbolName(internal.symbolPrefix .. name)
        internal.size = internal.size + t.size
    end
    internal.memory = allocateMemory(internal.size, optional and optional.baseAddress or nil)
    assert(alce.isAddresslike(internal.memory), 'alce.memory.AllocateSymbols(): failed to allocate memory...')
    local cursor = internal.memory
    for _,name in ipairs(internal.names) do
        internal.addresses[name] = cursor
        cursor = cursor + internal.types[name].size
    end
    if not doNotReigster then AllocateSymbols_register(internal) end

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
                    if optional_self == tbl then return AllocateSymbols_register(internal, ...)
                    else return AllocateSymbols_register(internal, optional_self, ...) end
                end
            elseif key == 'unregister' then return function(optional_self, ...) -- self is unnecessary: workaround to allow both `:` and `.` calling
                    if optional_self == tbl then return AllocateSymbols_unregister(internal, ...)
                    else return AllocateSymbols_unregister(internal, optional_self, ...) end
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
-----------------------------
----/> CE type helpers ------
-----------------------------



---------------------------
-----< Mono Features ------
---------------------------
--- # Mono Features

alce.mono = {}

--- ## Plumbing

--[[{
    Dumbed-down mono_invoke_method with a bugfix for [cheat-engine issues 3350](https://github.com/cheat-engine/cheat-engine/issues/3350)

    `maybe_arguments` may be omitted if method takes none. `maybe_instance` may be omitted if method is static. `optional_` parameters simply help to avoid redundant calls if you already have them.
--}]]
-- Mono functions have been migrated to alce/src/mono.lua
-- TODO: Remove these once fully verified.


--- ## Porcelain

--- helpers for commonly used mscorlib/system type offsets
alce.mono.T = {}

--- a friendly alias for mscorlib System.Collections.Generic.List types
alce.mono.T.List = {

    indexFrom = 0x20,
    indexBy = 0x8,
    offset = {
        items = 0x10,
        size = 0x18
    },

    new = function(self, baseAddress, optional_indexFrom, optional_indexBy, optional_offsetItems, optional_offsetSize) --> the newly created T.list that aliases `address`
        assert(alce.isAddresslike(baseAddress), 'alce.mono.T.List.new(): invalid argument: baseAddress: ' .. tostring(baseAddress))
        assert((not optional_indexFrom) or alce.isOffsetlike(optional_indexFrom), 'alce.mono.T.List.new(): invalid argument: optional_indexFrom')
        assert((not optional_indexBy) or alce.isOffsetlike(optional_indexBy), 'alce.mono.T.List.new(): invalid argument: optional_indexBy')
        assert((not optional_offsetItems) or alce.isOffsetlike(optional_offsetItems), 'alce.mono.T.List.new(): invalid argument: optional_offsetItems')
        assert((not optional_offsetSize) or alce.isOffsetlike(optional_offsetSize), 'alce.mono.T.List.new(): invalid argument: optional_offsetSize')
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

    --- Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`
    newFromChain = function(self, ...) --> the newly created T.List
        return self:new(alce.readPointerChain(...))
    end,

    size = function(self) --> the number of items
        assert(alce.isAddresslike(self.baseAddress), 'alce.mono.T.List.size(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
        return readInteger(self.baseAddress + self.offset.size)
    end,

    atUnsafe = function(self,index) --> address of the Nth element at index (starting from zero)
        local itemBase = readPointer(self.baseAddress + self.offset.items)
        return readPointer(itemBase + self.indexFrom + (index * self.indexBy))
    end,

    at = function(self, index) --> address of the Nth element at index (starting from zero)
        assert(alce.isAddresslike(self.baseAddress), 'alce.mono.T.List.at(): invalid state: baseAddress: ' .. tostring(self.baseAddress))
        assert(alce.isNonNegativeInteger(index), 'alce.mono.T.List.at(): invalid argument: index: ' .. tostring(index))
        assert(index < self:size(), 'alce.mono.T.List.at(): invalid argument: index is out of bounds')
        return self:atUnsafe(index)
    end,

    --[[{
        Returns an iterator which returns the value of the list item from optional_start to optional_end.
        Arguments will default to, or must be within the range of: [0,size) respectively.
    --}]]
    iterator = function(self, optional_start, optional_end) --> function-->counter,address: counts from 1; equivalent index is count-1
        local i = optional_start or 0
        local size = self:size()
        local e = optional_end or size
        assert(alce.isOffsetlike(i), 'alce.mono.T.List.iterator(): invalid argument: optional_start: ' .. tostring(optional_start))
        assert(alce.isOffsetlike(e), 'alce.mono.T.List.iterator(): invalid argument: optional_end: ' .. tostring(optional_end))
        assert(e <= size, 'alce.mono.T.List.iterator(): invalid argument: optional_end was out of bounds: ' .. tostring(optional_end))
        local info = debug.getinfo(2, "Sl")
        return function()
            if i < e then
                assert(i < self:size(), 'line ' .. tostring(info.currentline) .. ': alce.mono.T.List.iterator(): iterator went out of bounds during iteration... Size changed?')
                i = i + 1
                return i,self:atUnsafe(i-1)
            end
        end
    end,

    --- Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses
    instanceIterator = function(self, alceClass, optional_start, optional_end) --> function-->count,ObjectAlias
        assert(alce.isCallable(alceClass.instance), 'alce.mono.T.List.instanceIterator(): invalid argument: alceClass must have an Instance method.')
        local iter = self:iterator(optional_start, optional_end)
        return function()
            local i,r = iter()
            if r then return i,alceClass:instance(r)
            else return nil end
        end
    end
}

--- Helper that asserts the process is attached and tries to launch the mono data collector if it's not connected already.
function alce.mono.init()
    assert(alce.isAttached(), 'alce.mono.init(): not attached to process')
    if (monopipe == nil) then assert(LaunchMonoDataCollector(), 'alce.mono.init(): LaunchMonoDataCollector() failed.') end
end

--- A representation of, and call-abstraction for, mono methods.
alce.mono.Method = {
    init = function(self, methodID, name, flags) --> self
        assert(alce.isPositiveInteger(methodID), 'alce.mono.Method.init(): invalid methodID')
        self.id = methodID
        self.flags = flags or mono_method_getFlags(methodID)
        for k,v in pairs(mono_method_get_parameters(methodID)) do self[k] = v end
        self.signature = alce.mono.method_getSignature(methodID, name)
        self.name = name
        return self
    end,

    new = function(self, methodID, name, flags) --> the newly created Method
        local instance = {}
        setmetatable(instance, { __index = self, __call = self.call })
        if methodID then instance:init(methodID, name, flags) end
        return instance
    end,

    isStatic = function(self) --> boolean
        return alce.hasFlag(METHOD_ATTRIBUTE_STATIC, self.flags)
    end,

    getAttributes = function(self) --> array of strings: the names of global `monoscript.lua` constants representing the various method attributes
        local t = {}
        for _,flagName in pairs(alce.monoscript.methodAttribute.names) do if alce.hasFlag(_G[flagName], self.flags) then table.insert(t, flagName) end end
        return t
    end,

    compile = function(self) --> address
        if not self.address then
            assert(alce.isPositiveInteger(self.id), 'alce.mono.Method.compile(): malformed method; not initialized?')
            local r=mono_compile_method(self.id)
            assert(alce.isAddresslike(r), 'alce.mono.Method.compile(): failed to compile method; returned: ' .. alce.fmt.address(self.address))
            self.address = r
        end
        return self.address
    end,

    --[[{
        Invokes the method. The method must already be compiled. `maybe_instance` can be nil if the method is static. `maybe_args` can be nil if the method takes no arguments. Arguments must be supplied in CE's invoke format: `{ {type=vt,value=v}, ... }`
    --}]]
    callUnsafe = function(self, maybe_instance, maybe_args) --> the results of `alce.mono.invoke`: value of type `self.returntype`, error, `vtype`
        if alce.cfg.debug_print then alce.debug(string.format("alce.mono.Method.callUnsafe(): attempting to invoke call '%s' on instance %s with...\n%s", self.signature.full, alce.fmt.address(maybe_instance), alce.fmt.table({wants=self.parameters, giving=maybe_args or 'Nothing'}))) end
        return alce.mono.invoke(self.id, maybe_instance, maybe_args, self.parameters, self.flags)
    end,

    --[[{
        Invokes the method after safety checks and argument processing. `maybe_instance` can be nil if the method is static. `maybe_args` can be nil if the method takes no arguments.

        Arguments may be provided positionally in the form of either an arbitrary value or as a pair table matching CE's argumment format: `{type=vt,value=v}`. The types of raw value arguments are guessed from the method's corresponding parameter type.

        > **Caution:** doesn't type-check the provided arguments; it only deduces types from the method's parameters.

        Example usage:
        ```lua
        local e = FlagEnumValues.const -- an alce.Class
        local t = alce.T[vtDword] -- so we dont need to type `{type=vtDword,value=...}`
        local SetPlayerFlag = alce.mono.Method( ... ) -- void Player:SetPlayerFlag(enum,bool)
        SetPlayerFlag:call(player_ptr, t(e.hasGodmode), true)
        SetPlayerFlag:call(player_ptr, t(e.isCheating), false)
        ```
    --}]]
    call = function(self, maybe_instance, ...) --> self.returntype, error, vtype
        assert(self.id and self.parameters, 'alce.mono.Method.call(): malformed method; not initialized?')
        local raw_args = {...}
        local pcount = #raw_args
        assert(pcount == #(self.parameters), 'alce.mono.Method.call(): called with the wrong number of parameters')
        assert(self:isStatic() or alce.isAddresslike(maybe_instance), 'alce.mono.Method.call(): non-static method was called without an instance')
        self:compile()
        local args = {}
        for i=1, pcount do
            local arg = raw_args[i]
            assert(arg ~= nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was nil... Did you mean `0` or `false`?')
            if type(arg) == 'table' then
                assert(arg.type and alce.T[arg.type] and arg.value~=nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was a malformed table; tables must be {type=,value=}')
                args[i] = arg
            else
                -- best-effort: the user can pass the type explicitly if we get it wrong
                args[i] = alce.T.fromMono(self.parameters[i].type)(arg)
            end
        end

        local result, exception, vtype = self:callUnsafe(maybe_instance, args)
        assert(not exception, 'alce.mono.Method.call(): exception: ' .. tostring(exception))
        return result
    end,
}

--[[{
    a representation of a mono class type which will fetch, sort, and process its methods and fields into appropriate subtables.

    > TODO: might be worth-while to limit parent fetching to stop at `UnityEngine` stuff just to cut down on junk... Ain't nobody using `m_CancellationTokenSource`
--}]]
alce.mono.Class = {
    new = function(self, assemblyNameOrImage, className, optional_namespace, optional_getParents) --> the newly created Class
        alce.debug('alce.mono.Class.new(): attempting to get "', className, optional_getParents and '" with parents' or '"')
        assert(alce.isNonBlankString(className), 'alce.mono.Class.new(): invalid argument: className is nil')
        assert(alce.isPositiveInteger(assemblyNameOrImage) or alce.isNonBlankString(assemblyNameOrImage), 'alce.mono.Class.new(): invalid argument: assemblyNameOrImage: ' .. tostring(assemblyNameOrImage))
        assert(optional_namespace == nil or type(optional_namespace) == 'string', 'alce.mono.Class.new(): invalid argument: optional_namespace: ' .. tostring(optional_namespace))
        local id = alce.mono.getClass(assemblyNameOrImage, className, optional_namespace)
        if not alce.isAddresslike(id) then
            alce.warn('alce.mono.Class.new(): failed to find class: ' .. tostring(className))
            return nil
        end
        local hierarchy = alce.mono.class_getParentHierarchy(id)
        local methods = alce.mono.getProcessedMethods(id, optional_getParents, hierarchy, true)
        if not methods then
            alce.warn('alce.mono.Class.new(): failed to get fields: ' .. tostring(className))
            return nil
        end
        local fields = alce.mono.getProcessedFields(id, optional_getParents, hierarchy, true)
        if not fields then
            alce.warn('alce.mono.Class.new(): failed to get fields: ' .. tostring(className))
            return nil
        end
        local instance = {
            id = id,
            namespace = optional_namespace,
            name = className,
            method = methods,
        }
        for k,v in pairs(fields) do instance[k] = v end
        setmetatable(instance, { __index = self })
        return instance
    end,

    instance = function(self, baseAddress) --> ObjectAlias: a factory that returns a frieldy ergonomic wrapper around an instance of this monoclass
        return alce.mono.ObjectAlias(self, baseAddress)
    end,

    --- convenient shorthand for self:instance(alce.safeChain(...))
    instanceFrom = function(self, ...) --> ObjectAlias
        return self:instance(alce.safeChain(...))
    end,
}

local function aliasRead(context, key)
    local class = context.type
    local offset = class.offset[key]
    if offset then
        assert(alce.isNonEmptyTable(class.meta), 'alce.mono.ObjectAlias(): error in aliasRead: metadata table for "' .. tostring(class.name) .. '" was invalid; not populated?')
        local meta = class.meta.offset[key]
        assert(meta, 'alce.mono.ObjectAlias(): error in aliasRead: failed to find metadata for offset ' .. tostring(key))
        local t = alce.T.fromMono(meta.monotype)
        return t:read(context.baseAddress + offset)
    end
    local const = class.const[key]
    if const then return const end
    local static = class.static[key]
    if static and alce.isAddresslike(a) then readPointer(a) end
    assert(false, 'alce.mono.ObjectAlias(): error in aliasRead: failed to find datamember ' .. tostring(key))
end

local function aliasWrite(context, key, value)
    local class = context.type
    local offset = class.offset[key]
    if offset then
        assert(alce.isNonEmptyTable(class.meta), 'alce.mono.ObjectAlias(): error in aliasWrite: metadata table for "' .. tostring(class.name) .. '" was invalid; not populated?')
        local meta = class.meta.offset[key]
        assert(meta, 'alce.mono.ObjectAlias(): error in aliasWrite: failed to find metadata for offset ' .. tostring(key))
        local t = alce.T.fromMono(meta.monotype)
        return t:write(context.baseAddress + offset, value)
    end
    assert(not class.const[key], "alce.mono.ObjectAlias(): error in aliasWrite: can't write to constant value: " .. tostring(key))
    assert(not class.static[key], "alce.mono.ObjectAlias(): error in aliasWrite: shouldn't write to static member: " .. tostring(key) .. ". Did you really intend to? You can try doing it manually.")
    assert(false, 'alce.mono.ObjectAlias(): error in aliasWrite: failed to find datamember ' .. tostring(key))
end

--[[{
    ObjectAlias is an ergonomic wrapper around a monoclass object instance that lets you
    call methods or read and write from member variables in a natural way.

    ```lua
    local obj = ObjectAlias(theClassType, addrOfClassInstance)
    print(obj.x) -- read from datafield 'x'
    obj.x = 3 -- write to datafield 'x'
    assert(obj['x'] == 3) -- read from datafield 'x' again
    obj.SimpleMethod('my string') -- invoke a non-static method and provide it a string
    obj['OverloadedMethod(single)'](3.1415) -- invoke an overloaded non-static method and provide it a float value
    ```

    The datatypes used during read, write, call operations are interpretted from the metadata
    stored in the alce.mono.Class object. alce.mono.Class is a representation of the mono class
    type, while the alce.mono.ObjectAlias can represent an instance of said type.

    alce.mono.Class provides an ObjectAlias factory which can be called like: `obj = myAlceClassTable.Player:Instance(addr)`
--}]]
function alce.mono.ObjectAlias(alceClass, baseAddress) --> proxy object
    assert(alce.isAddresslike(baseAddress), 'alce.mono.ObjectAlias(): invalid argument: baseAddress: ' .. tostring(baseAddress))
    local internal = {
        baseAddress = baseAddress,
        type = alceClass,
    }
    local proxy = {} -- empty forever; everything happens in the closure and metatable
    setmetatable(proxy, {
        __tostring = function() return string.format("%s@%s", alceClass.name, alce.fmt.address(internal.baseAddress)) end,
        __pairs = function(_) error("alce.mono.ObjectAlias.__pairs(): Aliases don't support iteration; not sure what behavior was expected. Perhaps you want the alce.mono.Class; try `.__type`?") end,

        __eq = function(a, b)
            local ameta = getmetatable(a)
            local bmeta = getmetatable(b)
            return ameta == bmeta and rawequal(ameta.__index, bmeta.__index) and a.__baseAddress == b.__baseAddress
        end,

        -- __index handles all the regular `obj.thing` / `obj[thing]` accesses if the key isnt found
        __index = function(tbl, key)
            if not alce.isNonBlankString(key) then
                alce.warn('alce.mono.ObjectAlias.__index(): invalid argument: key should be the name of a data-member or method. Got: ' .. tostring(key))
                return nil
            end
            local m = internal.type.method[key]
            if m then
                return function(optional_self, ...) -- self is unnecessary: workaround to allow both `:` and `.` calling
                    if optional_self == tbl then return m:call(internal.baseAddress, ...)
                    else return m:call(internal.baseAddress, optional_self, ...) end
                end
            elseif key:sub(1, 2) == "__" then return internal[key:sub(3)]
            else return aliasRead(internal, key) end
        end,

        -- __newindex handles all the assignments to new keys e.g. `obj.x = 3` (always triggers because `proxy` is empty)
        __newindex = function (_, key, value) return aliasWrite(internal, key, value) end
    })
    return proxy
end

--- a table that loads and holds the mono clases you specify, associated by name, in the form of `alce.mono.Class`
alce.mono.ClassTable = {
    new = function(self, optional_keyPrefixAssembly, optional_keyPrefixNamespace) --> the newly created ClassTable
        local instance = { _internal = {
            targetList = {},
            isLoaded = false,
            keyPrefixAssembly = optional_keyPrefixAssembly,
            keyPrefixNamespace = optional_keyPrefixNamespace,
        } }
        setmetatable(instance, { __index = self })
        return instance
    end,

    --- accepts explicit `add({ {image, class[, namespace]}, ... })`
    add = function(self, ...) --> self
        assert(not self._internal.isLoaded, 'alce.mono.ClassTable.add(): cannot add while table is loaded. Try calling unload() first?')
        local entries = {...}
        alce.debug('alce.mono.ClassTable.add(): added targets: ' .. alce.fmt.table(entries))
        for _, entry in ipairs(entries) do table.insert(self._internal.targetList, entry) end
        return self
    end,

    --- convenience abstraction: `addFromImage(image, (class | {class, namespace}), ...)`
    addFromImage = function(self, image, ...) --> self
        assert(not self._internal.isLoaded, 'alce.mono.ClassTable.add(): cannot add while table is loaded. Try calling unload() first?')
        local args = {...}
        for _, item in ipairs(args) do
            if type(item) == 'table' then table.insert(self._internal.targetList, {image, item[1], item[2]})
            else table.insert(self._internal.targetList, {image, item, nil})
            end
        end
        return self
    end,

    isLoaded = function(self) --> boolean
        return self._internal.isLoaded == true
    end,

    load = function(self, optional_getParents) --> self
        alce.debug('alce.mono.ClassTable.load(): called.')
        assert(not self:isLoaded(), 'alce.mono.ClassTable.load(): already loaded. Forget to call :unload()?')
        self._internal.isLoaded = true
        local assemblies = mono_enumAssemblies()
        local images = {}
        local r = {}
        for _,target in ipairs(self._internal.targetList) do
            local assemblyNameOrImage, className, namespace = unpack(target)
            local assemblyName = type(assemblyNameOrImage) == 'string' and assemblyNameOrImage or mono_image_get_name(assemblyNameOrImage)
            if not assemblies[assemblyName] then
                assemblies[assemblyName] = alce.mono.getImage(assemblyName, assemblies)
            end
            local c = alce.mono.Class:new(assemblies[assemblyName], className, namespace, optional_getParents)
            if c then
                local keyPrefixA = self._internal.keyPrefixAssembly and assemblyName .. '.' or ''
                local keyPrefixB = self._internal.keyPrefixNamespace and c.namespace .. '.' or ''
                local key = keyPrefixA .. keyPrefixB .. className
                if r[key] then alce.warn('alce.mono.ClassTable.load(): Overwriting duplicate key: "' .. key .. '" (try enabling assembly or namespace prefixing?)') end
                r[key] = c
            end
        end
        for k,v in pairs(r) do self[k] = v end
        return self
    end,

    loadWithParents = function(self) return self:load(true) end,

    unload = function(self) --> self
        alce.debug('alce.mono.ClassTable.unload(): called.')
        if not self:isLoaded() then alce.warn('alce.mono.ClassTable.unload() called but nothing was loaded?... Doing it anyways.') end
        local internal = self._internal
        local count = #self
        for i=0, count do self[i]=nil end
        self._internal = internal
        self._internal.isLoaded = false
        return self
    end,

    clear = function(self) --> self
        alce.debug('alce.mono.ClassTable.clear(): called.')
        if self:isLoaded() then self:unload() end
        self._internal.targetList = {}
        return self
    end,
}
---------------------------
----/> Mono Features ------
---------------------------



--------------------------------
-----< Cheat Table Features ----
---------------------------------
--- # helpers for common manipulations of the cheat table

function onMemRecPreExecute(memrec, newState)
    if memrec.Type == vtAutoAssembler then
        alce.debug('Trying to run script: ', memrec.Description)
        --- The MemoryRecord of the the script currently executing. Only be valid during the time an enable/disable script is being run from the cheat table: it's invalid during syntax check and running via the 'execute' button .
        alce.THIS = memrec
    end
end

function onMemRecPostExecute(memrec, newState, succeeded)
    alce.THIS = nil
    alce.debug('Script ', memrec.Description, succeeded and ' succeeded' or ' failed')
    if memrec.Type == vtAutoAssembler then
        if succeeded then
            --- The MemoryRecord of the last script to succeed execution. Only valid after a table script has successfully run. Doesn't count scripts run from the 'execute' button.
            alce.LAST_SUCCESS = memrec
        else
            --- The memoryRecord of the last script to fail execution. Only valid after a table script has failed to run. Doesn't count scripts run from the 'execute' button.
            alce.LAST_FAILURE = memrec
        end
    end
    if alce.isCallable(alce.executionCallback) then
        alce.executionCallback(memrec, newState, succeeded)
        alce.executionCallback = nil
    end
end

alce.cheattable = {}

--- Makes disableWithoutExecute() be called on the next MemoryRecord script that runs successfully. Can be used at the bottom of an [ENABLE] section to turn a script into a momentary button rather than toggle.
function alce.cheattable.disableAfterSuccess(optional_disableBeep)
    alce.executionCallback = function(this,_,succeeded)
        if succeeded then
            this:disableWithoutExecute()
            if not optional_disableBeep then beep() end
        end
    end
end

--- `destroy()`'s  all children of the given memoryRecord
function alce.cheattable.clearChildren(memoryRecord)
  local count = memoryRecord.Count
  for i = count-1, 0, -1 do memoryRecord.Child[i].destroy() end
end

--- finds the MR by description then calls `alce.cheattable.clearChildren`
function alce.cheattable.clearChildrenByDesc(desc, optional_addressList)
    local al = optional_addressList or getAddressList()
    local parent = al.getMemoryRecordByDescription(desc)
    if parent then alce.cheattable.clearChildren(parent) end
end

--[[{
    Creates a new MemoryRecord and attaches it to `parent`. `optional_address` may be an integer or a string. `optional_offsets` may be an array of integer offsets from `address` such as `{ 0x10, ... }`. `optional_saveToTable` may be a boolean; children created from this function aren't saved by default.

    `optional_dropDownSettings` is a dict which if not nil must at minimum contain an either an `optionsFrom` string containing the description string from another dropdown MR, or an `options` string formatted as newline-separated pairs e.g. `"value:desc\n..."`. You may optionally provide `noManualInput` `hideNumbers`, and `dontDisplayAsString` booleans.

    Example usage, creating a pointer+offsets MR with a dropdown menu:
    ```lua
    local ddsettings = {
        options = '0:disabled\n1:normal\n2:overclocked',
        --optionsFrom = "some other MR description", -- if we already set one up and didn't want to duplicate...
        noManualInput = true,
        hideNumbers = true,
        --dontDisplayAsString = false -- displays MR value as dropdown string by default
    }
    local newmr = alce.cheattable.createChild(alce.THIS, 'mode', vtByte, baseaddr, {stateOffset, modeOffset}, false, ddsettings)
    print('the address of mode is ' .. newmr.AddressString)
    ```
--}]]
function alce.cheattable.createRecord(optional_parent, optional_description, optional_vtype, optional_address, optional_offsets, optional_dropDownSettings, optional_saveToTable) --> the newly created MemoryRecord
    local mr = AddressList.createMemoryRecord()
    if alce.isNonBlankString(optional_description) then mr.Description = optional_description end
    mr.Type = optional_vtype or vtDword
    mr.DontSave = optional_saveToTable ~= true
    if alce.isAddresslike(optional_address) then mr.Address = string.format("%X", optional_address)
    elseif alce.isNonBlankString(optional_address) then mr.Address = optional_address
    else assert(optional_address == nil, 'alce.cheattable.createChild(): invalid argument: optional_address must be nil, a valid address integer, or a non-blank string') end
    if optional_offsets then
        assert(type(optional_offsets) == 'table', 'alce.cheattable.createChild(): invalid argument:  optional_offsets must be an array or `nil`')
        mr.OffsetCount = #optional_offsets
        for i,offset in ipairs(optional_offsets) do mr.Offset[i - 1] = offset end
    end
    if optional_dropDownSettings then
        assert(type(optional_dropDownSettings) == 'table', 'alce.cheattable.createChild(): invalid argument: optional_dropDownSettings must be a dict or `nil`')
        if alce.isNonBlankString(optional_dropDownSettings.options) then mr.DropDownList.Text = optional_dropDownSettings.options
        elseif alce.isNonBlankString(optional_dropDownSettings.optionsFrom) then mr.DropDownLinkedMemrec = optional_dropDownSettings.optionsFrom
        else assert(false, 'alce.cheattable.createChild(): invalid argument: dropDown table requires either `options` or `optionsFrom` be a non-blank string') end
        mr.DropDownDescriptionOnly = optional_dropDownSettings.hideNumbers == true
        mr.DropDownReadOnly = optional_dropDownSettings.noManualInput == true
        mr.DisplayAsDropDownListItem = optional_dropDownSettings.dontDisplayAsString ~= true
    end
    mr.Options='[moAllowManualCollapseAndExpand]'
    if optional_parent then mr.appendToEntry(optional_parent) end
    return mr
end

function alce.cheattable.createHeader(optional_parent, optional_description, optional_showCollapseButtons, optional_saveToTable) --> the newly created MemoryRecord
    local mr = AddressList.createMemoryRecord()
    if alce.isNonBlankString(optional_description) then mr.Description = optional_description end
    if optional_parent then mr.appendToEntry(optional_parent) end
    mr.DontSave = optional_saveToTable ~= true
    mr.IsGroupHeader = true
    mr.Options= optional_showCollapseButtons and '[moHideChildren,moAllowManualCollapseAndExpand,moManualExpandCollapse]' or '[moHideChildren,moAllowManualCollapseAndExpand]'
    return mr
end
----------------------------------
----/> Cheat Table Features ------
----------------------------------
