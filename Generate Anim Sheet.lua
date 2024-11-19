--[[
To use: Replace the vars at the top of the file with the information of the crew animation sheets you have.
Keep a copy of this script for each of your mods, and use it whenever you want to make changes.
--]]
local sheetList = {
    {
        crew_name = "fff_buffer",
        sheet_width = 490,
        sheet_height = 805,
        --WARNING! Always use 35x35 or it won't fit right in the spaces.  Also you'll have issues with your projectile bleeding into your portrait.
        frame_width = 35,
        frame_height = 35,
        --Row and column are counted from the bottom right of the spritesheet, and then up and left.  Time is how long a single loop of all the frames takes.
            --Note: Time may break if set very large (around 1000000)
        --Leave name alone, change everything else based on your spritesheet and animation goals.
        {name="walk_down", length=4, row=22, column=0, time=1},
        {name="walk_left", length=4, row=21, column=0, time=1},
        {name="walk_right", length=4, row=20, column=0, time=1},
        {name="walk_up", length=4, row=19, column=0, time=1},
        {name="repair", length=1, row=18, column=0, time=2},
        {name="type_down", length=4, row=17, column=0, time=1},
        {name="type_left", length=4, row=14, column=0, time=1},
        {name="type_right", length=4, row=15, column=0, time=1},
        {name="type_up", length=4, row=16, column=0, time=1},
        {name="fire_down", length=1, row=13, column=0, time=1},
        {name="fire_left", length=1, row=10, column=0, time=1},
        {name="fire_right", length=1, row=11, column=0, time=1},
        {name="fire_up", length=1, row=12, column=0, time=1},
        {name="punch_down", length=1, row=22, column=0, time=2},
        {name="punch_up", length=1, row=21, column=0, time=2},
        {name="shoot_down", length=1, row=22, column=0, time=1},
        {name="shoot_left", length=1, row=21, column=0, time=1},
        {name="shoot_right", length=1, row=20, column=0, time=1},
        {name="shoot_up", length=1, row=19, column=0, time=1},
        {name="teleport", length=11, row=3, column=0, time=.5},
        {name="death_right", length=12, row=2, column=0, time=2},
        {name="death_left", length=1, row=2, column=0, time=2},
        {name="clone", length=11, row=1, column=0, time=.75},
        {name="portrait", length=1, row=0, column=0, time=1}
        --The projectile is defined by the portrait location, and is one frame to its right.
    }
}


--The rest of this is the program, run it and copy the output to a text file and read through it.















local ANIM_BLOCK_TEMPLATE = [[
	<anim name="%s_%s">
		<sheet>%s</sheet>
		<desc length="%d" x="%d" y="%d" />
		<time>%g</time>
	</anim>
]]

local ANIM_SHEET_TEMPLATE = [[
<animSheet name="%s" w="%s" h="%s" fw="%s" fh="%s">people/%s_base.png</animSheet>
]]


local function getAnimBlock(sheet, index)
    local definition = sheet[index]
    return string.format(ANIM_BLOCK_TEMPLATE,
        sheet.crew_name, definition.name,
        sheet.crew_name,
        definition.length, definition.column, definition.row, 
        definition.time)
end

local function makeText(sheet)
    local text = string.format(ANIM_SHEET_TEMPLATE, sheet.crew_name, sheet.sheet_width, sheet.sheet_height, sheet.frame_width, sheet.frame_height, sheet.crew_name)
    for i = 1,#sheet do
        text = text..getAnimBlock(sheet, i)
    end
    return text
end

local function makeSheets()
    local sheets = ""
    for i = 1,#sheetList do
        sheets = sheets..makeText(sheetList[i])
    end
    return sheets
end

local function runProgram()
    print("Put this in animations.xml.append:")
    print(makeSheets())
end
runProgram()

