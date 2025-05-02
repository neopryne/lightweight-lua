--[[
This is the file that is a library of effects that can go on crew, and also tracking which crew have which effects applied to them.  This will live within LWL.
todo add toggle to let effects be affected by time dilation

Usage:
local lwce = mods.lightweight_crew_effects
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
local Brightness = mods.brightness
local vter = mods.multiverse.vter

--Tracks an internal list of all crew, updates it when crew are lost or gained.
--Not impelmenting persistance as a core feature.  You feel like reloading to clear statuses, go for it.
local TAG = "LW Crew Effects"
local function NOOP() end
local FIRST_SYMBOL_RELATIVE_X = -9 
local FIRST_SYMBOL_RELATIVE_Y = -5
local SYMBOL_OFFSET_X = 14
local SYMBOL_OFFSET_Y = 14
local DECIMAL_STORAGE_PERCISION_FACTOR = 100000
local PERSIST_KEY_NUM_CREW = "lwce_num_crew"
local PERSIST_KEY_EFFECT_VALUE = "lwce_effect_value"
local PERSIST_KEY_EFFECT_RESIST = "lwce_effect_resist"
lwce.KEY_BLEED = "bleed"
lwce.KEY_CONFUSION = "confusion"
lwce.KEY_CORRUPTION = "corruption"

--Adding a button which describes all the effects when hovered.
--A crew object will look something like this effect_crew = {id=, bleed={}, effect2={}}
local mCrewList = {} --all the crew, both sides. it's just an ID list
local mScaledLocalTime = 0
local function noFilter() return true end
local mCrewChangeObserver = lwcco.createCrewChangeObserver(noFilter)
local mEffectDefinitions = {}
local mGlobal = Hyperspace.Global.GetInstance()
local mCrewFactory = mGlobal:GetCrewFactory()
local knownCrew = 0
local mInitialized = false

--Strongly recommend that if you're creating effects with this, add them to this library instead of your mod if they don't have too many dependencies.
-----------------------------HELPER FUNCTIONS--------------------------------------
local function createIcon(crewmem, effect)
    effect.icon = Brightness.create_particle("particles/effects/"..effect.name, 1, 60, crewmem:GetPosition(), 0, crewmem.currentShipId, "SHIP_MANAGER")
    effect.icon.persists = true
end

local function getListCrew(crewmem)
    for _,listCrew in ipairs(mCrewList) do
        if listCrew.id == crewmem.extend.selfId then
            return listCrew
        end
    end
    return nil
end

local function tickEffectStandard(effect_crew, effect)
    if (effect.value <= 0) then
        if effect.icon then
            effect.onEnd(effect_crew)
            Brightness.destroy_particle(effect.icon)
            effect.icon = nil
        end
    else
        if not effect.icon then
            local crewmem = lwl.getCrewById(effect_crew.id)
            createIcon(crewmem, effect)
        end
    end
end

--Some effects have a timer.  This is for those effects.  Other effects build up, or have other ways to remove them.
local function tickDownEffectStandard(effect_crew, effect)
    effect.value = math.max(0, effect.value - 1)
    tickEffectStandard(effect_crew, effect)
end

-----------------------------EFFECT DEFINITIONS--------------------------------------
------------------BLEED------------------
local function tickBleed(effect_crew)
    local bleed = effect_crew.bleed
    if bleed.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        crewmem:DirectModifyHealth(-.03 * (1 - bleed.resist))
        --print(crewmem:GetName(), "has bleed", bleed.value)
    end
    tickDownEffectStandard(effect_crew, bleed)
end

------------------CONFUSION------------------
local function tickConfusion(effect_crew)
    local confusion = effect_crew.confusion
    if confusion.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        --print(crewmem:GetName(), "has confusion", confusion.value)
    end
    --todo this needs to use the HS statboost logic.
    tickDownEffectStandard(effect_crew, confusion)
end
local function endConfusion(effect_crew)
    --todo this needs to use the HS statboost logic.
end

------------------CORRUPTION------------------
--Certain effects give corrpution, which is a stacking effect not removed through normal means.  
local function tickCorruption(effect_crew)
    local corruption = effect_crew.corruption
    if corruption.value > 0 then
        local crewmem = lwl.getCrewById(effect_crew.id)
        --print(crewmem:GetName(), "has corruption", corruption.value)
        crewmem:DirectModifyHealth(-.004 * corruption.value)
    end
    tickEffectStandard(effect_crew, corruption)
end

-----------------------------EXTERNAL API--------------------------------------
local function applyEffect(crewmem, amount, effectName)
    if not crewmem then
        --print("Failed to apply ", effectName, ": No such crewmember")
        return
    end
    local listCrew = getListCrew(crewmem)
    if not listCrew then
        --print("Failed to apply ", effectName, ": No such known crewmember ", crewmem:GetName(), crewmem.extend.selfId)
        return
    end
    local crewEffect = listCrew[effectName]
    if not crewEffect then
        --print("Error: could not find effect in ", lwl.dumpObject(listCrew))
    end
    --print("applying effect ", effectName, "is ", crewEffect)
    if crewEffect then
        crewEffect.value = math.max(0, crewEffect.value + (amount * (1 - crewEffect.resist)))
    else
        --Init new effect
        crewEffect = lwl.deepCopyTable(mEffectDefinitions[effectName])
        crewEffect.name = effectName
        createIcon(crewmem, crewEffect)
        crewEffect.value = amount
        crewEffect.resist = 0
        listCrew[effectName] = crewEffect
    end
    --print("applied effect ", effectName, "is ", crewEffect)
end

function mods.lightweight_crew_effects.addResist(crewmem, effectName, amount)
    if not crewmem then
        --print("Failed to apply resist ", effectName, ": No such crewmember")
        return
    end
    local listCrew = getListCrew(crewmem)
    local crewEffect = listCrew[effectName]
    crewEffect.resist = crewEffect.resist + amount
end

function mods.lightweight_crew_effects.applyBleed(crewmem, amount)
    applyEffect(crewmem, amount, lwce.KEY_BLEED)
end

function mods.lightweight_crew_effects.applyConfusion(crewmem, amount)
    applyEffect(crewmem, amount, lwce.KEY_CONFUSION)
end

function mods.lightweight_crew_effects.applyCorruption(crewmem, amount)
    applyEffect(crewmem, amount, lwce.KEY_CORRUPTION)
end

-----------------------------EFFECT LIST CREATION--------------------------------------
function lwce.createCrewEffectDefinition(name, onTick, onEnd, onRender, flagValue)
    mEffectDefinitions[name] = {name=name, onTick=onTick, onRender=onRender, onEnd=onEnd, flagValue=flagValue}
end

lwce.createCrewEffectDefinition(lwce.KEY_BLEED, tickBleed, NOOP, NOOP, 1)
lwce.createCrewEffectDefinition(lwce.KEY_CONFUSION, tickConfusion, endConfusion, NOOP, 2)
lwce.createCrewEffectDefinition(lwce.KEY_CORRUPTION, tickCorruption, NOOP, NOOP, 3)
--And when you hover the icons it prints a little popup with effect description and remaining duration



--[[
We persist all effects for all crew, and all listCrew have all effects
numCrew
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

-----------------------------ICON RENDERING LOGIC--------------------------------------
--features required to make lwui support this: removing objects from containers, vertical containers that extend upwards.
--vs I know exactly how to do this in brightness.
--Ok let's brightness, and maybe I'll find a good way to combine these.
local function repositionEffectStack(listCrew)
    local crewmem = lwl.getCrewById(listCrew.id)
    local i = 1
    for key,effect in pairs(listCrew) do
        --print("loop ", i, key)
        if not (key == "id") then
            local particle = effect.icon
            if particle then
                --Only show icons for hovered or selected crew (or ones you can't control|select)
                if crewmem.selectionState == lwl.UNSELECTED() then
                    particle.visible = false
                else
                    particle.visible = true
                end
                particle.space = crewmem.currentShipId            
                position_x = crewmem:GetPosition().x + FIRST_SYMBOL_RELATIVE_X + (((i + 1) % 2) * SYMBOL_OFFSET_X)
                position_y = crewmem:GetPosition().y + FIRST_SYMBOL_RELATIVE_Y - (math.ceil(i / 2) * SYMBOL_OFFSET_Y)
                
                if (particle.position ~= nil) then
                    particle.position = crewmem:GetPosition()
                end
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
                effect.onTick(effect_crew)
            end
        end
    end
end

--[[
local function renderEffectIcons() --buffer layer todo I did this elsewhere with Brightness
    for _,effect_crew in ipairs(mCrewList) do
        for key,effect in pairs(effect_crew) do
            if not (key == "id") then
                --render the effect icon
                --except instead of brightness this time we're using lwui for the object hover functionality.
                --actually... This functionality doesn't exist in either library, so why should I just not use the brightness code
                --Because this would create a text box at a dynamic location and luwi is great at that.
            end
        end
    end
end--]]

local function generatCrewMatchFilter(crewId)
    return function(table, i)
        --print("filter comparing ", crewId, table[i].id)
        return table[i].id ~= crewId
    end
end


--todo scale to real time, ie convert to 30ticks/second rather than frames.
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mCrewChangeObserver.isInitialized() then return end
    for _,listCrew in ipairs(mCrewList) do
        repositionEffectStack(listCrew)
    end
    
    if not lwl.isPaused() then
        local crewids = ""
        for _,crew in ipairs(mCrewList) do
            crewids = crewids..crew.id..", "
        end
        --print("List crew is ", crewids)
        mScaledLocalTime = mScaledLocalTime + (Hyperspace.FPS.SpeedFactor * 16)
        if (mScaledLocalTime > 1) then
            tickEffects()   
            mScaledLocalTime = 0
            local addedCrew = mCrewChangeObserver.getAddedCrew()
            for _,crewId in ipairs(addedCrew) do
                --print("EFFECT Added crew: ", lwl.getCrewById(crewId):GetName())
                table.insert(mCrewList, {id=crewId}) --probably never added any crew 
                --Set values.  ALL VALUES MUST BE SET HERE.
                lwce.applyBleed(lwl.getCrewById(crewId), 0)
                lwce.applyConfusion(lwl.getCrewById(crewId), 0)
                lwce.applyCorruption(lwl.getCrewById(crewId), 0)
            end
            for _,crewId in ipairs(mCrewChangeObserver.getRemovedCrew()) do
                --print("EFFECT Removed crew: ", crewId)
                lwl.arrayRemove(mCrewList, generatCrewMatchFilter(crewId))
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

script.on_game_event("START_BEACON_REAL", false, function()
        mCrewList = {}
        --Reset all persisted status values
        for i = 1,1500 do --idk how high the crew values go
            for j = 1,#mEffectDefinitions do
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_VALUE..i.."-"..j] = nil
                Hyperspace.metaVariables[PERSIST_KEY_EFFECT_RESIST..i.."-"..j] = nil
            end
        end
        end)

--todo When you hit the start beacon, zero out effects for all crew.
-----------------------------LEGEND BUTTON--------------------------------------
local mHelpButton = lwui.buildButton(1, 0, 11, 11, lwui.alwaysOnVisibilityFunction, lwui.spriteRenderFunction("icons/help/effects_help.png"), NOOP, NOOP)
mHelpButton.lwuiHelpText = "LWCE Statuses\nBleed:\n    Temporary duration damage over time\n    Resist reduces stacks gained and damage taken\nConfusion:\n    Not implemented yet\nCorruption:\n    Permanent damage over time\n    Resist reduces stacks gained"
lwui.addHelpButton(mHelpButton)
