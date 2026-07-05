
local alce = require("alce.src.globals")
local fn_module = require("alce.src.fn")

-- Test 1: Basic functionality of the factory
print("--- Testing fn factory with globals ---")
local function test_factory()
    local myfunc = fn_module.fn({
        doc = "A simple addition function",
        code = function(self, args)
            return args.a + args.b
        end,
        schema = {
            a = { type = "number", required = true },
            b = { type = "number", required = true }
        }
    })

    -- Test 1: Callability and Result
    local result = myfunc({a = 10, b = 20})
    print("Result of addition:", result)
    assert(result == 30, "Addition failed!")

    -- Test 2: Type Tag Check
    print("Type tag:", myfunc._type)
    assert(myfunc._type == "fn_structured_function", "Type tag mismatch!")

    -- Test 3: Debug Line Number
    print("Defined at line:", myfunc.debug.line)
    assert(type(myfunc.debug.line) == "number", "Line number missing in debug info!")

    -- Test 4: Metadata Access
    if myfunc.doc and myfunc.schema then
        print("Metadata access: SUCCESS")
    else
        error("Metadata access failed!")
    end

    print("\n--- Factory Test Passed ---")
end

local ok, err = pcall(test_factory)
if not ok then
    print("Test Failed: " .. tostring(err))
    os.exit(1)
end
