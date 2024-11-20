--[[
To use: Replace the vars at the top of the file with the information of the augment you want to create.

Keep a copy of this script for each of your mods, and use it whenever you want to make changes.

--This assumes your augment is passive, if it isn't you'll have to modify some text afterwards.

--Tip: You can merge findName blocks with the exact same text if you have multiples.
--]]


local labList = {
        {
            --  Make a list of all the crew types you want this agument to apply to.  Buffer doesn't have any variants, so there's just one name here.
            CREW_TYPES = {"fff_buffer"},
            --What is the general term in code for this type of crew? (Upper case, no spaces)
            CREW_NAME_INTERNAL = "FFF_BUFFER",
            --What is this type of crew called? (Spaces ok)
            CREW_NAME = "Buffer",
            --The following is a list of descriptions of the augments you want to make for this crew:
            {
                --What is this augment called?  (In code, this will be upper case, with spaces replaced with underscores.)
                AUG_FRIENDLY_NAME = "Extended Memory",
                --What does it do? (Short)
                AUG_DESCRIPTION = "Keep track of what you were doing.",
                --What does it do? (As detailed as you like.)
                AUG_LONG_DESCRIPTION = "Equip your Buffers with external memory banks, allowing them to remember their stack even if they are interrupted.",
                --How much should this upgrade cost?  (Scrap only, for other costs see cost guides.)
                SCRAP_COST = 40
            },
            {
                AUG_FRIENDLY_NAME = "Overclock",
                AUG_DESCRIPTION = "Buffers execute commands twice as fast but have 30 less health.",
                AUG_LONG_DESCRIPTION = "Manual tuning charges your Buffers with power, but makes their systems vulnerable. 2x execution speed, -30 health.",
                SCRAP_COST = 50
            }
        },
        {
            CREW_TYPES = {"fff_f22"},
            CREW_NAME_INTERNAL = "FFF_F22",
            CREW_NAME = "F-22",
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
                AUG_LONG_DESCRIPTION = "Undo the safety mechanisms on your F-22's engines, increasing their speed, dash damage, stun time, and self damage by 1.3x.",
                SCRAP_COST = 32
            },
            {
                AUG_FRIENDLY_NAME = "Armored Nosecones",
                AUG_DESCRIPTION = "No door can stand in your way.",
                AUG_LONG_DESCRIPTION = "Tiny battering rams turn your F-22's into wrecking crew, destroying any door that stands in their way.",
                SCRAP_COST = 20
            }
        }
    }



--The rest of this is the program, run it and copy the output to a text file and read through it.













--This is the master version, I need to pull in F22 and make this one file.
--todo add slug pleasure pod version.  Real easy.
--todo add a boon + the generating code for it.
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

function storageCheckInventoryLab(augmentList)
    local labInventoryChecks = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", augmentList.CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        labInventoryChecks = labInventoryChecks..string.format(STORAGE_CHECK_INVENTORY_LAB, 
            augName, augment.AUG_FRIENDLY_NAME, augmentList.CREW_NAME_INTERNAL, augName, augment.AUG_FRIENDLY_NAME)
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

function storageCheckLabCrew(augmentList)
    local labCrewChecks = ""
    local labCrewChecksEnd = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", augmentList.CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        labCrewChecks = labCrewChecks..string.format(STORAGE_CHECK_LAB_CREW, 
            augName, augment.AUG_FRIENDLY_NAME, augment.AUG_DESCRIPTION)
        labCrewChecksEnd = labCrewChecksEnd..string.format(STORAGE_CHECK_LAB_CREW_END,
            augmentList.CREW_NAME_INTERNAL, i, augment.AUG_FRIENDLY_NAME, augmentList.CREW_NAME_INTERNAL, i, augment.AUG_FRIENDLY_NAME, augment.SCRAP_COST, augName)
    end
    return labCrewChecks..STORAGE_CHECK_LAB_CREW_MIDDLE..labCrewChecksEnd
end

function storageCheckAugment(augmentList)
    local eventString = ""
    for i = 1,#augmentList do
        local augment = augmentList[i]
        local augName = string.format("LAB_%s_%s", augmentList.CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
        eventString = eventString..string.format(STORAGE_CHECK_AUGMENT, 
            augName, augment.AUG_FRIENDLY_NAME, augment.AUG_LONG_DESCRIPTION, CREW_NAME, augment.SCRAP_COST, augment.SCRAP_COST, augment.SCRAP_COST, augName,
            augName, augName, augmentList.CREW_NAME_INTERNAL, augmentList.CREW_NAME_INTERNAL)
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

local specialStorageHeaderEntry = [[
    <mod-append:choice req="LIST_CREW_%s" blue="false" hidden="true">
		<text>%s.</text>
		<event load="STORAGE_CHECK_LAB_%s"/>
    </mod-append:choice>
]]

local specialStorageHeader = [[
<mod:findName type="event" name="STORAGE_CHECK_LAB">%s</mod:findName>
]]

local specialStorageText = [[
<!-- Begin generated lab events for %s-->

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

local function getSpecialStorageHeader(labList)
    local storageEvents = ""
    for i=1,#labList do
        storageEvents = storageEvents..string.format(specialStorageHeaderEntry, labList[i].CREW_NAME_INTERNAL, labList[i].CREW_NAME, labList[i].CREW_NAME_INTERNAL)
    end
    return string.format(specialStorageHeader, storageEvents)
end

local function getSpecialStorageEntry(augmentList)
    return string.format(specialStorageText, 
        augmentList.CREW_NAME,
        augmentList.CREW_NAME_INTERNAL, augmentList.CREW_NAME, storageCheckLabCrew(augmentList),
        storageCheckAugment(augmentList),
        augmentList.CREW_NAME)
end

local function getSpecialStorageTextInternal(labList)
    local storageEvents = ""
        for i=1,#labList do
        local augmentList = labList[i]
        storageEvents = storageEvents..getSpecialStorageEntry(augmentList)
    end
    return getSpecialStorageHeader(labList)..storageEvents
end

local function getSpecialStorageText(labList)
    return getSpecialStorageTextInternal(labList)
end

local hyperspaceText = [[
	<augments limit="1">
%s
    </augments>
]]

local hyperspaceTextInternal = [[
		<aug name="%s">
			--You'll need to fill this out with what you want the augment to do.
		</aug>
]]

local function getHyperspaceTextInternal(labList)
    local eventString = ""
    for j =1,#labList do
        local augmentList = labList[j]
        for i = 1,#augmentList do
            local augment = augmentList[i]
            local augName = string.format("LAB_%s_%s", augmentList.CREW_NAME_INTERNAL, programmifyString(augment.AUG_FRIENDLY_NAME))
            eventString = eventString..string.format(hyperspaceTextInternal, 
                augName)
        end
    end
    return eventString
end

local function blueprintNames(augmentList)
    local names = ""
    for i = 1, #augmentList.CREW_TYPES do
        names = names.."<name>"..augmentList.CREW_TYPES[i].."</name>\n"
    end
    return names
end

local function getBlueprintText(labList)
    local retString = ""
    for i = 1,#labList do
        retString = retString..string.format(blueprintText, labList[i].CREW_NAME_INTERNAL, blueprintNames(labList[i]))
    end
    return retString
end

local function getHyperspaceText(labList)
    return string.format(hyperspaceText, getHyperspaceTextInternal(labList))
end

local function runProgram(labList)
    print("\n------------------------------------------------------------------")
    print("\nPut this in autoBlueprints.xml.append:")
    print(getBlueprintText(labList))
    print("Put the following in your events_special_storage.xml.append:")
    print(getSpecialStorageText(labList))
    print("Finally, go put something like this in your hyperspace.xml.append.  If you have multiple augments, you can use the same findLike tag to hold all of them.")
    print(getHyperspaceText(labList))
end
runProgram(labList)
