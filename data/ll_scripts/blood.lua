----brightness!
---
---
local Brightness = mods.brightness
local lwl = mods.lightweight_lua
local lwui = mods.lightweight_user_interface
local lweb = mods.lightweight_event_broadcaster
local vter = mods.multiverse.vter


--[[
ok, I think I need to make a crewtable for each crew, when they die they add a value to it, and when they revive they remove it.
which basically means I want to make a library that has various events that trigger.
And this one is onCrewDeath.


I'm doing something that makes crew spaz out when they spawn and go to places you didn't tell them to.
In CrewEquipmentLibrary?  Nothing there tells crew where to go.
It sure seems like adding CEL causes this to happen.  It must be something in like, utils that cel is calling into?

removed all the lua from cel.  if it still has this issue idefka
ok best guess is it's a crew observer thing.


Ok, here's what it is: crew being uncontrollable for a single tick due to confusion.
I can make a small mod/option that makes crew pick something to do after cloning back instead of standing there.
With options of: pick somewhere, or go back to your saved position (If I can access that)



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
--whenever someone dies, make a random blood particle.

--whenever a drone dies, make an oil slick (recolored blood particle)
--I should probably check lists instead of writing individual definitions.  All drones get the same treatment though.  Even plant drones.

--[[
its crashing because the crew has no location when dead.  Wait no.  It's not dead when it's animating.


                I was able to click the button in the menu.  However, it did not work, and gave me this:

                > Execution error for 'Export Multi-Opacity':

                Error: string-append: argument 1 must be: string 

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
local function getBlueprintListSafe(name)
    return lwl.setIfNil(Hyperspace.Blueprints:GetBlueprintList(name), {})
end


local engi = getBlueprintListSafe("LIST_CREW_ENGI")
local zoltan = getBlueprintListSafe("LIST_CREW_ZOLTAN")
local orchid = getBlueprintListSafe("LIST_CREW_ORCHID")
local shell = getBlueprintListSafe("LIST_CREW_SHELL")
local mantis = getBlueprintListSafe("LIST_CREW_MANTIS")
local rock = getBlueprintListSafe("LIST_CREW_ROCK")
local crystal = getBlueprintListSafe("LIST_CREW_CRYSTAL")
local lanius = getBlueprintListSafe("LIST_CREW_LANIUS")
local ghost = getBlueprintListSafe("LIST_CREW_GHOST")
local slug = getBlueprintListSafe("LIST_CREW_SLUG")
local leech = getBlueprintListSafe("LIST_CREW_LEECH")
local obelisk = getBlueprintListSafe("LIST_CREW_ANCIENT")
local cognitive = getBlueprintListSafe("LIST_CREW_COGNITIVE_ALL")
local spider = getBlueprintListSafe("LIST_CREW_SPIDER")
local pony = getBlueprintListSafe("LIST_CREW_PONY")
local lizard = getBlueprintListSafe("LIST_CREW_LIZARD")
local salt = getBlueprintListSafe("LIST_CREW_OBYN")
local morph = getBlueprintListSafe("LIST_CREW_MORPH")
local siren = getBlueprintListSafe("LIST_CREW_SIREN")
local eldritch = getBlueprintListSafe("LIST_CREW_ELDRITCH")

local plant_drones = getBlueprintListSafe("LIST_DRONES_VAMPWEED")

----Non-drones
local bloodOrange = {orchid, lanius}
local bloodGreen = {zoltan, shell, mantis, slug, spider, lizard}
local bloodBlue = {engi, crystal, ghost}
local bloodPurple = {cognitive, siren}
local bloodBrown = {rock}
local bloodGrey = {obelisk, morph, salt}

local bloodHer = {eldritch}
local bloodBlack = {} --DD, SS, HB, CD
local bloodWarmStatic = {} --FFFTL
--Anything not on this list is red blood.
----Drones

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

local testToggleButton = lwui.buildToggleButton(300, 300, 30, 30, lwui.alwaysOnVisibilityFunction, 
lwui.toggleButtonRenderFunction(
        "particles/effects/bleed/0.png",
        "particles/effects/confusion/0.png",
        "particles/effects/corruption/0.png",
        "particles/blood/default/blood_7/0.png"
), NOOP)

local switchScreenButton = lwui.buildButton(1218, 585, 30, 30, --disco icon?
    lwui.alwaysOnVisibilityFunction, lwui.solidRectRenderFunction(Graphics.GL_Color(1, 0, 0, 1)), NOOP, NOOP)

--lwui.addTopLevelObject(testToggleButton, "MOUSE_CONTROL_PRE")
--lwui.addTopLevelObject(switchScreenButton, "MOUSE_CONTROL_PRE")

local mDangItRonPaulMode = false

---comment
---@param crewmem any
---@return string
local function getBloodType(crewmem)
    local bloodType = mBloodMap[crewmem:GetSpecies()]
    if not bloodType then
        mDangItRonPaulMode = Hyperspace.playerVariables.stability < 100
        if mDangItRonPaulMode then
            return "pink"
        else
            return "default"
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
