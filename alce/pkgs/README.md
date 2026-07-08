# Alce Build System

## luapack

`luapack` is used to bundle the Alce library into a single Lua file (`alce.lua`).

### Bundling Mechanism
`luapack` replaces the standard Lua `require` function with a custom dispatcher:
```lua
require = function(c) return __M[c]() end
```
Every bundled module is assigned a unique ID and stored in the `__M` table as a function.

### Key Constraints and Findings

#### 1. Relative Path Requirements
`luapack` only bundles modules when the `require` call starts with `./` (e.g., `require("./globals")`). 
- **Impact:** All source files in `src/` must use relative paths for internal requirements.
- **Trade-off:** This breaks standard Lua execution of raw source files (like the `.#test` suite) because Lua's `require` is relative to the Current Working Directory (CWD), not the file location.

#### 2. Environment Dependencies
The bundled library depends on global constants (e.g., `vtByte`, `vtDword`) provided by the Cheat Engine environment.
- **Testing:** To run the bundled library in a standalone environment (e.g., `test_bundle`), the mock environment defined in `tools/env_mock.lua` must be required before the library is loaded.
- **Configuration:** The `LUA_PATH` must include the `tools` directory to allow the test suite to find the mock environment.

#### 3. Execution Model
When `luapack` bundles the project, it transforms the module graph into a flat table of functions. This resolves circular dependencies at the cost of introducing the custom dispatcher.
