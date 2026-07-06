local fn = require("alce.src.fn").fn
local alce = require("alce.src.globals")
local validators = require("alce.src.validators")

--- Global hooks used by Cheat Engine.
-- These are kept as global functions so that the CE environment can find and execute them.

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

local cheattable = {}

cheattable.disableAfterSuccess = fn({
    doc = [[
Makes disableWithoutExecute() be called on the next MemoryRecord script that runs successfully.
Can be used at the bottom of an [ENABLE] section to turn a script into a momentary button rather than toggle.
]],
    returns = "none",
    schema = {
        optional_disableBeep = { type = "boolean", default = false }
    },
    code = function(self, args)
        alce.executionCallback = function(this, _, succeeded)
            if succeeded then
                this:disableWithoutExecute()
                if not args.optional_disableBeep then beep() end
            end
        end
    end
})

cheattable.clearChildren = fn({
    doc = "destroy's all children of the given memoryRecord",
    returns = "none",
    positional = true,
    schema = {
        memoryRecord = { type = "any" }
    },
    code = function(self, memoryRecord)
        local count = memoryRecord.Count
        for i = count - 1, 0, -1 do
            memoryRecord.Child[i].destroy()
        end
    end
})

cheattable.clearChildrenByDesc = fn({
    doc = "finds the MR by description then calls alce.cheattable.clearChildren",
    returns = "none",
    positional = true,
    schema = {
        desc = { type = "string" },
        optional_addressList = { type = "any", default = nil }
    },
    code = function(self, desc, optional_addressList)
        local al = optional_addressList or getAddressList()
        local parent = al.getMemoryRecordByDescription(desc)
        if parent then
            cheattable.clearChildren(parent)
        end
    end
})

cheattable.createRecord = fn({
    doc = [[
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
local newmr = alce.cheattable.createRecord({
    optional_parent = alce.THIS,
    optional_description = 'mode',
    optional_vtype = vtByte,
    optional_address = baseaddr,
    optional_offsets = {stateOffset, modeOffset},
    optional_dropDownSettings = ddsettings
})
print('the address of mode is ' .. newmr.AddressString)
```
]],
    returns = "the newly created MemoryRecord",
    positional = false,
    schema = {
        optional_parent = { type = "any", default = nil },
        optional_description = { type = "string", default = nil },
        optional_vtype = { type = "any", default = vtDword },
        optional_address = { type = "any", default = nil },
        optional_offsets = { type = "table", default = nil },
        optional_dropDownSettings = { type = "table", default = nil },
        optional_saveToTable = { type = "boolean", default = false },
    },
    code = function(self, args)
        local mr = AddressList.createMemoryRecord()
        if validators.isNonBlankString(args.optional_description) then
            mr.Description = args.optional_description
        end
        mr.Type = args.optional_vtype or vtDword
        mr.DontSave = args.optional_saveToTable ~= true
        if validators.isAddresslike(args.optional_address) then
            mr.Address = string.format("%X", args.optional_address)
        elseif validators.isNonBlankString(args.optional_address) then
            mr.Address = args.optional_address
        else
            assert(args.optional_address == nil, 'alce.cheattable.createRecord(): invalid argument: optional_address must be nil, a valid address integer, or a non-blank string')
        end
        if args.optional_offsets then
            assert(type(args.optional_offsets) == 'table', 'alce.cheattable.createRecord(): invalid argument: optional_offsets must be an array or `nil`')
            mr.OffsetCount = #args.optional_offsets
            for i, offset in ipairs(args.optional_offsets) do
                mr.Offset[i - 1] = offset
            end
        end
        if args.optional_dropDownSettings then
            assert(type(args.optional_dropDownSettings) == 'table', 'alce.cheattable.createRecord(): invalid argument: optional_dropDownSettings must be a dict or `nil`')
            if validators.isNonBlankString(args.optional_dropDownSettings.options) then
                mr.DropDownList.Text = args.optional_dropDownSettings.options
            elseif validators.isNonBlankString(args.optional_dropDownSettings.optionsFrom) then
                mr.DropDownLinkedMemrec = args.optional_dropDownSettings.optionsFrom
            else
                assert(false, 'alce.cheattable.createRecord(): invalid argument: dropDown table requires either `options` or `optionsFrom` be a non-blank string')
            end
            mr.DropDownDescriptionOnly = args.optional_dropDownSettings.hideNumbers == true
            mr.DropDownReadOnly = args.optional_dropDownSettings.noManualInput == true
            mr.DisplayAsDropDownListItem = args.optional_dropDownSettings.dontDisplayAsString ~= true
        end
        mr.Options = '[moAllowManualCollapseAndExpand]'
        if args.optional_parent then
            mr.appendToEntry(args.optional_parent)
        end
        return mr
    end
})

cheattable.createHeader = fn({
    doc = "Creates a new Group Header MemoryRecord",
    returns = "the newly created MemoryRecord",
    positional = false,
    schema = {
        optional_parent = { type = "any", default = nil },
        optional_description = { type = "string", default = nil },
        optional_showCollapseButtons = { type = "boolean", default = false },
        optional_saveToTable = { type = "boolean", default = false },
    },
    code = function(self, args)
        local mr = AddressList.createMemoryRecord()
        if validators.isNonBlankString(args.optional_description) then
            mr.Description = args.optional_description
        end
        if args.optional_parent then
            mr.appendToEntry(args.optional_parent)
        end
        mr.DontSave = args.optional_saveToTable ~= true
        mr.IsGroupHeader = true
        mr.Options = args.optional_showCollapseButtons and '[moHideChildren,moAllowManualCollapseAndExpand,moManualExpandCollapse]' or '[moHideChildren,moAllowManualCollapseAndExpand]'
        return mr
    end
})

return cheattable
