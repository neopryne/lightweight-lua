--[[
usage: 


--]]

--[[
This uses player variables to avoid issues with loading while crew are cloning.
--]]

if (not mods) then mods = {} end
mods.lightweight_event_broadcaster = {}
local lweb = mods.lightweight_event_broadcaster

local lwl = mods.lightweight_lua
local userdata_table = mods.multiverse.userdata_table


local TAG = "LW Tele Status Observer"
local KEY_DEATH = "CREW_DEATH_EVENT"
local KEY_DEATH_ANIMATION = "CREW_DEATH_ANIMATION"
local KEY_LWEB_CREWTABLE = "mods.lweb.crewtable"

local mSetupRequested = false --todo should this be centralized like this?
local mListenerCategories = {}


local function observerUpdate(condition, key)
    --[[todo genericize this.
    for each thing this event could happen to
    check if thing happened
    if it did, tell all the listeners what thing it just happened to
    ]]
end


local function crewObserverUpdate(condition, key)
    if not mListenerCategories[KEY_DEATH] then return end
    local allCrew = lwl.getAllMemberCrewFromFactory(lwl.noFilter)
    for _,crewmem in ipairs(allCrew) do
        local wasMarked = Hyperspace.playerVariables[key..crewmem.extend.selfId]
        if condition(crewmem) then
            if not wasMarked or wasMarked == 0 then
                Hyperspace.playerVariables[key..crewmem.extend.selfId] = 1
                for _,listener in ipairs(mListenerCategories[key]) do
                    listener(crewmem)
                end
            end
        else
            Hyperspace.playerVariables[key..crewmem.extend.selfId] = 0
        end
    end
end

local function deathUpdate()
    local function deathCheck(crewmem)
        return crewmem.bDead
    end
    crewObserverUpdate(deathCheck, KEY_DEATH)
end

local function deathAnimationUpdate()
    local function deathCheck(crewmem)
        return crewmem.health.first <= 0
    end
    crewObserverUpdate(deathCheck, KEY_DEATH_ANIMATION)
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mSetupRequested then return end
    deathUpdate()
    deathAnimationUpdate()
end)


local function addListener(listener, key)
    if not mListenerCategories[key] then
        mListenerCategories[key] = {}
    end
    table.insert(mListenerCategories[key], listener)
    print("registered for", key)
end

-------------------API-----------

---More like a callback than a listener.
---The function passed should take the following arguments:
---     CrewMember the crew that has just died
--- Example: lweb.registerDeathListener(function(crewmem) print(crewmem:GetName(), "died.") end)
--- When any crew dies (is no longer on screen), the listener function will be called. (Including drones)
---@param listener function to be called upon crew death
function lweb.registerDeathListener(listener)
    mSetupRequested = true
    addListener(listener, KEY_DEATH)
end

---More like a callback than a listener.
---The function passed should take the following arguments:
---     CrewMember the crew that has just died
--- Example: lweb.registerDeathListener(function(crewmem) print(crewmem:GetName(), "died.") end)
--- When any crew begins their death animation, the listener function will be called. (Including drones)
---@param listener function to be called upon crew death animation start
function lweb.registerDeathAnimationListener(listener)
    mSetupRequested = true
    addListener(listener, KEY_DEATH_ANIMATION)
end

lweb.registerDeathListener(function(crewmem) print(crewmem:GetName(), "died.") end)
lweb.registerDeathAnimationListener(function(crewmem) print(crewmem:GetName(), "death animating.") end)

-------------------API-----------
---
-----kind of want a gimp script to export several files at different opacities.
---Then change the color and do it again.
---basically blood splatters are tedious and scriptable.