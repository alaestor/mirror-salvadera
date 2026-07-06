local fn = require("alce.src.fn").fn
local alce = require("alce.src.globals")
local validators = require("alce.src.validators")

function onMemRecPreExecute(memrec, newState)
    if memrec.Type == vtAutoAssembler then
        alce.debug('Trying to run script: ', memrec.Description)
        alce.THIS = memrec
    end
end

function onMemRecPostExecute(memrec, newState, succeeded)
    alce.THIS = nil
    alce.debug('Script ', memrec.Description, succeeded and ' succeeded' or ' failed')
    if memrec.Type == vtAutoAssembler then
        if succeeded then
            alce.LAST_SUCCESS = memrec
        else
            alce.LAST_FAILURE = memrec
        end
    end
    if alce.isCallable(alce.executionCallback) then
        alce.executionCallback(memrec, newState, succeeded)
        alce.executionCallback = nil
    end
end

local cheattable = {
    __doc = [[
    Hooks `onMemRecPreExecute` and `onMemRecPostExecute` in order to provide the following:

    - `alce.THIS`: The MemoryRecord of the the script currently executing. Only be valid during the time an enable/disable script is being run from the cheat table: it's invalid during syntax check and running via the 'execute' button.
    - `alce.LAST_SUCCESS`: The MemoryRecord of the last script to succeed execution. Only valid after a table script has successfully run. Doesn't count scripts run from the 'execute' button.
    - `alce.LAST_FAILURE`: The memoryRecord of the last script to fail execution. Only valid after a table script has failed to run. Doesn't count scripts run from the 'execute' button.
    ]];}

cheattable.disableAfterSuccess = fn({
    doc = [[
Makes disableWithoutExecute() be called on the next MemoryRecord script that runs successfully.
Can be used at the bottom of an [ENABLE] section to turn a script into a momentary button rather than toggle.
]],
    returns = "none",
    schema = {
        disableBeep = { type = "boolean", default = false }
    },
    code = function(self, args)
        alce.executionCallback = function(this, _, succeeded)
            if succeeded then
                this:disableWithoutExecute()
                if not args.disableBeep then beep() end
            end
        end
    end
})

cheattable.clearChildren = fn({
    doc = "destroy's all children of the given memoryRecord",
    returns = "none",
    positional = true,
    schema = {
        memoryRecord = { type = "any", required = true }
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
        desc = { type = "string", required = true },
        addressList = { type = "any", default = nil }
    },
    code = function(self, desc, addressList)
        local al = addressList or getAddressList()
        local parent = al.getMemoryRecordByDescription(desc)
        if parent then
            cheattable.clearChildren(parent)
        end
    end
})

cheattable.createRecord = fn({
    doc = [[
    Creates a new MemoryRecord and attaches it to `parent`. `address` may be an integer or a string. `offsets` may be an array of integer offsets from `address` such as `{ 0x10, ... }`. `saveToTable` may be a boolean; children created from this function aren't saved by default.

    `dropDownSettings` is a dict which if not nil must at minimum contain an either an `optionsFrom` string containing the description string from another dropdown MR, or an `options` string formatted as newline-separated pairs e.g. `"value:desc\n..."`. You may optionally provide `noManualInput` `hideNumbers`, and `dontDisplayAsString` booleans.

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
        parent = alce.THIS,
        description = 'mode',
        vtype = vtByte,
        address = baseaddr,
        offsets = {stateOffset, modeOffset},
        dropDownSettings = ddsettings
    })
    print('the address of mode is ' .. newmr.AddressString)
    ```
    ]],
    returns = "the newly created MemoryRecord",
    positional = false,
    schema = {
        parent = { type = "any", default = nil },
        description = { type = "string", default = nil },
        vtype = { type = "any", default = vtDword },
        address = {
            validate = function(v) return v == nil or validators.isAddresslike(v) or validators.isNonBlankString(v) end,
            default = nil
        },
        offsets = { validate = validators.isTable, default = nil },
        dropDownSettings = {
            validate = function(v)
                if v == nil then return true end
                return validators.isNonBlankString(v.options) or validators.isNonBlankString(v.optionsFrom)
            end,
            default = nil
        },
        saveToTable = { type = "boolean", default = false },
    },
    code = function(self, args)
        local mr = AddressList.createMemoryRecord()
        if validators.isNonBlankString(args.description) then
            mr.Description = args.description
        end
        mr.Type = args.vtype or vtDword
        mr.DontSave = args.saveToTable ~= true
        if validators.isAddresslike(args.address) then
            mr.Address = string.format("%X", args.address)
        elseif validators.isNonBlankString(args.address) then
            mr.Address = args.address
        end
        if args.offsets then
            mr.OffsetCount = #args.offsets
            for i, offset in ipairs(args.offsets) do
                mr.Offset[i - 1] = offset
            end
        end
        if args.dropDownSettings then
            if validators.isNonBlankString(args.dropDownSettings.options) then
                mr.DropDownList.Text = args.dropDownSettings.options
            elseif validators.isNonBlankString(args.dropDownSettings.optionsFrom) then
                mr.DropDownLinkedMemrec = args.dropDownSettings.optionsFrom
            end
            mr.DropDownDescriptionOnly = args.dropDownSettings.hideNumbers == true
            mr.DropDownReadOnly = args.dropDownSettings.noManualInput == true
            mr.DisplayAsDropDownListItem = args.dropDownSettings.dontDisplayAsString ~= true
        end
        mr.Options = '[moAllowManualCollapseAndExpand]'
        if args.parent then
            mr.appendToEntry(args.parent)
        end
        return mr
    end
})

cheattable.createHeader = fn({
    doc = "Creates a new Group Header MemoryRecord",
    returns = "the newly created MemoryRecord",
    positional = false,
    schema = {
        parent = { type = "any", default = nil },
        description = { type = "string", default = nil },
        showCollapseButtons = { type = "boolean", default = false },
        saveToTable = { type = "boolean", default = false },
    },
    code = function(self, args)
        local mr = AddressList.createMemoryRecord()
        if validators.isNonBlankString(args.description) then
            mr.Description = args.description
        end
        if args.parent then
            mr.appendToEntry(args.parent)
        end
        mr.DontSave = args.saveToTable ~= true
        mr.IsGroupHeader = true
        mr.Options = args.showCollapseButtons and '[moHideChildren,moAllowManualCollapseAndExpand,moManualExpandCollapse]' or '[moHideChildren,moAllowManualCollapseAndExpand]'
        return mr
    end
})

return cheattable
