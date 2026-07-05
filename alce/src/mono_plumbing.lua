local fn = require("alce.src.fn").fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")

local mono_plumbing = {}

-- Internal helper functions

local function aliasRead(context, key)
    local class = context.type
    local offset = class.offset[key]
    if offset then
        assert(validators.isNonEmptyTable(class.meta), 'alce.mono.ObjectAlias(): error in aliasRead: metadata table for "' .. tostring(class.name) .. '" was invalid; not populated?')
        local meta = class.meta.offset[key]
        assert(meta, 'alce.mono.ObjectAlias(): error in aliasRead: failed to find metadata for offset ' .. tostring(key))
        local T = require("alce.src.t")
        local t = T.fromMono({ monoType = meta.monotype })
        return t:read(context.baseAddress + offset)
    end
    local const = class.const[key]
    if const then return const end
    local static = class.static[key]
    if static and validators.isAddresslike(static) then readPointer(static) end
    assert(false, 'alce.mono.ObjectAlias(): error in aliasRead: failed to find datamember ' .. tostring(key))
end

local function aliasWrite(context, key, value)
    local class = context.type
    local offset = class.offset[key]
    if offset then
        assert(validators.isNonEmptyTable(class.meta), 'alce.mono.ObjectAlias(): error in aliasWrite: metadata table for "' .. tostring(class.name) .. '" was invalid; not populated?')
        local meta = class.meta.offset[key]
        assert(meta, 'alce.mono.ObjectAlias(): error in aliasWrite: failed to find metadata for offset ' .. tostring(key))
        local T = require("alce.src.t")
        local t = T.fromMono({ monoType = meta.monotype })
        return t:write(context.baseAddress + offset, value)
    end
    assert(not class.const[key], "alce.mono.ObjectAlias(): error in aliasWrite: can't write to constant value: " .. tostring(key))
    assert(not class.static[key], "alce.mono.ObjectAlias(): error in aliasWrite: shouldn't write to static member: " .. tostring(key) .. ". Did you really intend to? You can try doing it manually.")
    assert(false, 'alce.mono.ObjectAlias(): error in aliasWrite: failed to find datamember ' .. tostring(key))
end

-- Public API

mono_plumbing.init = fn({
    doc = "initializes mono state",
    returns = "nil",
    code = function(self)
        assert(alce.isAttached(), 'alce.mono.init(): not attached to process')
        if (monopipe == nil) then
            assert(LaunchMonoDataCollector(), 'alce.mono.init(): LaunchMonoDataCollector() failed.')
        end
    end
})

mono_plumbing.invoke = fn({
    doc = "invokes a mono method",
    returns = "any|nil, string|nil, string|nil",
    positional = true,
    code = function(self, methodID, maybe_instance, maybe_arguments, optional_parameters, optional_flags)
        alce.debug('alce.mono.invoke(): invoke_method called')
        assert(validators.isPositiveInteger(methodID), 'alce.mono.invoke(): invalid argument: methodID: '..tostring(methodID))

        local static = ((optional_flags or mono_method_getFlags(methodID)) & METHOD_ATTRIBUTE_STATIC) == METHOD_ATTRIBUTE_STATIC
        assert(validators.isAddresslike(maybe_instance) or static, 'alce.mono.invoke(): invalid argument: maybe_instance is required for non-static methods')

        local argument_count = #maybe_arguments
        local params = optional_parameters or mono_method_get_parameters(methodID)
        assert(argument_count == #params, 'alce.mono.invoke(): invalid argument: length of maybe_arguments does not match method parameters')
        for _, arg in ipairs(maybe_arguments) do
            assert(type(arg) == 'table' and arg.type and arg.value ~= nil, 'alce.mono.invoke(): invalid argument: maybe_arguments not well-formed')
        end

        local object = maybe_instance
        if object and object ~= 0 then
            local class = mono_method_getClass(methodID)
            if mono_type_get_type(mono_class_get_type(class)) == MONO_TYPE_VALUETYPE then
                object = mono_object_unbox(object)
            end
        end

        local result, vtype, exception
        local r, err = pcall(function()
            assert(mono_isValid(), 'alce.mono.invoke(): invalid mono state. Mono features not active?')
            alce.debug('alce.mono.invoke(): invoking MONOCMD_INVOKEMETHOD')
            libmono.monopipe.writeByte(MONOCMD_INVOKEMETHOD)
            libmono.monopipe.writeQword(methodID)
            libmono.monopipe.writeQword(object or 0)
            for i = 1, argument_count do
                mono_writeObject(maybe_arguments[i].type, maybe_arguments[i].value)
            end

            alce.debug('alce.mono.invoke(): waiting for result')
            result, vtype = mono_readObject()
            alce.debug('alce.mono.invoke(): result='..tostring(result)..' vtype='..tostring(vtype))
            if libmono.monopipe.readByte() == 1 then
                if libmono.monopipe.readByte() == 1 then
                    local excplen = libmono.monopipe.readWord()
                    exception = libmono.monopipe.readString(excplen)
                end
            end

            if vtype == MONO_TYPE_VALUETYPE then
                local f = mono_object_enumValues(result)
                if f then
                    result = f
                    return f, exception, vtype
                end
            end
        end)
        if r then
            return result, exception, vtype
        else
            return nil, err
        end
    end
})

mono_plumbing.sortByHierarchy = fn({
    doc = "sorts an array of members by parent hierarchy, from parent to child",
    returns = "table",
    schema = {
        array = { type = "table", required = true },
        hierarchy = { validate = validators.isNonEmptyTable, required = true }
    },
    code = function(self, args)
        local array = args.array
        local hierarchy = args.hierarchy
        if not array then return nil end
        local ClassID = hierarchy[#hierarchy]
        local classOrder = {}
        for i, classId in ipairs(hierarchy) do classOrder[classId] = i end
        table.sort(array, function(a, b)
            local orderA = classOrder[a.parent or ClassID]
            local orderB = classOrder[b.parent or ClassID]
            if orderA ~= orderB then return orderA < orderB end
            if a.name ~= b.name then return a.name < b.name end
            return (a.field or a.method) < (b.field or b.method)
        end)
        return array
    end
})

mono_plumbing.getImage = fn({
    doc = "gets Image by assemblyName",
    returns = "number|nil",
    schema = {
        assemblyName = { type = "string", required = true },
        optional_enumeratedAssemblies = { validate = function(v) return v == nil or validators.isNonEmptyTable(v) end }
    },
    code = function(self, args)
        local assemblies = args.optional_enumeratedAssemblies or mono_enumAssemblies()
        assert(validators.isNonEmptyTable(assemblies), "alce.mono.getImage(): Couldn't enumerate assemblies. Mono features not active?")
        for _, assembly in ipairs(assemblies) do
            local image = mono_getImageFromAssembly(assembly)
            if image and mono_image_get_name(image) == args.assemblyName then return image end
        end
        alce.warn("alce.mono.getImage(): Failed to find " .. tostring(args.assemblyName))
        return nil
    end
})

mono_plumbing.getClassEx = fn({
    doc = "finds a class by name in a specific assembly and namespace",
    returns = "table|nil",
    schema = {
        assemblyNameOrImage = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end, required = true },
        className = { validate = validators.isNonBlankString, required = true },
        optional_namespace = { type = "string" }
    },
    code = function(self, args)
        local t = type(args.assemblyNameOrImage)
        local image = t == 'number' and args.assemblyNameOrImage or (t == 'string' and self.getImage({ assemblyName = args.assemblyNameOrImage }) or nil)
        assert(image, "alce.mono.getClassEx(): Failed to get image: '" .. tostring(args.assemblyNameOrImage) .. "'")
        for _, v in ipairs(mono_image_enumClassesEx(image)) do
            if v.FullName == args.className and (args.optional_namespace and args.optional_namespace == v.NameSpace or true) then return v end
        end
        alce.warn("alce.mono.getClassEx(): No results for getClassEx(" .. tostring(args.assemblyNameOrImage) .. ", " .. args.className .. ((args.optional_namespace and ', "'..args.optional_namespace..'"') or '') .. ")")
        return nil
    end
})

mono_plumbing.getClass = fn({
    doc = "returns the class handle for a given class",
    returns = "number|nil",
    schema = {
        assemblyNameOrImage = { type = "any", required = true },
        className = { type = "string", required = true },
        optional_namespace = { type = "string" }
    },
    code = function(self, args)
        local r = self.getClassEx(args)
        return r and r.Handle or nil
    end
})

mono_plumbing.method_getSignature = fn({
    doc = "returns the signature of a method",
    returns = "table",
    schema = {
        methodID = { validate = validators.isPositiveInteger, required = true },
        optional_methodName = { type = "string" }
    },
    code = function(self, args)
        local name = args.optional_methodName and validators.isNonBlankString(args.optional_methodName) and args.optional_methodName or mono_method_getName(args.methodID)
        local paramtypes_raw, paramnames, returntype = mono_method_getSignature(args.methodID)
        local paramtypes = string.gsub(paramtypes_raw, '/', '+')
        local t = { types = paramtypes, paramnames = paramnames, returntype = returntype }
        t.initials = string.format('%s(%s)', name, paramtypes or '')
        local typenames = mono_splitParameters(paramtypes)
        local params = ''
        if typenames and #typenames == #paramnames then
            local rr = {}
            for i = 1, #typenames do rr[i] = typenames[i] .. ' ' .. paramnames[i] end
            params = table.concat(rr, ",")
        end
        local front = string.gsub(string.match(mono_method_getFullName(args.methodID), "^(.-) %("), '/', '+')
        t.full = string.format('%s(%s)', front, params)
        return t
    end
})

mono_plumbing.class_getParentHierarchy = fn({
    doc = "returns array of class IDs ordered from parent to child",
    returns = "table",
    schema = {
        classID = { validate = validators.isPositiveInteger, required = true }
    },
    code = function(self, args)
        local hierarchy = {}
        local current_class = args.classID
        while current_class and current_class ~= 0 do
            table.insert(hierarchy, 1, current_class)
            current_class = mono_class_getParent(current_class)
        end
        return hierarchy
    end
})

mono_plumbing.getProcessedFields = fn({
    doc = "enumerates and processes fields for a class",
    returns = "table|nil",
    schema = {
        classID = { type = "any", required = true },
        optional_getParents = { type = "boolean" },
        optional_hierarchy = { validate = function(v) return v == nil or validators.isNonEmptyTable(v) end },
        optional_keepMetadata = { type = "boolean" },
        optional_keepFields = { type = "boolean" }
    },
    code = function(self, args)
        local fields = mono_class_enumFields(args.classID, args.optional_getParents)
        if type(fields) ~= 'table' then
            alce.warn('alce.mono.getProcessedFields(): failed to lookup fields')
            return nil
        end
        if args.optional_getParents == true then
            fields = self.sortByHierarchy({
                array = fields,
                hierarchy = args.optional_hierarchy or self.class_getParentHierarchy({ classID = args.classID })
            })
        end
        local startOffset = mono_structfields_getStartOffset(fields)
        if not startOffset then startOffset = targetIs64Bit() and 0x10 or 0x8 end
        local t = {
            startOffset = startOffset,
            const = {},
            static = {},
            offset = {},
            meta = args.optional_keepMetadata == true and {
                const = {},
                static = {},
                offset = {},
            } or nil,
            constToKey = {},
            fields = args.optional_keepFields == true and fields or nil,
        }
        local function warnIfCollides(subtable, f)
            if not t[subtable][f.name] then return nil end
            local dstr = ((not alce.cfg.debug_print and "Set 'alce.cfg.debug_print=true` for more information.")
                or string.format('\n[WARN-DEBUG]>\nReplacing...\n---\n%s\n---\nwith data from...\n---\n%s\n---\n',
                    alce.fmt.table(t[subtable][f.name]), alce.fmt.table(f)))
            alce.debug(string.format("alce.mono.getProcessedFields(): duplicate %s field named '%s' detected. %s", subtable, f.name, dstr))
        end
        local function store(ts, f, val)
            warnIfCollides(ts, f)
            t[ts][f.name] = val
            if args.optional_keepMetadata == true then
                t.meta[ts][f.name] = {}
                local meta = t.meta[ts][f.name]
                for _, k in pairs({ 'typename', 'type', 'monotype', 'flags' }) do meta[k] = f[k] end
                meta.vtype = monoTypeToVartypeLookup[meta.monotype] or nil
            end
        end
        for _, f in pairs(fields) do
            if f.staticAddress then store('static', f, f.staticAddress)
            elseif f.isConst then store('const', f, mono_class_getStaticFieldValue(args.classID, f.field))
            elseif f.offset then store('offset', f, f.offset)
            else alce.warn("alce.mono.getProcessedFields(): uncategorized field; what is this?\n??:" .. alce.fmt.table(f)) end
        end
        t.const.enumSeperator = nil
        t.static.enumSeparatorCharArray = nil
        if next(t.const) then for k, v in pairs(t.const) do t.constToKey[v] = k end end
        return t or nil
    end
})

mono_plumbing.getProcessedMethods = fn({
    doc = "enumerates and processes methods for a class",
    returns = "table|nil",
    schema = {
        classID = { type = "any" },
        optional_getParents = { type = "boolean" },
        optional_hierarchy = { validate = function(v) return v == nil or validators.isNonEmptyTable(v) end }
    },
    code = function(self, args)
        local methods = mono_class_enumMethods(args.classID, args.optional_getParents)
        if type(methods) ~= 'table' then
            alce.warn('alce.mono.getProcessedMethods(): Failed to enumerate methods')
            return nil
        end
        if args.optional_getParents == true then
            methods = self.sortByHierarchy({
                array = methods,
                hierarchy = args.optional_hierarchy or self.class_getParentHierarchy({ classID = args.classID })
            })
        end
        local t = {}
        for _, mpack in ipairs(methods) do
            local m = alce.mono.Method:new(mpack.method, mpack.name, mpack.flags)
            if not t[mpack.name] or (t[m.signature.initials] and t[mpack.name] ~= 'tombstone') then t[mpack.name] = m
            else t[mpack.name] = 'tombstone' end
            t[m.signature.initials] = m
        end
        for k, _ in pairs(t) do if t[k] == 'tombstone' then t[k] = nil end end
        return t
    end
})

mono_plumbing.ObjectAlias = fn({
    doc = "creates a proxy object for a mono object",
    returns = "proxy object",
    schema = {
        alceClass = { type = "table" },
        baseAddress = { validate = validators.isAddresslike }
    },
    code = function(self, args)
        local internal = {
            baseAddress = args.baseAddress,
            type = args.alceClass,
        }
        local proxy = {}
        setmetatable(proxy, {
            __tostring = function() return string.format("%s@%s", args.alceClass.name, alce.fmt.address(internal.baseAddress)) end,
            __pairs = function(_) error("alce.mono.ObjectAlias.__pairs(): Aliases don't support iteration; not sure what behavior was expected. Perhaps you want the alce.mono.Class; try `.__type`?") end,
            __eq = function(a, b)
                local ameta = getmetatable(a)
                local bmeta = getmetatable(b)
                return ameta == bmeta and rawequal(ameta.__index, bmeta.__index) and a.__baseAddress == b.__baseAddress
            end,
            __index = function(tbl, key)
                if not validators.isNonBlankString(key) then
                    alce.warn('alce.mono.ObjectAlias.__index(): invalid argument: key should be the name of a data-member or method. Got: ' .. tostring(key))
                    return nil
                end
                local m = internal.type.method[key]
                if m then
                    return function(optional_self, ...)
                        if optional_self == tbl then return m:call(internal.baseAddress, ...)
                        else return m:call(internal.baseAddress, optional_self, ...) end
                    end
                elseif key:sub(1, 2) == "__" then return internal[key:sub(3)]
                else return aliasRead(internal, key) end
            end,
            __newindex = function(_, key, value) return aliasWrite(internal, key, value) end
        })
        return proxy
    end
})

return mono_plumbing
