# Alce Agent Guidelines

This document provides guidance for agents working on the ALCE library to ensure consistency in code quality, documentation, and testing.

## Testing

Alce uses a custom, lightweight BDD-style testing framework located in `alce/tests/test_utils.lua`. All new tests must adhere to this structure to maintain readability and consistent reporting.

### Test Structure

Tests should follow a **Given-When-Then** logical flow and be organized hierarchically:

1.  **Entry Point**: Every `.test.lua` file must wrap its contents in `test.run_and_report(function() ... end)`. This ensures the test results are summarized and the filename is correctly reported.
2.  **Grouping (`describe`)**: Use `test.describe("Feature Name", function() ... end)` to group related tests. This serves as the "Given" context.
3.  **Individual Tests (`it` / `it_throws`)**: 
    *   Use `test.it("should [expected behavior]", function() ... end)` for positive cases.
    *   Use `test.it_throws("should throw error when [condition]", function() ... end)` for negative cases (where the code is expected to `error()`).
4.  **Assertions (`expect`)**: Use the fluent `test.expect(actual)` API for validations:
    *   `.to_eq(expected)`: Checks for equality.
    *   `.to_be_type("type")`: Validates the Lua type (e.g., `"number"`, `"table"`, `"string"`).
    *   `.to_be_true()`: Validates that a value is truthy.
    *   `.to_be_false()`: Validates that a value is falsy/nil.

### Best Practices

- **Isolate Surface Area**: Unit tests should validate the smallest possible piece of logic. Integration tests should simulate high-level workflows.
- **Test the Interface**: Validate the guarantees the API makes, not the internal implementation details.
- **Negative Testing**: Always include cases where the code should fail (e.g., missing required arguments, type mismatches in strict mode).
- **Conciseness**: Tests should be clear and concise. If a test requires extensive setup, move that setup to the `describe` block.

### Example

```lua
local test = require("alce.tests.test_utils")
local module = require("alce.src.module")

test.run_and_report(function()
    test.describe("module.function_name", function()
        -- Given: a specific configuration
        local config = { ... }
        local obj = module.create(config)

        test.it("should return a value when input is valid", function()
            local result = obj:do_work(10)
            test.expect(result).to_eq(20)
        end)

        test.it_throws("should fail when input is nil", function()
            obj:do_work(nil)
        end)
    end)
end)
```

### Running Tests
    
Tests are executed via the Nix flake:
- Raw source tests: `nix run .#test` (Uses a shim to resolve relative requires for luapack compatibility)
- Bundled library tests: `nix run .#test_bundle` (Validates the final `alce.lua` bundle)
    
To enable detailed output during development, set the `ALCE_VERBOSE` environment variable:
`ALCE_VERBOSE=1 nix run .#test`

## Bundling and Execution

Alce is bundled into a single file (`alce.lua`) using `luapack`.

### Bundling Requirements
- **Relative Paths**: All internal `require` calls in `src/` must start with `./` (e.g., `require("./globals")`) for `luapack` to detect and bundle them.
- **Dispatcher**: The bundle replaces `require` with a custom dispatcher. Any `require` call that does not start with `./` is left as-is and will likely cause a crash (`attempt to call a nil value`) unless the module is provided by the host environment.

### Environment Mocking
The library depends on global constants provided by the Cheat Engine environment.
- When running in standalone Lua (e.g., during testing), the mock environment in `tools/env_mock.lua` must be loaded first.
- Example for test scripts: `require("tools.env_mock")` before `require("alce")`.
## Documentation and Migration

When migrating monolithic code from `alcelib.lua` to modular `src/*.lua` files, follow these documentation patterns to support the project's structured documentation system.

### Table Documentation (`__doc`)
- **Iterated Tables**: For "data" tables that are intended to be iterated using `pairs` (e.g. a map of values), avoid adding metadata keys like `__doc` as they will interfere with iteration. Instead, consolidate descriptions of the table's contents or subtables into a bulleted list within a parent table's `__doc` field.
  - *Pattern*: `alce.table = { __doc = [[ ... \n- table.sub: description \n- table.sub2: description ]] }`
- **Static/Helper Tables**: For tables used as namespaces or helper classes (not intended for iteration), add a `__doc` member directly to the table.

### Structured Functions (`fn` and `member_fn`)
Replace standard function declarations with the `alce.src.fn` wrapper to provide validation and metadata.

- **Standalone Functions**: Use `fn({ doc = "...", returns = "...", schema = { ... }, code = function(self, args) ... end })`. Note that the `type` field in the `schema` is used for documentation purposes only and should follow the pattern `vague type descriptor: context` (e.g., `"memory address: the address to read from"`).
- **Object Methods**: Use `member_fn({ ... })` for functions intended to be called as methods (`object:method()`). This ensures the object instance is passed as the first argument (`self`) to the `code` block while maintaining structured metadata.
