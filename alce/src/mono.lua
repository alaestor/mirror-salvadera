local fn = require("alce.src.fn").fn
local member_fn = require("alce.src.fn").member_fn
local validators = require("alce.src.validators")
local alce = require("alce.src.globals")
local mono_plumbing = require("alce.src.mono_plumbing")

local mono = {
    __doc = "Mono porcelain helpers for ergonomic interaction with Mono types.",
}

mono.T = require("alce.src.mono_t")

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
            methodID = { validate = validators.isPositiveInteger },
            optional_name = { type = "string" },
            optional_flags = { type = "number" }
        },
        code = function(self, args)
            local methodID = args.methodID
            local name = args.optional_name
            local flags = args.optional_flags

            self.id = methodID
            self.flags = flags or mono_method_getFlags(methodID)

            -- The parameters are returned as a table from the C function
            for k, v in pairs(mono_method_get_parameters(methodID)) do
                self[k] = v
            end

            self.signature = mono_plumbing.method_getSignature({
                methodID = methodID,
                optional_methodName = name
            })
            self.name = name
            return self
        end
    }),

    new = fn({
        doc = "creates a new mono method instance",
        returns = "Method",
        schema = {
            optional_methodID = { validate = validators.isPositiveInteger },
            optional_name = { type = "string" },
            optional_flags = { type = "number" }
        },
        code = function(self, args)
            local instance = {}
            setmetatable(instance, {
                __index = mono.Method,
                __call = function(obj, ...)
                    return obj:call(...)
                end
            })

            if args.optional_methodID then
                instance:init({
                    methodID = args.optional_methodID,
                    optional_name = args.optional_name,
                    optional_flags = args.optional_flags
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
            if alce.cfg.debug_print then
                alce.debug(string.format("alce.mono.Method.callUnsafe(): attempting to invoke call '%s' on instance %s with...\n%s", self.signature.full, alce.fmt.address(args.maybe_instance), alce.fmt.table({wants=self.parameters, giving=args.maybe_args or 'Nothing'})))
            end
            return mono_plumbing.invoke({
                methodID = self.id,
                maybe_instance = args.maybe_instance,
                maybe_arguments = args.maybe_args,
                optional_parameters = self.parameters,
                optional_flags = self.flags
            })
        end
    }),

    call = member_fn({
        doc = "invokes the method after safety checks and argument processing",
        returns = "any",
        schema = {
            maybe_instance = { type = "number: optional instance address" },
            ... = { type = "any: positional arguments" }
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
            assemblyNameOrImage = { validate = function(v) return validators.isPositiveInteger(v) or validators.isNonBlankString(v) end },
            className = { validate = validators.isNonBlankString },
            optional_namespace = { type = "string" },
            optional_getParents = { type = "boolean" }
        },
        code = function(self, args)
            local assemblyNameOrImage = args.assemblyNameOrImage
            local className = args.className
            local optional_namespace = args.optional_namespace
            local optional_getParents = args.optional_getParents

            alce.debug('alce.mono.Class.new(): attempting to get "', className, optional_getParents and '" with parents' or '"')

            local id = mono_plumbing.getClass({
                assemblyNameOrImage = assemblyNameOrImage,
                className = className,
                optional_namespace = optional_namespace
            })

            if not validators.isAddresslike(id) then
                alce.warn('alce.mono.Class.new(): failed to find class: ' .. tostring(className))
                return nil
            end

            local hierarchy = mono_plumbing.class_getParentHierarchy({ classID = id })
            local methods = mono_plumbing.getProcessedMethods({
                classID = id,
                optional_getParents = optional_getParents,
                optional_hierarchy = hierarchy,
                optional_keepMetadata = true
            })

            if not methods then
                alce.warn('alce.mono.Class.new(): failed to get methods: ' .. tostring(className))
                return nil
            end

            local fields = mono_plumbing.getProcessedFields({
                classID = id,
                optional_getParents = optional_getParents,
                optional_hierarchy = hierarchy,
                optional_keepMetadata = true
            })

            if not fields then
                alce.warn('alce.mono.Class.new(): failed to get fields: ' .. tostring(className))
                return nil
            end

            local instance = {
                id = id,
                namespace = optional_namespace,
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
    })
}

return mono
