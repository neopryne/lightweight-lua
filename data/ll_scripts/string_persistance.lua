

local lwl = mods.lightweight_lua

--Chatgpt, 2026
local ASCII_MAX = 127
local CYRILLIC_BASE = 0x0400


-- encode unicode codepoint → byte
local function encodeChar(code)
    if code <= ASCII_MAX then
        return code
    else
        return (code - CYRILLIC_BASE) + 128
    end
end


-- decode byte → unicode codepoint
local function decodeChar(byte)
    if byte <= ASCII_MAX then
        return byte
    else
        return (byte - 128) + CYRILLIC_BASE
    end
end


local function packBytes(b1,b2,b3,b4)
    return (b1)
        | (b2 << 8)
        | (b3 << 16)
        | (b4 << 24)
end


local function unpackBytes(n)
    local b1 =  n        & 0xFF
    local b2 = (n >> 8)  & 0xFF
    local b3 = (n >> 16) & 0xFF
    local b4 = (n >> 24) & 0xFF
    return b1,b2,b3,b4
end

---
---@param key string Unique identifier for this object.
---@param value string The string you want to persist.
---@param isMeta boolean true for metavariable, false for player variable.
function lwl.persistString(key, value, isMeta)
    -- print("Saving string", key, value, isMeta)
    local storageMedium
    if isMeta then
        storageMedium = Hyperspace.metaVariables
    else
        storageMedium = Hyperspace.playerVariables
    end

    local bytes = {}

    -- encode characters
    for _,code in utf8.codes(value) do
        bytes[#bytes+1] = encodeChar(code)
    end

    local length = #bytes
    storageMedium[key..":len"] = length
    -- print("Saved length ", storageMedium[key..":len"], "as", key..":len")

    local storageIndex = 1
    local i = 1

    while i <= length do

        -- explicit padding
        local b1 = bytes[i]     or 0
        local b2 = bytes[i + 1] or 0
        local b3 = bytes[i + 2] or 0
        local b4 = bytes[i + 3] or 0

        storageMedium[key..":"..storageIndex] =
            packBytes(b1,b2,b3,b4)

        i = i + 4
        storageIndex = storageIndex + 1
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

    local length = storageMedium[key..":len"]
    -- print("Loaded length ", key..":len", "as", storageMedium[key..":len"])
    if not length then
        return ""
    end

    local bytes = {}
    local storageIndex = 1

    while #bytes < length do

        local packed = storageMedium[key..":"..storageIndex] or 0
        local b1,b2,b3,b4 = unpackBytes(packed)

        if #bytes < length then bytes[#bytes+1] = b1 end
        if #bytes < length then bytes[#bytes+1] = b2 end
        if #bytes < length then bytes[#bytes+1] = b3 end
        if #bytes < length then bytes[#bytes+1] = b4 end

        storageIndex = storageIndex + 1
    end


    local codepoints = {}

    for i=1,length do
        codepoints[i] = decodeChar(bytes[i])
    end

    local loadedString = utf8.char(table.unpack(codepoints))
    -- print("Loading string", key, loadedString, isMeta)
    return loadedString
end

---
---@param key string Unique identifier for this object.
---@return string The string stored at this key, or the empty string if not found.
function lwl.loadStringPlayerVariable(key)
    return lwl.loadString(key, false)
end

---
---@param key string Unique identifier for this object.
---@return string The string stored at this key, or the empty string if not found.
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

-- mods.lightweight_lua.persistStringMetaVariable("name2", "ЖAasdfsadfsdf")
-- print("metavar name:", mods.lightweight_lua.loadStringMetaVariable("name2"))

-- mods.lightweight_lua.persistStringPlayerVariable("name2", "ЖAasdfsadfs")
-- print("player var name:", mods.lightweight_lua.loadStringPlayerVariable("name2"))

-- mods.lightweight_lua.persistStringPlayerVariable("name", "dasfsdf")
-- print("player var name:", mods.lightweight_lua.loadStringPlayerVariable("name"))


-- mods.lightweight_lua.persistStringPlayerVariable("a long name that has spaces in it really really long name", "rrrrrrrrrrrrrr")
-- print("player var name:", mods.lightweight_lua.loadStringPlayerVariable("a long name that has spaces in it really really long name"))