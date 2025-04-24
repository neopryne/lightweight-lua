mods.lightweight_lua = {}
local lwl = mods.lightweight_lua

--[[Usage:
    local lwl = mods.lightweight_lua
    lwl.whatever()

Table of Contents (Search for these strings to go to category header)
    TABLE UTILS
    LOGGING UTILS
    CREW UTILS
    GEOMETRY UTILS
    EVENT INTERACTION UTILS
]]--

local vter = mods.multiverse.vter
local get_room_at_location = mods.vertexutil.get_room_at_location

local global = Hyperspace.Global.GetInstance()
local mCrewMemberFactory = global:GetCrewFactory()

local TAU = math.pi * 2
local OWNSHIP = 0
local ENEMY_SHIP = 1
local TILE_SIZE = 35
--Breaking change, this is now a function.
--mods.lightweight_lua.TILE_SIZE = TILE_SIZE --Deprecated, use mods.lightweight_lua.sTILE_SIZE() instead.
function mods.lightweight_lua.TILE_SIZE() return TILE_SIZE end --getter to preserve immutible value.
function mods.lightweight_lua.OWNSHIP() return 0 end
function mods.lightweight_lua.CONTACT_1() return 1 end
function mods.lightweight_lua.UNSELECTED() return 0 end
function mods.lightweight_lua.SELECTED() return 1 end
function mods.lightweight_lua.SELECTED_HOVER() return 2 end

local SYS_SHIELDS = 0
local SYS_ENGINES = 1
local SYS_OXYGEN = 2
local SYS_WEAPONS = 3
local SYS_DRONES = 4
local SYS_MEDBAY = 5
local SYS_PILOT = 6
local SYS_SENSORS = 7
local SYS_DOORS = 8
local SYS_TELEPORTER = 9
local SYS_CLOAKING = 10
local SYS_ARTILLERY = 11
local SYS_BATTERY = 12
local SYS_CLONEBAY = 13
local SYS_MIND = 14
local SYS_HACKING = 15
local SYS_TEMPORAL = 20
function mods.lightweight_lua.SYS_SHIELDS() return SYS_SHIELDS end
function mods.lightweight_lua.SYS_ENGINES() return SYS_ENGINES end
function mods.lightweight_lua.SYS_OXYGEN() return SYS_OXYGEN end
function mods.lightweight_lua.SYS_WEAPONS() return SYS_WEAPONS end
function mods.lightweight_lua.SYS_DRONES() return SYS_DRONES end
function mods.lightweight_lua.SYS_MEDBAY() return SYS_MEDBAY end
function mods.lightweight_lua.SYS_PILOT() return SYS_PILOT end
function mods.lightweight_lua.SYS_SENSORS() return SYS_SENSORS end
function mods.lightweight_lua.SYS_DOORS() return SYS_DOORS end
function mods.lightweight_lua.SYS_TELEPORTER() return SYS_TELEPORTER end
function mods.lightweight_lua.SYS_CLOAKING() return SYS_CLOAKING end
function mods.lightweight_lua.SYS_ARTILLERY() return SYS_ARTILLERY end
function mods.lightweight_lua.SYS_BATTERY() return SYS_BATTERY end
function mods.lightweight_lua.SYS_CLONEBAY() return SYS_CLONEBAY end
function mods.lightweight_lua.SYS_MIND() return SYS_MIND end
function mods.lightweight_lua.SYS_HACKING() return SYS_HACKING end
function mods.lightweight_lua.SYS_TEMPORAL() return SYS_TEMPORAL end

--This might be overkill, but it works
function mods.lightweight_lua.isPaused()
    local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
    return commandGui.bPaused or commandGui.bAutoPaused or commandGui.event_pause or commandGui.menu_pause
end

--usage: object = nilSet(object, value) TODO rename setIfNil
function mods.lightweight_lua.nilSet(object, value)
    if (object == nil) then
        object = value
    end
    return object
end

--[[  TABLE UTILS  ]]--
--for use in printing all of a table
function mods.lightweight_lua.dumpObject(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. mods.lightweight_lua.dumpObject(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--deep copy of t1 and t2 to t3
--only one level deep though, it's not recursive.  For that, use deepTableMerge
function mods.lightweight_lua.tableMerge(t1, t2)
    local t3 = {}
    for i=1,#t1 do
        t3[#t3+1] = t1[i]
    end
    for i=1,#t2 do
        t3[#t3+1] = t2[i]
    end
    return t3
end

--note: does not copy objects in the table.
function mods.lightweight_lua.deepCopyTable(t)
    if type(t) ~= "table" then
        return t  -- Return the value directly if it's not a table (base case)
    end

    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = mods.lightweight_lua.deepCopyTable(v)  -- Recursively copy nested tables
        else
            copy[k] = v  -- Directly copy non-table values
        end
    end
    return copy
end

--https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
--The filter function is which ones to keep
function mods.lightweight_lua.arrayRemove(table, filterFunction)
    local j, n = 1, #table;
    for i=1,n do
        if (filterFunction(table, i)) then
            --print("keeping this one")
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                table[j] = table[i];
                table[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            table[i] = nil;
        end
    end
    return table;
end

--returns nil if table is empty
function mods.lightweight_lua.getRandomKey(table)
    local keys = {}
    for key in pairs(table) do
        keys[#keys + 1] = key
    end
    if #keys == 0 then 
        return nil 
    end
    local randomIndex = math.random(#keys)
    return keys[randomIndex]
end

--Returns the set of elements in newSet that are not in initialSet
function mods.lightweight_lua.getNewElements(newSet, initialSet)
    elements = {}
    for _, newElement in ipairs(newSet) do
        local wasPresent = false
        for _, oldElement in ipairs(initialSet) do
            if (oldElement == newElement) then
                wasPresent = true
                break
            end
        end
        if not wasPresent then
            table.insert(elements, newElement)
        end
    end
    return elements
end

function mods.lightweight_lua.setRemove(baseSet, elementsToRemove)
    elements = {}
    for _, oldElement in ipairs(baseSet) do
        local wasPresent = false
        for _, removeThis in ipairs(elementsToRemove) do
            if (oldElement == removeThis) then
                wasPresent = true
                break
            end
        end
        if not wasPresent then
            table.insert(elements, oldElement)
        end
    end
    return elements
end

function mods.lightweight_lua.setMerge(newSet, initialSet)
    elements = lwl.deepCopyTable(initialSet)
    for _, newElement in ipairs(newSet) do
        local wasPresent = false
        for _, oldElement in ipairs(initialSet) do
            if (oldElement == newElement) then
                wasPresent = true
                break
            end
        end
        if not wasPresent then
            table.insert(elements, newElement)
        end
    end
    return elements
end

--Returns the set intersection of two tables.
function mods.lightweight_lua.setXor(table1, table2)
   return lwl.setMerge(lwl.getNewElements(table1, table2), lwl.getNewElements(table2, table1))
end

--Returns the set intersection of two tables.
function mods.lightweight_lua.setIntersectionTable(table1, table2)
   local interSet = {}
   for i = 1,#table1 do
       local value = table1[i]
       for j = 1,#table2 do
           if (value == table2[j]) then
               table.insert(interSet, value)
           end
       end
   end
   return interSet
end

function mods.lightweight_lua.setIntersectionVter(userdata1, userdata2)
   local interSet = {}
   for door1 in vter(userdata1) do
       for door2 in vter(userdata2) do
           if (door1 == door2) then
               table.insert(interSet, door1)
           end
       end
   end
   return interSet
end

function mods.lightweight_lua.countKeys(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

--takes an integer value
function mods.lightweight_lua.setMetavar(name, value)
    if (value ~= nil) then
        Hyperspace.metaVariables[name] = value
    end
    return (value ~= nil)
end

--returns a merged deep copy of both tables.  Non-table objects will not be deep-copied.
function mods.lightweight_lua.deepTableMerge(t1, t2)
    t1Copy = mods.lightweight_lua.deepCopyTable(t1)
    t2Copy = mods.lightweight_lua.deepCopyTable(t2)
    return mods.lightweight_lua.tableMerge(t1Copy, t2Copy)
end

--[[  LOGGING UTILS  ]]--
--needs to be a metavar actually, or it can turn off randomly
mods.lightweight_lua.LOG_LEVEL = 1 --Higher is more verbose, feel free to modify this.
--[[
    0 -- NO logs, not even errors, not recommended.
    1 -- Errors only
    2 -- Adds Warnings
    3 -- Adds Debug
    4 -- Adds Info
    5 -- Verbose
    
    Usage:
    MY_MOD_LOG_LEVEL = 3
    
    lwl.logWarn("oh no, this will use the globally defined debug level anyone can modify!") -- Not recommended
    lwl.logWarn("oh no, this will use my debug level!", MY_MOD_LOG_LEVEL) -- Recommended
--]]
local LOG_LEVELS = {
    {text="ERROR", level=1},
    {text="WARN", level=2},
    {text="DEBUG", level=3},
    {text="INFO", level=4},
    {text="VERBOSE", level=5}}
local function logInternal(tag, text, logLevel, optionalLogLevel)
    local maxLogLevel = optionalLogLevel
    if (maxLogLevel == nil) then
        maxLogLevel = mods.lightweight_lua.LOG_LEVEL
    end
    if (logLevel <= maxLogLevel) then
        print(LOG_LEVELS[logLevel].text..": "..tag.." - "..text)
    end
end
--Optionally, pass the desired log level.  This lets you store that locally and change it in your mod.
--It might seem silly to pass values you know will fail, but that's the point, so you can enable debug easily when you want to change things,
--and turn it off when you want to ship.
function mods.lightweight_lua.logError(tag, text, optionalLogLevel)
    logInternal(tag, text, 1, optionalLogLevel)
end
function mods.lightweight_lua.logWarn(tag, text, optionalLogLevel)
    logInternal(tag, text, 2, optionalLogLevel)
end
function mods.lightweight_lua.logDebug(tag, text, optionalLogLevel)
    logInternal(tag, text, 3, optionalLogLevel)
end
function mods.lightweight_lua.logInfo(tag, text, optionalLogLevel)
    logInternal(tag, text, 4, optionalLogLevel)
end
function mods.lightweight_lua.logVerbose(tag, text, optionalLogLevel)
    logInternal(tag, text, 5, optionalLogLevel)
end

--[[  CREW UTILS  ]]--
local function getAllShipCrew(crewShipManager, targetShipManager, tracking)
    local memberCrew = {}
    if not targetShipManager then return memberCrew end
    local i = 0
    local j = 0
    for crewmem in vter(targetShipManager.vCrewList) do
        i=i+1
        if (crewmem.iShipId == crewShipManager.iShipId) then
            j=j+1
            if (tracking == "all") or (tracking == "crew" and not crewmem:IsDrone()) or (tracking == "drones" and crewmem:IsDrone()) then
                table.insert(memberCrew, crewmem)
            end
        end
    end
    --print(targetShipManager.iShipId, " Target ship has ", i, " total crew, ", j, " of which belong to ", crewShipManager.iShipId)
    return memberCrew
end

--[[
returns all crew belonging to the given ship on all ships
tracking={"crew", "drones", or "all"}  If no value is passed, defaults to all.
--]]
function mods.lightweight_lua.getAllMemberCrewFromFactory(shipManager, tracking)
    if not tracking then 
        tracking = "all"
    end
    local memberCrew = {}
    for _,crewmem in mCrewMemberFactory.crewMembers do
        if (crewmem.iShipId == shipManager.iShipId) and
            ((crewmem:IsDrone() and (tracking == "all" or tracking == "drones")) or
            (((not crewmem:IsDrone()) and (tracking == "all" or tracking == "crew")))) then
            table.insert(memberCrew, crewmem)
        end
    end
    
    return memberCrew
end


function mods.lightweight_lua.getAllMemberCrew(shipManager, tracking)
    if not tracking then 
        tracking = "all"
    end
    local printString = ""
    local memberCrew = {}
    printString = printString.." Own Crew "
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    local sameShipCrew = getAllShipCrew(shipManager, shipManager, tracking)
    for _,crewmem in ipairs(sameShipCrew) do
        table.insert(memberCrew, crewmem)
        printString = printString..crewmem:GetName()
    end
    printString = printString.." Enemy Crew "
    local otherShipCrew = getAllShipCrew(shipManager, otherShipManager, tracking)
    for _,crewmem in ipairs(otherShipCrew) do
        table.insert(memberCrew, crewmem)
        printString = printString..crewmem:GetName()
    end
    --if #memberCrew < 3 then
    --print("getAllMemberCrew "..printString)
    --end
    return memberCrew
end

--Searches all crew, both ships.  This is unique, so it can just return whatever it finds.
function mods.lightweight_lua.getCrewById(selfId)
    for i=0,1 do
        local shipManager = global:GetShipManager(i)
        for crewmem in vter(shipManager.vCrewList) do
            if (crewmem.extend.selfId == selfId) then
                return crewmem
            end
        end
    end
    print("ERROR: lwl could not get crew ", selfId)
end

--returns all crew on ship that belong to crewShip.
function mods.lightweight_lua.getCrewOnSameShip(shipManager, crewShipManager)
    crewList = {}
    for crewmem in vter(shipManager.vCrewList) do
        if (crewmem.iShipId == crewShipManager.iShipId) then
            table.insert(crewList, crewmem)
        end
    end
    return crewList
end

function mods.lightweight_lua.getSelectedCrew(shipId, selectionState)
    local selectedCrew = {}
    local shipManager = Hyperspace.ships(shipId)
    local i = 0
    if (shipManager ~= nil) then
        for k, crewmem in ipairs(lwl.getAllMemberCrew(shipManager)) do
            if (crewmem.selectionState == selectionState) then --fully selected
                table.insert(selectedCrew, crewmem)
            end
        end
    end

    return selectedCrew
end

-- Returns a table of all crew on shipManager ship's belonging to crewShipManager's crew on the room tile at the given point
--booleans getDrones and getNonDrones are optional, but you have to include both if you include one or it calls wrong
--default is returning all crew if not specified.
--maxCount is optional, but you must specify both getDrones and getNonDrones if you use it
function mods.lightweight_lua.get_ship_crew_point(shipManager, crewShipManager, x, y, getDrones, getNonDrones, maxCount)
    res = {}
    x = x//TILE_SIZE
    y = y//TILE_SIZE
    for crewmem in vter(shipManager.vCrewList) do--todo use the Factory instead.  Factory you can rely on.  Switch the whole library over to it.
        if crewmem.iShipId == crewShipManager.iShipId and x == crewmem.x//TILE_SIZE and y == crewmem.y//TILE_SIZE then
            if ((crewmem:IsDrone() and (getDrones == nil or getDrones) or ((not crewmem:IsDrone()) and (getNonDrones == nil or getNonDrones)))) then
                table.insert(res, crewmem)
                if maxCount and #res >= maxCount then
                    return res
                end
            end
        end
    end
    return res
end

--Relative to the ship crewmem is on
function mods.lightweight_lua.getFoesAtSpace(crewmem, location)
    local enemyList = {}
    local currentShipManager = global:GetShipManager(crewmem.currentShipId)
    local foeShipManager = global:GetShipManager(1 - crewmem.iShipId)
    if (currentShipManager and foeShipManager) then
        enemyList = mods.lightweight_lua.get_ship_crew_point(currentShipManager, foeShipManager, location.x, location.y)
    end
    return enemyList
end

function mods.lightweight_lua.getFoesAtSelf(crewmem)
    return lwl.getFoesAtSpace(crewmem, crewmem:GetPosition())
end

-- -1 in the unlikely event no room is found
function mods.lightweight_lua.getRoomAtCrewmember(crewmem)
    local shipManager = global:GetShipManager(crewmem.currentShipId)
    --need to call this with the shipManager of the ship you want to look at.
    room = get_room_at_location(shipManager, crewmem:GetPosition(), true)
    --print(crewmem:GetLongName(), ", Room: ", room, " at ", crewmem:GetPosition().x, crewmem:GetPosition().y)
    return room
end

--If two rooms have multiple doors, returns all of them.
function mods.lightweight_lua.getSharedDoors(shipId, roomIdFirst, roomIdSecond)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local doorList = shipGraph:GetDoors(roomIdFirst)
    local doorList2 = shipGraph:GetDoors(roomIdSecond)
    local sharedDoors = mods.lightweight_lua.setIntersectionVter(doorList, doorList2)
    return sharedDoors 
end

--returns true if it did anything and false otherwise
function mods.lightweight_lua.damageFoesAtSpace(crewmem, location, damage, stunTime, directDamage)
    local foes_at_point = lwl.getFoesAtSpace(crewmem, location)
    for j = 1, #foes_at_point do
        local foe = foes_at_point[j]
        foe.fStunTime = foe.fStunTime + stunTime
        foe:ModifyHealth(-damage)
        foe:DirectModifyHealth(-directDamage)
    end
    return #foes_at_point > 0
end

--returns true if it did anything and false otherwise
function mods.lightweight_lua.damageFoesInSameSpace(crewmem, damage, stunTime, directDamage)
    return mods.lightweight_lua.damageFoesAtSpace(crewmem, crewmem:GetPosition(), damage, stunTime, directDamage)
end

function mods.lightweight_lua.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
    --print("bystander in helper: " bystander)
    --print(bystander:GetLongName(), "room ", bystander.iRoomId, " ", currentRoom, " ", bystander.currentShipId == activeCrew.currentShipId)
    --print(bystander:GetLongName(), "room ", bystander.iRoomId == currentRoom, " ", bystander.iShipId == ENEMY_SHIP, " ", bystander.currentShipId == activeCrew.currentShipId)
    if bystander.iRoomId == currentRoom and bystander.iShipId == ENEMY_SHIP and bystander.currentShipId == activeCrew.currentShipId then
        --print(bystander:GetLongName(), " was in the same room!  Hit for ", amount, " damage!")
        if (stunTime ~= nil) then
            bystander.fStunTime = bystander.fStunTime + stunTime
        end
        bystander:DirectModifyHealth(-amount)
    end
end

--Does direct damage to all foes in the room. optional stun time
function mods.lightweight_lua.damageEnemyCrewInSameRoom(activeCrew, amount, stunTime)
    local currentRoom = mods.lightweight_lua.getRoomAtCrewmember(activeCrew)
        -- Modified from brightlord's modification of Arc's get_ship_crew_room().
    if (Hyperspace.ships.enemy) then
      for bystander in vter(Hyperspace.ships.enemy.vCrewList) do
            --print(bystander:GetLongName(), " was in the same room!")
          mods.lightweight_lua.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
      end
    end
    --do the same for friendly ship
    for bystander in vter(Hyperspace.ships.player.vCrewList) do
        mods.lightweight_lua.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
    end
end


-- Generate a random point radius away from a point
--modified from vertexUtils random_point_radius
function mods.lightweight_lua.random_point_circle(origin, radius)
    local r = radius
    local theta = TAU*(math.random())
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

--[[  GEOMETRY UTILS  ]]--
-- Generate a random point within the radius of a given point
--modified from vertexUtils random_point_radius
function mods.lightweight_lua.random_point_adjacent(origin)
    local r = TILE_SIZE
    local theta = math.pi*(math.floor(math.random(0, 4))) / 2
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

function mods.lightweight_lua.random_valid_space_point_adjacent(origin, shipManager)
    local r = TILE_SIZE
    local theta = math.pi*(math.floor(math.random(0, 4))) / 2
    for i = 0,3 do
        new_angle = theta + (i * math.pi / 2)
        point = Hyperspace.Point(origin.x + r*math.cos(new_angle), origin.y + r*math.sin(new_angle))
        if (not ((get_room_at_location(shipManager, point, true) == -1))) then
            return point
        end
    end
    return nil
end

--returns the closest available slot, or a slot with id and room -1 if none is found.
--isIntruder seems to be iff you want to check slots ignoring ones invading crew occupy, else ignoring ones defending crew occupy.
function mods.lightweight_lua.closestOpenSlot(point, shipId, isIntruder)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    return shipGraph:GetClosestSlot(point, shipId. isIntruder)
end

--Doesn't matter who's in it, returns -1 if no room is found. For use with things like MoveToRoom
function mods.lightweight_lua.slotIdAtPoint(point, shipManager)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
    local roomNumber = get_room_at_location(shipManager, point, true)
    if (roomNumber == -1) then
        return -1
    end
    local shape = shipGraph:GetRoomShape(roomNumber)
    --always l->r, t->bottom.
    --get the x y indexes of the slot.  0,0; 1,1, etc.
    local width = shape.w / TILE_SIZE
    local deltaX = point.x - shape.x
    local deltaY = point.y - shape.y
    local indexX
    indexX = math.floor(deltaX / TILE_SIZE)
    indexY = math.floor(deltaY / TILE_SIZE)
    return indexX + (indexY * width)
end

--Returns a random slot id in the given room.
function mods.lightweight_lua.randomSlotRoom(roomNumber, shipId)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local shape = shipGraph:GetRoomShape(roomNumber)
    local width = shape.w / TILE_SIZE
    local height = shape.h / TILE_SIZE
    local count_of_tiles_in_room = width * height
    return math.floor(math.random() * count_of_tiles_in_room) --zero indexed
end



--[[  EVENT INTERACTION UTILS  ]]--
--toggle with INSert key, because this can be quite verbose
--storage checks, sylvan, and the starting beacon are all very long.
--Call the internal version instead if you ALWAYS want to print
function mods.lightweight_lua.printChoiceInternal(choice, level) end
function mods.lightweight_lua.printEventInternal(locationEvent, level) end
mods.lightweight_lua.PRINT_EVENTS = false

script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
        if (key == Defines.SDL.KEY_INSERT) then
            mods.lightweight_lua.PRINT_EVENTS = (not mods.lightweight_lua.PRINT_EVENTS)
            print("Set event logging ", mods.lightweight_lua.PRINT_EVENTS)
        end
    end)

local function indentPrint(text, indentLevel)
    prefix = ""
    for i = 0,indentLevel do
        prefix = prefix.."\t"
    end
    print(prefix..text)
end

function mods.lightweight_lua.printEvent(locationEvent)
    if mods.lightweight_lua.PRINT_EVENTS then
        mods.lightweight_lua.printEventInternal(locationEvent, 0)
    end
end

function mods.lightweight_lua.printChoice(choice)
    if mods.lightweight_lua.PRINT_EVENTS then
        mods.lightweight_lua.printChoiceInternal(choice, 0)
    end
end

--somehow this doesn't cause issues with recursive checks.
mods.lightweight_lua.printChoiceInternal = function(choice, level)
    indentPrint("Choice Text: "..choice.text.data.." Requirement: "..choice.requirement.object.." min "..choice.requirement.min_level.." max "..choice.requirement.max_level.." max choice num "..choice.requirement.max_group, level)
    choiceEvent = choice.event
    if (choiceEvent ~= nil) then
        mods.lightweight_lua.printEventInternal(choiceEvent, level + 1)
    end
end

mods.lightweight_lua.printEventInternal = function(locationEvent, level)
    --recursive print through all event trees, using level to indent with tabs and newlines.
    indentPrint("Event Name: "..locationEvent.eventName, level)
    indentPrint("Event Text: "..locationEvent.text.data, level)
    local choices = locationEvent:GetChoices()
    for choice in vter(choices) do
        mods.lightweight_lua.printChoiceInternal(choice, level + 1)
    end
end

--need unique way of defining rooms.  Systems are on fire, rooms uh check CME.

-- written by arc
local function convertMousePositionToPlayerShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

-- written by kokoro
local function convertMousePositionToEnemyShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local position = combatControl.position
    local targetPosition = combatControl.targetPosition
    local enemyShipOriginX = position.x + targetPosition.x
    local enemyShipOriginY = position.y + targetPosition.y
    return Hyperspace.Point(mousePosition.x - enemyShipOriginX, mousePosition.y - enemyShipOriginY)
end

local mTeleportConditions = {}

--nil if none exists.
function getRoomAtLocation(position)
    playerShipManager = global:GetShipManager(OWNSHIP)
    enemyShipManager = global:GetShipManager(ENEMY_SHIP)
    --Ships in mv don't overlap, so check both ships --poinf?
    local retRoom = get_room_at_location(playerShipManager, convertMousePositionToPlayerShipPosition(mousePos), true)
    if retRoom then return retRoom end
    retRoom = get_room_at_location(enemyShipManager, convertMousePositionToEnemyShipPosition(mousePos), true)
    return retRoom
end

--crewFilterFunction(crewmember): which crew this should apply to, conditionFunction(crewmember): when it should apply to them
function mods.lightweight_lua.registerConditionalTeleport(conditionFunction, crewFilterFunction)
    table.insert(mTeleportConditions, {conditionFunction, crewFilterFunction})
end

--Rooms on both ends must contain fire
--Current ship is the one the crew is on, target ship is the one that has been clicked.
local function fireTeleportCondition(crewmem)
    local mousePos = Hyperspace.Mouse.position
    local targetRoom = getRoomAtLocation(mousePos)
    if not targetRoom then return false end
    local sourceRoom = getRoomAtCrewmember(crewmem)
    
    return shipManager:GetFireCount(targetRoom) > 0 and shipManager:GetFireCount(sourceRoom) > 0 
end

local function laniusCondition(crewmem)
    print("checking race of ", crewmem:GetName(), crewmem.extend:GetDefinition().race)
    return crewmem.extend:GetDefinition().race == "lanius"
end

lwl.registerConditionalTeleport(fireTeleportCondition, laniusCondition)

local function teleportCheck(crewmem)
    for _,teleCond in ipairs(mTeleportConditions) do
        if crewFilterFunction(crewmem) and conditionFunction(crewmem) then
            return Defines.Chain.PREEMPT, amount, true
        end
    end
    return false
end

--[[
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE,
                        function(crew, stat, def, amount, value)
                            if teleportCheck(crewmem) then
                                if stat == Hyperspace.CrewStat.TELEPORT_MOVE or stat == Hyperspace.CrewStat.TELEPORT_MOVE_OTHER_SHIP then
                                    return Defines.Chain.PREEMPT, amount, true
                                end
                            end
                            return Defines.Chain.CONTINUE, amount, value
                        end)
                        --]]

mods.lightweight_lua.METAVAR_NUM_CREW_PLAYER = "lightweightlua_NUM_CREW_PLAYER"
mods.lightweight_lua.METAVAR_CREW_ID_PLAYER = "lightweightlua_CREW_ID_PLAYER"


function mods.lightweight_lua.getPersistedCrewIds()
    crewIds = {}
    numCrew = Hyperspace.metaVariables[lwl.METAVAR_NUM_CREW_PLAYER]
    for i=1,#numCrew do
        table.insert(crewIds, Hyperspace.metaVariables[lwl.METAVAR_CREW_ID_PLAYER..i])
    end
    return crewIds
end


--[[ Neat idea, but it needs to many layers of encapsulation to be a good idiom.
local function waitForInitialization(blockedFunction, localVar, varGetter)
    if localVar == nil then
        localVar = varGetter()
    else
        blockedFunction
    end
end
--]]

--Here lives the crew metavars.  Use these to find the list of crewmembers persisted over saves.
--todo do I need to do this every step?  Also does this actually work how I'm trying to use it?  I need it for GEx, so I'll find out soon.
local ownshipManager
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
        --Get all crew on your ship
        if ownshipManager == nil then
            ownshipManager = global:GetShipManager(OWNSHIP)
        else
            crewList = lwl.getAllMemberCrew(ownshipManager)
            Hyperspace.metaVariables[lwl.METAVAR_NUM_CREW_PLAYER] = #crewList
            for i=1,#crewList do
                Hyperspace.metaVariables[lwl.METAVAR_CREW_ID_PLAYER..i] = crewList[i].extend.selfId
            end
        end
        end)