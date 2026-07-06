-- See alce/src/memory.lua
-- See alce/src/vt.lua
-- T and Mono utilities have been moved to alce/src/t.lua and alce/src/mono.lua
-- See alce/src/memory.lua

-----------------------------
----/> CE type helpers ------
-----------------------------

-- The remaining functions in this file are for legacy support or specific cheat table hooks.
-- Mono-related porcelain like ClassTable and ObjectAlias have been moved to alce/src/mono.lua and alce/src/mono_plumbing.lua.

--- # helpers for common manipulations of the cheat table



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
