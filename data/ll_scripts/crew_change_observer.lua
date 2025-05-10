--[[
usage: 

local crewChangeObserver = lwcco.createCrewChangeObserver()
Wait for crewChangeObserver.isInitialized() to become true.
Then call crewChangeObserver.getAddedCrew() and getRemovedCrew() when you want to know what changed since you last saved,
    and saveLastSeenState() when you want to let the observer know you're up to date.
CCO is an alternative to saving crew.  If you're using CCO, don't persist your crew; rely on CCO to tell you who's around.
--]]

if (not mods) then mods = {} end
mods.lightweight_crew_change_observer = {}
local lwcco = mods.lightweight_crew_change_observer
local lwtso = mods.lightweight_teleport_status_observer
local lwl = mods.lightweight_lua

local TAG = "LW Crew Change Observer"

local mCrewChangeObservers = {}
local mCrewMemberFactory
local mSetupRequested = false
local mTeleportStatusObserver

--todo make it ignore crew you don't have.
--Fixed it already, but one correct solution to this is not to allow effects/equipment to add duplicate crewIds.  I think I may need to do that also.

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mSetupRequested then return end--todo use crew factory in some smart way, maybe let the user pass in a filter function that takes this object (and other things)
    --Initialization code
    if not Hyperspace.ships(0) or Hyperspace.ships(0).iCustomizeMode == 2 or lwl.isPaused() then return end
    if not mTeleportStatusObserver.isInitialized() then
        print("lightweight_crew_change_observer: mTeleportStatusObserver is not set up yet, waiting till it is.")
        return 
    end
    
    for _,crewId in ipairs(mTeleportStatusObserver.getAddedCrew()) do--todo this might not be needed anymore.
        --print(lwl.getCrewById(crewId):GetName(), " is teleporting! lwcco") --lol the error actually works as a log here.
        --We have to wait till this list is empty, so we never save this value.
        return
    end
    
    --update mCrewIds
    for _,crewChangeObserver in ipairs(mCrewChangeObservers) do
        crewChangeObserver.selfIsInitialized = true
        local currentCrew = lwl.getAllMemberCrewFromFactory(crewChangeObserver.filterFunction)
        crewChangeObserver.crew = {}
        for _,crewmem in ipairs(currentCrew) do
            table.insert(crewChangeObserver.crew, crewmem.extend.selfId)
        end
        crewChangeObserver.selfIsInitialized = true
    end
end)

script.on_game_event("START_BEACON_REAL", false, function() --reset observers on restart.  --todo also for tele if I still need it.  I do, but the way I use CCO means I personally don't.
        for _,crewChangeObserver in ipairs(mCrewChangeObservers) do
            if crewChangeObserver.selfIsInitialized then
                crewChangeObserver.crew = {}
            end
        end
        end)

--[[todo remove dead crew  :OutOfGame()?:IsDead()
    bool :PermanentDeath()
tracking={"crew", "drones", or "all"}  If no value is passed, defaults to all.
shipId = {0,1} If not set, defaults to ownship.
extend:GetDefinition().noWarning
--]]
function lwcco.createCrewChangeObserver(filterFunction)
    mSetupRequested = true
    mTeleportStatusObserver = lwtso.createTeleportStatusObserver()
    local crewChangeObserver = {}
    crewChangeObserver.filterFunction = filterFunction
    crewChangeObserver.crew = {}
    crewChangeObserver.lastSeenCrew = {}
    crewChangeObserver.selfIsInitialized = false

    --actually no, just return a new object to all consumers so they don't conflict.
    local function saveLastSeenState()
        crewChangeObserver.lastSeenCrew = lwl.deepCopyTable(crewChangeObserver.crew)
    end
    local function getAddedCrew()
        --print("currentCrew", lwl.dumpObject(crewChangeObserver.crew))
        --print("what the observer knows about", lwl.dumpObject(crewChangeObserver.lastSeenCrew))
        return lwl.getNewElements(crewChangeObserver.crew, crewChangeObserver.lastSeenCrew)
    end
    local function getRemovedCrew()
        local removedCrew = lwl.getNewElements(crewChangeObserver.lastSeenCrew, crewChangeObserver.crew)
        if #removedCrew > 0 then
            --print("Removed crew ", #removedCrew)
        end
        return removedCrew
    end
    local function isInitialized()
        return crewChangeObserver.selfIsInitialized
    end
    
    crewChangeObserver.saveLastSeenState = saveLastSeenState
    crewChangeObserver.getAddedCrew = getAddedCrew
    crewChangeObserver.getRemovedCrew = getRemovedCrew
    crewChangeObserver.isInitialized = isInitialized
    table.insert(mCrewChangeObservers, crewChangeObserver)
    return crewChangeObserver
end