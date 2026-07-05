-- Global namespace and configuration for libALCE

alce = {
    __doc = [[
# libALCE

**Alaestor's Cheat Engine Library**

Intended to be used in the table's lua script, or parted out as needed.
]],

    cfg = {
        __doc = [[
    ### ALCE Configuration

    These global config options can be set from anywhere at any time. Some functions, such as `isAddress`, have optional parameter overrides.

    About magic numbers:
    - `isAddress_userspaceBoundary32` defaults to a "3g split"; set `0x7FFFFFFF` for 2GB
    - `isOffset_tooFarBoundary` expects offsets to be < 4096 bytes
    - `isAddress_userspaceBoundary64` is a number that came to me in a dream

    ]],
        __doc_verbatim = true, -- print KV pairs verbatim in documentation

        debug_print = false,
        warn_print = true,
        isAddress_nearNullBoundary = 0xFFFF,
        isAddress_userspaceBoundary32 = 0xBFFFFFFF,
        isAddress_userspaceBoundary64 = 0x00007FFFFFFFFFFF,
        isOffset_tooFarBoundary = 0x1000,
    },

    isAttached = function()
        return process and readInteger(process) ~= 0
    end,
},

return alce
