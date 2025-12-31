local lwl = mods.lightweight_lua
local vter = mods.multiverse.vter
--[[
Usage: Patch this mod.
--]]

lwl.safe_script.on_render_event("lwl_print_room_info", Defines.RenderEvents.SHIP_SPARKS, function() end, function(ship)
    if not (lwl.varAsBoolean(Hyperspace.metaVariables["lwl_print_room_info"])) then return end
    local shipManager = Hyperspace.ships(ship.iShipId)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
    for room in vter(shipGraph.rooms) do
        local shape = shipGraph:GetRoomShape(room.iRoomId)
        Graphics.CSurface.GL_SetColor(Graphics.GL_Color(0, 0, 0, 1))
        Graphics.freetype.easy_print(8, shape.x + 5, shape.y, tostring(math.floor(room.iRoomId)))
        local width = shape.w / lwl.TILE_SIZE()
        local height = shape.h / lwl.TILE_SIZE()
        Graphics.CSurface.GL_SetColor(Graphics.GL_Color(0, 0, .8, 1))
        for i = 1, width do
            for j = 1, height do
                local x = shape.x - 15 + (lwl.TILE_SIZE() * i)
                local y = shape.y - 15 + (lwl.TILE_SIZE() * j)
                local slot = lwl.slotIdAtPoint(Hyperspace.Point(x,y), shipManager)
                Graphics.freetype.easy_print(8, x, y, tostring(math.floor(slot)))
            end
        end
    end
end)