--- ## stuff I'm not using but wanted to keep around for reference

--- probably wont work out-of-the-box with alce due to refactors etc

--- untested
function alce.mono.value_box(classID, valuePtr, optional_allocatedMemory) --> address: MonoObject
    assert(not mono_isil2cpp(), 'alce.mono.value_box(): not implemented for IL2CPP; mono only.')
    alce.debug("alce.mono.value_box(): called with classID: " .. tostring(classID) .. ", valuePtr: " .. tostring(valuePtr))
    assert(alce.util.isAddresslike(classID), 'alce.mono.value_box(): invalid argument: classID')
    assert(alce.util.isAddresslike(valuePtr), 'alce.mono.value_box(): invalid argument: valuePtr')
    assert(optional_allocatedMemory == nil or alce.util.isAddresslike(optional_allocatedMemory), 'invalid argument: optional_allocatedMemory')
    local m = optional_allocatedMemory or allocateMemory(1024)
    local aa_string = ([[
      0x%X:
      //{$TRY} bugged in 7.6
        sub rsp,28
      // setup
        call mono_get_root_domain
        mov rcx,rax
        mov [monodomain],rax
        call mono_thread_attach
        mov [monothread],rax
      // pass the args to mono_value_box(MonoDomain *domain, MonoClass *klass, gpointer value)
        mov rcx,[monodomain]
        mov rdx,0x%X
        mov r8,0x%X
        call mono_value_box
        mov r13,rax
      // cleanup
        mov rcx,[monothread]
        call mono_thread_detach
      //{$EXCEPT} bugged in 7.6
        add rsp,28
        mov rax,r13
        ret
      // storage
      monodomain:
        dq 0
      monothread:
        dq 0
        align 10,CC
    ]]):format(m, classID, valuePtr)
    assert(autoAssemble(aa_string), 'alce.mono.value_box(): failed to assemble code; unexpected error')
    local boxed_object = executeCodeEx(0, 1000, m)
    if not optional_allocatedMemory then
        deAlloc(m)
    end
    return boxed_object
end

--- works but idk why you would... You probably don't want this; other abstractions in monoscript already use it and unbox the value for you.
function alce.mono.field_get_value_object(fieldID, optional_allocatedMemory) --> address: MonoObject
    assert(not mono_isil2cpp(), 'alce.mono.field_get_value_object(): not implemented for IL2CPP; mono only.')
    alce.debug("alce.mono.field_get_value_object(): called with ID: " .. tostring(fieldID))
    assert(alce.util.isAddresslike(fieldID), 'alce.mono.field_get_value_object(): invalid argument: fieldID')
    assert(optional_allocatedMemory == nil or alce.util.isAddresslike(optional_allocatedMemory), 'invalid argument: optional_allocatedMemory')
    local m = optional_allocatedMemory or allocateMemory(1024)
    local aa_string = ([[
      0x%X:
      //{$TRY} bugged in 7.6
        sub rsp,28
      // setup
        call mono_get_root_domain
        mov rcx,rax
        mov [monodomain],rax
        call mono_thread_attach
        mov [monothread],rax
      // pass the args mono_field_get_value_object
        mov rcx,[monodomain]
        mov rdx,0x%X
        mov r8,monoobject
        call mono_field_get_value_object
        mov r13,rax
      // cleanup
        mov rcx,[monothread]
        call mono_thread_detach
      //{$EXCEPT} bugged in 7.6
        add rsp,28
        mov rax,r13
        ret
      // storage
      monodomain:
        dq 0
      monothread:
        dq 0
      monoobject:
        dq 0
        align 10,CC
    ]]):format(m, fieldID)
    assert(autoAssemble(aa_string), 'alce.mono.field_get_value_object(): failed to assemble code; unexpected error')
    local enum_object = executeCodeEx(0,1000,m)
    if not optional_allocatedMemory then
        deAlloc(m)
    end
    return enum_object
end



--- Deep-copy a lua object; taken from [tylerneylon's gist](https://gist.github.com/tylerneylon/81333721109155b2d244)
function alce.deepCopy(obj, internal_seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if internal_seen and internal_seen[obj] then return internal_seen[obj] end
    -- New table; mark it as seen and copy recursively.
    local s = internal_seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[alce.deepCopy(k, s)] = alce.deepCopy(v, s) end
    return setmetatable(res, getmetatable(obj))
end



--[[{
    Turn a table's key strings into global variables.
    > **Example Usage**
    > ```lua
    > local tbl = { ['x'] = 3, ['y'] = 2 }
    > alce.globalize(tbl, true)
    > assert(x+y == 5)
    > ```
--}]]
function alce.globalize(tbl, optional_overwrite)
    for k,v in pairs(tbl) do
        if type(k) == 'string' then
            if optional_overwrite == true or _G[k] == nil then _G[k] = v end
        else alce.warn('alce.globalize(): skipping non-string key: ' .. tostring(k)) end
    end
end

--- The opposite of globalize: nil's global variables by the table's key strings
function alce.deglobalize(tbl)
    for k,_ in pairs(tbl) do
        if type(k) == 'string' then _G[k] = nil
        else alce.warn('alce.deglobalize(): skipping non-string key: ' .. tostring(k)) end
    end
end



