--[[
usage: 
    lweb.registerDeathListener(function(crewmem) print(crewmem:GetName(), "died.") end)
    lweb.registerDeathAnimationListener(function(crewmem) print(crewmem:GetName(), "death animating.") end)
    lweb.registerClonedListener(function(crewmem) print(crewmem:GetName(), "was cloned.") end)
--]]

--[[
This uses player variables to avoid issues with loading while crew are cloning.
--]]

if (not mods) then mods = {} end
local lwl = mods.lightweight_lua
mods.lightweight_event_broadcaster = lwl.setIfNil(mods.lightweight_event_broadcaster, {})
local lweb = mods.lightweight_event_broadcaster



local TAG = "LW Tele Status Observer"
local KEY_DEATH = "CREW_DEATH_EVENT"
local KEY_DEATH_ANIMATION = "CREW_DEATH_ANIMATION"
local KEY_CREW_CLONED = "CREW_CLONED_EVENT"
local KEY_PLAYER_VARIABLES_LOADED = "PLAYER_VARIABLES_LOADED"
local KEY_ENTERED_HANGAR = "ENTERED_HANGAR" --Means the previous run has been removed.
local KEYS_LIST = {KEY_DEATH, KEY_DEATH_ANIMATION, KEY_CREW_CLONED, KEY_PLAYER_VARIABLES_LOADED, KEY_ENTERED_HANGAR}

local KEY_HAS_RUN = "metavars_run_saved"
local hasRun = Hyperspace.metaVariables[KEY_HAS_RUN]
local mRunInitializationCode = false
local mHangarBroadcastSent = false
local mRunInitialized = false
local mNewGame = false

local mInitWatchRequested = false
local mSetupRequested = false --todo should this be centralized like this?
local mListenerCategories = {}
for _,key in ipairs(KEYS_LIST) do
    mListenerCategories[key] = lwl.setIfNil(mListenerCategories[key], {})
end

local function observerUpdate(condition, key)
    --[[todo genericize this.
    for each thing this event could happen to
    check if thing happened
    if it did, tell all the listeners what thing it just happened to
    ]]
end

local function crewObserverUpdate(condition, key, updateListeners)
    if not mListenerCategories[key] then return end
    local allCrew = lwl.getAllMemberCrewFromFactory(lwl.noFilter)
    for _,crewmem in ipairs(allCrew) do
        local wasMarked = Hyperspace.playerVariables[key..crewmem.extend.selfId]
        if condition(crewmem) then
            if wasMarked == 0 then
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

local function clonedUpdate(updateListeners) --todo check if this applies when any crew spawns, or just when they clone in.
    local function clonedCheck(crewmem)
        return not crewmem.bDead
    end
    crewObserverUpdate(clonedCheck, KEY_CREW_CLONED, updateListeners)
end

local function deathUpdate(updateListeners)
    local function deathCheck(crewmem)
        return crewmem.bDead
    end
    crewObserverUpdate(deathCheck, KEY_DEATH, updateListeners)
end

local function deathAnimationUpdate(updateListeners)
    local function deathAnimCheck(crewmem)
        return crewmem.health.first <= 0
    end
    crewObserverUpdate(deathAnimCheck, KEY_DEATH_ANIMATION, updateListeners)
end

local function hangarStatusUpdate()
    local inHanger = (Hyperspace.ships(0)) and Hyperspace.ships(0).iCustomizeMode == 2
    if inHanger then
        if not mHangarBroadcastSent then
            for _,listener in ipairs(mListenerCategories[KEY_ENTERED_HANGAR]) do
                listener()
            end
            mHangarBroadcastSent = true
            mRunInitialized = false
        end
    else
        mHangarBroadcastSent = false
    end
end

local function playerVariablesLoadedUpdate() --todo If I broke stuff, this commit is probably the one that did it.
    --if not mInitWatchRequested then return end
    --print("got here 3.0")
    if mRunInitializationCode then
        --print("got here 3.1")
        deathUpdate(false)
        --print("got here 3.2")
        deathAnimationUpdate(false)
        --print("got here 3.3")
        clonedUpdate(false)
        --print("got here 3.4")
        for _,listener in ipairs(mListenerCategories[KEY_PLAYER_VARIABLES_LOADED]) do
            --print("got here 3.5")
            listener(mNewGame)
        end
    end
    --print("got here 3.6")
    mRunInitializationCode = false
    mRunInitialized = true
end

--todo need a broadcast for when in the hangar.
---Then, I need to toggle the rest of these off until the player variables load, and 
----No actually, what I need to do is mark the current status of everyone when the player variables load.
---So go through and call all the callbacks except don't call this listeners.

lwl.safe_script.on_internal_event("lweb_main_tick", Defines.InternalEvents.ON_TICK, function()
-- script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    --print("got here 1")
    if not mSetupRequested then return end
    --print("got here 2")
    hangarStatusUpdate()
    --print("got here 3")
    playerVariablesLoadedUpdate()
    --print("got here 4")
    if not mRunInitialized then return end
    --print("got here 5")
    deathUpdate(true)
    --print("got here 7")
    deathAnimationUpdate(true)
    --print("got here 7")
    clonedUpdate(true)
    --print("got here 8")
end)

local function addListener(listener, key)
    mSetupRequested = true
    if not mListenerCategories[key] then
        mListenerCategories[key] = {}
    end
    table.insert(mListenerCategories[key], listener)
    print("registered for", key)
end

script.on_init(function(new) --todo actually is it a problem if I don't reset anything when entering the hangar?
    mRunInitializationCode = true
    mNewGame = new
end)

-------------------API-----------

---More like a callback than a listener.
---The function passed should take the following arguments:
---     CrewMember the crew that has just died
--- Example: lweb.registerDeathListener(function(crewmem) print(crewmem:GetName(), "died.") end)
--- When any crew dies (is no longer on screen), the listener function will be called. (Including drones)
---@param listener function to be called upon crew death
function lweb.registerDeathListener(listener)
    addListener(listener, KEY_DEATH)
end

---More like a callback than a listener.
---The function passed should take the following arguments:
---     CrewMember the crew that has just died
--- Example: lweb.registerDeathAnimationListener(function(crewmem) print(crewmem:GetName(), "died.") end)
--- When any crew begins their death animation, the listener function will be called. (Including drones)
---@param listener function to be called upon crew death animation start
function lweb.registerDeathAnimationListener(listener)
    addListener(listener, KEY_DEATH_ANIMATION)
end

---More like a callback than a listener.
---The function passed should take the following arguments:
---     CrewMember the crew that has just died
--- Example: lweb.registerClonedListener(function(crewmem) print(crewmem:GetName(), "died.") end)
--- When any crew begins their death animation, the listener function will be called. (Including drones)
---@param listener function to be called upon crew death animation start
function lweb.registerClonedListener(listener)
    addListener(listener, KEY_CREW_CLONED)
end

---More like a callback than a listener.
---The function passed should take the following arguments:
---     boolean newGame, true if this is a new run and false otherwise.
--- Example: lweb.registerPlayerVariableInitializationListener(function(newGame) print("player vars loaded!", newGame) end)
--- When any crew begins their death animation, the listener function will be called. (Including drones)
---@param listener function to be called upon crew death animation start
function lweb.registerPlayerVariableInitializationListener(listener)
    mInitWatchRequested = true
    addListener(listener, KEY_PLAYER_VARIABLES_LOADED)
end

-------------------API-----------
---
-----kind of want a gimp script to export several files at different opacities.
---Then change the color and do it again.
---basically blood splatters are tedious and scriptable.