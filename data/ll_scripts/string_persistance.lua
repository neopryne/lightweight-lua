

local lwl = mods.lightweight_lua

--Chatgpt, 2026
-- helper: build subkeys
local function makeKey(base, index)
    return base .. ":" .. index
end

-- helper: string → codepoints
local function stringToCodepoints(str)
    local t = {}
    for _, code in utf8.codes(str) do
        t[#t+1] = code
    end
    return t
end

-- helper: codepoints → string
local function codepointsToString(t)
    if #t == 0 then
        return ""
    end
    return utf8.char(table.unpack(t))
end


---
---@param key string Unique identifier for this object.
---@param value string The string you want to persist.
---@param isMeta boolean true for metavariable, false for player variable.
function lwl.persistString(key, value, isMeta)
    local storageMedium
    if isMeta then
        storageMedium = Hyperspace.metaVariables
    else
        storageMedium = Hyperspace.playerVariables
    end

    local codepoints = stringToCodepoints(value)
    local length = #codepoints

    -- store length
    storageMedium[makeKey(key, "len")] = length

    -- store characters
    for i = 1, length do
        storageMedium[makeKey(key, i)] = codepoints[i]
    end
end


---
---@param key string Unique identifier for this object.
---@param isMeta boolean true for metavariable, false for player variable.
---@return string The string stored at this key.
function lwl.loadString(key, isMeta)
    local storageMedium
    if isMeta then
        storageMedium = Hyperspace.metaVariables
    else
        storageMedium = Hyperspace.playerVariables
    end

    local length = storageMedium[makeKey(key, "len")]

    if not length or length == 0 then
        return ""
    end

    local codepoints = {}

    for i = 1, length do
        codepoints[i] = storageMedium[makeKey(key, i)]
    end

    local value = codepointsToString(codepoints)
    return value
end


---
---@param key string Unique identifier for this object.
---@return string|nil The string stored at this key
function lwl.loadStringPlayerVariable(key)
    return lwl.loadString(key, false)
end

---
---@param key string Unique identifier for this object.
---@return string The string stored at this key.
function lwl.loadStringMetaVariable(key)
    return lwl.loadString(key, true)
end


---
---@param key string Unique identifier for this object.
---@param value string The string you want to persist.
function lwl.persistStringPlayerVariable(key, value)
    return lwl.persistString(key, value, false)
end

---
---@param key string Unique identifier for this object.
---@param value string The string you want to persist.
function lwl.persistStringMetaVariable(key, value)
    return lwl.persistString(key, value, true)
end

-- mods.lightweight_lua.persistStringMetaVariable("name", "ЖA")
-- print("metavar name:", mods.lightweight_lua.loadStringMetaVariable("name"))

-- mods.lightweight_lua.persistStringPlayerVariable("name", "dasfsdf")
-- print("player var name:", mods.lightweight_lua.loadStringPlayerVariable("name"))

-- mods.lightweight_lua.persistStringPlayerVariable("name", "dasfsdf")
-- print("player var name:", mods.lightweight_lua.loadStringPlayerVariable("name"))