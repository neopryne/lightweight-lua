if (not mods) then mods = {} end
mods.lightweight_crew_change_observer = {}
local lwcco = mods.lightweight_crew_change_observer
local lwl = mods.lightweight_lua

local mCrewChangeObservers = {}

--[[

--]]

if (script) then--todo optimize maybe
    script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
        --Initialization code
        if not mGlobal then
            mGlobal = Hyperspace.Global.GetInstance()
        end
        local ownshipManager = mGlobal:GetShipManager(0)
        local enemyManager = mGlobal:GetShipManager(1)
        if (ownshipManager) then
            --update mCrewIds
            local enemyCrew = {}
            for _, crewChangeObserver in ipairs(mCrewChangeObservers) do
                if enemyManager then
                    enemyCrew = lwl.getAllMemberCrew(enemyManager, crewChangeObserver.tracking)
                end
                local playerCrew = lwl.getAllMemberCrew(ownshipManager, crewChangeObserver.tracking)
                crewChangeObserver.crew = {}
                if crewChangeObserver.shipId == 0 then
                    for _,crewmem in ipairs(playerCrew) do
                        table.insert(crewChangeObserver.crew, crewmem)--todo check if this compares correctly.
                    end
                else
                    for _,crewmem in ipairs(enemyCrew) do
                        table.insert(crewChangeObserver.crew, crewmem)--todo check if this compares correctly.
                    end
                end
            end
        end
    end)
end

--[[
tracking={"crew", "drones", or "all"}  If no value is passed, defaults to all.
shipId = {0,1} If not set, defaults to ownship.
--]]
function lwcco.createCrewChangeObserver(tracking, shipId)
    if not tracking then tracking = "all" end
    if not shipId then shipId = 0 end
    local crewChangeObserver = {}
    crewChangeObserver.tracking = tracking
    crewChangeObserver.shipId = shipId
    crewChangeObserver.crew = {}
    crewChangeObserver.lastSeenCrew = {}

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