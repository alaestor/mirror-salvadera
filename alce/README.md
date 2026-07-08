---
include_toc: true
---

# ALCE Library Documentation

## alce

# libALCE
**Alaestor's Cheat Engine Library**
Intended to be used in the table's lua script, or parted out as needed.

### alce.T

A convenient table that can be indexed by CE vartype value (`vtDword`), basic type string (`'dword'`), or CE vartype string (`'vtDword'`) to get a corresponding `alce.vt.VTypeHelper`. Useful for quick conversions, creating arguments, or doing type-appropriate reads/writes programmatically.
Example usage:
```lua
-- read and write values
local x = alce.T[vtDword]:read(x_addr)
alce.T[vtDword]:write(y_addr, x)
-- easy conversions
local t = alce.T.(something.type)
print('The type is ' .. t.name) -- basic lowercase type name without the vartype `vt` prefix
assert(alce.T[t.name] == alce.T[t.vType])
print('That type is used for the following monotypes: ' .. alce.fmt.table(t:getMonotypes)) -- prints integer
-- creating `{type=,value=}` dict pairs (calling is just a shorthand for `asInvokeArgument`)
invoke(method, {
alce.T[vtPointer]:asInvokeArgument(instance),
alce.T[vtString]('my string'), -- lookup by vartype integer ID
alce.T['single'](3.14159), -- lookup by basic type name
alce.T['vtSingle'](6.28318) -- lookup by vartype string
})
```

#### alce.T.1

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.2

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.3

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.4

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.5

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.0

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.byte

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.qword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.T.unsafeFromMono

returns a VTypeHelper from a monoType, with a warning if it exceeds the lookup key limit

**Returns:** `VTypeHelper`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| monoType | rough type | Yes |  any - the monoType to convert from |


#### alce.T.dword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.12

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtDouble

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtWord

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtSingle

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtByte

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtPointer

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.T.fromMono

returns a VTypeHelper from a monoType with a bounds-checking assertion

**Returns:** `VTypeHelper`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| monoType | rough type | Yes |  any - the monoType to convert from |


#### alce.T.single

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtDword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.double

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.vtQword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.word

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

#### alce.T.pointer

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.monoscript

Collection related to global constants defined in CE's `monoscript.lua`
Groups:
- `monotype`
- `fieldAttribute`
- `methodAttribute`
Each group's dict contains the string `prefix` of the global constants, an array of `names` and a `nameLookup` dict of names keyed by their value.
Note: For each name string, you can get its value by `_G[name]`. For some monoTypes, `monoscript.lua` provides C-style type names via `monoTypeToCStringLookup[name]`

### alce.cfg

### ALCE Configuration
These global config options can be set from anywhere at any time. Some functions, such as `isAddress`, have optional parameter overrides.
About magic numbers:
- `isAddress_userspaceBoundary32` defaults to a "3g split"; set `0x7FFFFFFF` for 2GB
- `isOffset_tooFarBoundary` expects offsets to be < 4096 bytes
- `isAddress_userspaceBoundary64` is a number that came to me in a dream

**Default Values:**

```lua
debug_print = false
isAddress_nearNullBoundary = 65535  (integer: 0xFFFF)
isAddress_userspaceBoundary32 = 3221225471  (integer: 0xBFFFFFFF)
isAddress_userspaceBoundary64 = 140737488355327  (integer: 0x7FFFFFFFFFFF)
isOffset_tooFarBoundary = 4096  (integer: 0x1000)
monotype_max_key = 29  (integer: 0x1D)
warn_print = true
```

### alce.src.fmt.titleCase

string: "title case" -> "Title Case"

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| str | string | Yes |  the string to title case |


### alce.src.fmt.sanitizeSymbolName

string: the input string with non-alphanumeric replaced with underscores

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| str | string | Yes |  the string to sanitize |


### alce.src.fmt.table

string: the human-readable representation of the table

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  the table to represent as a string |
| useDontSortKeys | boolean | No |  whether to avoid sorting keys |
| internal_depth | number | No |  internal depth counter |
| useDontToString | boolean | No |  whether to avoid using the table's __tostring method |
| internal_path | string | No |  internal path tracker |
| internal_seen | table | No |  internal table for tracking circular references |
| useKeysToIgnore | table | No |  keys to exclude from the representation |
| useDepthLimit | number | No |  the maximum depth of recursion |


### alce.src.fmt.pretty

string: single line, unless value is a table and usePrintFullTable is true.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| usePrintFullTable | boolean | No |  whether to print the full table if value is a table |
| value | any | Yes |  the value to format |


### alce.src.fmt.address

string: `alce.fmt.hex(value, true, false)` padded to address length

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | number | Yes |  the numeric value to convert to address |


### alce.src.fmt.binary

string: `0b` prefixed big-endien binary string representation in groups of 8

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| useDouble | boolean | No |  whether to use double precision |
| useNativeEndian | boolean | No |  whether to use native endianness |
| value | number | Yes |  the numeric value to convert to binary |


### alce.src.fmt.hex

string: 0x prefixed hexadecimal string representation

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| useNativeEndian | boolean | No |  whether to use native endianness |
| withPadding | boolean | No |  whether to include leading zeros for padding |
| value | number | Yes |  the numeric value to convert to hex |


### alce.src.printers.prettyprint

pretty-stringifies, concatenates, and prints input

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.debug

print message with source linenumber only if alce.cfg.debug_print is `true`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.inspect

Prints the table formatted by fmt.table

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  |
| optional_title | string|nil | No |  |


### alce.src.printers.warn

print message with source linenumber only if alce.cfg.warn_print is `true`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.inspectKeys

print a sorted array of the table's keys

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  |
| optional_title | string|nil | No |  |


### alce.src.memory.AllocateSymbols_register

void: Registers symbols defined in a context, optionally filtered by a list of names.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| context | table | Yes |  context containing symbols and registration state |
| names | table | No |  optional list of names to register |


### alce.src.memory.AllocateSymbols_unregister

void: Unregisters symbols defined in a context, optionally filtered by a list of names.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| context | table | Yes |  context containing symbols and registration state |
| names | table | No |  optional list of names to unregister |


### alce.src.memory.AllocateSymbols

Allocates contiguous memory aliased by name calculated by type size and provides easy read/write access to them. Also lets you register/unregister the names as global symbols with an optional prefix.
> **Note:** the registered symbols will have all non-alphanumeric characters replaced with underscores. Symbols will be registered by default at creation unless you the optional parameter `doNotRegister` is true.
Exposes methods `register(names)` and `unregister(names)`. `names` may be nil or an array of valid and unprefixed names. If nil, the functions perform the action for all symbols for all symbols not already registered/unregistered.
The object also exposes internal state through __ prefixed keys. You probably shouldn't write to these but I'm a line of documentation, not a cop.
- `__size` - the total size of the memory region in bytes.
- `__memory` - base address of the memory region.
- `__names` - array of names as they would be accessed for reading/writing.
- `__symbolPrefix` - the string to be prefixed to names when registering and unregistering symbols.
- `__symbolNames` - dict of names to (optionally-prefixed) symbol names as they would be globally registered.
- `__addresses` - dict of name keys to integer addresses in the memory region.
- `__types` - dict of name string keys to alce.vt.VTypeHelper objects.
- `__registered` - dict of names to registered symbolnames; presense in table means that the symbols are registered.
Example usage:
```lua
-- this is important, and it should be global to persist state.
region = region or MemoryRegion({
alce.T[vtDword]('level'), -- or { type = vtDword, name = 'level' },
alce.T[vtSingle]('health'),
},{
doNotRegister = true,
symbolPrefix = 'PTR_'
})
[ENABLE]
-- write to aliased memory by using the unprefixed names
region.level = 99
region.health = 100.0
assert(region:register(), 'failed: already registered?') -- manually, since we set `doNotRegister`
-- access the registered CE symbols from anywhere
print(string.format('health is stored at address: 0x%X', PTR_health))
-- get type information from an internal table (VTypeHelper)
print('level is a ' .. region.__types['health'].name)
[DISABLE]
-- read from aliased memory
print('ending health: ', region.health)
region:unregister()
```

**Returns:** `table`:  proxy object providing access to allocated memory

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| packets | table | Yes |  list of packets defining memory layout {type, value} |
| doNotRegister | boolean | No |  if true, symbols aren't registered on creation |
| baseAddress | address | No |  optional specific address to allocate at |
| symbolPrefix | string | No |  prefix added to registered symbol names |
| protection | boolean | No |  optional memory protection setting |


## alce.src.vt

a table of various CE type helpers. They can be useful on their own, but they mainly exist to be utilized by the user-friendly `alce.vt.VTypeHelper` instances in `alce.T`
- `vt.typeStrings`: array of CE type strings (e.g. string 'vtByte', 'vtDword', 'vtPointer')
- `vt.size`: dict mapping CE's vt types and their respective sizes in bytes (accounts for 32/64bit processes; no support for 16bit addressing)
- `vt.read`: dict mapping CE's vt types and their respective read functions (e.g. [vdDword] is readInteger)
- `vt.write`: mapping of CE's vt types and their respective write functions (e.g. [vdDword] is writeInteger)

### alce.src.vt.VTypeHelper

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.vt.VTypeHelper.new

creates a new VType helper

**Returns:** `VTypeHelper`:  the created VType helper

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| basicTypeString | string | Yes |  the name of the type without prefix (e.g. 'dword') |


### alce.src.vt.VTypeHelper.read

reads a value from the specified address using the VType

**Returns:** `any`:  the value read from the address

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| address | number | Yes |  the address to read from |


### alce.src.vt.VTypeHelper.getMonotypes

returns the monotypes associated with the VType

**Returns:** `table`:  array of monotype integers

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.vt.VTypeHelper.write

writes a value to the specified address using the VType

**Returns:** `boolean`:  whether the write succeeded

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to write |
| address | number | Yes |  the address to write to |


### alce.src.vt.VTypeHelper.asInvokeArgument

formats the VType and a value for invoking methods

**Returns:** `table`:  a table containing the vType and value for invoke

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to wrap |


### alce.src.vt.VTypeHelper.getMonotypesAsStrings

returns a sorted array of strings representing the monotypes

**Returns:** `table`:  array of monotype name strings

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.validators.isCallable

any: checks if value is callable

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isPositiveInteger

any: checks if value is a positive integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isTable

any: checks if value is a table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isNonBlankString

any: checks if value is a non-blank string

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isFloat

any: checks if value is a float

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isInteger

any: checks if value is an integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isSignedOffsetlike

any: checks that the value isInteger and within positive and negative tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tooFarBoundary | number | No |  the boundary value |
| value | any | Yes |  the value to check |


### alce.src.validators.check

any: passthru assert with source line (checks positive, e.g. assert(value) or assert(checker(value)))

**Returns:** `any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| checker | any | No |  the checker function |
| value | any | Yes |  the value to check |


### alce.src.validators.isFiniteNumber

any: checks if value is a finite number

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.hasFlag

any: equivalent to (flags & flag) == flag

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| flags | number | Yes |  the bit-flags to check |
| flag | number | Yes |  the flag to check for |


### alce.src.validators.isAddresslike

any: checks that the value isInteger and greater than nearNullBoundary (or alce.cfg.isAddress_nearNullBoundary) and less than userspaceBoundary (or alce.cfg.isAddress_userspaceBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| nearNullBoundary | number | No |  the near-null boundary |
| userspaceBoundary | number | No |  the userspace boundary |
| value | any | Yes |  the value to check |


### alce.src.validators.isNonNegativeFloat

any: checks if value is a non-negative float

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.ncheck

any: passthru negation-assert with source line (checks negative, e.g. assert(not value) or assert(not checker(value)))

**Returns:** `any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| checker | any | No |  the checker function |
| value | any | Yes |  the value to check |


### alce.src.validators.isNonNegativeInteger

any: checks if value is a non-negative integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isBetween

any: checks if value is between minimum and maximum

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| minimum | number | Yes |  the minimum value |
| maximum | number | Yes |  the maximum value |
| value | any | Yes |  the value to check |


### alce.src.validators.isOffsetlike

any: checks that the value isNonNegativeInteger and less than tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tooFarBoundary | number | No |  the boundary value |
| value | any | Yes |  the value to check |


### alce.src.validators.isNonEmptyString

any: checks if value is a non-empty string

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isNonEmptyTable

any: checks if value is a non-empty table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isEmptyTable

any: checks if value is an empty table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.validators.isZeroEmptyOrNil

any: checks if value is zero, empty table, blank string, or nil

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | Yes |  the value to check |


### alce.src.mono_t.List.iterator

Returns an iterator which returns the value of the list item from first to end.

**Returns:** `function`:  an iterator over the list

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| first | offset | No |  starting index |
| last | offset | No |  ending index |


### alce.src.mono_t.List.size

Returns the number of items in the list.

**Returns:** `integer`:  the number of items in the list

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.new

Creates a new T.List representation at the given baseAddress.

**Returns:** `T.List`:  a new T.List instance

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| indexBy | offset | No |  index increment |
| baseAddress | address | Yes |  the base address |
| offsetSize | offset | No |  offset to size |
| indexFrom | offset | No |  starting index |
| offsetItems | offset | No |  offset to items |


### alce.src.mono_t.List.instanceIterator

Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses.

**Returns:** `function`:  an iterator over object instances

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| last | offset | No |  ending index |
| alceClass | table | Yes |  the alce class with an instance method |
| first | offset | No |  starting index |


### alce.src.mono_t.List.newFromChain

Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`

**Returns:** `T.List`:  a new T.List instance

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.atUnsafe

Returns address of the Nth element at index (starting from zero) without bounds checking.

**Returns:** `address`:  the address of the Nth element

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| index | integer | Yes |  the index of the element |


### alce.src.mono_t.List.at

Returns address of the Nth element at index (starting from zero) with bounds checking.

**Returns:** `address`:  the address of the Nth element

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| index | integer | Yes |  the index of the element |


### alce.src.utils.safeChain

reads a chain of pointers and asserts the resulting address isAddressLike

**Returns:** `address`:  the resulting address

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| offsets | number... | No |  a sequence of offsets to follow |
| pointer | address | Yes |  the starting address to read from |


### alce.src.utils.prune

recursively nils keys with empty tables

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  the table to prune |


### alce.src.utils.enumerate

enumerates an iterator, providing an index starting from startFrom

**Returns:** `integer, any`:  the current index and the value from the iterator

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| startFrom | number | No |  the index to start from (defaults to 1) |
| iterator | function | Yes |  the iterator to enumerate |


### alce.src.utils.readPointerChain

reads a chain of pointers starting from the given pointer and following the provided offsets

**Returns:** `address|nil`:  the resulting address if successful, otherwise nil

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| offsets | number... | No |  a sequence of offsets to follow |
| pointer | address | Yes |  the starting address to read from |


### alce.src.utils.extend

assigns k,v pairs from one table to another, asserting that the keys do not already exist

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| to | table | Yes |  the destination table |
| from | table | Yes |  the source table |


### alce.src.utils.unsafeExtend

assigns k,v pairs from one table to another, silently overwriting duplicate keys

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| to | table | Yes |  the destination table |
| from | table | Yes |  the source table |


### alce.src.utils.keyFromValue

returns the first key associated with a given value

**Returns:** `any|nil`:  the first key associated with the value, or nil if not found

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  the table to search in |
| value | any | Yes |  the value to search for |


### alce.src.utils.keysFromValue

returns an array of all keys associated with a given value

**Returns:** `table|nil`:  a sorted array of keys associated with the value, or nil if none

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  the table to search in |
| value | any | Yes |  the value to search for |


## alce.src.t

A convenient table that can be indexed by CE vartype value (`vtDword`), basic type string (`'dword'`), or CE vartype string (`'vtDword'`) to get a corresponding `alce.vt.VTypeHelper`. Useful for quick conversions, creating arguments, or doing type-appropriate reads/writes programmatically.
Example usage:
```lua
-- read and write values
local x = alce.T[vtDword]:read(x_addr)
alce.T[vtDword]:write(y_addr, x)
-- easy conversions
local t = alce.T.(something.type)
print('The type is ' .. t.name) -- basic lowercase type name without the vartype `vt` prefix
assert(alce.T[t.name] == alce.T[t.vType])
print('That type is used for the following monotypes: ' .. alce.fmt.table(t:getMonotypes)) -- prints integer
-- creating `{type=,value=}` dict pairs (calling is just a shorthand for `asInvokeArgument`)
invoke(method, {
alce.T[vtPointer]:asInvokeArgument(instance),
alce.T[vtString]('my string'), -- lookup by vartype integer ID
alce.T['single'](3.14159), -- lookup by basic type name
alce.T['vtSingle'](6.28318) -- lookup by vartype string
})
```

### alce.src.t.1

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.2

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.3

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.4

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.5

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.0

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.byte

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.qword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.unsafeFromMono

returns a VTypeHelper from a monoType, with a warning if it exceeds the lookup key limit

**Returns:** `VTypeHelper`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| monoType | rough type | Yes |  any - the monoType to convert from |


### alce.src.t.dword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.12

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtDouble

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtWord

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtSingle

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtByte

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtPointer

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.fromMono

returns a VTypeHelper from a monoType with a bounds-checking assertion

**Returns:** `VTypeHelper`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| monoType | rough type | Yes |  any - the monoType to convert from |


### alce.src.t.single

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtDword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.double

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.vtQword

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.word

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.t.pointer

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

## alce.src.mono

Mono porcelain helpers for ergonomic interaction with Mono types.

### alce.src.mono.Class

A representation of a mono class type which will fetch, sort, and process its methods and fields into appropriate subtables.

### alce.src.mono.Class.new

creates a new mono class instance

**Returns:** `Class`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| getParents | boolean | No |  whether to get parents |
| assemblyNameOrImage | unknown | Yes |  |
| namespace | string | No |  the namespace of the mono class |
| className | unknown | Yes |  |


### alce.src.mono.Class.instance

creates a proxy object (ObjectAlias) for an instance of this class

**Returns:** `ObjectAlias`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| baseAddress | unknown | Yes |  |


### alce.src.mono.Class.instanceFrom

convenient shorthand for self:instance(alce.safeChain(...))

**Returns:** `ObjectAlias`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.T.List.iterator

Returns an iterator which returns the value of the list item from first to end.

**Returns:** `function`:  an iterator over the list

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| first | offset | No |  starting index |
| last | offset | No |  ending index |


### alce.src.mono.T.List.size

Returns the number of items in the list.

**Returns:** `integer`:  the number of items in the list

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.T.List.new

Creates a new T.List representation at the given baseAddress.

**Returns:** `T.List`:  a new T.List instance

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| indexBy | offset | No |  index increment |
| baseAddress | address | Yes |  the base address |
| offsetSize | offset | No |  offset to size |
| indexFrom | offset | No |  starting index |
| offsetItems | offset | No |  offset to items |


### alce.src.mono.T.List.instanceIterator

Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses.

**Returns:** `function`:  an iterator over object instances

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| last | offset | No |  ending index |
| alceClass | table | Yes |  the alce class with an instance method |
| first | offset | No |  starting index |


### alce.src.mono.T.List.newFromChain

Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`

**Returns:** `T.List`:  a new T.List instance

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.T.List.atUnsafe

Returns address of the Nth element at index (starting from zero) without bounds checking.

**Returns:** `address`:  the address of the Nth element

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| index | integer | Yes |  the index of the element |


### alce.src.mono.T.List.at

Returns address of the Nth element at index (starting from zero) with bounds checking.

**Returns:** `address`:  the address of the Nth element

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| index | integer | Yes |  the index of the element |


### alce.src.mono.Method

A representation of, and call-abstraction for, mono methods.

### alce.src.mono.Method.new

creates a new mono method instance

**Returns:** `Method`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| methodID | unknown | Yes |  |
| flags | integer | Yes |  the flags of the mono method |
| name | string | Yes |  the name of the mono method |


### alce.src.mono.Method.isStatic

checks if the method is static

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.Method.getAttributes

gets the names of global monoscript.lua constants representing the method attributes

**Returns:** `array`:  the list of `METHOD_ATTRIBUTE_...`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.Method.call

invokes the method after safety checks and argument processing

**Returns:** `any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| ... | any | No |  positional arguments |
| maybe_instance | number | No |  optional instance address |


### alce.src.mono.Method.compile

compiles the method for invocation

**Returns:** `number`:  the compiled address

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.Method.init

initializes a mono method

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| methodID | unknown | Yes |  |
| flags | integer | Yes |  the flags of the mono method |
| name | string | Yes |  the name of the mono method |


### alce.src.mono.Method.callUnsafe

invokes the method without safety checks. Arguments must be in CE's invoke format

**Returns:** `any, string, number`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| maybe_args | table | No |  optional arguments table |
| maybe_instance | number | No |  optional instance address |


### alce.src.mono.init

Helper that asserts the process is attached and tries to launch the mono data collector if it's not connected already.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.ClassTable

A table that loads and holds the mono classes you specify, associated by name, in the form of alce.mono.Class

### alce.src.mono.ClassTable.unload

unloads the class table

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.ClassTable.new

creates a new mono class table instance

**Returns:** `ClassTable`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| keyPrefixNamespace | string | Yes |  prefix for namespace names |
| keyPrefixAssembly | string | Yes |  prefix for assembly names |


### alce.src.mono.ClassTable.add

accepts explicit add({ {image, class[, namespace]}, ... })

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| targets | table | Yes |  list of targets to add |


### alce.src.mono.ClassTable.clear

clears the target list and unloads if necessary

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.ClassTable.loadWithParents

convenience shorthand for self:load({ getParents = true })

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono.ClassTable.load

loads the classes specified in the target list

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| getParents | boolean | No |  whether to get parents |


### alce.src.mono.ClassTable.addFromImage

convenience abstraction: addFromImage(image, (class | {class, namespace}), ...)

**Returns:** `self`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| targets | table | Yes |  list of targets |
| image | unknown | Yes |  |


### alce.src.mono.ClassTable.isLoaded

checks if the class table is loaded

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_plumbing.getClassEx

finds a class by name in a specific assembly and namespace

**Returns:** `table|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| assemblyNameOrImage | unknown | Yes |  |
| namespace | string | No |  |
| className | unknown | Yes |  |


### alce.src.mono_plumbing.ObjectAlias

creates a proxy object for a mono object

**Returns:** `proxy object`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| alceClass | unknown | Yes |  |
| baseAddress | unknown | Yes |  |


### alce.src.mono_plumbing.getProcessedMethods

enumerates and processes methods for a class

**Returns:** `table|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| getParents | unknown | No |  |
| hierarchy | unknown | No |  |
| classID | unknown | Yes |  |


### alce.src.mono_plumbing.sortByHierarchy

sorts an array of members by parent hierarchy, from parent to child

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| array | table | Yes |  |
| hierarchy | unknown | Yes |  |


### alce.src.mono_plumbing.getClass

returns the class handle for a given class

**Returns:** `number|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| assemblyNameOrImage | any | Yes |  |
| namespace | string | No |  |
| className | string | Yes |  |


### alce.src.mono_plumbing.getImage

gets Image by assemblyName

**Returns:** `number|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| assemblyName | string | Yes |  |
| enumeratedAssemblies | unknown | No |  |


### alce.src.mono_plumbing.method_getSignature

returns the signature of a method

**Returns:** `table`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| methodID | unknown | Yes |  |
| methodName | string | No |  |


### alce.src.mono_plumbing.class_getParentHierarchy

returns array of class IDs ordered from parent to child

**Returns:** `table`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| classID | unknown | Yes |  |


### alce.src.mono_plumbing.invoke

invokes a mono method

**Returns:** `any|nil, string|nil, string|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_plumbing.init

initializes mono state

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_plumbing.getProcessedFields

enumerates and processes fields for a class

**Returns:** `table|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| getParents | boolean | No |  |
| hierarchy | unknown | No |  |
| keepFields | boolean | No |  |
| keepMetadata | boolean | No |  |
| classID | any | Yes |  |


## alce.src.monoscript

Collection related to global constants defined in CE's `monoscript.lua`
Groups:
- `monotype`
- `fieldAttribute`
- `methodAttribute`
Each group's dict contains the string `prefix` of the global constants, an array of `names` and a `nameLookup` dict of names keyed by their value.
Note: For each name string, you can get its value by `_G[name]`. For some monoTypes, `monoscript.lua` provides C-style type names via `monoTypeToCStringLookup[name]`

## alce.src.cheat_table

Hooks `onMemRecPreExecute` and `onMemRecPostExecute` in order to provide the following:
- `alce.THIS`: The MemoryRecord of the the script currently executing. Only be valid during the time an enable/disable script is being run from the cheat table: it's invalid during syntax check and running via the 'execute' button.
- `alce.LAST_SUCCESS`: The MemoryRecord of the last script to succeed execution. Only valid after a table script has successfully run. Doesn't count scripts run from the 'execute' button.
- `alce.LAST_FAILURE`: The memoryRecord of the last script to fail execution. Only valid after a table script has failed to run. Doesn't count scripts run from the 'execute' button.

### alce.src.cheat_table.clearChildrenByDesc

finds the MR by description then calls alce.cheattable.clearChildren

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| addressList | AddressList | No |  optional address list to search in |
| desc | string | Yes |  the description of the memory record to find |


### alce.src.cheat_table.clearChildren

destroy's all children of the given memoryRecord

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| memoryRecord | MemoryRecord | Yes |  the memory record whose children should be destroyed |


### alce.src.cheat_table.createHeader

Creates a new Group Header MemoryRecord

**Returns:** `MemoryRecord`:  the newly created MemoryRecord

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| showCollapseButtons | boolean | No |  whether to show collapse buttons on the header |
| parent | MemoryRecord | No |  the parent memory record to attach the new header to |
| description | string | No |  the description of the new header |
| saveToTable | boolean | No |  whether the created header should be saved to the table |


### alce.src.cheat_table.createRecord

Creates a new MemoryRecord and attaches it to `parent`. `address` may be an integer or a string. `offsets` may be an array of integer offsets from `address` such as `{ 0x10, ... }`. `saveToTable` may be a boolean; children created from this function aren't saved by default.
`dropDownSettings` is a dict which if not nil must at minimum contain an either an `optionsFrom` string containing the description string from another dropdown MR, or an `options` string formatted as newline-separated pairs e.g. `"value:desc\n..."`. You may optionally provide `noManualInput` `hideNumbers`, and `dontDisplayAsString` booleans.
Example usage, creating a pointer+offsets MR with a dropdown menu:
```lua
local ddsettings = {
options = '0:disabled\n1:normal\n2:overclocked',
--optionsFrom = "some other MR description", -- if we already set one up and didn't want to duplicate...
noManualInput = true,
hideNumbers = true,
--dontDisplayAsString = false -- displays MR value as dropdown string by default
}
local newmr = alce.cheattable.createRecord({
parent = alce.THIS,
description = 'mode',
vtype = vtByte,
address = baseaddr,
offsets = {stateOffset, modeOffset},
dropDownSettings = ddsettings
})
print('the address of mode is ' .. newmr.AddressString)
```

**Returns:** `MemoryRecord`:  the newly created MemoryRecord

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| dropDownSettings | table | No |  dropdown settings (options or optionsFrom) |
| saveToTable | boolean | No |  whether the created record should be saved to the table |
| offsets | table | No |  an array of integer offsets from address |
| vtype | value type | No |  the value type of the new memory record (e.g., vtByte, vtDword) |
| parent | MemoryRecord | No |  the parent memory record to attach the new record to |
| description | string | No |  the description of the new memory record |
| address | address | No |  the memory address or address-like string |


### alce.src.cheat_table.disableAfterSuccess

Makes disableWithoutExecute() be called on the next MemoryRecord script that runs successfully.
Can be used at the bottom of an [ENABLE] section to turn a script into a momentary button rather than toggle.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| disableBeep | boolean | No |  whether to disable the beep when the script runs successfully |


