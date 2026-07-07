local fn = require("alce.src../fn").fn
local fmt = require("alce.src../fmt")
local alce = require("alce.src../globals")

local printers = {}

printers.inspect = fn({
    __doc = [[Prints the table formatted by fmt.table]],
    positional = true,
    parameters = {
        optional_title = { __doc = [[string|nil]] },
        tbl = { __doc = [[table]], required = true }
    },
    code = function(self, optional_title, tbl)
        if type(optional_title) ~= 'string' then
            if tbl == nil then
                if type(optional_title) == 'table' then
                    tbl = optional_title
                    optional_title = nil
                else
                    error('alce.inspect(): invalid arguments')
                end
            end
        end

        local table_to_print = tbl
        if optional_title then
            table_to_print = { [tostring(optional_title)] = tbl }
        end

        print('[INSPECT] ' .. fmt.table({ tbl = table_to_print }))
    end,
})

printers.inspectKeys = fn({
    __doc = [[print a sorted array of the table's keys]],
    positional = true,
    parameters = {
        optional_title = { __doc = [[string|nil]] },
        tbl = { __doc = [[table]], required = true }
    },
    code = function(self, optional_title, tbl)
        if tbl == nil then
            if type(optional_title) == 'table' then
                tbl = optional_title
                optional_title = nil
            else
                error('alce.inspectKeys(): invalid argument(s)')
            end
        end

        local keys = {}
        for key, _ in pairs(tbl) do table.insert(keys, key) end
        table.sort(keys)

        local table_to_print = keys
        if optional_title then
            table_to_print = { [tostring(optional_title)] = keys }
        end

        print('[INSPECT] ' .. fmt.table({ tbl = table_to_print }))
    end,
})

printers.prettyprint = fn({
    __doc = [[pretty-stringifies, concatenates, and prints input]],
    positional = true,
    parameters = {
        args = { __doc = [[any...]], required = true }
    },
    code = function(self, ...)
        local args = {...}
        local result = ""
        for i = 1, #args do
            local a = args[i]
            local t = type(a)
            if t == 'string' or t == 'number' then
                result = result .. tostring(a)
            else
                result = result .. fmt.pretty({ value = a })
            end
        end
        print(result)
    end,
})

printers.debug = fn({
    __doc = [[print message with source linenumber only if alce.cfg.debug_print is `true`]],
    positional = true,
    parameters = {
        args = { __doc = [[any...]], required = true }
    },
    code = function(self, ...)
        local info = debug.getinfo(2, "Sl")
        if alce.cfg.debug_print then
            printers.prettyprint(string.format("[DEBUG] L%i: ", info.currentline), ...)
        end
    end,
})

printers.warn = fn({
    __doc = [[print message with source linenumber only if alce.cfg.warn_print is `true`]],
    positional = true,
    parameters = {
        args = { __doc = [[any...]], required = true }
    },
    code = function(self, ...)
        local info = debug.getinfo(2, "Sl")
        if alce.cfg.warn_print then
            printers.prettyprint(string.format('[WARN] L%i: ', info.currentline), ...)
        end
    end,
})

return printers
