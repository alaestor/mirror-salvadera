local fn = require("alce.src.fn").fn
local member_fn = require("alce.src.fn").member_fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")
local mono_plumbing = require("alce.src.mono_plumbing")
local mono_t = require("alce.src.mono_t")

local mono = {
    __doc = "Mono porcelain helpers for ergonomic interaction with Mono types.",
}

mono.T = mono_t

mono.init = fn({
    doc = "Helper that asserts the process is attached and tries to launch the mono data collector if it's not connected already.",
    returns = "nil",
    code = function(self, args)
        return mono_plumbing.init()
    end
})

mono.Method = {
    __doc = "A representation of, and call-abstraction for, mono methods.",

    init = member_fn({
        doc = "initializes a mono method",
        returns = "self",
        schema = {
            methodID = { validate = validators.isPositiveInteger, required = true },
            name = { type = "string: the name of the mono method" },
            flags = { type = "integer: the flags of the mono method" }
        },
        code = function(self, args)
            assert(type(args) == 'table', 'alce.mono.Method.init(): expected argument table')
            local methodID = args.methodID
            local name = args.name
            local flags = args.flags

            self.id = methodID
            self.flags = flags or mono_method_getFlags(methodID)

            -- The parameters are returned as a table from the C function
            for k, v in pairs(mono_method_get_parameters(methodID)) do
                self[k] = v
            end

            self.signature = mono_plumbing.method_getSignature({
                methodID = methodID,
                methodName = name
            })
            self.name = name
            return self
        end
    }),

    new = fn({
        doc = "creates a new mono method instance",
        returns = "Method",
        schema = {
            methodID = { validate = validators.isPositiveInteger },
            name = { type = "string: the name of the mono method" },
            flags = { type = "integer: the flags of the mono method" }
        },
        code = function(self, args)
            local instance = {}
            setmetatable(instance, {
                __index = mono.Method,
                __call = function(obj, ...)
                    return obj:call(...)
                end
            })

            if args.methodID then
                instance:init({
                    methodID = args.methodID,
                    name = args.name,
                    flags = args.flags
                })
            end
            return instance
        end
    }),

    isStatic = member_fn({
        doc = "checks if the method is static",
        returns = "boolean",
        code = function(self)
            return alce.hasFlag(METHOD_ATTRIBUTE_STATIC, self.flags)
        end
    }),

    getAttributes = member_fn({
        doc = "gets the names of global monoscript.lua constants representing the method attributes",
        returns = "table",
        code = function(self)
            local t = {}
            for _, flagName in pairs(alce.monoscript.methodAttribute.names) do
                if alce.hasFlag(_G[flagName], self.flags) then
                    table.insert(t, flagName)
                end
            end
            return t
        end
    }),

    compile = member_fn({
        doc = "compiles the method for invocation",
        returns = "number: the compiled address",
        code = function(self)
            if not self.address then
                assert(validators.isPositiveInteger(self.id), 'alce.mono.Method.compile(): malformed method; not initialized?')
                local r = mono_compile_method(self.id)
                assert(validators.isAddresslike(r), 'alce.mono.Method.compile(): failed to compile method')
                self.address = r
            end
            return self.address
        end
    }),

    callUnsafe = member_fn({
        doc = "invokes the method without safety checks. Arguments must be in CE's invoke format",
        returns = "any, string, number",
        schema = {
            maybe_instance = { type = "number: optional instance address" },
            maybe_args = { type = "table: optional arguments table" }
        },
        code = function(self, args)
            assert(type(args) == 'table', 'alce.mono.Method.callUnsafe(): expected argument table')
            if alce.cfg.debug_print then
                alce.debug(string.format("alce.mono.Method.callUnsafe(): attempting to invoke call '%s' on instance %s with...\n%s", self.signature.full, alce.fmt.address(args.maybe_instance), alce.fmt.table({wants=self.parameters, giving=args.maybe_args or 'Nothing'})))
            end
            return mono_plumbing.invoke({
                methodID = self.id,
                maybe_instance = args.maybe_instance,
                maybe_arguments = args.maybe_args,
                parameters = self.parameters,
                flags = self.flags
            })
        end
    }),

    call = member_fn({
        doc = "invokes the method after safety checks and argument processing",
        returns = "any",
        schema = {
            maybe_instance = { type = "number: optional instance address" },
            ["..."] = { type = "any: positional arguments" }
        },
        code = function(self, maybe_instance, ...)
            assert(self.id and self.parameters, 'alce.mono.Method.call(): malformed method; not initialized?')

            local raw_args = {...}
            local pcount = #raw_args
            assert(pcount == #(self.parameters), 'alce.mono.Method.call(): called with the wrong number of parameters')
            assert(self:isStatic() or validators.isAddresslike(maybe_instance), 'alce.mono.Method.call(): non-static method was called without an instance')

            self:compile()

            local args = {}
            for i = 1, pcount do
                local arg = raw_args[i]
                assert(arg ~= nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was nil... Did you mean `0` or `false`?')
                if type(arg) == 'table' then
                    assert(arg.type and alce.T[arg.type] and arg.value ~= nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was a malformed table; tables must be {type=,value=}')
                    args[i] = arg
                else
                    args[i] = alce.T.fromMono(self.parameters[i].type)(arg)
                end
            end

            local result, exception, vtype = self:callUnsafe({
                maybe_instance = maybe_instance,
                maybe_args = args
            })
            assert(not exception, 'alce.mono.Method.call(): exception: ' .. tostring(exception))
            return result
        end
    })
}

mono.Class = {
    __doc = "A representation of a mono class type which will fetch, sort, and process its methods and fields into appropriate subtables.",

    new = fn({
        doc = "creates a new mono class instance",
        returns = "Class",
        schema = {
            assemblyNameOrImage = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end, required = true },
            className = { validate = validators.isNonBlankString, required = true },
            namespace = { type = "string: the namespace of the mono class" },
            getParents = { type = "boolean" }
        },
        code = function(self, args)
            local assemblyNameOrImage = args.assemblyNameOrImage
            local className = args.className
            local namespace = args.namespace
            local getParents = args.getParents

            alce.debug('alce.mono.Class.new(): attempting to get "', className, getParents and '" with parents' or '"')

            local id = mono_plumbing.getClass({
                assemblyNameOrImage = assemblyNameOrImage,
                className = className,
                namespace = namespace
            })

            if not validators.isAddresslike(id) then
                alce.warn('alce.mono.Class.new(): failed to find class: ' .. tostring(className))
                return nil
            end

            local hierarchy = mono_plumbing.class_getParentHierarchy({ classID = id })
            local methods = mono_plumbing.getProcessedMethods({
                classID = id,
                getParents = getParents,
                hierarchy = hierarchy,
                keepMetadata = true
            })

            if not methods then
                alce.warn('alce.mono.Class.new(): failed to get methods: ' .. tostring(className))
                return nil
            end

            local fields = mono_plumbing.getProcessedFields({
                classID = id,
                getParents = getParents,
                hierarchy = hierarchy,
                keepMetadata = true
            })

            if not fields then
                alce.warn('alce.mono.Class.new(): failed to get fields: ' .. tostring(className))
                return nil
            end

            local instance = {
                id = id,
                namespace = namespace,
                name = className,
                method = methods,
            }
            for k, v in pairs(fields) do
                instance[k] = v
            end

            setmetatable(instance, { __index = mono.Class })
            return instance
        end
    }),

    instance = member_fn({
        doc = "returns a proxy object (ObjectAlias) for an instance of this class",
        returns = "ObjectAlias",
        schema = {
            baseAddress = { validate = validators.isAddresslike }
        },
        code = function(self, args)
            assert(type(args) == 'table', 'alce.mono.Class.instance(): expected argument table')
            return mono_plumbing.ObjectAlias({
                alceClass = self,
                baseAddress = args.baseAddress
            })
        end
    }),

    instanceFrom = member_fn({
        doc = "convenient shorthand for self:instance(alce.safeChain(...))",
        returns = "ObjectAlias",
        code = function(self, ...)
            return self:instance({ baseAddress = alce.safeChain(...) })
        end
    }),
}

mono.ClassTable = {
    __doc = "A table that loads and holds the mono classes you specify, associated by name, in the form of alce.mono.Class",

    new = fn({
        doc = "creates a new mono class table instance",
        returns = "ClassTable",
        schema = {
            keyPrefixAssembly = { type = "string" },
            keyPrefixNamespace = { type = "string" },
        },
        code = function(self, args)
            local instance = {
                _internal = {
                    targetList = {},
                    isLoaded = false,
                    keyPrefixAssembly = args.keyPrefixAssembly,
                    keyPrefixNamespace = args.keyPrefixNamespace,
                }
            }
            setmetatable(instance, { __index = mono.ClassTable })
            return instance
        end
    }),

    add = member_fn({
        doc = "accepts explicit add({ {image, class[, namespace]}, ... })",
        returns = "self",
        schema = {
            targets = { type = "table" }
        },
        code = function(self, args)
            assert(type(args) == 'table', 'alce.mono.ClassTable.add(): expected argument table')
            assert(not self._internal.isLoaded, 'alce.mono.ClassTable.add(): cannot add while table is loaded. Try calling unload() first?')
            local entries = args.targets or {}
            alce.debug('alce.mono.ClassTable.add(): added targets: ' .. alce.fmt.table(entries))
            for _, entry in ipairs(entries) do
                table.insert(self._internal.targetList, entry)
            end
            return self
        end
    }),

    addFromImage = member_fn({
        doc = "convenience abstraction: addFromImage(image, (class | {class, namespace}), ...)",
        returns = "self",
        schema = {
            image = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end },
            targets = { type = "table" }
        },
        code = function(self, args)
            assert(type(args) == 'table', 'alce.mono.ClassTable.addFromImage(): expected argument table')
            assert(not self._internal.isLoaded, 'alce.mono.ClassTable.addFromImage(): cannot add while table is loaded. Try calling unload() first?')
            local image = args.image
            local items = args.targets or {}
            for _, item in ipairs(items) do
                if type(item) == 'table' then
                    table.insert(self._internal.targetList, { image, item[1], item[2] })
                else
                    table.insert(self._internal.targetList, { image, item, nil })
                end
            end
            return self
        end
    }),

    isLoaded = member_fn({
        doc = "checks if the class table is loaded",
        returns = "boolean",
        code = function(self)
            return self._internal.isLoaded == true
        end
    }),

    load = member_fn({
        doc = "loads the classes specified in the target list",
        returns = "self",
        schema = {
            getParents = { type = "boolean" }
        },
        code = function(self, args)
            alce.debug('alce.mono.ClassTable.load(): called.')
            assert(not self:isLoaded(), 'alce.mono.ClassTable.load(): already loaded. Forget to call :unload()?')
            self._internal.isLoaded = true
            local assemblies = mono_plumbing.enumAssemblies()
            local r = {}
            for _, target in ipairs(self._internal.targetList) do
                local assemblyNameOrImage, className, namespace = unpack(target)
                local assemblyName = type(assemblyNameOrImage) == 'string' and assemblyNameOrImage or mono_plumbing.image_get_name(assemblyNameOrImage)
                if not assemblies[assemblyName] then
                    assemblies[assemblyName] = mono_plumbing.getImage(assemblyName, assemblies)
                end
                local c = mono.Class.new({
                    assemblyNameOrImage = assemblies[assemblyName],
                    className = className,
                    namespace = namespace,
                    getParents = args.getParents
                })
                if c then
                    local keyPrefixA = self._internal.keyPrefixAssembly and assemblyName .. '.' or ''
                    local keyPrefixB = self._internal.keyPrefixNamespace and c.namespace .. '.' or ''
                    local key = keyPrefixA .. keyPrefixB .. className
                    if r[key] then
                        alce.warn('alce.mono.ClassTable.load(): Overwriting duplicate key: "' .. key .. '" (try enabling assembly or namespace prefixing?)')
                    end
                    r[key] = c
                end
            end
            for k, v in pairs(r) do
                self[k] = v
            end
            return self
        end
    }),

    loadWithParents = member_fn({
        doc = "convenience shorthand for self:load({ optional_getParents = true })",
        returns = "self",
        code = function(self)
            return self:load({ optional_getParents = true })
        end
    }),

    unload = member_fn({
        doc = "unloads the class table",
        returns = "self",
        code = function(self)
            alce.debug('alce.mono.ClassTable.unload(): called.')
            if not self:isLoaded() then
                alce.warn('alce.mono.ClassTable.unload() called but nothing was loaded?... Doing it anyways.')
            end
            local internal = self._internal
            -- We need to clear the keys that were added to the instance
            for k, v in pairs(self) do
                if type(v) == 'table' and v._type == 'fn_structured_function' then
                    -- This is one of our methods, don't clear it
                elseif k ~= '_internal' then
                    self[k] = nil
                end
            end
            self._internal = internal
            self._internal.isLoaded = false
            return self
        end
    }),

    clear = member_fn({
        doc = "clears the target list and unloads if necessary",
        returns = "self",
        code = function(self)
            alce.debug('alce.mono.ClassTable.clear(): called.')
            if self:isLoaded() then
                self:unload()
            end
            self._internal.targetList = {}
            return self
        end
    }),
}

return mono
