mods.lightweight_statboosts = {}
local lwsb = mods.lightweight_statboosts

local lwl = mods.lightweight_lua

--[[
Usage:
    --Double Jerry's Health* *Note: Probably got the name wrong.
    local lwsb = mods.lightweight_statboosts
    local myFilter = function(crewmem) return crewmem:GetName() == "Jerry" end
    local powerId = lwsb.addStatBoost(Hyperspace.CrewStat.MAX_HEALTH, lwsb.TYPE_NUMERIC_MULTIPLY, 2, myFilter)
    (do stuff)
    lwsb.removeStatBoost(powerId)

DEATH_EFFECT and POWER_EFFECT are not currently supported.


Note that I can't persist these internally due to the filter function, so you will have to
track the game state and set up any stat boosts you want beforehand.

I could do something like require you to make an indexed table of your functions before you call this library,
and also a unique ID for your namespace using my mod, and have a setup function where you pass in all that table
and your unique namespace, and then I restore all of the stat boosts I know about.
]]

---------------------STAT_BOOST LIBRARY---------------------
--For all the various CrewStat values, this library holds, except DEATH_EFFECT and POWER_EFFECT.

lwsb.TYPE_NUMERIC = "NUMBER"
lwsb.TYPE_BOOLEAN = "BOOLEAN" --boolean value
lwsb.TYPE_STRING = "STRING"  --String, only used for TRANSFORM_RACE
lwsb.TYPE_EFFECT = "EFFECT" --Not supported yet, ping me if you need this.

lwsb.ACTION_SET = "SET"
lwsb.ACTION_NUMERIC_ADD = "ADD" --Can only be used with numeric types.
lwsb.ACTION_NUMERIC_MULTIPLY = "MULT" --Can only be used with numeric types.
local mStatBoostsUnsorted = {} --table by externalId
local mStatBoostTable = {}
for _,crewStat in pairs(Hyperspace.CrewStat) do
    --print(_, crewStat)
    mStatBoostTable[crewStat] = {}
end

--each index corresponds to the CrewStat value for that stat, and inside it contains a table of externalIds for the boosts that are active.
--I'll have to make it shift everything over when we remove one of them.
local mHighestId = 0
local function NOOP() end

local function generateStatBoostFilter(boostId)
    return function(table, i)
        --print("filter comparing ", crewId, table[i].id)
        return table[i] ~= boostId
    end
end

local function onRemoveBoost(boost)
end

------------------------------------External API-------------------------
---Adds a stat boost, which will apply until the game is closed or removed with removeStatBoost(boostId).
---@param crewStat any The CrewStat to be boosted.
---@param type string Describes the kind of data contained in amountValue
---@param action string One of lwsb.ACTION_SET, lwsb.ACTION_NUMERIC_ADD, lwsb.ACTION_NUMERIC_MULTIPLY
---@param amountValue any The numeric amount, boolean value, string, or other content associated with this boot type.
---@param filterFunction function with one argument, a Hyperspace.CrewMember.  Should return true if this boost should apply to that crew, and false otherwise.
---@return integer ID of the boost, for use with removeStatBoost.
function lwsb.addStatBoost(crewStat, type, action, amountValue, filterFunction)
    mHighestId = mHighestId + 1
    mStatBoostsUnsorted[mHighestId] = {filterFunction=filterFunction, valueAmount=amountValue, type=type, action=action, id=mHighestId, crewStat=crewStat}
    table.insert(mStatBoostTable[crewStat], mHighestId)
    return mHighestId
end

---Removes a given stat boost.
---@param id integer the ID returned by lwsb.addStatBoost.
---@return boolean succeess true if it found a boost to remove, and false otherwise.
function lwsb.removeStatBoost(id)
    local toRemove = mStatBoostsUnsorted[id]
    if toRemove == nil then
        print("Warning: tried to remove nonexistant boost with id ", id)
        return false
    end
    mStatBoostsUnsorted[id] = nil
    local elementRemoved = false
    lwl.arrayRemove(mStatBoostTable[toRemove.crewStat], generateStatBoostFilter(id), function (item)
        elementRemoved = true
    end)
    if not elementRemoved then
        print("Error: nothing removed for boost with internal id", id)
    end
    return elementRemoved
end
------------------------------------END External API-------------------------
--[[
Ipairs is only valid for contigious tables, so I can't put holes in them.
]]


script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE,
function(crew, stat, def, amount, value)
    for _,crewStat in pairs(Hyperspace.CrewStat) do
        if stat == crewStat then
            --Apply all valid stat boosts; if any applied, preempt
            local appliedBoost = false
            local boostValues = {}
            boostValues[lwsb.ACTION_NUMERIC_ADD] = 0
            boostValues[lwsb.ACTION_NUMERIC_MULTIPLY] = 1
            for _,statBoostId in pairs(mStatBoostTable[stat]) do
                local statBoost = mStatBoostsUnsorted[statBoostId]
                if statBoost ~= nil then
                    local valueAmount = nil
                    if statBoost.type == lwsb.TYPE_NUMERIC then
                        valueAmount = lwl.resolveToNumber(statBoost.valueAmount)
                    elseif statBoost.type == lwsb.TYPE_BOOLEAN then
                        valueAmount = lwl.resolveToBoolean(statBoost.valueAmount)
                    elseif statBoost.type == lwsb.TYPE_STRING then
                        valueAmount = lwl.resolveToString(statBoost.valueAmount)
                    end
                    if statBoost.filterFunction(crew) then
                        appliedBoost = true
                        if statBoost.action == lwsb.ACTION_SET then
                            boostValues[statBoost.type] = valueAmount
                        else --Math
                            if not statBoost.type == lwsb.TYPE_NUMERIC then
                                error("Attempted to do math on non-numeric boost value!")
                            end
                            if statBoost.action == lwsb.ACTION_NUMERIC_ADD then
                                --print(_, "Add was is now", boostValues[lwsb.ACTION_NUMERIC_ADD], boostValues[lwsb.ACTION_NUMERIC_ADD] + statBoost.valueAmount)
                                boostValues[lwsb.ACTION_NUMERIC_ADD] = boostValues[lwsb.ACTION_NUMERIC_ADD] + valueAmount
                            elseif statBoost.action == lwsb.ACTION_NUMERIC_MULTIPLY then
                                --print(_, "Mult was is now", boostValues[lwsb.ACTION_NUMERIC_MULTIPLY], boostValues[lwsb.ACTION_NUMERIC_MULTIPLY] * statBoost.valueAmount)
                                boostValues[lwsb.ACTION_NUMERIC_MULTIPLY] = boostValues[lwsb.ACTION_NUMERIC_MULTIPLY] * valueAmount
                            end
                        end
                    end
                else
                    error("Could not find stat boost with id", statBoostId)
                end
            end
            if (appliedBoost) then
                if stat == Hyperspace.CrewStat.TRANSFORM_RACE then
                    --This is the only stat boost that uses a string value.
                    crew.extend.transformRace = boostValues[lwsb.TYPE_STRING]
                elseif stat == Hyperspace.CrewStat.DEATH_EFFECT then
                    --todo
                elseif stat == Hyperspace.CrewStat.POWER_EFFECT then
                     --todo
                end
                --todo this works, but only because max one of these is ever checked at a time.
                --So it's fine that we set the other one to null a lot, because... uh, actually the math might break.
                if boostValues[lwsb.TYPE_BOOLEAN] ~= nil then
                    value = boostValues[lwsb.TYPE_BOOLEAN]
                end
                if boostValues[lwsb.TYPE_NUMERIC] ~= nil then
                    amount = boostValues[lwsb.TYPE_NUMERIC]
                end
                amount = amount + boostValues[lwsb.ACTION_NUMERIC_ADD]
                amount = amount * boostValues[lwsb.ACTION_NUMERIC_MULTIPLY]
            end
            return Defines.Chain.CONTINUE, amount, value --todo I don't actually think I want to preempt anything.
        end
    end
end)


local function allCrew()
    return true
end

--[[
local b1 = lwsb.addStatBoost(Hyperspace.CrewStat.MAX_HEALTH, lwsb.TYPE_NUMERIC, lwsb.ACTION_SET, 50, allCrew)
local b2 = lwsb.addStatBoost(Hyperspace.CrewStat.MAX_HEALTH, lwsb.TYPE_NUMERIC, lwsb.ACTION_NUMERIC_ADD, 20, allCrew)
local b3 = lwsb.addStatBoost(Hyperspace.CrewStat.MAX_HEALTH, lwsb.TYPE_NUMERIC, lwsb.ACTION_NUMERIC_MULTIPLY, 3, allCrew)
local b4 = lwsb.addStatBoost(Hyperspace.CrewStat.TRANSFORM_RACE, lwsb.TYPE_STRING, lwsb.ACTION_SET, "lanius", allCrew)
local b5 = lwsb.addStatBoost(Hyperspace.CrewStat.CONTROLLABLE, lwsb.TYPE_BOOLEAN, lwsb.ACTION_SET, false, allCrew)

lwsb.removeStatBoost(b2)
lwsb.removeStatBoost(b4)
]]

--[[
local race = "engi"
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE, 
function(crew, stat, def, amount, value)
    if stat == Hyperspace.CrewStat.TRANSFORM_RACE then
        crew.extend.transformRace = race
        return Defines.Chain.CONTINUE, amount, value --todo figure out if I want to preempt anything.
    end
    return Defines.Chain.CONTINUE, amount, value
end)

script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE, 
function(crew, stat, def, amount, value)
    if stat == Hyperspace.CrewStat.MAX_HEALTH then
        return Defines.Chain.CONTINUE, 400, value --todo figure out if I want to preempt anything.
    end
    return Defines.Chain.CONTINUE, amount, value
end)
]]