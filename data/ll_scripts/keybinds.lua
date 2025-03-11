if (not mods) then mods = {} end
mods.lightweight_editor = {}
local lwed = mods.lightweight_editor

--This doesn't disable existing hotkeys, so watch out I guess.

local MODIFIER_KEYS = {
    -- Modifier and special keys (no printed character)
    "KEY_LSHIFT",
    "KEY_RSHIFT",
    "KEY_LCTRL",
    "KEY_RCTRL",
    "KEY_LALT",
    "KEY_RALT"
}

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

local SHIFT = "SHIFT"
local CTRL = "CTRL"
local META = "META"
local mPressedModifierKeys = {}
local mMinibufferText = ""
local mMinibufferMode = false
local mKeyBindings = {}
local mBufferBindings = {}
local mCapsLock = false

--Used when characters need to be printed to the screen, or otherwise saved in a buffer.
local function getPrintableCharacter(keyName, isShiftPressed)
    local entry = KEY_TO_CHARACTER_MAP[keyName]
    if entry then
        return isShiftPressed and entry[2] or entry[1]
    end
    return nil -- Return nil for unknown keys
end

--todo change when integrating with ftl to real values
local function modifierIsPressed(keyId)
    --print("checking if is pressed ", keyId)
    return (mPressedModifierKeys[keyId] ~= nil)
end

function mods.lightweight_editor.shiftPressed()
    return modifierIsPressed("KEY_RSHIFT") or modifierIsPressed("KEY_LSHIFT")
end

function mods.lightweight_editor.ctrlPressed()
    return modifierIsPressed("KEY_RCTRL") or modifierIsPressed("KEY_LCTRL")
end

function mods.lightweight_editor.metaPressed()
    return modifierIsPressed("KEY_RMETA") or modifierIsPressed("KEY_LMETA") or modifierIsPressed("KEY_LALT") or modifierIsPressed("KEY_RALT")
end

--extract and order modifier keys for internal key bindings.
local function normalizedModifierKeys()
    local orderedModifiers = {}
    if lwed.shiftPressed() then table.insert(orderedModifiers, "SHIFT") end
    if lwed.ctrlPressed() then table.insert(orderedModifiers, "CTRL") end
    if lwed.metaPressed() then table.insert(orderedModifiers, "META") end
    return orderedModifiers
end

--[[
I need a better code editor, I need a better thing, I need a better language.  I need to learn lisp like really learn it like write it myself like engrain it into myself or I will die.
--]]

--TODO need a way to ensure modifier key order is always the same, and
-- Function to register a callback for a specific key combination
--Functions must take one argument, operatorKey.  They do not have to use it if they don't want to.
--To get modifier keys, the methods shiftPressed(), ctrlPressed(), and metaPressed() are available.
--modifierKeys is defined as an array with keys SHIFT, CTRL, and META with boolean values.
local function getModifiersAsString(modifierKeys)
    return table.concat(modifierKeys, "+")
end

--each command can only have one registered callback.  Name it something else if it conflicts.
function mods.lightweight_editor.registerBufferCommand(commandName, callback)
    if (mBufferBindings[commandName]) then
        print("ERROR: ", commandName, " is already registered!  Skipping.")
        return
    end
    mBufferBindings[commandName] = callback
end

--Sorry, this can't really pass anything, you'll have to use other methods to access game state.
local function executeBufferCommand(commandName)
    if (mBufferBindings[commandName]) then
        mBufferBindings[commandName]()
    else
        print("No such command: '", commandName, "'")
    end
end

--multiple functions can be registered for the same key
function mods.lightweight_editor.registerKeyFunctionCombo(operatorKey, modifierKeys, callback)
    --print("registering ", operatorKey, modKey)
    if not  mKeyBindings[operatorKey] then
         mKeyBindings[operatorKey] = {}
    end

    local modKey = getModifiersAsString(modifierKeys)
    --print("modkey1 ", modKey)
    if not mKeyBindings[operatorKey][modKey] then
         mKeyBindings[operatorKey][modKey] = {}
    end

    table.insert(mKeyBindings[operatorKey][modKey], callback)
    --print("registered ", operatorKey, modKey)
end

-- Function to execute callbacks for a given key press
local function executeKeyFunctions(operatorKey)
    local modKey = getModifiersAsString(normalizedModifierKeys())
    --print("modkey ", modKey)
    local callbacksList = mKeyBindings[operatorKey]
    if not callbacksList then return end
    local callbacks = callbacksList[modKey]
    if callbacks then
        for _, callback in ipairs(callbacks) do
            --print("found callback for ", operatorKey, modKey)
            callback(operatorKey)
        end
    end
end


--SPECIAL FUNCTIONS

local function flushMinibuffer(execute)
    if (execute) then
        --print("executed ", mMinibufferText)
        executeBufferCommand(mMinibufferText)
        --todo execute buffer command
        --todo create table of buffer commands and registration function like for the keybinds.
    end
    mMinibufferText = ""
    mMinibufferMode = false
end

--prints to the minibuffer
local function localPrint(character)
    if (character ~= nil) then
        if (mMinibufferMode) then
            mMinibufferText = mMinibufferText..character
        end
    end
end

local function handleShiftCaps(lowercaseChar, uppercaseChar)
    --xor
    local useUppercase = not (not lwed.shiftPressed() == not mCapsLock)
    --print("printing handled shift, ", lowercaseChar, uppercaseChar, useUppercase, ((useUppercase and uppercaseChar) or lowercaseChar))
    return (useUppercase and uppercaseChar) or lowercaseChar
end

--For all the printable keys, register a function that "prints" that character (to the current buffer).
for k, v in pairs(KEY_TO_CHARACTER_MAP) do
    --k, v[1], v[2]
    mods.lightweight_editor.registerKeyFunctionCombo(k, {}, function(operatorKey)
            localPrint(handleShiftCaps(v[1], v[2]))
        end)
    mods.lightweight_editor.registerKeyFunctionCombo(k, {"SHIFT"}, function(operatorKey)
            localPrint(handleShiftCaps(v[1], v[2]))
        end)
end

--Modifier keys don't do anything on their own, they are checked when other keys are pressed.
local function modifierKeyDown(keyId)
    --print("modifier key pressed ", keyId)
    mPressedModifierKeys[keyId] = keyId
end

local function modifierKeyUp(keyId)
    mPressedModifierKeys[keyId] = nil
end

local function onFtlKeyDown(keyId)
    --modifier keys
    for i = 1, #MODIFIER_KEYS do
        --print("mod key check ", keyId, MODIFIER_KEYS[i])
        if keyId == MODIFIER_KEYS[i] then
            modifierKeyDown(keyId)
        end
    end
    
    --Keys that bypass modifiers
    if (keyId == "KEY_RETURN") and mMinibufferMode then
        flushMinibuffer(true)
    end
    if (keyId == "KEY_BACKSPACE") and mMinibufferMode then
        mMinibufferText = mMinibufferText:sub(1, -2)
    end
    if (keyId == "KEY_CAPSLOCK") then
        mCapsLock = not mCapsLock
    end
    --callbacks
    executeKeyFunctions(keyId)
end

local function onFtlKeyUp(keyId)
    for i = 1, #MODIFIER_KEYS do
        if keyId == MODIFIER_KEYS[i] then
            modifierKeyUp(keyId)
        end
    end
end

mods.lightweight_editor.registerKeyFunctionCombo("KEY_x", {"META"}, function(operatorKey)
        mMinibufferMode = true
    end)
mods.lightweight_editor.registerKeyFunctionCombo("KEY_g", {"CTRL"}, function(operatorKey)
        flushMinibuffer(false)
    end)

mods.lightweight_editor.registerBufferCommand("help", function()
        print("for help type 'HERP'")
    end)
mods.lightweight_editor.registerBufferCommand("herp", function()
        print("herp is nowhere to be seen.")
    end)

--render loop, should render a box with text on top of it when the buffer is running.


--uh, M-x opens the minibuffer so you can type stuff.
--mods.lightweight_editor.registerKeyFunctionCombo()
-- A magic item that works by you referencing the idea of it, by this you can pull out a shining pellet and change.

--How to implement the minibuffer?  Basically, every time a character is pressed, we will add it to a buffer.  Enter submits the buffer for evaluation, and c-g aborts the buffer.  The buffer is triggered with meta-x, once that happens we start recording, otherwise keystrokes with no modifiers are ignored.  The default for all combinations is actually nothing.

--The behavior for keystroke, and keystroke + only shift, is a function which looks up in a table based on the keyCode what should print.
--[KEY_A, a, A; KEY_AMPERSAND, &, &], and so on.  Caps lock inverts this, I don't care about its initial state or if that's confusing.

if script then
    script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function() 
        if mMinibufferMode then
            local storedColor = Graphics.CSurface.GL_GetColor()
            Graphics.CSurface.GL_DrawRect(247, 700, 500, 18, Graphics.GL_Color(28 / 256, 134 / 256, 238 / 256, .85));
            Graphics.CSurface.GL_SetColor(Graphics.GL_Color(.8, .8, .8, 1))
            Graphics.freetype.easy_print(14, 250, 692, mMinibufferText)
            Graphics.CSurface.GL_SetColor(storedColor)
        end
        --render a blue bar below the uatofire button, render light grey text on top of that. 247, 700, 750, 718
        end)

    script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(Key)
            --print("onDown ", keyNameTable[Key])
            onFtlKeyDown(keyNameTable[Key])
        end)
    script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(Key)
            --print("onUp ", keyNameTable[Key])
            onFtlKeyUp(keyNameTable[Key])
        end)
end
--render loop, should render a box with text on top of it when the buffer is running.


--uh, M-x opens the minibuffer so you can type stuff.
--mods.lightweight_editor.registerKeyFunctionCombo()
-- A magic item that works by you referencing the idea of it, by this you can pull out a shining pellet and change.

--How to implement the minibuffer?  Basically, every time a character is pressed, we will add it to a buffer.  Enter submits the buffer for evaluation, and c-g aborts the buffer.  The buffer is triggered with meta-x, once that happens we start recording, otherwise keystrokes with no modifiers are ignored.  The default for all combinations is actually nothing.

--The behavior for keystroke, and keystroke + only shift, is a function which looks up in a table based on the keyCode what should print.
--[KEY_A, a, A; KEY_AMPERSAND, &, &], and so on.  Caps lock inverts this, I don't care about its initial state or if that's confusing.


print("hello this printed")
onFtlKeyDown("KEY_RALT")
print(lwed.metaPressed())
onFtlKeyDown("KEY_x")
print("buffer text ", mMinibufferText)
print("Should be non-nil", mPressedModifierKeys["KEY_RALT"])
onFtlKeyUp("KEY_RALT")
onFtlKeyDown("KEY_x")
onFtlKeyDown("KEY_x")
onFtlKeyDown("KEY_s")
print("buffer text ", mMinibufferText)
onFtlKeyDown("KEY_RETURN")