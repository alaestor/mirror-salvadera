
-- alce/schema_demo_test.lua
-- A demonstration of attaching metadata (schema) to functions in Lua.

--------------------------------------------------------------------------------
-- APPROACH 1: The "Alongside" Approach (Correct for Introspection)
-- This attaches the schema to the function object itself, making it globally
-- accessible via the function name.
--------------------------------------------------------------------------------
local add_numbers = function(input)
    return input.a + input.b
end

-- Attach metadata directly to the function object
add_numbers.schema = {
    args = {
        a = { type = "number", required = true },
        b = { type = "number", required = true }
    },
    description = "Adds two numbers from a table input."
}

--------------------------------------------------------------------------------
-- APPROACH 2: The "Inside" Approach (Incorrect for Introspection)
-- If you declare the schema inside the function, it is local to that function's
-- scope. Once the function finishes running, the schema is gone!
--------------------------------------------------------------------------------
local function internal_schema_func(input)
    -- This variable 'local_schema' only exists while this function is executing.
    local local_schema = {
        args = { a = { type = "number" } }
    }
    return input.a + 0
end

------------------------------------------------
-- TEST SUITE
--------------------------------------------------------------------------------
print("--- Testing Approach 1 (Alongside) ---")
if add_numbers.schema then
    print("SUCCESS: Found add_numbers.schema")
    print("Description: " .. add_numbers.schema.description)
else
    error("FAILURE: Could not find add_numbers.schema")
end

print("\n--- Testing Approach 2 (Inside) ---")
local function check_internal_visibility()
    if internal_schema_func.schema == nil then
        print("SUCCESS: As expected, internal_schema_func.schema is nil (it's hidden inside!)")
    else
        error("FAILURE: internal_schema_func.schema was unexpectedly visible!")
    end
end

local ok, err = pcall(check_internal_visibility)
if ok then print("Visibility check passed.") else error(err) end

print("\n--- Demonstration Complete ---")
