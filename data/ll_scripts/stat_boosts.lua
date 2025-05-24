mods.lightweight_statboosts = {}
local lwsb = mods.lightweight_statboosts

----UUUGH I don't want to have to persist these...  
---Thankfully they all have their own id already...  but uh... that could get messy fast.
--- I! _could_ iterate through ALL INTEGERS to find the extant boosts.  
--- Oh.  I just literally can't.  that simplifies things.

---------------------STAT_BOOST LIBRARY---------------------
--For all the various CrewStat values, this library holds.


lwsb.TYPE_SET = "SET"
lwsb.TYPE_ADD = "ADD"
lwsb.TYPE_MULTIPLY = "MULT"
lwsb.TYPE_VALUE = "VALUE"
local CREW_STAT_LIST = Hyperspace.CrewStat --todo check if this syntax works
local mStatBoostTable = {} --each index corresponds to the CrewStat value for that stat.
local nextId = 0
--Stat boost row: {statboost, statboost}
--filterFunction: Which crew this will apply to.
--stat boost: {filterFunction, amount, value, type={set, add, mult, value}}

--The boosts might be different in ways that makes trying to loop it hard.

--generate a unique id
---comment
---@param crewStat any
---@param type string
---@param amountValue any
---@param filterFunction function with one argument, a Hyperspace.CrewMember.  Returns true if this boost should apply to that crew.
-- @param persists true if this should carry over if the game is reloaded. --I can't persist functions, so uh, it's on you to manage this across game load states.
---@return integer ID of the boost, for use with removeStatBoost.
function lwsb.addStatBoost(crewStat, type, amountValue, filterFunction, persists)
    nextId = nextId + 1
    mStatBoostTable[crewStat][nextId] = {filterFunction=filterFunction, valueAmount=amountValue, type=type, id=nextId}
    return nextId
end

---comment
---@param id integer
---@return boolean succeess true if it found a boost to remove, and false otherwise.
function lwsb.removeStatBoost(id)
    for _,crewStat in ipairs(CREW_STAT_LIST) do
        if mStatBoostTable[crewStat][id] then
            mStatBoostTable[crewStat][id] = nil
            return true
        end
    end
    print("Warning: tried to remove nonexistant boost with id ", id)
    return false
end


script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE,
function(crew, stat, def, amount, value)
    for _,crewStat in ipairs(CREW_STAT_LIST) do
        if stat == crewStat then
            --Apply all valid stat boosts; if any applied, preempt
            local appliedBoost = false
            local boostValues = {}
            boostValues[lwsb.TYPE_SET] = 0
            boostValues[lwsb.TYPE_ADD] = 0
            boostValues[lwsb.TYPE_MULTIPLY] = 0
            for _,statBoost in pairs(mStatBoostTable[stat]) do
                if statBoost.filterFunction(crew) then
                    appliedBoost = true --todo check value is boolean, amount is int
                    if statBoost.type == lwsb.TYPE_VALUE then
                        boostValues[statBoost.type] =  statBoost.valueAmount
                    else
                        boostValues[statBoost.type] = boostValues[statBoost.type] + statBoost.valueAmount
                    end
                end
            end
            if (appliedBoost) then
                value = boostValues[lwsb.TYPE_VALUE]
                amount = boostValues[lwsb.TYPE_SET]
                amount = amount + boostValues[lwsb.TYPE_ADD]
                amount = amount * boostValues[lwsb.TYPE_MULTIPLY]
                return Defines.Chain.PREEMPT, amount, value
            else
                return Defines.Chain.CONTINUE, amount, value
            end
        end
    end
end)


--[[
health = 400
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE,
function(crew, stat, def, amount, value)
    if stat == Hyperspace.CrewStat.MAX_HEALTH then
        amount = health
        return Defines.Chain.PREEMPT, amount, value
    end
    return Defines.Chain.CONTINUE, amount, value
end)

race = ""
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE, 
function(crew, stat, def, amount, value)
    if stat == Hyperspace.CrewStat.TRANSFORM_RACE and race ~= "" then
        crew.extend.transformRace = race
        return Defines.Chain.PREEMPT, amount, value
    end
    return Defines.Chain.CONTINUE, amount, value
end)]]