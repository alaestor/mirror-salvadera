
-- alce/src/globals.lua
-- Initializes the global namespace for the Alce library.

local alce = {}

alce.cfg = {
    debug_print = false,
    warn_print = true,
    isAddress_nearNullBoundary = 0xFFFF,
    isAddress_userspaceBoundary32 = 0xBFFFFFFF,
    isAddress_userspaceBoundary64 = 0x00007FFFFFFFFFFF,
    isOffset_tooFarBoundary = 0x1000,
    strict = true -- The "Fast Path" toggle discussed earlier
}

return alce
