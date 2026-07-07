local test = require("alce.tests.test_utils")
-- Set verbose based on environment variable or default
test.cfg.verbose = os.getenv("ALCE_VERBOSE") ~= nil

local alce = require("alce.src.globals")
local fn_module = require("alce.src.fn")

test.run_and_report(function()
    test.describe("Structured Function Integration", function()
        local myfunc = fn_module.fn({
            __doc = "Adds two numbers",
            returns = "number",
            code = function(self, args)
                return args.a + args.b
            end,
            schema = {
                a = { type = "number", required = true },
                b = { type = "number", required = true }
            }
        })

        test.it("should execute correctly with valid arguments", function()
            test.expect(myfunc({a = 10, b = 20})).to_eq(30)
        end)

        test.it("should maintain metadata", function()
            test.expect(myfunc.__doc).to_eq("Adds two numbers")
            test.expect(myfunc.returns).to_eq("number")
        end)
    end)

    test.describe("Positional Function Integration", function()
        local myfunc = fn_module.fn({
            positional = true,
            __doc = "Adds two numbers positionally",
            returns = "number",
            code = function(self, a, b)
                return a + b
            end
        })

        test.it("should execute correctly with positional arguments", function()
            test.expect(myfunc(10, 20)).to_eq(30)
        end)

        test.it("should have the positional flag set", function()
            test.expect(myfunc.positional).to_be_true()
        end)
    end)

    test.describe("Argument Parser Strict Mode (Validation)", function()
        -- Given: strict mode is enabled
        alce.cfg.strict = true

        local myfunc = fn_module.fn({
            code = function(self, args)
                return args.a + args.b
            end,
            schema = {
                a = { type = "number", required = true },
                b = { type = "number", required = true }
            }
        })

        test.it("should execute correctly when all required arguments are provided", function()
            test.expect(myfunc({a = 10, b = 20})).to_eq(30)
        end)

        test.it_throws("should throw error when a required argument is missing", function()
            myfunc({a = 10})
        end)

        test.it_throws("should throw error when an unexpected argument is provided", function()
            myfunc({a = 10, b = 20, c = 30})
        end)
    end)

    test.describe("Argument Parser Fast Path (Non-Strict)", function()
        -- Given: strict mode is disabled
        alce.cfg.strict = false

        local myfunc = fn_module.fn({
            code = function(self, args)
                return args.a + args.b
            end,
            schema = {
                a = { default = 10 },
                b = { default = 20 }
            }
        })

        test.it("should use default value for b when only a is provided", function()
            test.expect(myfunc({a = 5})).to_eq(25)
        end)

        test.it("should use default value for a when only b is provided", function()
            test.expect(myfunc({b = 5})).to_eq(15)
        end)

        test.it("should use all defaults when no arguments are provided", function()
            test.expect(myfunc({})).to_eq(30)
        end)
    end)
end)
