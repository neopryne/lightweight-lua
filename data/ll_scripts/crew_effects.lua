--[[
This is the file that is a library of effects that can go on crew, and also tracking which crew have which effects applied to them.  This will live within LWL.
todo add toggle to let effects be affected by time dilation

Usage:
(In your top level)
local lwce = mods.lightweight_crew_effects
lwce.RequestInitialization()

(In script blocks, or functions called by script blocks)
lwce.applyBleed(crewmem, amount)
lwce.addResist(crewmem, lwce.KEY_BLEED, 1)
This applies bleed to a crew and then makes them immune to it.  Note that not all resistances work the same.

**Statuses**
Bleed:
    Temporary duration damage over time
    Resist reduces stacks gained and damage taken
Confusion:
    Not implemented yet
Corruption:
    Permanent damage over time
    Resist reduces stacks gained
--]]
if (not mods) then mods = {} end
mods.lightweight_crew_effects = {}
local lwce = mods.lightweight_crew_effects
local lwl = mods.lightweight_lua
local lwui = mods.lightweight_user_interface
local lwcco = mods.lightweight_crew_change_observer
local lwsb = mods.lightweight_statboosts
local Brightness = mods.brightness
local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table --todo use this maybe, have crewList only hold ids.
local get_room_at_location = mods.multiverse.get_room_at_location

---@alias EffectType
---| '"bleed"'
---| '"corruption"'
---| '"confusion"'
---| '"teleportitis"'

---@class (Exact) StatusEffect
---@field name EffectType
---@field value number
---@field resist number
---@field icon table|nil

---@class (Exact) ListCrew
---@field id number
---@field bleed StatusEffect
---@field corrpution StatusEffect
---@field confusion StatusEffect

--Tracks an internal list of all crew, updates it when crew are lost or gained.
--Not impelmenting persistance as a core feature.  You feel like reloading to clear statuses, go for it.
local TAG = "LW Crew Effects"
local function NOOP() end
local FIRST_SYMBOL_RELATIVE_X = -9
local FIRST_SYMBOL_RELATIVE_Y = -5
local SYMBOL_OFFSET_X = 14
local SYMBOL_OFFSET_Y = 14
local DECIMAL_STORAGE_PERCISION_FACTOR = 100000
local PERSIST_KEY_EFFECT_VALUE = "lwce_effect_value"
local PERSIST_KEY_EFFECT_RESIST = "lwce_effect_resist"
lwce.KEY_BLEED = "bleed"
lwce.KEY_CONFUSION = "confusion"
lwce.KEY_CORRUPTION = "corruption"
lwce.KEY_TELEPORTITIS = "teleportitis"

--Adding a button which describes all the effects when hovered.
--A crew object will look something like this effect_crew = {id=, bleed={}, effect2={}}
---
---I need to be able to make surethat the particles for a crew get cleaned upand that is why I have a crew list.
---
local mCrewList = {} --all the crew, both sides. it's just an ID list.  --todo change this to a crewmem list?
local mScaledLocalTime = 0
local mCrewChangeObserver
local mEffectDefinitions = {}
local mGlobal = Hyperspace.Global.GetInstance()
local mCrewFactory = mGlobal:GetCrewFactory()
local mInitialized = false
local mSetupRequested = false

--Strongly recommend that if you're creating effects with this, add them to this library instead of your mod if they don't have too many dependencies.
-----------------------------HELPER FUNCTIONS--------------------------------------

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
local function generateCrewFilterFunction(crewmem)
    return function (crew)
        return crew.extend.selfId == crewmem.extend.selfId
    end
end

---@param crewmem Hyperspace.CrewMember
---@param effect StatusEffect
local function createIcon(crewmem, effect)
    effect.icon = Brightness.create_particle("particles/effects/"..effect.name, 1, 60, crewmem:GetPosition(), 0, crewmem.currentShipId, "SHIP_MANAGER")
    effect.icon.persists = true
end

---@param crewmem Hyperspace.CrewMember
local function getListCrew(crewmem)
    for _,listCrew in ipairs(mCrewList) do
        if listCrew.id == crewmem.extend.selfId then
            return listCrew
        end
    end
    return nil
end

---Returns the icon if it's rendering, and nil otherwise
---@param effect_crew ListCrew
---@param effect StatusEffect
local function renderEffectStandard(effect_crew, effect)
    if (effect.value <= 0) then
        if effect.icon then
            effect.onEnd(effect_crew)
            Brightness.destroy_particle(effect.icon)
            effect.icon = nil
        end
    else
        if not effect.icon then
            local crewmem = lwl.getCrewById(effect_crew.id)
            if crewmem then
                createIcon(crewmem, effect)
            end
        end
    end
    return effect.icon
end

---Some effects have a timer.  This is for those effects.  Other effects build up, or have other ways to remove them.
---@param effect_crew ListCrew
---@param effect StatusEffect
local function tickDownEffect(effect_crew, effect)
    effect.value = math.max(0, effect.value - 1)
end

-----------------------------EFFECT DEFINITIONS--------------------------------------
------------------BLEED------------------
local function tickBleed(effect_crew)
    local bleed = effect_crew.bleed
    if bleed.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        crewmem:DirectModifyHealth(-.035 * (1 - bleed.resist))
        --print(crewmem:GetName(), "has bleed", bleed.value)
        tickDownEffect(effect_crew, bleed)
    end
end

------------------CONFUSION------------------
local function tickConfusion(effect_crew)
    local confusion = effect_crew.confusion
    if confusion.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        --print(crewmem:GetName(), "has confusion", confusion.value)
        tickDownEffect(effect_crew, confusion)
    end
    --todo this needs to use the HS statboost logic.
end
local function endConfusion(effect_crew)
    lwsb.removeStatBoost(effect_crew.confusion.statBoostId)
end

------------------CORRUPTION------------------
--Certain effects give corrpution, which is a stacking effect not removed through normal means.  
local function tickCorruption(effect_crew)
    local corruption = effect_crew.corruption
    if corruption.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        
        if crewmem.bDead then --todo effects don't tick when dead, so what this will actually do is set the cloneable value to true or false randomly every tick.
            if not corruption.didDeathSave then
                corruption.didDeathSave = true
                if (corruption.value > (math.random() * 100)) then
                    --u dead
                    --crewmem. todo need stat boosts for this to work
                    --play some kind of noise, schlooping wworks i think
                end
            end
        else
            corruption.didDeathSave = false
            crewmem:DirectModifyHealth(-.004 * corruption.value)
        end
        --print(crewmem:GetName(), "has corruption", corruption.value)
    end
end



------------------TELEPORTITIS------------------
local function ticktTeleportitis(effect_crew)
    local teleportitis = effect_crew.teleportitis
    if teleportitis.value > 0 then
        local teleportitisStability = (100 + Hyperspace.playerVariables.stability) / 17
        tickDownEffect(effect_crew, teleportitis)
        if math.random() > .82 then
            teleportitis.instability = teleportitis.instability + 1
            --print("Teleportitis", teleportitis.instability, "out of", teleportitisStability)
        end
        if teleportitis.instability > teleportitisStability then
            local shipManager = Hyperspace.ships.player
            if Hyperspace.ships.enemy then
                if math.random(1,2) == 1 then
                    shipManager = Hyperspace.ships.enemy
                end
            end
            local realCrew = lwl.getCrewById(effect_crew.id)
            if not realCrew then return end --todo print error or zero values?

            local newPoint = lwl.pointfToPoint(shipManager:GetRandomRoomCenter())
            local newRoom = get_room_at_location(shipManager, newPoint, false)
            local newSlot = lwl.randomSlotRoom(newRoom, shipManager.iShipId)
            realCrew.extend:InitiateTeleport(shipManager.iShipId, newRoom, newSlot)
            Hyperspace.Sounds:PlaySoundMix("teleport", 9, false)
            teleportitis.instability = 0
            --print("Teleporting", shipManager.iShipId)
        end
    end
end

-----------------------------EXTERNAL API--------------------------------------
--todo This should take a crew ID instead Once I figure out why crewmem is null

---@param crewmem Hyperspace.CrewMember
---@param amount number
---@param effectName EffectType
---@return table|nil
local function applyEffect(crewmem, amount, effectName)
    if not crewmem then
        print("Failed to apply ", effectName, ": No such crewmember")
        return
    end
    local listCrew = getListCrew(crewmem)
    if not listCrew then
        print("Failed to apply ", effectName, ": No such known crewmember ", crewmem:GetName(), crewmem.extend.selfId)
        return
    end
    local crewEffect = listCrew[effectName]
    --print("applying effect ", effectName, "is ", crewEffect)
    if crewEffect then
        crewEffect.value = math.max(0, crewEffect.value + (amount * (1 - crewEffect.resist)))
    else
        --print("Did not find", effectName, "for crew", crewmem:GetName(), ", creating it with", amount)
        --Init new effect
        crewEffect = lwl.deepCopyTable(mEffectDefinitions[effectName])
        crewEffect.name = effectName
        createIcon(crewmem, crewEffect)
        crewEffect.value = amount
        crewEffect.resist = 0
        listCrew[effectName] = crewEffect
    end
    return crewEffect
end

---The first thing you call.  Tells this to create itself if it hasn't already.
function mods.lightweight_crew_effects.RequestInitialization()
    mSetupRequested = true
end

---Use after RequestInitialization to check if the library is ready.  The second thing you call.
---@return boolean
function mods.lightweight_crew_effects.isInitialized()
    return mInitialized
end

---Add resistance to the given effect to this crew. One means total immunity.
---@param crewmem Hyperspace.CrewMember
---@param effectName EffectType
---@param amount number
function mods.lightweight_crew_effects.addResist(crewmem, effectName, amount)
    if not crewmem then
        print("Failed to apply resist ", effectName, ": No such crewmember")
        return
    end
    local listCrew = getListCrew(crewmem)
    if not listCrew then
        print("Failed to apply resist ", effectName, ": No such listCrew")
        return
    end
    local crewEffect = listCrew[effectName]
    crewEffect.resist = crewEffect.resist + amount
end

---Apply amount of bleed to crew. Returns a the new status.
---@param crewmem Hyperspace.CrewMember
---@param amount number
---@return table|nil
function mods.lightweight_crew_effects.applyBleed(crewmem, amount)
    return applyEffect(crewmem, amount, lwce.KEY_BLEED)
end

---Apply amount of confusion to crew. Returns a the new status.
---@param crewmem Hyperspace.CrewMember
---@param amount number
---@return table|nil
function mods.lightweight_crew_effects.applyConfusion(crewmem, amount)
    local effect = applyEffect(crewmem, amount, lwce.KEY_CONFUSION)
    if effect.value == amount then --If this is a new effect for this crew
        effect.statBoostId = lwsb.addStatBoost(Hyperspace.CrewStat.CONTROLLABLE, lwsb.TYPE_BOOLEAN, lwsb.ACTION_SET, false, generateCrewFilterFunction(crewmem))
    end
    return effect
end

---Apply amount of corruption to crew. Returns a the new status.
---@param crewmem Hyperspace.CrewMember
---@param amount number
---@return table|nil 
function mods.lightweight_crew_effects.applyCorruption(crewmem, amount)
    return applyEffect(crewmem, amount, lwce.KEY_CORRUPTION)
end

---Apply amount of teleportitis to crew. Returns a the new status.
---@param crewmem Hyperspace.CrewMember
---@param amount number
---@return table|nil 
function mods.lightweight_crew_effects.applyTeleportitis(crewmem, amount)
    return applyEffect(crewmem, amount, lwce.KEY_TELEPORTITIS)
end

---Returns a status object for the given effect.
---@param crewmem Hyperspace.CrewMember
---@param effectName EffectType
---@return table|nil
function mods.lightweight_crew_effects.getEffect(crewmem, effectName)
    local listCrew = getListCrew(crewmem)
    if not listCrew then
        print("LWCE INTERNAL ERROR: Failed to get ", effectName, ": No such known crewmember ", crewmem:GetName(), crewmem.extend.selfId)
        return
    end
    return listCrew[effectName]
end

-----------------------------EFFECT LIST CREATION--------------------------------------
function lwce.createCrewEffectDefinition(name, onTick, onEnd, onRender, flagValue)
    mEffectDefinitions[name] = {name=name, onTick=onTick, onRender=onRender, onEnd=onEnd, flagValue=flagValue}
end

lwce.createCrewEffectDefinition(lwce.KEY_BLEED, tickBleed, NOOP, NOOP, 1)
lwce.createCrewEffectDefinition(lwce.KEY_CONFUSION, tickConfusion, endConfusion, NOOP, 2)
lwce.createCrewEffectDefinition(lwce.KEY_CORRUPTION, tickCorruption, NOOP, NOOP, 3)
lwce.createCrewEffectDefinition(lwce.KEY_TELEPORTITIS, ticktTeleportitis, NOOP, NOOP, 4)
--And when you hover the icons it prints a little popup with effect description and remaining duration



--[[
We persist all effects for all crew, and all listCrew have all effects
--crewId
----Value
----Resist
--]]
-----------------------------PERSISTANCE--------------------------------------
local function persistEffects()
    local factoryCrew = mCrewFactory.crewMembers --statuses should define which kinds of crew they can apply to.
    for crewmem in vter(factoryCrew) do
        --print("persistEffects crewmem", crewmem)
        if crewmem then
            local listCrew = getListCrew(crewmem)
            if listCrew then --If you can't, don't worry about it
                for key,effect in pairs(listCrew) do
                    if not (key == "id") then
                        --print("Saving", crewmem:GetName(), " effect ", effect.name, effect.value, effect.resist, effect.flagValue)
                        Hyperspace.metaVariables[PERSIST_KEY_EFFECT_VALUE..listCrew.id.."-"..effect.flagValue] = effect.value * DECIMAL_STORAGE_PERCISION_FACTOR
                        Hyperspace.metaVariables[PERSIST_KEY_EFFECT_RESIST..listCrew.id.."-"..effect.flagValue] = effect.resist * DECIMAL_STORAGE_PERCISION_FACTOR
                    end
                end
            end
        end
    end
    --print("persisted ", successes , " out of ", numEquipment)
end

--must load all crewmembers first.
local function loadEffects()
    local factoryCrew = mCrewFactory.crewMembers
    for crewmem in vter(factoryCrew) do
        --print("loadEffects crewmem", crewmem)
        if crewmem then
            local listCrew = getListCrew(crewmem)
            if listCrew then --If you can't, don't worry about it
                for key,effect in pairs(listCrew) do
                    if not (key == "id") then
                        --print(crewmem:GetName(), " effect ", effect.name, effect.value, effect.resist, effect.flagValue)
                        effect.value = Hyperspace.metaVariables[PERSIST_KEY_EFFECT_VALUE..listCrew.id.."-"..effect.flagValue] / DECIMAL_STORAGE_PERCISION_FACTOR
                        effect.resist = Hyperspace.metaVariables[PERSIST_KEY_EFFECT_RESIST..listCrew.id.."-"..effect.flagValue] / DECIMAL_STORAGE_PERCISION_FACTOR
                    end
                end
            end
        end
    end
end

local function resetEffects()
    local factoryCrew = mCrewFactory.crewMembers
    for crewmem in vter(factoryCrew) do
        --print("loadEffects crewmem", crewmem)
        if crewmem then
            local listCrew = getListCrew(crewmem)
            if listCrew then --If you can't, don't worry about it
                for key,effect in pairs(listCrew) do
                    if not (key == "id") then
                        --print(crewmem:GetName(), " effect ", effect.name, effect.value, effect.resist, effect.flagValue)
                        effect.value = 0
                        effect.resist = 0
                    end
                end
            end
        end
    end
end

-----------------------------ICON RENDERING LOGIC--------------------------------------
--features required to make lwui support this: removing objects from containers, vertical containers that extend upwards.
--vs I know exactly how to do this in brightness.
--Ok let's brightness, and maybe I'll find a good way to combine these.
local function repositionEffectStack(listCrew)
    local crewmem = lwl.getCrewById(listCrew.id)
    if not crewmem then return end --todo print this, it's never supposed to happen.
    local i = 1
    for key,effect in pairs(listCrew) do
        --print("loop ", i, key)
        if not (key == "id") then
            effect.onRender(listCrew, effect)
            local particle = renderEffectStandard(listCrew, effect)
            if particle then
                --Only show icons for hovered or selected crew (or ones you can't control|select)
                if (crewmem.selectionState == lwl.UNSELECTED() and (crewmem:GetControllable()) and crewmem.iShipId == 0) then --
                    particle.visible = false
                else
                    particle.visible = true
                end
                particle.space = crewmem.currentShipId
                local position_x = crewmem:GetPosition().x + FIRST_SYMBOL_RELATIVE_X + (((i + 1) % 2) * SYMBOL_OFFSET_X)
                local position_y = crewmem:GetPosition().y + FIRST_SYMBOL_RELATIVE_Y - (math.ceil(i / 2) * SYMBOL_OFFSET_Y)
                --print("Rendering particle in space", particle.space, "at position", position_x, position_y, effect.name)
                particle.position.x = position_x
                particle.position.y = position_y
                i = i + 1
            end
        end
    end
end

--w/e ill make them buttons with no onClick.
--maybe I will use brightness for rendering the status effect animations.  It's pretty good at that.
-----------------------------ON TICK LOGIC--------------------------------------
local function tickEffects()
    --print("ticking effects")
    for _,effect_crew in ipairs(mCrewList) do
        for key,effect in pairs(effect_crew) do
            if not (key == "id") then
                --print("ticking ", effect.name)
                local realCrew = lwl.getCrewById(effect_crew.id)
                if not realCrew then
                    --print("Warning!  Crew no longer exists with id", effect_crew.id) --todo fix this so it's better.
                else
                    if (not realCrew.bDead and realCrew.health.first > 0) then
                        effect.onTick(effect_crew)
                    end
                end
            end
        end
    end
end

local function generateCrewMatchFilter(crewId)
    return function(table, i)
        --print("filter comparing ", crewId, table[i].id)
        return table[i].id ~= crewId
    end
end

local function onRemoveCrew(listCrew)
    for key,effect in pairs(listCrew) do
        --print("loop ", i, key)
        if ((not (key == "id")) and (effect.icon)) then
            Brightness.destroy_particle(effect.icon)
        end
    end
end

--todo scale to real time, ie convert to 30ticks/second rather than frames.
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mSetupRequested then return end
    if not mCrewChangeObserver then --for now, include drones in valid targets.  FTL crew is weird enough drones probably count as people.
        mCrewChangeObserver = lwcco.createCrewChangeObserver(lwl.filterLivingCrew)
    end
    if not mCrewChangeObserver.isInitialized() then return end
    for _,listCrew in ipairs(mCrewList) do
        repositionEffectStack(listCrew)
    end

    if not lwl.isPaused() then
        --[[local crewids = ""
        for _,crew in ipairs(mCrewList) do
            crewids = crewids..crew.id..", "
        end
        print("List crew is ", crewids)--]]
        mScaledLocalTime = mScaledLocalTime + (Hyperspace.FPS.SpeedFactor * 16 / 10) --this runs slightly slower than equipment and it's not clear why.
        if (mScaledLocalTime > 1) then
            tickEffects()
            mScaledLocalTime = 0
            local addedCrew = mCrewChangeObserver.getAddedCrew()
            for _,crewId in ipairs(addedCrew) do
                --print("EFFECT Added crew: ", lwl.getCrewById(crewId):GetName())
                table.insert(mCrewList, {id=crewId}) --probably never added any crew 
                --Set values.  ALL VALUES MUST BE SET HERE.
                local realCrew = lwl.getCrewById(crewId)
                if realCrew then
                    lwce.applyBleed(realCrew, 0)
                    lwce.applyConfusion(realCrew, 0)
                    local corruptionEffect = lwce.applyCorruption(realCrew, 0)
                    corruptionEffect.didDeathSave = false
                    local teleEffect = lwce.applyTeleportitis(realCrew, 0)
                    teleEffect.instability = 0
                end
                --print("EFFECT after adding ", crewId, " there are now ", #mCrewList, " crew")
            end
            for _,crewId in ipairs(mCrewChangeObserver.getRemovedCrew()) do
                --print("EFFECT Removed crew: ", crewId)
                lwl.arrayRemove(mCrewList, generateCrewMatchFilter(crewId), onRemoveCrew)
                --print("EFFECT after removing ", crewId, " there are now ", #mCrewList, " crew left")
            end
            if not mInitialized and #addedCrew > 0 then --The first load will load all saved crew.
                loadEffects()
                mInitialized = true
            end
            persistEffects() --todo try to call this less.
            mCrewChangeObserver.saveLastSeenState()
            --print("EFFECTS: Compare ", #mCrewList, knownCrew, knownCrew == #mCrewList)
        end
    end
    --print("Icons repositioned!")
end)

------------------------------------ATTEMPTS TO RESET EFFECT VALUES--------------------------------------------
local clearedShipCrew = false
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not clearedShipCrew and Hyperspace.ships(0) and Hyperspace.ships(0).iCustomizeMode == 2 then
        for crewmem in vter(Hyperspace.ships(0).vCrewList) do
            for j = 1,#mEffectDefinitions do
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_VALUE..crewmem.extend.iShipId.."-"..j] = nil
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_RESIST..crewmem.extend.iShipId.."-"..j] = nil
            end
        end
        clearedShipCrew = true
    end
end)

--todo When you hit the start beacon, zero out effects for all crew.
script.on_game_event("START_BEACON_REAL", false, function()
        mCrewList = {}
        --Reset all persisted status values  --this is too much, I need another way.  In hangar?  Clear effects from all that ship's crew.
        for i = 0,2000 do --idk how high the crew values go
            for j = 1,#mEffectDefinitions do
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_VALUE..i.."-"..j] = nil
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_RESIST..i.."-"..j] = nil
            end
        end
        --reset all loaded effects
        resetEffects()
        end)
------------------------------------END ATTEMPTS TO RESET EFFECT VALUES--------------------------------------------
-----------------------------LEGEND BUTTON--------------------------------------
local mHelpButton = lwui.buildButton(1, 0, 11, 11, lwui.alwaysOnVisibilityFunction, lwui.spriteRenderFunction("icons/help/effects_help.png"), NOOP, NOOP)
mHelpButton.lwuiHelpText = "LWCE Statuses\nBleed:\n    Temporary duration damage over time\n    Resist reduces stacks gained and damage taken\nConfusion:\n    Not implemented yet\nCorruption:\n    Permanent damage over time\n    Resist reduces stacks gained\nTeleportitis:\n    Crew occasionally randomly teleports to another location."
lwui.addHelpButton(mHelpButton)
