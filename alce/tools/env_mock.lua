-- Mocking layer for Cheat Engine API to allow standalone Lua execution of ALCE.
-- This file should be required before any ALCE modules.

--- Variable types from CE's defines.lua
_G.vtByte=0
_G.vtWord=1
_G.vtDword=2
_G.vtQword=3
_G.vtSingle=4
_G.vtDouble=5
_G.vtString=6
_G.vtUnicodeString=7 --Only used by autoguess
_G.vtWideString=7
_G.vtByteArray=8
_G.vtBinary=9
_G.vtAll=10
_G.vtAutoAssembler=11
_G.vtPointer=12 --Only used by autoguess and structures
_G.vtCustom=13
_G.vtGrouped=14

--- Global constants from CE's monoscript.lua
_G.MONO_TYPE_END        = 0x00       -- End of List
_G.MONO_TYPE_VOID       = 0x01
_G.MONO_TYPE_BOOLEAN    = 0x02
_G.MONO_TYPE_CHAR       = 0x03
_G.MONO_TYPE_I1         = 0x04
_G.MONO_TYPE_U1         = 0x05
_G.MONO_TYPE_I2         = 0x06
_G.MONO_TYPE_U2         = 0x07
_G.MONO_TYPE_I4         = 0x08
_G.MONO_TYPE_U4         = 0x09
_G.MONO_TYPE_I8         = 0x0a
_G.MONO_TYPE_U8         = 0x0b
_G.MONO_TYPE_R4         = 0x0c
_G.MONO_TYPE_R8         = 0x0d
_G.MONO_TYPE_STRING     = 0x0e
_G.MONO_TYPE_PTR        = 0x0f       -- arg: <type> token
_G.MONO_TYPE_BYREF      = 0x10       -- arg: <type> token
_G.MONO_TYPE_VALUETYPE  = 0x11       -- arg: <type> token
_G.MONO_TYPE_CLASS      = 0x12       -- arg: <type> token
_G.MONO_TYPE_VAR         = 0x13          -- number
_G.MONO_TYPE_ARRAY      = 0x14       -- type, rank, boundsCount, bound1, loCount, lo1
_G.MONO_TYPE_GENERICINST= 0x15          -- <type> <type-arg-count> <type-1> \x{2026} <type-n> */
_G.MONO_TYPE_TYPEDBYREF = 0x16
_G.MONO_TYPE_I          = 0x18
_G.MONO_TYPE_U          = 0x19
_G.MONO_TYPE_FNPTR      = 0x1b          -- arg: full method signature */
_G.MONO_TYPE_OBJECT     = 0x1c
_G.MONO_TYPE_SZARRAY    = 0x1d       -- 0-based one-dim-array */
_G.MONO_TYPE_MVAR       = 0x1e       -- number */
_G.MONO_TYPE_CMOD_REQD  = 0x1f       -- arg: typedef or typeref token */
_G.MONO_TYPE_CMOD_OPT   = 0x20       -- optional arg: typedef or typref token */
_G.MONO_TYPE_INTERNAL   = 0x21       -- CLR internal type */
_G.MONO_TYPE_MODIFIER   = 0x40       -- Or with the following types */
_G.MONO_TYPE_SENTINEL   = 0x41       -- Sentinel for varargs method signature */
_G.MONO_TYPE_PINNED     = 0x45       -- Local var that points to pinned object */
_G.MONO_TYPE_ENUM       = 0x55        -- an enumeration */
_G.monoTypeToVartypeLookup={} --for dissect data
_G.monoTypeToVartypeLookup[MONO_TYPE_BOOLEAN]=vtByte
_G.monoTypeToVartypeLookup[MONO_TYPE_CHAR]=vtUnicodeString --the actual chars...
_G.monoTypeToVartypeLookup[MONO_TYPE_I1]=vtByte
_G.monoTypeToVartypeLookup[MONO_TYPE_U1]=vtByte
_G.monoTypeToVartypeLookup[MONO_TYPE_I2]=vtWord
_G.monoTypeToVartypeLookup[MONO_TYPE_U2]=vtWord
_G.monoTypeToVartypeLookup[MONO_TYPE_I4]=vtDword
_G.monoTypeToVartypeLookup[MONO_TYPE_U4]=vtDword
_G.monoTypeToVartypeLookup[MONO_TYPE_I8]=vtQword
_G.monoTypeToVartypeLookup[MONO_TYPE_U8]=vtQword
_G.monoTypeToVartypeLookup[MONO_TYPE_R4]=vtSingle
_G.monoTypeToVartypeLookup[MONO_TYPE_R8]=vtDouble
_G.monoTypeToVartypeLookup[MONO_TYPE_STRING]=vtPointer --pointer to a string object
_G.monoTypeToVartypeLookup[MONO_TYPE_PTR]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_I]=vtPointer --IntPtr
_G.monoTypeToVartypeLookup[MONO_TYPE_U]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_OBJECT]=vtPointer --object
_G.monoTypeToVartypeLookup[MONO_TYPE_BYREF]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_CLASS]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_FNPTR]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_GENERICINST]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_ARRAY]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_SZARRAY]=vtPointer
_G.monoTypeToVartypeLookup[MONO_TYPE_VALUETYPE]=vtPointer --needed for structs when returned by invoking a method( even though they are not qwords)
_G.monoTypeToCStringLookup={}
_G.monoTypeToCStringLookup[MONO_TYPE_END]='void'
_G.monoTypeToCStringLookup[MONO_TYPE_BOOLEAN]='boolean'
_G.monoTypeToCStringLookup[MONO_TYPE_CHAR]='char'
_G.monoTypeToCStringLookup[MONO_TYPE_I1]='char'
_G.monoTypeToCStringLookup[MONO_TYPE_U1]='unsigned char'
_G.monoTypeToCStringLookup[MONO_TYPE_I2]='short'
_G.monoTypeToCStringLookup[MONO_TYPE_U2]='unsigned short'
_G.monoTypeToCStringLookup[MONO_TYPE_I4]='int'
_G.monoTypeToCStringLookup[MONO_TYPE_U4]='unsigned int'
_G.monoTypeToCStringLookup[MONO_TYPE_I8]='int64'
_G.monoTypeToCStringLookup[MONO_TYPE_U8]='unsigned int 64'
_G.monoTypeToCStringLookup[MONO_TYPE_R4]='single'
_G.monoTypeToCStringLookup[MONO_TYPE_R8]='double'
_G.monoTypeToCStringLookup[MONO_TYPE_STRING]='String'
_G.monoTypeToCStringLookup[MONO_TYPE_PTR]='Pointer'
_G.monoTypeToCStringLookup[MONO_TYPE_BYREF]='Object'
_G.monoTypeToCStringLookup[MONO_TYPE_CLASS]='Object'
_G.monoTypeToCStringLookup[MONO_TYPE_FNPTR]='Function'
_G.monoTypeToCStringLookup[MONO_TYPE_GENERICINST]='<Generic>'
_G.monoTypeToCStringLookup[MONO_TYPE_ARRAY]='Array[]'
_G.monoTypeToCStringLookup[MONO_TYPE_SZARRAY]='String[]'
_G.FIELD_ATTRIBUTE_FIELD_ACCESS_MASK=0x0007
_G.FIELD_ATTRIBUTE_COMPILER_CONTROLLED=0x0000
_G.FIELD_ATTRIBUTE_PRIVATE=0x0001
_G.FIELD_ATTRIBUTE_FAM_AND_ASSEM=0x0002
_G.FIELD_ATTRIBUTE_ASSEMBLY=0x0003
_G.FIELD_ATTRIBUTE_FAMILY=0x0004
_G.FIELD_ATTRIBUTE_FAM_OR_ASSEM=0x0005
_G.FIELD_ATTRIBUTE_PUBLIC=0x0006
_G.FIELD_ATTRIBUTE_STATIC=0x0010
_G.FIELD_ATTRIBUTE_INIT_ONLY=0x0020
_G.FIELD_ATTRIBUTE_LITERAL=0x0040
_G.FIELD_ATTRIBUTE_NOT_SERIALIZED=0x0080
_G.FIELD_ATTRIBUTE_SPECIAL_NAME=0x0200
_G.FIELD_ATTRIBUTE_PINVOKE_IMPL=0x2000
_G.FIELD_ATTRIBUTE_RESERVED_MASK=0x9500
_G.FIELD_ATTRIBUTE_RT_SPECIAL_NAME=0x0400
_G.FIELD_ATTRIBUTE_HAS_FIELD_MARSHAL=0x1000
_G.FIELD_ATTRIBUTE_HAS_DEFAULT=0x8000
_G.FIELD_ATTRIBUTE_HAS_FIELD_RVA=0x0100
_G.METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK      =0x0007
_G.METHOD_ATTRIBUTE_COMPILER_CONTROLLED     =0x0000
_G.METHOD_ATTRIBUTE_PRIVATE                 =0x0001
_G.METHOD_ATTRIBUTE_FAM_AND_ASSEM           =0x0002
_G.METHOD_ATTRIBUTE_ASSEM                   =0x0003
_G.METHOD_ATTRIBUTE_FAMILY                  =0x0004
_G.METHOD_ATTRIBUTE_FAM_OR_ASSEM            =0x0005
_G.METHOD_ATTRIBUTE_PUBLIC                  =0x0006
_G.METHOD_ATTRIBUTE_STATIC                  =0x0010
_G.METHOD_ATTRIBUTE_FINAL                   =0x0020
_G.METHOD_ATTRIBUTE_VIRTUAL                 =0x0040
_G.METHOD_ATTRIBUTE_HIDE_BY_SIG             =0x0080
_G.METHOD_ATTRIBUTE_VTABLE_LAYOUT_MASK      =0x0100
_G.METHOD_ATTRIBUTE_REUSE_SLOT              =0x0000
_G.METHOD_ATTRIBUTE_NEW_SLOT                =0x0100
_G.METHOD_ATTRIBUTE_STRICT                  =0x0200
_G.METHOD_ATTRIBUTE_ABSTRACT                =0x0400
_G.METHOD_ATTRIBUTE_SPECIAL_NAME            =0x0800
_G.METHOD_ATTRIBUTE_PINVOKE_IMPL            =0x2000
_G.METHOD_ATTRIBUTE_UNMANAGED_EXPORT        =0x0008

_G.process = 0x12345678

--- Mocking functions

-- Memory read/write mocks
_G.readInteger = function(addr) return 0 end
_G.readFloat = function(addr) return 0.0 end
_G.readByte = function(addr) return 0 end
_G.writeInteger = function(addr, val) return true end
_G.writeFloat = function(addr, val) return true end
_G.writeByte = function(addr, val) return true end
_G.getAddress = function(addr) return tonumber(addr) or 0 end
_G.getPointerAddress = function(addr) return 0 end
_G.readPointer = function(addr) return 0 end
_G.writePointer = function(addr, val) return true end
_G.readString = function(addr) return "" end
_G.writeString = function(addr, val) return true end
_G.readMemory = function(addr, size) return "" end
_G.writeMemory = function(addr, data) return true end
_G.readSmallInteger = function(addr) return 0 end
_G.readQword = function(addr) return 0 end
_G.readDouble = function(addr) return 0.0 end
_G.readBytes = function(addr, size, signed) return {} end
_G.writeSmallInteger = function(addr, val) return true end
_G.writeQword = function(addr, val) return true end
_G.writeDouble = function(addr, val) return true end
_G.writeBytes = function(addr, data) return true end

-- System mocks
_G.target64Bit = function() return true end
_G.targetIs64Bit = function() return true end
_G.isAttached = function() return true end
_G.getAddressList = function() return { getMemoryRecordByDescription = function() return nil end } end
_G.LaunchMonoDataCollector = function() return true end

-- Mono-specific mocks
_G.mono_isValid = function() return true end
_G.mono_readObject = function() return 0, 0 end
_G.mono_method_getFlags = function(id) return 0 end
_G.mono_method_get_parameters = function(id) return {} end
_G.mono_compile_method = function(id) return 0 end
_G.mono_method_getClass = function(id) return 0 end
_G.mono_class_get_type = function(id) return 0 end
_G.mono_object_unbox = function(obj) return obj end
_G.mono_object_enumValues = function(obj) return nil end
_G.mono_getImageFromAssembly = function(id) return 0 end
_G.mono_image_get_name = function(id) return "mock_image" end
_G.mono_image_enumClassesEx = function(id) return {} end
_G.mono_enumAssemblies = function() return {} end
_G.mono_method_getName = function(id) return "mock_method" end
_G.mono_method_getSignature = function(id) return "", {}, 0 end
_G.mono_method_getFullName = function(id) return "mock_class.mock_method()" end
_G.mono_splitParameters = function(str) return {} end
_G.mono_class_getParent = function(id) return 0 end
_G.mono_class_enumFields = function(id, parents) return {} end
_G.mono_structfields_getStartOffset = function(fields) return 0 end
_G.mono_class_getStaticFieldValue = function(id, field) return 0 end
_G.mono_class_enumMethods = function(id, parents) return {} end
_G.mono_writeObject = function(type, val) return true end

-- Constants
_G.MONOCMD_INVOKEMETHOD = 1
_G.METHOD_ATTRIBUTE_STATIC = 0x01
_G.MONO_TYPE_VALUETYPE = 2

-- Table-based globals
_G.libmono = {
    monopipe = {
        writeByte = function(b) return true end,
        writeQword = function(q) return true end,
        readByte = function() return 0 end,
        readWord = function() return 0 end,
        readString = function(len) return "" end,
    }
}

-- Additional symbols found during scan
_G.monopipe = _G.libmono.monopipe
