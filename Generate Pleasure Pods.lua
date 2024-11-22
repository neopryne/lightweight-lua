--name is plural
local crewTable = {
    {
        name="Buffers",
        nameInternal="fff_buffer",
        text="The Buffers shuffle off into the pleasure pods. Time passes. You're starting to wonder if they're actually doing anything when you hear an indescribable cacophony and shortly after, are greeted by three Buffers."
    },
    {
        name="Lockheed Martin F-22 Raptors",
        nameInternal="fff_f22",
        text="The planes somehow manage to cram into the pods.  When they finally emerge again after much crashing and groaning, they are three.  You double check the room, but can't for the life of you figure out how they managed to fit."
    },
    {
        name="OMENS",
        nameInternal="fff_omen",
        text="There are two OMENS.  You go to bring them to the pods. Your head hurts.  There are three OMENS."
    }
}

-------------Below this is the program---------------------











local EVENT_TEXT = [[
<mod:findName type="event" name="%s" panic="true">
    <mod-append:choice req="%s" lvl="2" hidden="true">
		<text>Breed two %s.</text>
		<event>
			<text>%s</text>
			<crewMember amount="1" class="%s"/>
		</event>
    </mod-append:choice>
</mod:findName>
]]


local PLEASURE_PODS = "STORAGE_CHECK_AUG_SLUG_DUPLICATOR"
local GHOST_PODS = "STORAGE_CHECK_AUG_SLUG_DUPLICATOR_GHOST"


local function getEvent(eventName, crewDef)
    return string.format(EVENT_TEXT, eventName, crewDef.nameInternal, crewDef.name, crewDef.text, crewDef.nameInternal)
end

local function makeEvents()
    local eventText = ""
    for i =1,#crewTable do
        crew = crewTable[i]
        eventText = eventText..getEvent(PLEASURE_PODS, crew)
        eventText = eventText..getEvent(GHOST_PODS, crew)
    end
    return eventText
end

local function runProgram()
    print("Put the following in your events_special_storage.xml.append:")
    print(makeEvents())
end
runProgram()
