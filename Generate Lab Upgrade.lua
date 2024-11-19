--[[
To use: Replace the vars at the top of the file with the information of the augment you want to create.

Keep a copy of this script for each of your mods, and use it whenever you want to make changes.

--This assumes your augment is passive, if it isn't you'll have to modify some text afterwards.

--Tip: You can merge findName blocks with the exact same text if you have multiples.
--]]

--Which crew types is this for?
--  Make a list of all the crew types you want this agument to apply to.  F22 doesn't have any variants, so there's just one name here.
local CREW_TYPES = {"fff_f22"}
--What is the general term in code for this type of crew? (Upper case, no spaces)
local CREW_NAME_INTERNAL = "FFF_F22"
--What is this type of crew called? (Spaces ok)
local CREW_NAME = "F-22"
--The following is a list of descriptions of the augments you want to make for this crew:
local augmentList = {
        {
            --What is this augment called?  (In code, this will be upper case, with spaces replaced with underscores.)
            AUG_FRIENDLY_NAME = "Thermal Imaging",
            --What does it do? (Short)
            AUG_DESCRIPTION = "See crew locations even without sensors.",
            --What does it do? (As detailed as you like.)
            AUG_LONG_DESCRIPTION = "Your F-22 crew gain the ability to see crew even if your ship's sensors are not functioning.",
            --How much should this upgrade cost?  (Scrap only, for other costs see cost guides.)
            SCRAP_COST = 40
        },
        {
            AUG_FRIENDLY_NAME = "Supersonic Airbags",
            AUG_DESCRIPTION = "Extra padding reduces damage to autopilots.",
            AUG_LONG_DESCRIPTION = "Install active inflation collision devices to stop your F-22's from hurting themselves as they zoom around.  Removes the self damage from errant dashes.",
            SCRAP_COST = 22
        },        
        {
            AUG_FRIENDLY_NAME = "Freedom Boosters",
            AUG_DESCRIPTION = "Let your F-22's excercise their god-given right to reckless endangerment in pursuit of going really fast.",
            AUG_LONG_DESCRIPTION = "Undo the safety mechanisms on your F22's engines, increasing their speed, dash damage, stun time, and self damage by 1.3x.",
            SCRAP_COST = 32
        },
    }



--The rest of this is the program, run it and copy the output to a text file and read through it.















--todo I could loop this to create several, make the current vars a table and let people add more.
--Honestly not a bad idea, it would make the experience much easier of adding more upgrades for a single unit.

local function programmifyString(input)
    return (string.upper(input):gsub("%s", "_"))
end

local blueprintText = [[
	<blueprintList name="LIST_CREW_%s"> 
		%s
	</blueprintList>
]]

function storageCheckInventoryLab()
    local labInventoryChecks = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        labInventoryChecks = labInventoryChecks..string.format(STORAGE_CHECK_INVENTORY_LAB, 
            augName, augment.AUG_FRIENDLY_NAME, CREW_NAME_INTERNAL, augName, augment.AUG_FRIENDLY_NAME)
    end
    return labInventoryChecks
end


STORAGE_CHECK_INVENTORY_LAB = [[
 	<mod-append:choice hidden="true" req="%s" lvl="1" blue="false">
		<text>%s [Installed]</text>
		<event load="STORAGE_CHECK_LAB_%s"/>
	</mod-append:choice>
	<mod-append:choice hidden="true" req="%s" lvl="0" max_lvl="0" blue="false">
		<text>%s [Not Installed]</text>
		<event load="OPTION_INVALID"/>
	</mod-append:choice>
]]
    
STORAGE_CHECK_LAB_CREW = [[
	<choice req="%s" lvl="1" max_group="0" blue="false" hidden="true">
		<text>Currently Installed Passive: %s.
		[%s]</text>
		<event load="OPTION_INVALID"/>
	</choice>
]]

STORAGE_CHECK_LAB_CREW_MIDDLE = [[
	<choice req="pilot" lvl="1" max_group="0" blue="false" hidden="true">
		<text>Currently Installed Passive: None</text>
		<event load="OPTION_INVALID"/>
	</choice>

]]

STORAGE_CHECK_LAB_CREW_END = [[
	<choice req="LAB_%s_INSTALLED" lvl="1" max_group="%d" blue="false" hidden="true">
		<text>Pas: %s. [An upgrade is already installed]</text>
		<event load="OPTION_INVALID"/>
	</choice>
	<choice req="LAB_%s_INSTALLED" lvl="0" max_group="%d" blue="false" hidden="true">
		<text>Pas: %s. [Cost: %d~]</text>
		<event load="STORAGE_CHECK_%s"/>
	</choice>
]]

function storageCheckLabCrew()
    local labCrewChecks = ""
    local labCrewChecksEnd = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        labCrewChecks = labCrewChecks..string.format(STORAGE_CHECK_LAB_CREW, 
            augName, augment.AUG_FRIENDLY_NAME, augment.AUG_DESCRIPTION)
        labCrewChecksEnd = labCrewChecksEnd..string.format(STORAGE_CHECK_LAB_CREW_END,
            CREW_NAME_INTERNAL, i, augment.AUG_FRIENDLY_NAME, CREW_NAME_INTERNAL, i, augment.AUG_FRIENDLY_NAME, augment.SCRAP_COST, augName)
    end
    return labCrewChecks..STORAGE_CHECK_LAB_CREW_MIDDLE..labCrewChecksEnd
end

function storageCheckAugment()
    local eventString = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        eventString = eventString..string.format(STORAGE_CHECK_AUGMENT, 
            augName, augment.AUG_FRIENDLY_NAME, augment.AUG_LONG_DESCRIPTION, CREW_NAME, augment.SCRAP_COST, augment.SCRAP_COST, augment.SCRAP_COST, augName,
            augName, augName, CREW_NAME_INTERNAL, CREW_NAME_INTERNAL)
    end
    return eventString
end

STORAGE_CHECK_AUGMENT = [[
<event name="STORAGE_CHECK_%s">
	<text>You are about to install the %s modification.
	[Effects: %s]
	
	[Warning: After installing this, you will not be able to install any more Passive upgrades for %s crew. You will not be able to deactivate this mod either.]</text>
	<choice hidden="true">
		<text>Install the modification. [Cost: %d~]</text>
		<event>
			<text>You install the modification.</text>
			<item_modify>
				<item type="scrap" min="-%d" max="-%d"/>
			</item_modify>
			<choice hidden="true">
				<text>Continue...</text>
				<event load="INSTALL_%s"/>
			</choice>
		</event>
	</choice>
	<choice req="pilot" lvl="1" max_group="1" blue="false" hidden="true">
		<text>Nevermind.</text>
		<event load="STORAGE_CHECK_LAB_LOAD"/>
	</choice>
</event>

<event name="INSTALL_%s">
	<variable name="loc_lab_upgrades" op="add" val="1"/>
	<hiddenAug>%s</hiddenAug>
	<hiddenAug>LAB_%s_INSTALLED</hiddenAug>
	<loadEvent>STORAGE_CHECK_LAB_%s</loadEvent>
</event>

]]

local specialStorageText = [[
<!-- Begin generated lab events for %s-->
<mod:findName type="event" name="STORAGE_CHECK_INVENTORY_LAB"> 
%s</mod:findName>

<mod:findName type="event" name="STORAGE_CHECK_LAB">
    <mod-append:choice req="LIST_CREW_%s" blue="false" hidden="true">
		<text>%s.</text>
		<event load="STORAGE_CHECK_LAB_%s"/>
    </mod-append:choice>
    <mod:findWithChildLike type="choice" child-type="text">
      <mod:selector>Nevermind.</mod:selector>
      <mod:setAttributes max_group="998" req="pilot" lvl="1" blue="false"/>
    </mod:findWithChildLike>
</mod:findName>

<event name="STORAGE_CHECK_LAB_%s">
	<text>You are viewing the lab menu for: [%s]</text>
%s
	<choice req="pilot" lvl="1" max_group="999" blue="false" hidden="true">
		<text>Go back.</text>
		<event load="STORAGE_CHECK_LAB_LOAD"/>
	</choice>
</event>

%s
<!-- End generated lab events for %s-->
]]

local function getSpecialStorageText()
    return string.format(specialStorageText,
        CREW_NAME,
        storageCheckInventoryLab(),
        CREW_NAME_INTERNAL, CREW_NAME, CREW_NAME_INTERNAL,
        CREW_NAME_INTERNAL, CREW_NAME, storageCheckLabCrew(),
        storageCheckAugment(),
        CREW_NAME)
end

local hyperspaceText = [[
	<mod:findLike type="augments" limit="1">
%s</mod:findLike>
]]

local hyperspaceTextInternal = [[
		<mod-append:aug name="%s">
			--You'll need to fill this out with what you want the augment to do.
		</mod-append:aug>
]]

local function getHyperspaceTextInternal()
    local eventString = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        eventString = eventString..string.format(hyperspaceTextInternal, 
            augName)
    end
    return eventString
end

local function blueprintNames()
    local names = ""
    for i = 1, #CREW_TYPES do
        names = names.."<name>"..CREW_TYPES[i].."</name>\n"
    end
    return names
end

local function getBlueprintText()
    return string.format(blueprintText, CREW_NAME_INTERNAL, blueprintNames())
end

local function getHyperspaceText()
    return string.format(hyperspaceText, getHyperspaceTextInternal())
end

local function runProgram()
    print("\n------------------------------------------------------------------")
    print("\nPut this in autoBlueprints.xml.append:")
    print(getBlueprintText())
    print("Put the following in your events_special_storage.xml.append:")
    print(getSpecialStorageText())
    print("Finally, go put something like this in your hyperspace.xml.append.  If you have multiple augments, you can use the same findLike tag to hold all of them.")
    print(getHyperspaceText())
end
runProgram()
