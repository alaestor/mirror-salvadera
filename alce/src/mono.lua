local fn = require("alce.src../fn").fn
local member_fn = require("alce.src../fn").member_fn
local validators = require("alce.src../validators")
local alce = require("alce.src../globals")
local mono_plumbing = require("alce.src../mono_plumbing")
local mono_t = require("alce.src../mono_t")

local mono = {
    __doc = [[Mono porcelain helpers for ergonomic interaction with Mono types.]],
}

mono.T = mono_t

mono.init = fn({
    __doc = [[Helper that asserts the process is attached and tries to launch the mono data collector if it's not connected already.]],
    code = function(self, args)
        return mono_plumbing.init()
    end
})

mono.Method = {
    __doc = [[A representation of, and call-abstraction for, mono methods.]],

    init = member_fn({
        __doc = [[initializes a mono method]],
        __doc_returns = [[self]],
        parameters = {
            methodID = { validate = validators.isPositiveInteger, required = true },
            name = { __doc = [[string: the name of the mono method]], required = true },
            flags = { __doc = [[integer: the flags of the mono method]], required = true }
        },
        code = function(self, args)
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
        __doc = [[creates a new mono method instance]],
        __doc_returns = [[Method]],
        parameters = {
            methodID = { validate = validators.isPositiveInteger, required = true },
            name = { __doc = [[string: the name of the mono method]], required = true },
            flags = { __doc = [[integer: the flags of the mono method]], required = true }
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
        __doc = [[checks if the method is static]],
        __doc_returns = [[boolean]],
        code = function(self)
            return alce.hasFlag(METHOD_ATTRIBUTE_STATIC, self.flags)
        end
    }),

    getAttributes = member_fn({
        __doc = [[gets the names of global monoscript.lua constants representing the method attributes]],
        __doc_returns = [[array: the list of `METHOD_ATTRIBUTE_...`]],
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
        __doc = [[compiles the method for invocation]],
        __doc_returns = [[number: the compiled address]],
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
        __doc = [[invokes the method without safety checks. Arguments must be in CE's invoke format]],
        __doc_returns = [[any, string, number]],
        parameters = {
            maybe_instance = { __doc = [[number: optional instance address]] },
            maybe_args = { __doc = [[table: optional arguments table]] }
        },
        positional = true,
        code = function(self, args)
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
        __doc = [[invokes the method after safety checks and argument processing]],
        __doc_returns = [[any]],
        parameters = {
            maybe_instance = { __doc = [[number: optional instance address]] },
            ["..."] = { __doc = [[any: positional arguments]] }
        },
        positional = true,
        code = function(self, args)
            local maybe_instance = args.maybe_instance
            local raw_args = args["..."] or {}
            assert(self.id and self.parameters, 'alce.mono.Method.call(): malformed method; not initialized?')

            local pcount = #raw_args
            assert(pcount == #(self.parameters), 'alce.mono.Method.call(): called with the wrong number of parameters')
            assert(self:isStatic() or validators.isAddresslike(maybe_instance), 'alce.mono.Method.call(): non-static method was called without an instance')

            self:compile()

            local args_list = {}
            for i = 1, pcount do
                local arg = raw_args[i]
                assert(arg ~= nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was nil... Did you mean `0` or `false`?')
                if type(arg) == 'table' then
                    assert(arg.type and alce.T[arg.type] and arg.value ~= nil, 'alce.mono.Method.call(): argument ' .. tostring(i) .. ' was a malformed table; tables must be {type=,value=}')
                    args_list[i] = arg
                else
                    args_list[i] = alce.T.fromMono(self.parameters[i].type)(arg)
                end
            end

            local result, exception, vtype = self:callUnsafe({
                maybe_instance = maybe_instance,
                maybe_args = args_list
            })
            assert(not exception, 'alce.mono.Method.call(): exception: ' .. tostring(exception))
            return result
        end
    })
}

mono.Class = {
    __doc = [[A representation of a mono class type which will fetch, sort, and process its methods and fields into appropriate subtables.]],

    new = fn({
        __doc = [[creates a new mono class instance]],
        __doc_returns = [[Class]],
        parameters = {
            assemblyNameOrImage = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end, required = true },
            className = { validate = validators.isNonBlankString, required = true },
            namespace = { __doc = [[string: the namespace of the mono class]] },
            getParents = { __doc = [[boolean: whether to get parents]] }
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
        __doc = [[creates a proxy object (ObjectAlias) for an instance of this class]],
        __doc_returns = [[ObjectAlias]],
        parameters = {
            baseAddress = { validate = validators.isAddresslike, required = true }
        },
        code = function(self, args)
            return mono_plumbing.ObjectAlias({
                alceClass = self,
                baseAddress = args.baseAddress
            })
        end
    }),

    instanceFrom = member_fn({
        __doc = [[convenient shorthand for self:instance(alce.safeChain(...))]],
        __doc_returns = [[ObjectAlias]],
        code = function(self, ...)
            return self:instance({ baseAddress = alce.safeChain(...) })
        end
    }),
}

mono.ClassTable = {
    __doc = [[A table that loads and holds the mono classes you specify, associated by name, in the form of alce.mono.Class]],

    new = fn({
        __doc = [[creates a new mono class table instance]],
        __doc_returns = [[ClassTable]],
        parameters = {
            keyPrefixAssembly = { __doc = [[string: prefix for assembly names]], required = true },
            keyPrefixNamespace = { __doc = [[string: prefix for namespace names]], required = true },
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
        __doc = [[accepts explicit add({ {image, class[, namespace]}, ... })]],
        __doc_returns = [[self]],
        parameters = {
            targets = { __doc = [[table: list of targets to add]], required = true }
        },
        code = function(self, args)
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
        __doc = [[convenience abstraction: addFromImage(image, (class | {class, namespace}), ...)]],
        __doc_returns = [[self]],
        parameters = {
            image = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end, required = true },
            targets = { __doc = [[table: list of targets]], required = true }
        },
        code = function(self, args)
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
        __doc = [[checks if the class table is loaded]],
        __doc_returns = [[boolean]],
        code = function(self)
            return self._internal.isLoaded == true
        end
    }),

    load = member_fn({
        __doc = [[loads the classes specified in the target list]],
        __doc_returns = [[self]],
        parameters = {
            getParents = { __doc = [[boolean: whether to get parents]] }
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
        __doc = [[convenience shorthand for self:load({ getParents = true })]],
        __doc_returns = [[self]],
        code = function(self)
            return self:load({ getParents = true })
        end
    }),

    unload = member_fn({
        __doc = [[unloads the class table]],
        __doc_returns = [[self]],
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
        __doc = [[clears the target list and unloads if necessary]],
        __doc_returns = [[self]],
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
