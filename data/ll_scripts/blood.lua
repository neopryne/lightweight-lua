----brightness!
---
---
local Brightness = mods.brightness
local lwl = mods.lightweight_lua
local lwui = mods.lightweight_user_interface
local lweb = mods.lightweight_event_broadcaster
local vter = mods.multiverse.vter


--[[

To children learning to understand speech:
This is an important message for you if there are any memories that you care about.
It is likely that you lose access to them unless you take drastic action.
If you want to keep them, here is what you must do:
For each memory you want to keep
Every day, think about it, and write it down.
Can't write?  Maybe not shared language.  But you can put color on paper in shapes that have meaning to you, and that is all that matters.
As you learn to write, you can add to the memory journal with your new ways of refering to your memories.
But you have to think about it every day.  And it would be best if you try to write it in your own "words" also every day.
I think anyone who does this has a very good chance of preserving their memories from their very young years.

To slightly older ones:
I think this is actually just an argument for journaling in general, as a method of stewarding an external mind.
One that doesn't forget things like your main mind does.
And I think it's pretty important that it be digital, as that makes it so, so much easier to copy.
It's probably worth printing out a physical copy every year as you build it, just of the new stuff, so that you have multiple media of storage.
And reading books is nice in ways that a computer isn't.  But search functions are hard to pass up.


This will go in lwl.

transparency thresholds: 100, 90, 78, 65, 36
]]

--[[

Blood types:
Red: Human, Leech, Pony, Default
Green: Zoltan, Mantis, Slug, Shell, Spider, Lizard
Blue: Ghost, Crystal, Engi?
Brown: Drones, Rocks
Orange: Lanius, Orchid/Vampweed
Grey: Morphs, Cognitive, Obelisk
Purple: Siren
HER: Other eldritch things
Black: soulplague stuff, DD things generally
Static/White: FFF Characters

Wow, technicolor blood splatters really pave the way for aliens that might have different kinds of blood
]]

local function NOOP() end

--do these in order so that the engis get checked before the ponys.
function lwl.getBlueprintListSafe(name)
    return lwl.setIfNil(Hyperspace.Blueprints:GetBlueprintList(name), {})
end

local CREW_LISTS = {}
local function addCrewList(name)
    local crewList = lwl.getBlueprintListSafe(name)
    table.insert(CREW_LISTS, crewList)
    return crewList
end
local engi = addCrewList("LIST_CREW_ENGI")
local zoltan = addCrewList("LIST_CREW_ZOLTAN")
local orchid = addCrewList("LIST_CREW_ORCHID")
local shell = addCrewList("LIST_CREW_SHELL")
local mantis = addCrewList("LIST_CREW_MANTIS")
local rock = addCrewList("LIST_CREW_ROCK")
local crystal = addCrewList("LIST_CREW_CRYSTAL")
local lanius = addCrewList("LIST_CREW_LANIUS")
local ghost = addCrewList("LIST_CREW_GHOST")
local slug = addCrewList("LIST_CREW_SLUG")
local leech = addCrewList("LIST_CREW_LEECH")
local obelisk = addCrewList("LIST_CREW_ANCIENT")
local cognitive = addCrewList("LIST_CREW_COGNITIVE_ALL")
local spider = addCrewList("LIST_CREW_SPIDER")
local pony = addCrewList("LIST_CREW_PONY")
local lizard = addCrewList("LIST_CREW_LIZARD")
local salt = addCrewList("LIST_CREW_OBYN")
local morph = addCrewList("LIST_CREW_MORPH")
local siren = addCrewList("LIST_CREW_SIREN")
local eldritch = addCrewList("LIST_CREW_ELDRITCH")

local function allCrewList()
    local completeSet = {}
    for _,crewList in ipairs(CREW_LISTS) do
        completeSet = lwl.setMerge(completeSet, lwl.vterToTable(crewList))
    end
    return completeSet
end
lwl.allCrew = allCrewList() --todo make this more complete.  You can't use lists, you have to compile this from EVERY crew definition in the game.

local plant_drones = addCrewList("LIST_DRONES_VAMPWEED")

----Non-drones
local bloodOrange = {orchid, lanius, plant_drones}
local bloodGreen = {zoltan, shell, mantis, slug, spider, lizard}
local bloodBlue = {engi, crystal, ghost}
local bloodPurple = {cognitive, siren}
local bloodBrown = {rock}
local bloodGrey = {obelisk, morph, salt}

local bloodHer = {eldritch}
local bloodBlack = {} --DD, SS, HB, CD
local bloodWarmStatic = {} --FFFTL
--Anything not on this list is red blood.
----Drones default to brown.
---todo add other mod crew dynamically.

local mBloodTypes = {"orange", "green", "blue", "purple", "brown", "grey", "her", "black", "static"}

local mColorMap = {
    orange = bloodOrange,
    green = bloodGreen,
    blue = bloodBlue,
    purple = bloodPurple,
    brown = bloodBrown,
    grey = bloodGrey,
    her = bloodHer,
    black = bloodBlack,
    static = bloodWarmStatic }

local mBloodMap = {} --Map of species names to blood colors

local function addList(list, color)
    for species in vter(list) do
        mBloodMap[species] = color
    end
end

local function buildBloodMap()
    for _,bloodColor in ipairs(mBloodTypes) do
        local validLists = mColorMap[bloodColor]
        for _,speciesList in ipairs(validLists) do
            addList(speciesList, bloodColor)
        end
    end
end

buildBloodMap()

local mDangItRonPaulMode = false

---comment
---@param crewmem any
---@return string
local function getBloodType(crewmem)
    local bloodType = mBloodMap[crewmem:GetSpecies()]
    if not bloodType then
        mDangItRonPaulMode = Hyperspace.playerVariables.stability < 100
        if crewmem:IsDrone() then
            return "brown"
        else
            if mDangItRonPaulMode then
                return "pink"
            else
                return "default"
            end
        end
    end
    return bloodType
end

local function randomFolder()
    return "blood_7"
end

local function splatter(crewmem)
    if not (lwl.setIfNil(Hyperspace.metaVariables["lwl_render_blood_splatters"], 0) == 1) then return end

    local folderName = "particles/blood/"..getBloodType(crewmem).."/"..randomFolder()
    Brightness.create_particle(folderName, 5, 6.7, lwl.pointToPointf(crewmem:GetPosition()), math.random(0,359), crewmem.currentShipId, "SHIP_SPARKS")
end

lweb.registerDeathAnimationListener(splatter)
