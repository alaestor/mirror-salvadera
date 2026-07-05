local fn = require("alce.src.fn").fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local memory = {}

memory.AllocateSymbols_register = fn({
    doc = "Registers symbols defined in a context, optionally filtered by a list of names.",
    returns = "nil",
    schema = {
        context = { type = "table" },
        optional_names = { type = "table", default = nil }
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
        context = { type = "table" },
        optional_names = { type = "table", default = nil }
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

return memory
