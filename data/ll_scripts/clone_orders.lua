--[[
Basically this listens for when a crew undies, and makes them briefly insane.
This makes them much better overall subordinates.
Advanced: have them go to their demarked positions.  (or even their Extra positions!)
]]

local lwl = mods.lightweight_lua
local lwce = mods.lightweight_crew_effects
local lweb = mods.lightweight_event_broadcaster


--todo make this maybe not function in the hangar so it throws less errors.


local function temporaryInsanity(crewmem)
    if lwl.setIfNil(Hyperspace.metaVariables["lwl_clone_auto_pathing"], 0) == 1 then
        lwce.applyConfusion(crewmem, 1)
    end
end

lweb.registerClonedListener(temporaryInsanity)