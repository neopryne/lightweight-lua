--[[
Basically this listens for when a crew undies, and makes them briefly insane.
This makes them much better overall subordinates.
Advanced: have them go to their demarked positions.  (or even their Extra positions!)
]]

local lwl = mods.lightweight_lua
local lwce = mods.lightweight_crew_effects
local lweb = mods.lightweight_event_broadcaster
local mscp
--todo make this maybe not function in the hangar so it throws less errors.
---also so that your crew doesn't randomly walk around when you start a run.  That's annoying.
--todo this can lock you out of moving crew.  disable until fixed.
---Saved slot?
local TAG = "clone_orders"

---Try to load any saved slots, and fall back to using game AI.
---@param crewmem any
local function pickDestination(crewmem)
    if lwl.setIfNil(Hyperspace.metaVariables["lwl_clone_auto_pathing"], 0) == 1 then
        if not mscp then
            lwl.logDebug(TAG, "mscp was missing.")
            lwce.applyConfusion(crewmem, 1)
        else
            if not mscp.moveToSavedPosition(crewmem, 1) then
                if not mscp.moveToSavedPosition(crewmem, 2) then
                    lwce.applyConfusion(crewmem, 1)
                end
            end
        end
    end
end

lweb.registerClonedListener(pickDestination)

script.on_init(function(newGame)
    mscp = mods.more_crew_positions
end)