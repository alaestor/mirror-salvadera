local fn = require("alce.src../fn").fn
local validators = require("alce.src../validators")

local function byte_to_bits(byte)
    local bits = {}
    for i = 7, 0, -1 do bits[#bits + 1] = (byte >> i) & 1 end
    return table.concat(bits)
end

local fmt = {}

	fmt.titleCase = fn({
		    __doc = [[string: "title case" -> "Title Case"]],
		    code = function(self, args)
		        local str = args.str
		        return str:gsub("(%a)([%w']*)", function(first, rest) return first:upper() .. rest:lower() end)
		    end,
		    schema = {
		        str = { __doc = [[string: the string to title case]], required = true }
		    }
		})

    fmt.binary = fn({
    __doc = [[string: `0b` prefixed big-endien binary string representation in groups of 8]],
    code = function(self, args)
        local value = args.value
        local useDouble = args.useDouble
        local useNativeEndian = args.useNativeEndian

        assert(type(value) == 'number', 'alce.fmt.binary(): expected number, got type: ' .. type(value))
        local endian = useNativeEndian and '' or '>'
        local fmt_str = (math.type(value) == 'integer') and (endian .. 'j') or (endian .. (useDouble and 'd' or 'f'))
        local bytes = string.pack(fmt_str, value)
        local t = {}
        for i = 1, #bytes do t[i] = byte_to_bits(string.byte(bytes, i)) end
        return '0b' .. table.concat(t, ' ')
    end,
    schema = {
        value = { __doc = [[number: the numeric value to convert to binary]], required = true },
        useDouble = { __doc = [[boolean: whether to use double precision]] },
        useNativeEndian = { __doc = [[boolean: whether to use native endianness]] }
    }
})

local BYTE_TO_HEX = {}
for i = 0, 255 do BYTE_TO_HEX[i] = string.format("%02X", i) end

	fmt.hex = fn({
	    __doc = [[string: 0x prefixed hexadecimal string representation]],
	    code = function(self, args)
	        local value = args.value
	        local withPadding = args.withPadding
	        local useNativeEndian = args.useNativeEndian

	        assert(type(value) == 'number', 'alce.fmt.hex(): expected number, got type: ' .. type(value))
	        local endian = useNativeEndian and '' or '>'
	        local fmt_str = (math.type(value) == 'integer') and (endian .. 'j') or (endian .. 'd')
	        local bytes = string.pack(fmt_str, value)
	        local hex = {}
	        for i = 1, #bytes do hex[i] = BYTE_TO_HEX[string.byte(bytes, i)] end
	        local result = table.concat(hex)
	        if withPadding ~= true then
	            result = result:gsub("^0+", "")
	            if result == "" then result = "0" end
	        end
	        return '0x' .. result
	    end,
	    schema = {
	        value = { __doc = [[number: the numeric value to convert to hex]], required = true },
	        withPadding = { __doc = [[boolean: whether to include leading zeros for padding]] },
	        useNativeEndian = { __doc = [[boolean: whether to use native endianness]] }
	    }
	})

	fmt.address = fn({
	    __doc = [[string: `alce.fmt.hex(value, true, false)` padded to address length]],
	    code = function(self, args)
	        local value = args.value

	        if not validators.isInteger(value) then return 'NaN: ' .. tostring(value) end

	        local full = fmt.hex({ value = value, withPadding = true, useNativeEndian = false })
	        if targetIs64Bit() then return full
	        else return '0x' .. full:sub(-8) end
	    end,
	    schema = {
	        value = { __doc = [[number: the numeric value to convert to address]], required = true }
	    }
	})

	fmt.sanitizeSymbolName = fn({
	    __doc = [[string: the input string with non-alphanumeric replaced with underscores]],
	    code = function(self, args)
	        local str = args.str
	        return string.gsub(str, '[^%a%d]', '_')
	    end,
	    schema = {
	        str = { __doc = [[string: the string to sanitize]], required = true }
	    }
	})

	fmt.pretty = fn({
	    __doc = [[string: single line, unless value is a table and usePrintFullTable is true.]],
	    code = function(self, args)
	        local value = args.value
	        local usePrintFullTable = args.usePrintFullTable
	        local t = type(value)
	        if t == 'table' and usePrintFullTable then return fmt.table({ tbl = value })
	        elseif t == 'string' then return '"' .. value .. '"'
	        elseif t == 'number' then return string.format('%s  (%s: %s)', tostring(value), math.type(value), fmt.hex({ value = value }))
	        elseif t == 'function' or t == 'thread' or t == 'userdata' then return '<' .. tostring(value) .. '>'
	        else return tostring(value) end
	    end,
	    schema = {
	        value = { __doc = [[any: the value to format]], required = true },
	        usePrintFullTable = { __doc = [[boolean: whether to print the full table if value is a table]] }
	    }
	})

	fmt.table = fn({
	    __doc = [[string: the human-readable representation of the table]],
	    code = function(self, args)
	        local tbl = args.tbl
	        local useDepthLimit = args.useDepthLimit
	        local useKeysToIgnore = args.useKeysToIgnore or {}
	        local useDontToString = args.useDontToString == true
	        local useDontSortKeys = args.useDontSortKeys
	        local internal_depth = args.internal_depth or 0
	        local internal_seen = args.internal_seen or {}
	        local internal_path = args.internal_path or "root"

	        local depth = internal_depth
	        local seen = internal_seen
	        local path = internal_path
	        local keysToIgnore = useKeysToIgnore
	        local dontToString = useDontToString

	        if type(tbl) ~= "table" or useDepthLimit == depth then return fmt.pretty({ value = tbl }) end
	        if seen[tbl] then return string.format("<circular reference to %s @ %s>", seen[tbl], tostring(tbl):gsub("table: ", "")) end
	        seen[tbl] = path
	        if not dontToString then
	            local mt = getmetatable(tbl)
	            if mt and type(mt.__tostring) == "function" then
	                local ok, str = pcall(mt.__tostring, tbl)
	                if ok then return str end
	            end
	        end
	        local result = {}
	        local prefix = string.rep("  ", depth)
	        local keys = {}
	        for k in pairs(tbl) do if not keysToIgnore[k] then table.insert(keys, k) end end
	        if not useDontSortKeys then
	            table.sort(keys, function(a, b)
	                local ta, tb = type(a), type(b)
	                if ta == tb then return a < b end
	                return ta < tb
	            end)
	        end
	        for _, k in ipairs(keys) do
	            local v = tbl[k]
	            local key_str = (type(k) == "string") and k or "[" .. tostring(k) .. "]"
	            local current_path = path .. "." .. key_str
	            local line_prefix = prefix .. key_str .. " = "
	            if type(v) ~= "table" then table.insert(result, line_prefix .. fmt.pretty({ value = v }))
	            else
	                if seen[v] then table.insert(result, line_prefix .. string.format("<circular reference to %s @ %s>", seen[v], tostring(v):gsub("table: ", "")))
	                elseif next(v) == nil then table.insert(result, line_prefix .. "{}")
	                else
	                    table.insert(result, line_prefix .. "{")
	                    table.insert(result, fmt.table({
	                        tbl = v,
	                        useDepthLimit = useDepthLimit,
	                        useKeysToIgnore = keysToIgnore,
							useDontSortKeys = useDontSortKeys,
	                        internal_depth = depth + 1,
	                        internal_seen = seen,
	                        internal_path = current_path
	                    }))
	                    table.insert(result, prefix .. "}")
	                end
	            end
	        end
	        return table.concat(result, "\n")
	    end,
	    schema = {
	        tbl = { __doc = [[table: the table to represent as a string]], required = true },
	        useDepthLimit = { __doc = [[number: the maximum depth of recursion]] },
	        useKeysToIgnore = { __doc = [[table: keys to exclude from the representation]] },
	        useDontToString = { __doc = [[boolean: whether to avoid using the table's __tostring method]] },
	        useDontSortKeys = { __doc = [[boolean: whether to avoid sorting keys]] },
	        internal_depth = { __doc = [[number: internal depth counter]] },
	        internal_seen = { __doc = [[table: internal table for tracking circular references]] },
	        internal_path = { __doc = [[string: internal path tracker]] }
	    }
	})

return fmt
