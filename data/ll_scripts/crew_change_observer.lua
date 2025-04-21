if (not mods) then mods = {} end
mods.lightweight_crew_change_observer = {}
local lwcco = mods.lightweight_crew_change_observer
local lwl = mods.lightweight_lua

local mCrewChangeObservers = {}

--God, what about ship-to-ship teleport?
--[[
What do I _do_ about 
Right, you track the current teleporting crew (they cannot die while teleporting) (_NO_) and unset that value when you find them again and they aren't teleporting.

--]]


--[[
usage: 

local crewChangeObserver = lwcco.createCrewChangeObserver(tracking, shipId)
Then call crewChangeObserver.getAddedCrew() and getAddedCrew() when you want to know what changed since you last saved,
    and saveLastSeenState() when you want to let the observer know you're up to date.
    
    
    local function compareCrewLists(list1, list2)
    return (#lwl.getNewElements(list1, list2) == 0) and (#lwl.getNewElements(list1, list2) == 0)
end                --Crew blink out of existance for one frame when teleporting (only on the way back???)  

--]]

--Crew blink out of existance for one frame when teleporting (only on the way back???)
if (script) then--todo optimize maybe.  Ok actually not maybe, and instead of optimal we want clean because this stuff is MESSY and lots of important things depend on it.
    script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
        --Initialization code
        if not mGlobal then
            mGlobal = Hyperspace.Global.GetInstance()
        end
        local ownshipManager = mGlobal:GetShipManager(0)
        local enemyManager = mGlobal:GetShipManager(1)
        --[[
        --Check for teleporting crew
        if (ownshipManager) then
            --update mCrewIds
            for _, crewChangeObserver in ipairs(mCrewChangeObservers) do
                crewChangeObserver.crew = {}
                local playerCrew = lwl.getAllMemberCrew(ownshipManager, crewChangeObserver.tracking)
                local enemyCrew = {}
                if enemyManager then
                    enemyCrew = lwl.getAllMemberCrew(enemyManager, crewChangeObserver.tracking)
                end
                for _,crewmem in ipairs(playerCrew) do
                    if crewmem.extend.customTele.teleporting then
                        print(crewmem:GetName(), " is teleporting!")
                        crewChangeObserver.teleportingCrew = lwl.setMerge(crewChangeObserver.teleportingCrew, {crewmem.extend.selfId})
                    else
                        crewChangeObserver.teleportingCrew = lwl.setRemove(crewChangeObserver.teleportingCrew, {crewmem.extend.selfId})
                    end
                end
                for _,crewmem in ipairs(enemyCrew) do
                    if crewmem.extend.customTele.teleporting then
                        print(crewmem:GetName(), " is teleporting!")
                        crewChangeObserver.teleportingCrew = lwl.setMerge(crewChangeObserver.teleportingCrew, {crewmem.extend.selfId})
                    else
                        crewChangeObserver.teleportingCrew = lwl.setRemove(crewChangeObserver.teleportingCrew, {crewmem.extend.selfId})
                    end
                end
                if #crewChangeObserver.teleportingCrew > 0 then
                    for _,id in ipairs(crewChangeObserver.teleportingCrew) do
                        print(lwl.getCrewById(id):GetName(), " is teleporting, skipping observer update")
                    end
                    return
                end
            end
        end
        --]]

        
        --If anybody is teleporting, skip this update.
        if (ownshipManager) then
            --update mCrewIds
            local enemyCrew = {}
            for _, crewChangeObserver in ipairs(mCrewChangeObservers) do
                local localCrewBuffer = {}
                if enemyManager then
                    enemyCrew = lwl.getAllMemberCrew(enemyManager, crewChangeObserver.tracking)
                end
                local playerCrew = lwl.getAllMemberCrew(ownshipManager, crewChangeObserver.tracking)
                crewChangeObserver.crew = {}
                if crewChangeObserver.shipId == 0 or crewChangeObserver.shipId == -2 then
                    for _,crewmem in ipairs(playerCrew) do
                        --print("player crew ", crewmem:GetName())  This is properly updating.
                        table.insert(localCrewBuffer, crewmem)
                    end
                end
                if crewChangeObserver.shipId == 1 or crewChangeObserver.shipId == -2 then
                    for _,crewmem in ipairs(enemyCrew) do
                        table.insert(localCrewBuffer, crewmem)
                    end
                end
            end
        end
    end)
end

--[[
tracking={"crew", "drones", or "all"}  If no value is passed, defaults to all.
shipId = {-2, 0, 1} If not set, defaults to ownship. -2 is both ships.
--]]
function lwcco.createCrewChangeObserver(tracking, shipId)
    if not tracking then tracking = "all" end
    if not shipId then shipId = 0 end
    local crewChangeObserver = {}
    crewChangeObserver.tracking = tracking
    crewChangeObserver.shipId = shipId
    crewChangeObserver.crew = {}
    crewChangeObserver.lastSeenCrew = {}
    crewChangeObserver.teleportingCrew = {}

    --actually no, just return a new object to all consumers so they don't conflict.
    local function saveLastSeenState()
        crewChangeObserver.lastSeenCrew = lwl.deepCopyTable(crewChangeObserver.crew)
    end
    --local function hasStateChanged()
    --Return arrays of the crew diff from last save.
    local function getAddedCrew()
        return lwl.getNewElements(crewChangeObserver.crew, crewChangeObserver.lastSeenCrew)
    end
    local function getRemovedCrew()
        return lwl.getNewElements(crewChangeObserver.lastSeenCrew, crewChangeObserver.crew)
    end
    
    crewChangeObserver.saveLastSeenState = saveLastSeenState
    crewChangeObserver.getAddedCrew = getAddedCrew
    crewChangeObserver.getRemovedCrew = getRemovedCrew
    table.insert(mCrewChangeObservers, crewChangeObserver)
    return crewChangeObserver
end