local fn = require("alce.src.fn").fn
local member_fn = require("alce.src.fn").member_fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local vt = {
    __doc = [[
a table of various CE type helpers. They can be useful on their own, but they mainly exist to be utilized by the user-friendly `alce.vt.VTypeHelper` instances in `alce.T`

- `vt.typeStrings`: array of CE type strings (e.g. string 'vtByte', 'vtDword', 'vtPointer')
- `vt.size`: dict mapping CE's vt types and their respective sizes in bytes (accounts for 32/64bit processes; no support for 16bit addressing)
- `vt.read`: dict mapping CE's vt types and their respective read functions (e.g. [vdDword] is readInteger)
- `vt.write`: mapping of CE's vt types and their respective write functions (e.g. [vdDword] is writeInteger)
    ]],

    basicTypeStrings = {
        'byte',
        'word',
        'dword',
        'qword',
        'single',
        'double',
        'pointer',
    },
}

vt.typeStrings = {}
for _,v in ipairs(vt.basicTypeStrings) do table.insert(vt.typeStrings, 'vt' .. v:sub(1,1):upper() .. v:sub(2)) end

vt.size = {
    [vtByte]          = 1,
    [vtWord]          = 2,
    [vtDword]         = 4,
    [vtQword]         = 8,
    [vtSingle]        = 4,
    [vtDouble]        = 8,
    [vtString]        = targetIs64Bit() and 8 or 4,
    [vtPointer]       = targetIs64Bit() and 8 or 4,
}

vt.read = {
    [vtByte]          = function(addr) return readBytes(addr, 1, false) end,
    [vtWord]          = readSmallInteger,
    [vtDword]         = readInteger,
    [vtQword]         = readQword,
    [vtSingle]        = readFloat,
    [vtDouble]        = readDouble,
    [vtString]        = readString,
    [vtPointer]       = readPointer,
}

vt.write = {
    [vtByte]          = function(addr, val) return writeBytes(addr, {val & 0xFF}) end,
    [vtWord]          = writeSmallInteger,
    [vtDword]         = writeInteger,
    [vtQword]         = writeQword,
    [vtSingle]        = writeFloat,
    [vtDouble]        = writeDouble,
    [vtString]        = writeString,
    [vtPointer]       = function(addr, val) return (targetIs64Bit() and writeQword or writeInteger)(addr, val) end,
}

vt.VTypeHelper = {
    __doc = [[
For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.
    ]]
}

vt.VTypeHelper.new = member_fn({
    doc = "creates a new VType helper",
    returns = "VType",
    schema = {
        basicTypeString = { type = "any" }
    },
    code = function(self, basicTypeString)
        assert(validators.isNonBlankString(basicTypeString), 'alce.T.VType(): invalid argument: typeString: ' .. tostring(basicTypeString))
        local vts = 'vt' .. basicTypeString:sub(1,1):upper() .. basicTypeString:sub(2)
        local vt_global = _G[vts]
        assert(validators.isInteger(vt_global), 'alce.T.VType(): invalid argument: basicTypeString: no global variable named ' .. tostring(vts) )
        local instance = {
            name = basicTypeString,
            vtName = vts,
            vType = vt_global,
            size = vt.size[vt_global],
            readUnsafe = vt.read[vt_global],
            writeUnsafe = vt.write[vt_global],
        }
        setmetatable(instance, { __index = self, __call = self.asInvokeArgument, __name ='VTypeHelper: ' .. basicTypeString })
        return instance
    end,
})

vt.VTypeHelper.getMonotypes = member_fn({
    doc = "returns the monotypes associated with the VType",
    returns = "nil or array of integers",
    code = function(self)
        return alce.keysFromValue(self.vType, monoTypeToVartypeLookup)
    end,
})

vt.VTypeHelper.getMonotypesAsStrings = member_fn({
    doc = "returns a sorted array of strings representing the monotypes",
    returns = "nil or array of strings",
    code = function(self)
        local keys = alce.keysFromValue(self.vType, monoTypeToVartypeLookup)
        local r = {}
        for _,v in ipairs(keys) do table.insert(r, alce.monoscript.monotype.nameLookup[v]) end
        table.sort(r)
        return next(r) and r or nil
    end,
})

vt.VTypeHelper.asInvokeArgument = member_fn({
    doc = "formats the VType and a value for invoking methods",
    returns = "dict {type=, value=}",
    schema = {
        value = { type = "any" }
    },
    code = function(self, value)
        return {type = self.vType, value = value}
    end,
})

vt.VTypeHelper.read = member_fn({
    doc = "reads a value from the specified address using the VType",
    returns = "nil or the value",
    schema = {
        address = { type = "any" }
    },
    code = function(self, address)
        assert(self.readUnsafe, 'alce.T.VType.read(): no read function for type ' .. self.name)
        assert(validators.isAddresslike(address), 'alce.T.VType.read(): invalid address')
        return self.readUnsafe(address)
    end,
})

vt.VTypeHelper.write = member_fn({
    doc = "writes a value to the specified address using the VType",
    returns = "boolean: whether or not it succeeded",
    schema = {
        address = { type = "any" },
        value = { type = "any" }
    },
    code = function(self, address, value)
        assert(self.writeUnsafe, 'alce.T.VType.write(): no read function for type ' .. self.name)
        assert(validators.isAddresslike(address), 'alce.T.VType.write(): invalid address')
        return self.writeUnsafe(address, value)
    end,
})

return vt
