-- Documentation Generator for ALCE
-- This script dynamically analyzes the ALCE library and generates ALCE_DOCS.md

-- 1. Environment Setup
-- Handle package.path so that we can require modules using dot notation relative to the project root
package.path = package.path .. ";/home/user/Projects/alaestor-codeberg/salvadera/?.lua"

-- Require the mock environment first to avoid Cheat Engine dependencies
require("alce.tools.env_mock")

-- Require the main ALCE modules
-- We only require the ones that are well-behaved or essential for the root namespace.
-- Since some modules have side-effects or complex dependencies that might fail in this environment,
-- we will use pcall for the rest.
local alce_globals = require("alce.src.globals")

local modules = {
    ["alce"] = alce_globals,
}

-- Try to load other modules from src to be comprehensive
local src_modules = {
    "alce.src.arg_parser",
    "alce.src.cheat_table",
    "alce.src.fmt",
    "alce.src.fn",
    "alce.src.memory",
    "alce.src.mono",
    "alce.src.mono_plumbing",
    "alce.src.mono_t",
    "alce.src.monoscript",
    "alce.src.printers",
    "alce.src.t",
    "alce.src.utils",
    "alce.src.validators",
    "alce.src.vt",
}

for _, mod_path in ipairs(src_modules) do
    local ok, mod = pcall(require, mod_path)
    if ok and type(mod) == "table" then
        local name = mod_path:match("src%.([^.]+)%.lua?$") or mod_path
        modules[name] = mod
    end
end

-- 2. Traversal & Extraction
local output = "# ALCE Library Documentation\n\n"

local function trim(s)
    if not s then return "" end
    local lines = {}
    for line in s:gmatch("[^\n]+") do
        lines[#lines + 1] = line:gsub("^%s*(.-)%s*$", "%1")
    end

    -- Handle cases where the string might be empty or only contains newlines
    if #lines == 0 then
        return ""
    end

    while #lines > 0 and lines[1] == "" do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines] == "" do table.remove(lines, #lines) end

    return table.concat(lines, "\n")
end

local function parse_schema(schema)
    if not schema then return "" end

    local header = "| Argument | Type | Required | Description |\n| --- | --- | --- | --- |\n"
    local rows = ""

    for arg_name, details in pairs(schema) do
        local type_raw = details.__doc or "unknown"
        local type_part, desc_part = type_raw:match("([^:]+):?(.*)")

        local type_str = type_part or "unknown"
        local desc_str = desc_part or ""
        local required_str = details.required and "Yes" or "No"

        rows = rows .. string.format("| %s | %s | %s | %s |\n", arg_name, type_str, required_str, desc_str)
    end

    return header .. rows
end

local function traverse(ns, full_path, level)
    if type(ns) ~= "table" then return end

    local indent = string.rep("#", level)

    -- Handle Table Documentation
    if ns.__doc then
        output = output .. string.format("%s %s\n\n%s\n\n", indent, full_path, trim(ns.__doc))
    end

    if ns.__doc_verbatim then
        output = output .. "**Default Values:**\n\n```lua\n"
        local fmt_mod = require("alce.src.fmt")
        output = output .. fmt_mod.table({
            tbl = ns,
            useKeysToIgnore = { ["__doc"] = true, ["__doc_verbatim"] = true }
        })
        output = output .. "\n```\n\n"
    end

    for k, v in pairs(ns) do
        if k == "__doc" or k == "__doc_verbatim" then goto continue end

        if type(v) == "table" then
            local current_path = full_path .. "." .. k
            if v._type == "fn_structured_function" then
                -- Handle Structured Function
                output = output .. string.format("### %s\n\n", current_path)
                if v.__doc then
                    output = output .. string.format("%s\n\n", trim(v.__doc))
                end
                if v.__doc_returns and v.__doc_returns ~= "" then
                    local ret_text = v.__doc_returns
                    if ret_text:match("^%a+$") or ret_text:match("^%d+$") then
                        ret_text = string.format("`%s`", ret_text)
                    else
                        -- Simple attempt to format as `type`: description
                        local type_part, desc_part = ret_text:match("([^:]+):?(.*)")
                        if desc_part and desc_part ~= "" then
                            ret_text = string.format("`%s`: %s", type_part, desc_part)
                        else
                            ret_text = string.format("`%s`", ret_text)
                        end
                    end
                    output = output .. string.format("**Returns:** %s\n\n", ret_text)
                end
                if v.parameters then
                    output = output .. parse_schema(v.parameters) .. "\n\n"
                end
            elseif v.__doc or (type(v) == "table" and next(v) ~= nil) then
                -- Recurse into tables that are likely modules or namespaces
                if k ~= "_G" and k ~= "alce" then
                    traverse(v, current_path, level + 1)
                end
            end
        end
        ::continue::
    end
end

    -- Determine output path from environment variable or default to ALCE_DOCS.md
    local output_path = os.getenv("ALCE_DOC_OUTPUT") or "ALCE_DOCS.md"

    -- Start traversal for the root 'alce' module first, then others
    if modules["alce"] then
        traverse(modules["alce"], "alce", 2)
    end

    for mod_name, mod_ns in pairs(modules) do
        if mod_name ~= "alce" then
            traverse(mod_ns, mod_name, 2)
        end
    end

    -- 3. Output
    -- Prefix with Codeberg frontmatter for TOC rendering
    local final_output = "---\ninclude_toc: true\n---\n\n" .. output

    local file = io.open(output_path, "w")
    if file then
        file:write(final_output)
        file:close()
        print("Successfully generated " .. output_path)
    else
        print("Error: Could not open " .. output_path .. " for writing")
        os.exit(1)
    end
