-- See alce/src/memory.lua
-- See alce/src/vt.lua
-- T and Mono utilities have been moved to alce/src/t.lua and alce/src/mono.lua
-- See alce/src/memory.lua

-----------------------------
----/> CE type helpers ------
-----------------------------



---------------------------
-----< Mono Features ------
---------------------------
--- # Mono Features

alce.mono = {}

--- ## Plumbing


--- ## Porcelain

--- helpers for commonly used mscorlib/system type offsets
alce.mono.T = require("alce.src.mono_t")

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
