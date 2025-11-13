--[[
usage: 

local teleportStatusObserver = lwtso.createTeleportStatusObserver()
Wait for teleportStatusObserver.isInitialized() to become true.
Then call teleportStatusObserver.getAddedCrew() and getRemovedCrew() when you want to know what changed since you last saved,
    and saveLastSeenState() when you want to let the observer know you're up to date.
--]]

--[[
You track the current teleporting crew (if they die while teleporting we're screwed, but ignore that) and unset that value when you find them again and they aren't teleporting.
My use for this is in crew_change_observer, but really this is the only way to tell if someone is teleporting or not due to FTL's buggy logic surrounding this.
--]]

if (not mods) then mods = {} end
mods.lightweight_teleport_status_observer = {}
local lwtso = mods.lightweight_teleport_status_observer
local lwl = mods.lightweight_lua

local TAG = "LW Tele Status Observer"

local mTeleportStatusObservers = {}
local mSetupRequested = false
local mGlobal

--Crew blink out of existance for one frame when teleporting (only on the way back???)
--todo optimize maybe.  Ok actually not maybe, and instead of optimal we want clean because this stuff is MESSY and lots of important things depend on it.
lwl.safe_script.on_internal_event(TAG.."onTick", Defines.InternalEvents.ON_TICK, function()
    if not mSetupRequested then return end
    --Initialization code
    if not mGlobal then
        mGlobal = Hyperspace.Global.GetInstance()
    end
    local ownshipManager = Hyperspace.ships(0)
    local enemyManager = Hyperspace.ships(1)
    
    --If anybody is teleporting, skip this update.
    if (ownshipManager) then
        for _, teleportStatusObserver in ipairs(mTeleportStatusObservers) do
            local enemyCrew = {}
            local localCrewBuffer = {}
            local allCrew = lwl.getAllMemberCrewFromFactory(lwl.noFilter)
            teleportStatusObserver.crew = {}
            for _,crewmem in ipairs(allCrew) do
                if crewmem.extend.customTele.teleporting then
                    --print(crewmem:GetName(), " is teleporting!")
                    teleportStatusObserver.teleportingCrew = lwl.setMerge(teleportStatusObserver.teleportingCrew, {crewmem.extend.selfId})
                else
                    teleportStatusObserver.teleportingCrew = lwl.setRemove(teleportStatusObserver.teleportingCrew, {crewmem.extend.selfId})
                end
                --print("player crew ", crewmem:GetName())  This is properly updating.
            end
            teleportStatusObserver.selfIsInitialized = true
        end
    end
end)


--[[
tracking={"crew", "drones", or "all"}  If no value is passed, defaults to all.
shipId = {-2, 0, 1} If not set, defaults to ownship. -2 is both ships.
--]]
function lwtso.createTeleportStatusObserver()
    mSetupRequested = true
    local teleportStatusObserver = {}
    teleportStatusObserver.lastSeenTeleporters = {}
    teleportStatusObserver.teleportingCrew = {}
    teleportStatusObserver.selfIsInitialized = false

    --actually no, just return a new object to all consumers so they don't conflict.
    local function saveLastSeenState()
        teleportStatusObserver.lastSeenTeleporters = lwl.deepCopyTable(teleportStatusObserver.teleportingCrew)
    end
    --local function hasStateChanged()
    --Return arrays of the crew diff from last save.
    local function getAddedCrew()
        return lwl.getNewElements(teleportStatusObserver.teleportingCrew, teleportStatusObserver.lastSeenTeleporters)
    end
    local function getRemovedCrew()
        return lwl.getNewElements(teleportStatusObserver.lastSeenTeleporters, teleportStatusObserver.teleportingCrew)
    end
    local function isInitialized()
        return teleportStatusObserver.selfIsInitialized
    end
    
    teleportStatusObserver.saveLastSeenState = saveLastSeenState
    teleportStatusObserver.getAddedCrew = getAddedCrew
    teleportStatusObserver.getRemovedCrew = getRemovedCrew
    teleportStatusObserver.isInitialized = isInitialized
    table.insert(mTeleportStatusObservers, teleportStatusObserver)
    return teleportStatusObserver
end