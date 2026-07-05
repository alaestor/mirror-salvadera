# Experiment Results

## Overview
This document summarizes the findings from various experiments conducted while designing the new `fn` function factory and argument parsing infrastructure for the `alce` library overhaul.

## Completed Experiments

### 1. Argument Parser Validation (`arg_parser_test`)
- **Goal**: Test a robust, table-based argument parser that supports defaults, validation, and transformations.
- **Findings**: 
    - Using a `schema` table to define requirements (required, default, validator, transform) works well.
    - The parser can effectively handle "lazy defaults" (using functions to generate new tables/objects per call).
    - The implementation must correctly distinguish between an absent key and an explicitly passed `nil` (though in standard Lua, this requires a sentinel value or specific usage pattern).

### 2. Function Metadata Attachment (`schema_demo_test`)
- **Goal**: Determine if metadata can be attached to functions in Lua.
- **Findings**:
    - Attaching properties directly to a function object (e.g., `my_func.schema = {}`) is valid and highly effective for introspection.
    - **Crucial Discovery**: Defining the schema *inside* the function scope makes it inaccessible from the outside once the function returns. The schema must be defined in the same scope as the function definition itself or via a wrapper object.

### 	3. The "Immutable Function" Problem (`minimal_test` / `wrapper_test`)
- **Goal**: Test if properties can be attached to standard Lua functions.
- **Findings**: 
    - In some environments/contexts, attempting to index a function (e.g., `f.foo = "bar"`) triggered an error: `attempt to index a function value`. This suggests the environment might treat functions as immutable or wrapped in a way that restricts property assignment.
    - **Solution**: The "Table Wrapper" pattern was found to be 100% reliable. By creating a table entry for the function (e.g., `alce.myfunc = { call = function(...) ... end, schema = {} }`), we can safely attach metadata without hitting any immutability restrictions.

### 4. Function Factory Implementation (`factory_test`)
- **Goal**: Test a factory (`fn`) that uses the `__call` metamethod to make a table behave like a function while carrying metadata.
- **Findings**:
    - Using `setmetatable(func, { __call = ... })` allows us to maintain the clean syntax `alce.myfunc({args})` while keeping all metadata accessible via `alce.my_func.schema`.
    - This approach is robust and integrates perfectly with our argument parser.

## Conclusion
The architectural foundation for the new `alce` library is established: a table-based factory (`fn`) that produces callable wrappers containing logic, documentation, and schema-driven validation.
