-- Simple BDD-style test runner for Alce
local test_utils = {
    cfg = {
        verbose = false,
    },
    stats = {
        passed = 0,
        failed = 0,
    }
}

local function fail(msg)
    error(msg)
end

function test_utils.expect(actual)
    return {
        to_eq = function(expected)
            if actual ~= expected then
                fail(string.format("Expected %s, but got %s", tostring(expected), tostring(actual)))
            end
        end,
        to_be_type = function(type_name)
            if type(actual) ~= type_name then
                fail(string.format("Expected type %s, but got %s", type_name, type(actual)))
            end
        end,
        to_be_true = function()
            if not actual then
                fail("Expected value to be true, but it was false/nil")
            end
        end,
        to_be_false = function()
            if actual then
                fail("Expected value to be false/nil, but it was true")
            end
        end,
    }
end

function test_utils.describe(name, suite_fn)
    if test_utils.cfg.verbose then
        print("\n--- " .. name .. " ---")
    end
    suite_fn()
end

function test_utils.run_and_report(suite_fn)
    local info = debug.getinfo(2, "S")
    local filename = info and info.source or "unknown"
    -- Remove '@' prefix if present
    filename = filename:gsub("^@", "")

    suite_fn()
    test_utils.report(filename)
end

function test_utils.it(name, test_fn)
    local ok, err = pcall(test_fn)
    if ok then
        test_utils.stats.passed = test_utils.stats.passed + 1
        if test_utils.cfg.verbose then
            print("  ✓ " .. name)
        end
    else
        test_utils.stats.failed = test_utils.stats.failed + 1
        print("  ✗ " .. name .. "\n    Error: " .. tostring(err))
        test_utils.report()
        os.exit(1) -- Fail hard and fast
    end
end

function test_utils.it_throws(name, test_fn)
    local ok, err = pcall(test_fn)
    if not ok then
        test_utils.stats.passed = test_utils.stats.passed + 1
        if test_utils.cfg.verbose then
            print("  ✓ " .. name .. " (threw expected error)")
        end
    else
        test_utils.stats.failed = test_utils.stats.failed + 1
        print("  ✗ " .. name .. "\n    Error: Expected error but function completed successfully")
        test_utils.report()
        os.exit(1)
    end
end

function test_utils.report(name)
    local suffix = name and (" — " .. name) or ""
    if test_utils.cfg.verbose then
        print(string.format("\nSummary: %d passed, %d failed%s", test_utils.stats.passed, test_utils.stats.failed, suffix))
    else
        if test_utils.stats.failed == 0 then
            print(string.format("All %d tests passed%s", test_utils.stats.passed, suffix))
        else
            print(string.format("FAILED: %d passed, %d failed%s", test_utils.stats.passed, test_utils.stats.failed, suffix))
        end
    end
end

return test_utils
