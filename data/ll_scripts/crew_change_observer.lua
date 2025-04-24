--[[
usage: 

local crewChangeObserver = lwcco.createCrewChangeObserver()
Wait for crewChangeObserver.isInitialized() to become true.
Then call crewChangeObserver.getAddedCrew() and getRemovedCrew() when you want to know what changed since you last saved,
    and saveLastSeenState() when you want to let the observer know you're up to date.
--]]

if (not mods) then mods = {} end
mods.lightweight_crew_change_observer = {}
local lwcco = mods.lightweight_crew_change_observer
local lwtso = mods.lightweight_teleport_status_observer
local lwl = mods.lightweight_lua

local mCrewChangeObservers = {}
local mGlobal
local mCrewMemberFactory
local mTeleportStatusObserver = lwtso.createTeleportStatusObserver()

--todo this conflicts with whatever I'm doing in equipment when you load a file with teleporting crew.
--Fixed it already, but one correct solution to this is not to allow effects/equipment to add duplicate crewIds.

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()--todo use crew factory in some smart way, maybe let the user pass in a filter function that takes this object (and other things)
    --Initialization code
    if not mGlobal then
        mGlobal = Hyperspace.Global.GetInstance()
    end
    local ownshipManager = mGlobal:GetShipManager(0)
    local enemyManager = mGlobal:GetShipManager(1)
    if (ownshipManager) then
        
        if not mTeleportStatusObserver.isInitialized() then
            print("lightweight_crew_change_observer: mTeleportStatusObserver is not set up yet, waiting till it is.")
            return 
        end
        for _,crewId in ipairs(mTeleportStatusObserver.getAddedCrew()) do
            print(lwl.getCrewById(crewId):GetName(), " is teleporting! lwcco") --lol the error actually works as a log here.
            --We have to wait till this list is empty, so we never save this value.
            return
        end
        
        --update mCrewIds
        for _, crewChangeObserver in ipairs(mCrewChangeObservers) do
            local enemyCrew = {}
            if enemyManager then
                enemyCrew = lwl.getAllMemberCrew(enemyManager, crewChangeObserver.tracking)
            end
            local playerCrew = lwl.getAllMemberCrew(ownshipManager, crewChangeObserver.tracking)
            crewChangeObserver.crew = {}
            if crewChangeObserver.shipId == 0 or crewChangeObserver.shipId == -2 then
                for _,crewmem in ipairs(playerCrew) do
                    --print("player crew ", crewmem:GetName())  This is properly updating.
                    table.insert(crewChangeObserver.crew, crewmem.extend.selfId)
                end
            end
            if crewChangeObserver.shipId == 1 or crewChangeObserver.shipId == -2 then
                for _,crewmem in ipairs(enemyCrew) do
                    table.insert(crewChangeObserver.crew, crewmem.extend.selfId)
                end
            end
            crewChangeObserver.selfIsInitialized = true
        end
    end
end)


--[[
--Version using CrewFactory
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    --Initialization code
    if not mGlobal then
        mGlobal = Hyperspace.Global.GetInstance()
    end
    local ownshipManager = mGlobal:GetShipManager(0)
    local enemyManager = mGlobal:GetShipManager(1)
    if (ownshipManager) then
        
        --update mCrewIds
        for _, crewChangeObserver in ipairs(mCrewChangeObservers) do
            local enemyCrew = {}
            if enemyManager then
                enemyCrew = lwl.getAllMemberCrewFromFactory(enemyManager, crewChangeObserver.tracking)
            end
            local playerCrew = lwl.getAllMemberCrewFromFactory(ownshipManager, crewChangeObserver.tracking)
            crewChangeObserver.crew = {}
            if crewChangeObserver.shipId == 0 or crewChangeObserver.shipId == -2 then
                for _,crewmem in ipairs(playerCrew) do
                    --print("player crew ", crewmem:GetName())  This is properly updating.
                    table.insert(crewChangeObserver.crew, crewmem.extend.selfId)
                end
            end
            if crewChangeObserver.shipId == 1 or crewChangeObserver.shipId == -2 then
                for _,crewmem in ipairs(enemyCrew) do
                    table.insert(crewChangeObserver.crew, crewmem.extend.selfId)
                end
            end
            crewChangeObserver.selfIsInitialized = true
        end
    end
end)
--]]

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
    crewChangeObserver.selfIsInitialized = false

    --actually no, just return a new object to all consumers so they don't conflict.
    local function saveLastSeenState()
        crewChangeObserver.lastSeenCrew = lwl.deepCopyTable(crewChangeObserver.crew)
    end
    local function getAddedCrew()
        return lwl.getNewElements(crewChangeObserver.crew, crewChangeObserver.lastSeenCrew)
    end
    local function getRemovedCrew()
        local removedCrew = lwl.getNewElements(crewChangeObserver.lastSeenCrew, crewChangeObserver.crew)
        if #removedCrew > 0 then
            print("Removing crew ", #removedCrew)
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