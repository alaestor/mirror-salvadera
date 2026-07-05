local test = require("alce.tests.test_utils")
-- Set verbose based on environment variable or default
test.cfg.verbose = os.getenv("ALCE_VERBOSE") ~= nil

local fn_module = require("alce.src.fn")

test.run_and_report(function()
    test.describe("alce.src.fn.fn factory", function()
        local config = {
            doc = "A simple addition function",
            code = function(self, args)
                return args.a + args.b
            end,
            schema = {
                a = { type = "number", required = true },
                b = { type = "number", required = true }
            }
        }

        local myfunc = fn_module.fn(config)

        test.it("should create a function with the correct type tag", function()
            test.expect(myfunc._type).to_eq("fn_structured_function")
        end)

        test.it("should preserve metadata from configuration", function()
            test.expect(myfunc.doc).to_eq("A simple addition function")
            test.expect(myfunc.schema).to_be_type("table")
        end)

        test.it("should automatically assign a debug line number", function()
            test.expect(myfunc.debug.line).to_be_type("number")
        end)

        test.it("should be callable and return the expected result", function()
            local result = myfunc({a = 10, b = 20})
            test.expect(result).to_eq(30)
        end)
    end)

    test.describe("alce.src.fn.member_fn factory", function()
        local config = {
            doc = "A simple member function",
            code = function(instance, value)
                return instance.base + value
            end,
            schema = {
                value = { type = "number" }
            }
        }

        local my_member_fn = fn_module.member_fn(config)
        local mock_instance = { base = 100, my_member_fn = my_member_fn }

        test.it("should be callable as a method using colon syntax", function()
            local result = mock_instance:my_member_fn(50)
            test.expect(result).to_eq(150)
        end)

        test.it("should be callable as a function passing the instance explicitly", function()
            local result = my_member_fn(mock_instance, 50)
            test.expect(result).to_eq(150)
        end)

        test.it("should preserve metadata from configuration", function()
            test.expect(my_member_fn.doc).to_eq("A simple member function")
            test.expect(my_member_fn.schema).to_be_type("table")
        end)
    end)
end)
