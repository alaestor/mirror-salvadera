
-- alce/wrapper_demo_test.lua
-- Demonstrating the "Table Wrapper" approach for attaching metadata to functions.

local alce = {}

--------------------------------------------------------------------------------
-- Define a function as a member of the 'alce' table.
-- This allows us to treat it as a table entry and attach properties safely.
--------------------------------------------------------------------------------
alce.add_numbers = function(input)
    return input.a + input.b
end

-- Now we can safely attach the schema to the table entry.
alce.add_numbers.schema = {
    args = {
        a = { type = "number", required = true },
        b = { type = "number", required = true }
    },
    description = "Adds two numbers from a table input."
}

--------------------------------------------------------------------------------
-- Define another function with different metadata.
--------------------------------------------------------------------------------
alce.greet = function(name)
    return "Hello, " .. tostring(name) .. "!"
end

alce.greet.schema = {
    args = {
        name = { type = "string", required = true }
    },
    description = "Greets a person by name."
}

--------------------------------------------------------------------------------
-- TEST SUITE
--------------------------------------------------------------------------------
print("--- Testing Table Wrapper Approach ---")

-- Test 1: Functionality
local sum = alce.add_numbers({a = 5, b = 10})
print("Test 1 (Sum):", sum == 15 and "SUCCESS" or "FAILURE")

-- Test 2: Metadata Access (Introspection)
if alce.add_numbers.schema then
    print("Test 2 (Metadata Found): SUCCESS")
    print("   Description:", alce.add_numbers.schema.description)
else
    print("Test 2 (Metadata Found): FAILURE")
end

-- Test 3: Another function check
if alce.greet.schema and alce.greet.schema.args.name then
    print("Test 3 (Greet Schema): SUCCESS")
else
    print("Test 3 (Greet Schema): FAILURE")
end

-- Test 4: Verifying we can still call it like a function
local greeting = alce.greet("World")
print("Test 4 (Callability):", greeting == "Hello, World!" and "SUCCESS" or "FAILURE")

print("\n--- Demonstration Complete ---")
