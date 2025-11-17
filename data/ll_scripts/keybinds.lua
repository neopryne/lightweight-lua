if (not mods) then mods = {} end
mods.lightweight_keybinds = {}
local lwk = mods.lightweight_keybinds

local lwl = mods.lightweight_lua

local keyNameTable = {
    [0] = "KEY_UNKNOWN",
    [8] = "KEY_BACKSPACE",
    [9] = "KEY_TAB",
    [12] = "KEY_CLEAR",
    [13] = "KEY_RETURN",
    [19] = "KEY_PAUSE",
    [27] = "KEY_ESCAPE",
    [32] = "KEY_SPACE",
    [33] = "KEY_EXCLAIM",
    [34] = "KEY_QUOTEDBL",
    [36] = "KEY_DOLLAR",
    [38] = "KEY_AMPERSAND",
    [40] = "KEY_LEFTPAREN",
    [41] = "KEY_RIGHTPAREN",
    [42] = "KEY_ASTERISK",
    [43] = "KEY_PLUS",
    [44] = "KEY_COMMA",
    [45] = "KEY_MINUS",
    [46] = "KEY_PERIOD",
    [47] = "KEY_SLASH",
    [48] = "KEY_0",
    [49] = "KEY_1",
    [50] = "KEY_2",
    [51] = "KEY_3",
    [52] = "KEY_4",
    [53] = "KEY_5",
    [54] = "KEY_6",
    [55] = "KEY_7",
    [56] = "KEY_8",
    [57] = "KEY_9",
    [58] = "KEY_COLON",
    [59] = "KEY_SEMICOLON",
    [61] = "KEY_EQUALS",
    [63] = "KEY_QUESTION",
    [64] = "KEY_AT",
    [91] = "KEY_LEFTBRACKET",
    [92] = "KEY_BACKSLASH",
    [93] = "KEY_RIGHTBRACKET",
    [94] = "KEY_CARET",
    [95] = "KEY_UNDERSCORE",
    [96] = "KEY_BACKQUOTE",
    [97] = "KEY_a",
    [98] = "KEY_b",
    [99] = "KEY_c",
    [100] = "KEY_d",
    [101] = "KEY_e",
    [102] = "KEY_f",
    [103] = "KEY_g",
    [104] = "KEY_h",
    [105] = "KEY_i",
    [106] = "KEY_j",
    [107] = "KEY_k",
    [108] = "KEY_l",
    [109] = "KEY_m",
    [110] = "KEY_n",
    [111] = "KEY_o",
    [112] = "KEY_p",
    [113] = "KEY_q",
    [114] = "KEY_r",
    [115] = "KEY_s",
    [116] = "KEY_t",
    [117] = "KEY_u",
    [118] = "KEY_v",
    [119] = "KEY_w",
    [120] = "KEY_x",
    [121] = "KEY_y",
    [122] = "KEY_z",
    [127] = "KEY_DELETE",
    [256] = "KEY_KP0",
    [257] = "KEY_KP1",
    [258] = "KEY_KP2",
    [259] = "KEY_KP3",
    [260] = "KEY_KP4",
    [261] = "KEY_KP5",
    [262] = "KEY_KP6",
    [263] = "KEY_KP7",
    [264] = "KEY_KP8",
    [265] = "KEY_KP9",
    [266] = "KEY_KP_PERIOD",
    [267] = "KEY_KP_DIVIDE",
    [268] = "KEY_KP_MULTIPLY",
    [269] = "KEY_KP_MINUS",
    [270] = "KEY_KP_PLUS",
    [271] = "KEY_KP_ENTER",
    [272] = "KEY_KP_EQUALS",
    [273] = "KEY_UP",
    [274] = "KEY_DOWN",
    [275] = "KEY_RIGHT",
    [276] = "KEY_LEFT",
    [277] = "KEY_INSERT",
    [278] = "KEY_HOME",
    [279] = "KEY_END",
    [280] = "KEY_PAGEUP",
    [281] = "KEY_PAGEDOWN",
    [282] = "KEY_F1",
    [283] = "KEY_F2",
    [284] = "KEY_F3",
    [285] = "KEY_F4",
    [286] = "KEY_F5",
    [287] = "KEY_F6",
    [288] = "KEY_F7",
    [289] = "KEY_F8",
    [290] = "KEY_F9",
    [291] = "KEY_F10",
    [292] = "KEY_F11",
    [293] = "KEY_F12",
    [294] = "KEY_F13",
    [295] = "KEY_F14",
    [296] = "KEY_F15",
    [300] = "KEY_NUMLOCK",
    [301] = "KEY_CAPSLOCK",
    [302] = "KEY_SCROLLOCK",
    [303] = "KEY_RSHIFT",
    [304] = "KEY_LSHIFT",
    [305] = "KEY_RCTRL",
    [306] = "KEY_LCTRL",
    [307] = "KEY_RALT",
    [308] = "KEY_LALT",
    [309] = "KEY_RMETA",
    [310] = "KEY_LMETA",
    [311] = "KEY_LSUPER",
    [312] = "KEY_RSUPER",
    [313] = "KEY_MODE",
    [314] = "KEY_COMPOSE",
    [315] = "KEY_HELP",
    [316] = "KEY_PRINTSCREEN",
    [317] = "KEY_SYSREQ",
    [318] = "KEY_BREAK",
    [319] = "KEY_MENU",
    [320] = "KEY_POWER",
    [321] = "KEY_EURO",
    [322] = "KEY_UNDO"
}

local KEY_TO_CHARACTER_MAP = {
    KEY_a = {"a", "A"},
    KEY_b = {"b", "B"},
    KEY_c = {"c", "C"},
    KEY_d = {"d", "D"},
    KEY_e = {"e", "E"},
    KEY_f = {"f", "F"},
    KEY_g = {"g", "G"},
    KEY_h = {"h", "H"},
    KEY_i = {"i", "I"},
    KEY_j = {"j", "J"},
    KEY_k = {"k", "K"},
    KEY_l = {"l", "L"},
    KEY_m = {"m", "M"},
    KEY_n = {"n", "N"},
    KEY_o = {"o", "O"},
    KEY_p = {"p", "P"},
    KEY_q = {"q", "Q"},
    KEY_r = {"r", "R"},
    KEY_s = {"s", "S"},
    KEY_t = {"t", "T"},
    KEY_u = {"u", "U"},
    KEY_v = {"v", "V"},
    KEY_w = {"w", "W"},
    KEY_x = {"x", "X"},
    KEY_y = {"y", "Y"},
    KEY_z = {"z", "Z"},

    -- Keys that do not change with shift
    KEY_0 = {"0", "0"},
    KEY_1 = {"1", "1"},
    KEY_2 = {"2", "2"},
    KEY_3 = {"3", "3"},
    KEY_4 = {"4", "4"},
    KEY_5 = {"5", "5"},
    KEY_6 = {"6", "6"},
    KEY_7 = {"7", "7"},
    KEY_8 = {"8", "8"},
    KEY_9 = {"9", "9"},

    KEY_COMMA = {",", ","},
    KEY_PERIOD = {".", "."},
    KEY_SLASH = {"/", "/"},
    KEY_SEMICOLON = {";", ";"},
    KEY_APOSTROPHE = {"'", "'"},
    KEY_LEFTBRACKET = {"[", "["},
    KEY_RIGHTBRACKET = {"]", "]"},
    KEY_BACKSLASH = {"\\", "\\"},
    KEY_MINUS = {"-", "-"},
    KEY_EQUAL = {"=", "="},
    KEY_SPACE = {" ", " "},
    
        -- Additional keys for shifted characters
    KEY_EXCLAIM = {"!", "!"},
    KEY_AT = {"@", "@"},
    KEY_HASH = {"#", "#"},
    KEY_DOLLAR = {"$", "$"},
    KEY_PERCENT = {"%", "%"},
    KEY_CARET = {"^", "^"},
    KEY_AMPERSAND = {"&", "&"},
    KEY_ASTERISK = {"*", "*"},
    KEY_LEFTPAREN = {"(", "("},
    KEY_RIGHTPAREN = {")", ")"},
    KEY_UNDERSCORE = {"_", "_"},
    KEY_PLUS = {"+", "+"},
    KEY_LEFTCURLY = {"{", "{"},
    KEY_RIGHTCURLY = {"}", "}"},
    KEY_PIPE = {"|", "|"},
    KEY_TILDE = {"~", "~"},
    KEY_LESS = {"<", "<"},
    KEY_GREATER = {">", ">"},
    KEY_QUESTION = {"?", "?"},
    KEY_QUOTE = {"\"", "\""},
    
        -- Keypad keys
    KEY_KP0 = {"0", "0"},
    KEY_KP1 = {"1", "1"},
    KEY_KP2 = {"2", "2"},
    KEY_KP3 = {"3", "3"},
    KEY_KP4 = {"4", "4"},
    KEY_KP5 = {"5", "5"},
    KEY_KP6 = {"6", "6"},
    KEY_KP7 = {"7", "7"},
    KEY_KP8 = {"8", "8"},
    KEY_KP9 = {"9", "9"},
    KEY_KP_PERIOD = {".", "."},
    KEY_KP_DIVIDE = {"/", "/"},
    KEY_KP_MULTIPLY = {"*", "*"},
    KEY_KP_MINUS = {"-", "-"},
    KEY_KP_PLUS = {"+", "+"},
    KEY_KP_ENTER = nil,

    -- Special keys (no printed character)
}

local ON_KEY_DOWN = "ON_KEY_DOWN"
local ON_KEY_UP = "ON_KEY_UP"
lwk.SHIFT = "SHIFT"
lwk.CTRL = "CTRL"
lwk.META = "META"
local mKeyBindings = {}
local mPressedKeys = {}


local function isPressed(keyId)
    return mPressedKeys[keyId]
end

function lwk.shiftPressed()
    return isPressed(Defines.SDL_KEY_RSHIFT) or isPressed(Defines.SDL_KEY_LSHIFT)
end

function lwk.ctrlPressed()
    return isPressed(Defines.SDL_KEY_RCTRL) or isPressed(Defines.SDL_KEY_LCTRL)
end

function lwk.metaPressed()
    return isPressed(Defines.SDL_KEY_RMETA) or isPressed(Defines.SDL_KEY_LMETA) or isPressed(Defines.SDL_KEY_RALT) or isPressed(Defines.SDL_KEY_LALT)
end

--todo I should really make a syntax for "or" and "and" for modifiers.  Right now it's always "and".
--This whole business of modifiers is kind of contentious, but if you don't have them you run into issues of unrelated keys counting as modifiers
-- and preventing you from entering your key combo.  It means that meta x+y doesn't work.  Not that it does anyway in this interface.
local function getActiveModifiers()
    local activeModifiers = {}
    if lwk.shiftPressed() then table.insert(activeModifiers, lwk.SHIFT) end
    if lwk.ctrlPressed() then table.insert(activeModifiers, lwk.CTRL) end
    if lwk.metaPressed() then table.insert(activeModifiers, lwk.META) end
    return activeModifiers
end

--Sort by value ascending
local function normalizedModifierKeys(modifierKeys)
    table.sort(modifierKeys)
    return modifierKeys
end

--[[
I need a better code editor, I need a better thing, I need a better language.  I need to learn lisp like really learn it like write it myself like engrain it into myself or I will die.
--]]
local function getModifiersAsString(modifierKeys)
    --print("getModifiersAsString", modifierKeys)
    local normalizedKeys = normalizedModifierKeys(modifierKeys)
    --print("normalizedKeys", normalizedKeys)
    if not normalizedKeys then return "" end
    local string = table.concat(normalizedKeys, "+")
    --print("modstring", string)
    return string
end


-----------------------------------API--------------------------------------

---Registers a callback to be executed upon a given key (combination).
---multiple functions can be registered for the same key
---Currently, only ctrl, shift, and meta are accepted as modifiers, but I don't see any reason why I couldn't change that in the future. 
---@param operatorKey number Hyperspace KeyId
---@param modifierKeys table|nil Valid values: any combination of lwk.SHIFT, lwk.CTRL, and lwk.META.
---@param keyPressCallback function|nil The return value of this function is a boolean that tells lwk if it should override the normal keypress.  It is passed the calling key.
---@param keyReleaseCallback function|nil The return value of this function is a boolean that tells lwk if it should override the normal keypress.
function lwk.registerKeyFunctionCombo(operatorKey, modifierKeys, keyPressCallback, keyReleaseCallback)
    if not modifierKeys then modifierKeys = {} end
    --print("registering ", operatorKey, modKey)
    if not mKeyBindings[operatorKey] then
         mKeyBindings[operatorKey] = {}
    end

    local modKeys = getModifiersAsString(modifierKeys)
    --print("modkey1 ", modKey)
    if not mKeyBindings[operatorKey][modKeys] then
         mKeyBindings[operatorKey][modKeys] = {}
    end

    if not mKeyBindings[operatorKey][modKeys][ON_KEY_DOWN] then
        mKeyBindings[operatorKey][modKeys][ON_KEY_DOWN] = {}
    end
    if not mKeyBindings[operatorKey][modKeys][ON_KEY_UP] then
        mKeyBindings[operatorKey][modKeys][ON_KEY_UP] = {}
    end

    if keyPressCallback then
        --print("registered onkeydown")
        table.insert(mKeyBindings[operatorKey][modKeys][ON_KEY_DOWN], keyPressCallback)
    end
    if keyReleaseCallback then
        --print("registered onkeyup")
        table.insert(mKeyBindings[operatorKey][modKeys][ON_KEY_UP], keyReleaseCallback)
    end
    --print("registered ", operatorKey, modKey)
    --print("Key binds are now\n",lwl.dumpObject(mKeyBindings))
    --todo return an ID that cen be used to deregister this callback.
end

    
---Takes a Hyperspace KeyId and tells you if it's pressed or not.
---@param keyId number
---@return boolean
function lwk.isKeyPressed(keyId)
    return isPressed(keyId)
end
-----------------------------------END API--------------------------------------

-- Function to execute callbacks for a given key press
---Returns true if any callbacks requested to preempt, and false otherwise.
---@param operatorKey any
---@param operation any
---@return boolean
local function executeKeyFunctions(operatorKey, operation)
    --print("xec", operatorKey, operation)
    local modKeys = getModifiersAsString(getActiveModifiers())
    --print("modkey ", modKey)
    local keyTable = mKeyBindings[operatorKey]
    --print("keyTable", keyTable)
    if not keyTable then return end

    local modifiersTable = keyTable[modKeys]
    --print("modifiersTable", modifiersTable)
    if not modifiersTable then return end

    local callbacks
    if operation == ON_KEY_DOWN then
        callbacks = modifiersTable[ON_KEY_DOWN]
    elseif operation == ON_KEY_UP then
        callbacks = modifiersTable[ON_KEY_UP]
    else
        error("Incorrect operation", operation)
    end
    local shouldPreempt = false
    if callbacks then
        for _, callback in ipairs(callbacks) do
            --print("found callback for ", operatorKey, modKey)
            if callback(operatorKey) then
                shouldPreempt = true
            end
        end
    else
        --print("No callbacks found for", operatorKey, modKeys, operation)
    end
    return shouldPreempt
end


--SPECIAL FUNCTIONS
local function onFtlKeyDown(keyId)
    --print("key down", keyId)
    if mPressedKeys[keyId] then
        --error("Key was pressed while already pressed! Key: "..keyNameTable[keyId])
    end
    mPressedKeys[keyId] = true
    return executeKeyFunctions(keyId, ON_KEY_DOWN)
end

local function onFtlKeyUp(keyId)
    --print("key up", keyId)
    if not mPressedKeys[keyId] then
        --error("Key was released while already released! Key: "..keyNameTable[keyId])
    end
    mPressedKeys[keyId] = false
    return executeKeyFunctions(keyId, ON_KEY_UP)
end

--If you register a keybind for an existing key, it will overwrite the normal functionality if you return true in your callback.  This allows you to do dynamic keybinds, actually.
--I should consider letting you decide if things should preempt here.
-- script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(Key)
lwl.safe_script.on_internal_event("lwk_key_down", Defines.InternalEvents.ON_KEY_DOWN, function(Key)
        --print("onDown ", keyNameTable[Key])
        local shouldPreempt = onFtlKeyDown(Key)
        if shouldPreempt then
            return Defines.Chain.PREEMPT
        else
            return Defines.Chain.CONTINUE
        end
    end)
-- script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(Key)
lwl.safe_script.on_internal_event("lwk_key_up", Defines.InternalEvents.ON_KEY_UP, function(Key)
    --print("onUp ", keyNameTable[Key])
        local shouldPreempt = onFtlKeyUp(Key)
        if shouldPreempt then
            return Defines.Chain.PREEMPT
        else
            return Defines.Chain.CONTINUE
        end
    end)

onFtlKeyDown(Defines.SDL_KEY_RALT)
print("Expect true", lwk.metaPressed())
onFtlKeyDown(Defines.SDL_KEY_x)
print("Expect true", mPressedKeys[Defines.SDL_KEY_RALT])
onFtlKeyUp(Defines.SDL_KEY_RALT)
print("Expect false", mPressedKeys[Defines.SDL_KEY_RALT])
--onFtlKeyDown(Defines.SDL_KEY_x)
--onFtlKeyDown(Defines.SDL_KEY_x)
onFtlKeyDown(Defines.SDL_KEY_s)
onFtlKeyDown(Defines.SDL_KEY_RETURN)