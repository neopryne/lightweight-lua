local lwl = mods.lightweight_lua
local primitiveList = mods.lightweight_lua.primitiveList

--[[

Things that should be cached.  Centralized because it should be and to reduce code duplication.
]]

--This won't be as useful as I thought outside of this, as it can't do other parameters.
--Allows a render event to refer to an already-existing primitive of a png file if possible to avoid creating duplicates.
function lwl.primitiveListManager(string, createCentered)
    local x, y = 0, 0
    local cacheString = string..tostring(createCentered)
    if not primitiveList[cacheString] then
        local stringID = Hyperspace.Resources:GetImageId(string)
        if createCentered then
            x = -stringID.width / 2
            y = -stringID.height / 2
        end
        primitiveList[cacheString] = Hyperspace.Resources:CreateImagePrimitiveString(
            string,
            x,
            y,
            0,
            Graphics.GL_Color(1, 1, 1, 1),
            1.0,
            false
        )
    end
    return primitiveList[cacheString]
end