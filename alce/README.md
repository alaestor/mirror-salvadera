---
include_toc: true
---

# ALCE Library Documentation

## alce

# libALCE
**Alaestor's Cheat Engine Library**
Intended to be used in the table's lua script, or parted out as needed.

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
warn_print = true
```

### alce.src.memory.AllocateSymbols_unregister

Unregisters symbols defined in a context, optionally filtered by a list of names.

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_names | table | No |  |
| context | table | Yes |  |


### alce.src.memory.AllocateSymbols

Allocates contiguous memory aliased by name calculated by type size and provides easy read/write access to them. Also lets you register/unregister the names as global symbols with an optional prefix.
> **Note:** the registered symbols will have all non-alphanumeric characters replaced with underscores. Symbols will be registered by default at creation unless you the optional parameter `doNotRegister` is true.
Exposes methods `register(optional_names)` and `unregister(optional_names)`. `optional_names` may be nil or an array of valid and unprefixed names. If nil, the functions perform the action for all symbols for all symbols not already registered/unregistered.
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

**Returns:** `table (proxy)`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| packets | table | Yes |  |
| protection | boolean | No |  |
| baseAddress | address | No |  |
| symbolPrefix | string | No |  |
| doNotRegister | boolean | No |  |


### alce.src.memory.AllocateSymbols_register

Registers symbols defined in a context, optionally filtered by a list of names.

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_names | table | No |  |
| context | table | Yes |  |


### alce.src.mono_t.List.new

Creates a new T.List representation at the given baseAddress.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.atUnsafe

Returns address of the Nth element at index (starting from zero) without bounds checking.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.at

Returns address of the Nth element at index (starting from zero) with bounds checking.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.size

Returns the number of items in the list.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.iterator

Returns an iterator which returns the value of the list item from optional_start to optional_end.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.instanceIterator

Convenience method wraps the result of the iterator in `alceClass:instance`, returning object instance aliases rather than addresses.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.mono_t.List.newFromChain

Convenience constructor that returns new T.List that aliases the result from `readPointerChain(...)`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.utils.keyFromValue

returns the first key associated with a given value

**Returns:** `any|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  |
| value | any | Yes |  |


### alce.src.utils.extend

assigns k,v pairs from one table to another, asserting that the keys do not already exist

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| from | table | Yes |  |
| to | table | Yes |  |


### alce.src.utils.keysFromValue

returns an array of all keys associated with a given value

**Returns:** `table|nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  |
| value | any | Yes |  |


### alce.src.utils.unsafeExtend

assigns k,v pairs from one table to another, silently overwriting duplicate keys

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| from | table | Yes |  |
| to | table | Yes |  |


### alce.src.utils.prune

recursively nils keys with empty tables

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| tbl | table | Yes |  |


### alce.src.utils.safeChain

reads a chain of pointers and asserts the resulting address isAddressLike

**Returns:** `address`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| offsets | number... | No |  |
| pointer | address | Yes |  |


### alce.src.utils.enumerate

enumerates an iterator, providing an index starting from optional_startFrom

**Returns:** `integer, any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| startFrom | number | No |  |
| iterator | unknown | Yes |  |


### alce.src.utils.readPointerChain

reads a chain of pointers starting from the given pointer and following the provided offsets

**Returns:** `nil|address`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| offsets | number... | No |  |
| pointer | address | Yes |  |


### alce.src.validators.isFiniteNumber

checks if value is a finite number

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isTable

checks if value is a table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isBetween

checks if value is between minimum and maximum

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| maximum | number | No |  |
| minimum | number | No |  |
| value | any | No |  |


### alce.src.validators.isNonEmptyString

checks if value is a non-empty string

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isNonBlankString

checks if value is a non-blank string

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isEmptyTable

checks if value is an empty table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.ncheck

passthru negation-assert with source line (checks negative, e.g. assert(not value) or assert(not optional_checker(value)))

**Returns:** `any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_checker | any | No |  |
| value | any | No |  |


### alce.src.validators.hasFlag

equivalent to (flags & flag) == flag

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| flag | number | No |  |
| flags | number | No |  |


### alce.src.validators.isNonEmptyTable

checks if value is a non-empty table

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isOffsetlike

checks that the value isNonNegativeInteger and less than optional_tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_tooFarBoundary | number | No |  |
| value | any | No |  |


### alce.src.validators.isNonNegativeFloat

checks if value is a non-negative float

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isAddresslike

checks that the value isInteger and greater than optional_nearNullBoundary (or alce.cfg.isAddress_nearNullBoundary) and less than optional_userspaceBoundary (or alce.cfg.isAddress_userspaceBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_nearNullBoundary | number | No |  |
| optional_userspaceBoundary | number | No |  |
| value | any | No |  |


### alce.src.validators.isNonNegativeInteger

checks if value is a non-negative integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isCallable

checks if value is callable

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isInteger

checks if value is an integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isFloat

checks if value is a float

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isPositiveInteger

checks if value is a positive integer

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.check

passthru assert with source line (checks positive, e.g. assert(value) or assert(optional_checker(value)))

**Returns:** `any`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_checker | any | No |  |
| value | any | No |  |


### alce.src.validators.isZeroEmptyOrNil

checks if value is zero, empty table, blank string, or nil

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any | No |  |


### alce.src.validators.isSignedOffsetlike

checks that the value isInteger and within positive and negative optional_tooFarBoundary (or alce.cfg.isOffset_tooFarBoundary)

**Returns:** `boolean`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_tooFarBoundary | number | No |  |
| value | any | No |  |


### alce.src.printers.prettyprint

pretty-stringifies, concatenates, and prints input

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.inspectKeys

print a sorted array of the table's keys

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_title | string|nil | No |  |
| tbl | table | Yes |  |


### alce.src.printers.warn

print message with source linenumber only if alce.cfg.warn_print is `true`

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.debug

print message with source linenumber only if alce.cfg.debug_print is `true`

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| args | any... | Yes |  |


### alce.src.printers.inspect

Prints the table formatted by fmt.table

**Returns:** `nil`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_title | string|nil | No |  |
| tbl | table | Yes |  |


### alce.src.fmt.pretty

string: single line, unless value is a table and optional_printFullTable is true.

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_printFullTable | boolean | No |  |
| value | any | No |  |


### alce.src.fmt.address

`alce.fmt.hex(value, true, false)` padded to address length

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | number | No |  |


### alce.src.fmt.hex

string: 0x prefixed hexadecimal string representation

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_withPadding | boolean | No |  |
| optional_useNativeEndian | boolean | No |  |
| value | number | No |  |


### alce.src.fmt.table

string: the human-readable representation of the table

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| internal_path | string | No |  |
| tbl | table | No |  |
| optional_depthLimit | number | No |  |
| optional_dontSortKeys | boolean | No |  |
| internal_depth | number | No |  |
| optional_keysToIgnore | table | No |  |
| internal_seen | table | No |  |
| optional_dontToString | boolean | No |  |


### alce.src.fmt.sanitizeSymbolName

string: the input string with non-alphanumeric replaced with underscores

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| str | string | No |  |


### alce.src.fmt.binary

string: `0b` prefixed big-endien binary string representation in groups of 8

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| optional_useDouble | boolean | No |  |
| optional_useNativeEndian | boolean | No |  |
| value | number | No |  |


### alce.src.fmt.titleCase

string: "title case" -> "Title Case"

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| str | string | No |  |


## alce.src.cheat_table

Hooks `onMemRecPreExecute` and `onMemRecPostExecute` in order to provide the following:
- `alce.THIS`: The MemoryRecord of the the script currently executing. Only be valid during the time an enable/disable script is being run from the cheat table: it's invalid during syntax check and running via the 'execute' button.
- `alce.LAST_SUCCESS`: The MemoryRecord of the last script to succeed execution. Only valid after a table script has successfully run. Doesn't count scripts run from the 'execute' button.
- `alce.LAST_FAILURE`: The memoryRecord of the last script to fail execution. Only valid after a table script has failed to run. Doesn't count scripts run from the 'execute' button.

### alce.src.cheat_table.clearChildrenByDesc

finds the MR by description then calls alce.cheattable.clearChildren

**Returns:** `none`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| desc | string | Yes |  the description of the memory record to find |
| addressList | AddressList | No |  optional address list to search in |


### alce.src.cheat_table.disableAfterSuccess

Makes disableWithoutExecute() be called on the next MemoryRecord script that runs successfully.
Can be used at the bottom of an [ENABLE] section to turn a script into a momentary button rather than toggle.

**Returns:** `none`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| disableBeep | boolean | No |  whether to disable the beep when the script runs successfully |


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

**Returns:** `the newly created MemoryRecord`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| description | string | No |  the description of the new memory record |
| dropDownSettings | unknown | No |  |
| parent | MemoryRecord | No |  the parent memory record to attach the new record to |
| saveToTable | boolean | No |  whether the created record should be saved to the table |
| vtype | value type | No |  the value type of the new memory record (e.g., vtByte, vtDword) |
| address | unknown | No |  |
| offsets | unknown | No |  |


### alce.src.cheat_table.createHeader

Creates a new Group Header MemoryRecord

**Returns:** `the newly created MemoryRecord`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| showCollapseButtons | boolean | No |  whether to show collapse buttons on the header |
| description | string | No |  the description of the new header |
| saveToTable | boolean | No |  whether the created header should be saved to the table |
| parent | MemoryRecord | No |  the parent memory record to attach the new header to |


### alce.src.cheat_table.clearChildren

destroy's all children of the given memoryRecord

**Returns:** `none`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| memoryRecord | MemoryRecord | Yes |  the memory record whose children should be destroyed |


## alce.src.vt

a table of various CE type helpers. They can be useful on their own, but they mainly exist to be utilized by the user-friendly `alce.vt.VTypeHelper` instances in `alce.T`
- `vt.typeStrings`: array of CE type strings (e.g. string 'vtByte', 'vtDword', 'vtPointer')
- `vt.size`: dict mapping CE's vt types and their respective sizes in bytes (accounts for 32/64bit processes; no support for 16bit addressing)
- `vt.read`: dict mapping CE's vt types and their respective read functions (e.g. [vdDword] is readInteger)
- `vt.write`: mapping of CE's vt types and their respective write functions (e.g. [vdDword] is writeInteger)

### alce.src.vt.VTypeHelper

For working with a vartype such as: finding its monotypes, reading and writing, and formatting invoke-style argument tables.

### alce.src.vt.VTypeHelper.getMonotypes

returns the monotypes associated with the VType

**Returns:** `nil or array of integers`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.vt.VTypeHelper.write

writes a value to the specified address using the VType

**Returns:** `boolean`:  whether or not it succeeded

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any value | Yes |  the value to write |
| address | memory address | Yes |  the address to write to |


### alce.src.vt.VTypeHelper.read

reads a value from the specified address using the VType

**Returns:** `nil or the value`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| address | memory address | Yes |  the address to read from |


### alce.src.vt.VTypeHelper.asInvokeArgument

formats the VType and a value for invoking methods

**Returns:** `dict {type=, value=}`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| value | any value | Yes |  the value to wrap |


### alce.src.vt.VTypeHelper.getMonotypesAsStrings

returns a sorted array of strings representing the monotypes

**Returns:** `nil or array of strings`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |


### alce.src.vt.VTypeHelper.new

creates a new VType helper

**Returns:** `VType`

| Argument | Type | Required | Description |
| --- | --- | --- | --- |
| basicTypeString | basic type string | Yes |  the name of the type without prefix (e.g. 'dword') |


