
local alce = {}

-- Defining a function wrapped in a table entry
alce.add_numbers = {
    call = function(input)
        return input.a + input.b
    end,
    schema = {
        description = "Adds two numbers from a table input."
    }
}

print("Testing add_numbers call:")
local result = alce.add_numbers.call({a = 5, b = 10})
print("Result:", result)

print("\nTesting metadata access:")
if alce.add_numbers.schema then
    print("Description:", alce.add_numbers.schema.description)
else
    print("Metadata NOT found!")
end

if alce.add_numbers.schema and alce.add_numbers.call then
    print("\nSUCCESS: The wrapper approach works!")
else
    print("\nFAILURE: Something went wrong.")
end
