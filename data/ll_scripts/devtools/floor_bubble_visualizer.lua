local lwl = mods.lightweight_lua
local vter = mods.multiverse.vter
--[[
Usage: Patch this mod.
--]]

local function shouldRenderFloorBubbles()
    return lwl.varAsBoolean(Hyperspace.metaVariables["lwl_render_floor_bubbles"])
end

--TODO sliders for bubble size and opacity. (both 0-100)

---A slider is defined as a button and two points.  The buffer on a slider is part of the skin.  Sliders have skins.  Scroll bars already use sliders.
---The nub is locked to the line defined by the points.  It cannot go past the points + their buffer.  Add negative buffer to extend this.
---
---

--gpt code to get the slider thing
local function makePerpendicularProjector(a, b)
    -- Direction vector of the line AB
    local dx = b.x - a.x
    local dy = b.y - a.y

    -- Precompute length squared (used every call)
    local len2 = dx*dx + dy*dy

    -- Edge case: a and b are the same point
    if len2 == 0 then
        error("Line points must not be identical")
    end

    return function(p)
        -- Vector from A to P
        local px = p.x - a.x
        local py = p.y - a.y

        -- Project AP onto AB using dot product
        local t = (px*dx + py*dy) / len2
        t = math.max(0, math.min(1, t)) --clamp t between endpoints

        -- Closest point on the line
        return {
            x = a.x + t * dx,
            y = a.y + t * dy
        }
    end
end


---Sliders return a value from 0-1 inclusive for how far the nub is from the bottom.  If both points are the same, output is undefined but valid.
---They will rotate the images involved to align with the inscribed line. todo this.
---ugh.  I'm just going to ship this.  This also makes several letterbox mods obsolute, which is good.
local function createSlider(topPoint, bottomPoint, skin)
    ---nub is an lwl button.  When held, it moves to the point described by the intersection of the inscribed line, and a perpendicular line originating from the cursor.
    ---ask gpt about this maybe, i can't right now.
    
end

local mBubbleRadius = 55
local mBubbleAlpha = .2
local mBubbleColor = function ()
    return Graphics.GL_Color(.2, .5, .7, mBubbleAlpha)
end

lwl.safe_script.on_render_event("lwl_render_floor_bubbles", Defines.RenderEvents.SHIP_SPARKS, function() end, function(ship)
    if not (shouldRenderFloorBubbles()) then return end
    local shipManager = Hyperspace.ships(ship.iShipId)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
    for room in vter(shipGraph.rooms) do
        local shape = shipGraph:GetRoomShape(room.iRoomId)
        local width = shape.w / lwl.TILE_SIZE()
        local height = shape.h / lwl.TILE_SIZE()
        --Graphics.CSurface.GL_SetColor(Graphics.GL_Color(0, 0, .8, 1))
        for i = 1, width do
            for j = 1, height do
                local x = shape.x - 15 + (lwl.TILE_SIZE() * i)
                local y = shape.y - 15 + (lwl.TILE_SIZE() * j)
                local slot = lwl.slotIdAtPoint(Hyperspace.Point(x,y), shipManager)
                local slotCenter = lwl.slotCenter(ship.iShipId, room.iRoomId, slot)
                Graphics.CSurface.GL_DrawCircle(slotCenter.x, slotCenter.y, mBubbleRadius, mBubbleColor())
            end
        end
    end
end)