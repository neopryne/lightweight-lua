--[[Usage:
    local lwl = mods.lightweight_lua
    lwl.whatever()

Table of Contents (Search for these strings to go to category header)
    TABLE UTILS
    LOGGING UTILS
    CREW UTILS
    GEOMETRY UTILS
    EVENT INTERACTION UTILS

PS: I Vim Pulchritude Imagination u



]]
--mods.lightweight_lua = {}
local lwl = mods.lightweight_lua
if not mods.brightness then
    error("Brightness Particles was not patched, or was patched after Lightweight Lua.  Install it properly or face undefined behavior.")
end

---@alias TrackingType
---| '"all"'
---| '"crew"'
---| '"drones"'

---@alias ShipId
---| '1'
---| '0'

--todo remove all vCrewList usage, it's flaky.
local vter = mods.multiverse.vter
local get_room_at_location = mods.multiverse.get_room_at_location

local global = Hyperspace.Global.GetInstance()
local mCrewMemberFactory = global:GetCrewFactory()

local TAU = math.pi * 2
local OWNSHIP = 0
local ENEMY_SHIP = 1
local TILE_SIZE = 35
lwl.SCREEN_WIDTH = 1280
lwl.SCREEN_HEIGHT = 720
--Breaking change, this is now a function.
--mods.lightweight_lua.TILE_SIZE = TILE_SIZE --Deprecated, use mods.lightweight_lua.sTILE_SIZE() instead.
lwl.NOOP = function() end
function lwl.TILE_SIZE() return TILE_SIZE end --getter to preserve immutible value. --todo this doesn't actually solve anything and just adds needless complexity.
function lwl.OWNSHIP() return 0 end
function lwl.CONTACT_1() return 1 end
function lwl.UNSELECTED() return 0 end
function lwl.SELECTED() return 1 end
function lwl.SELECTED_HOVER() return 2 end

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

local SKILL_PILOT = 0
local SKILL_ENGINES = 1
local SKILL_SHIELDS = 2
local SKILL_WEAPONS = 3
local SKILL_REPAIR = 4
local SKILL_COMBAT = 5

---@return integer
function lwl.SKILL_PILOT() return SKILL_PILOT end
---@return integer
function lwl.SKILL_ENGINES() return SKILL_ENGINES end
---@return integer
function lwl.SKILL_SHIELDS() return SKILL_SHIELDS end
---@return integer
function lwl.SKILL_WEAPONS() return SKILL_WEAPONS end
---@return integer
function lwl.SKILL_REPAIR() return SKILL_REPAIR end
---@return integer
function lwl.SKILL_COMBAT() return SKILL_COMBAT end

---@return integer
function lwl.SYS_SHIELDS() return SYS_SHIELDS end
---@return integer
function lwl.SYS_ENGINES() return SYS_ENGINES end
---@return integer
function lwl.SYS_OXYGEN() return SYS_OXYGEN end
---@return integer
function lwl.SYS_WEAPONS() return SYS_WEAPONS end
---@return integer
function lwl.SYS_DRONES() return SYS_DRONES end
---@return integer
function lwl.SYS_MEDBAY() return SYS_MEDBAY end
---@return integer
function lwl.SYS_PILOT() return SYS_PILOT end
---@return integer
function lwl.SYS_SENSORS() return SYS_SENSORS end
---@return integer
function lwl.SYS_DOORS() return SYS_DOORS end
---@return integer
function lwl.SYS_TELEPORTER() return SYS_TELEPORTER end
---@return integer
function lwl.SYS_CLOAKING() return SYS_CLOAKING end
---@return integer
function lwl.SYS_ARTILLERY() return SYS_ARTILLERY end
---@return integer
function lwl.SYS_BATTERY() return SYS_BATTERY end
---@return integer
function lwl.SYS_CLONEBAY() return SYS_CLONEBAY end
---@return integer
function lwl.SYS_MIND() return SYS_MIND end
---@return integer
function lwl.SYS_HACKING() return SYS_HACKING end
---@return integer
function lwl.SYS_TEMPORAL() return SYS_TEMPORAL end

--This might be overkill, but it works
function lwl.isPaused()
    local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
    return commandGui.bPaused or commandGui.bAutoPaused or commandGui.event_pause or commandGui.menu_pause
end

---usage: object = nilSet(object, value)
---@param object any
---@param value any
---@return any
function lwl.nilSet(object, value)
    if (object == nil) then
        object = value
    end
    return object
end

---usage: object = nilSet(object, value)
---@param object any
---@param value any
---@return any
function lwl.setIfNil(object, value)
    return lwl.nilSet(object, value)
end

--[[  TABLE UTILS  ]]--
---for use in printing all of a table
---@param o table
---@return string
function lwl.dumpObject(o)
    if o == nil then return "" end
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. lwl.dumpObject(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--one level deep copy of t1 and t2 to t3 deep, it's not recursive.  For full deep copy, use deepTableMerge
---@param t1 table
---@param t2 table
---@return table
function lwl.tableMerge(t1, t2)
    local t3 = {}
    for i=1,#t1 do
        t3[#t3+1] = t1[i]
    end
    for i=1,#t2 do
        t3[#t3+1] = t2[i]
    end
    return t3
end

---note: does not copy objects in the table.
---@param t table
---@return table
function lwl.deepCopyTable(t)
    if type(t) ~= "table" then
        return t  -- Return the value directly if it's not a table (base case)
    end

    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = lwl.deepCopyTable(v)  -- Recursively copy nested tables
        else
            copy[k] = v  -- Directly copy non-table values
        end
    end
    return copy
end

--https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
---The filter function is which ones to keep, onRemove is called on elements removed.
---@param table table
---@param filterFunction function
---@param onRemove function
---@return table
function lwl.arrayRemove(table, filterFunction, onRemove)
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
            if onRemove then
                onRemove(table[i])
            end
            table[i] = nil;
        end
    end
    return table;
end

---returns nil if table is empty
---@param table table
---@return any|nil
function lwl.getRandomKey(table)
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

---returns nil if table is empty
---@param table table
---@return any a random non-nil value stored in the table.
function lwl.getRandomValue(table)
    local key = lwl.getRandomKey(table)
    if key == nil then return nil end
    return table[key]
end

---Returns the set of elements in newSet that are not in initialSet.  Arguments should not have duplicate entries.
---@param newSet table
---@param initialSet table
---@return table
function lwl.getNewElements(newSet, initialSet)
    local elements = {}
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

---Arguments should not have duplicate entries.
---@param baseSet table
---@param elementsToRemove table
---@return table
function lwl.setRemove(baseSet, elementsToRemove)
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

function lwl.vterToTable(vterObject)
    local tableObject = {}
    for item in vter(vterObject) do
        table.insert(tableObject, item)
    end
    return tableObject
end

---Arguments should not have duplicate entries.  Returns the set union of both sets.
---@param set1 table
---@param set2 table
---@return table
function lwl.setMerge(set1, set2)
    local elements = lwl.deepCopyTable(set2)
    for _, newElement in ipairs(set1) do
        local wasPresent = false
        for _, oldElement in ipairs(set2) do
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

--Returns the set intersection of two sets.
---@param set1 table
---@param set2 table
---@return table
function lwl.setXor(set1, set2)
   return lwl.setMerge(lwl.getNewElements(set1, set2), lwl.getNewElements(set2, set1))
end

---Returns the set intersection of two tables.
---@param set1 any
---@param set2 any
---@return table
function lwl.setIntersectionTable(set1, set2)
   local interSet = {}
   for i = 1,#set1 do
       local value = set1[i]
       for j = 1,#set2 do
           if (value == set2[j]) then
               table.insert(interSet, value)
           end
       end
   end
   return interSet
end

---For use with userdata objects
---@param userdata1 any
---@param userdata2 any
---@return table
function lwl.setIntersectionVter(userdata1, userdata2)
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

---Returns the number of keys in the table
---@param table table
---@return integer
function lwl.countKeys(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

---returns false if value is nil and true otherwise.
---@param name string
---@param value integer
---@return boolean
function lwl.setMetavar(name, value)
    if (value ~= nil) then
        Hyperspace.metaVariables[name] = value
    end
    return (value ~= nil)
end

---returns a merged deep copy of both tables.  Non-table objects will not be deep-copied.
---@param t1 table
---@param t2 table
---@return table
function lwl.deepTableMerge(t1, t2)
    local t1Copy = lwl.deepCopyTable(t1)
    local t2Copy = lwl.deepCopyTable(t2)
    return lwl.tableMerge(t1Copy, t2Copy)
end

function lwl.tableContains(currentTable, value)
    for _,val in ipairs(currentTable) do
        if val == value then
            return true
        end
    end
    return false
end


---logical xor.
---@param a boolean
---@param b boolean
---@return boolean
function lwl.xor(a,b)
    return (a or b) and (not(a and b))
end


--[[
How about a function that takes a argument and tries to make it into a thing?
Like, assume it's the type you want, and if it's not but can be eval'd, eval it, and if it still has the same value as before, you can't use it.
Otherwise, keep calling this recusively.
Hmm, actually this is annoying, because the thing that you're really looking for is loops, but a loop of size 1 is the easiest to find.
Loop patterns larger than that quickly get much rarer and harder to check for/find.
But the longer you've been evaling for, the more [power|resources] you should spend checking for loops.
]]



--[[  LOGGING UTILS  ]]--
lwl.LOG_LEVEL = 1 --Higher is more verbose, feel free to modify this.
--[[
    0 -- NO logs, not even errors, not recommended.
    1 -- Errors only
    2 -- Adds Warnings
    3 -- Adds Debug
    4 -- Adds Info
    5 -- Verbose
    
    Usage:
    MY_MOD_LOG_LEVEL = 3
    
    lwl.logWarn(MYTAG, "This will use the globally defined debug level anyone can modify!") -- Recommended for libraries
    lwl.logWarn(MYTAG, "This will use my debug level!", MY_MOD_LOG_LEVEL) -- Recommended for standalone packages
--]]
local LOG_LEVELS = {
    {text="ERROR", level=1},
    {text="WARN", level=2},
    {text="DEBUG", level=3},
    {text="INFO", level=4},
    {text="VERBOSE", level=5}}
local function logInternal(tag, text, messageLogLevel, optionalLogLevel)
    local maxLogLevel = optionalLogLevel
    if (maxLogLevel == nil) then
        maxLogLevel = lwl.LOG_LEVEL
    end
    if (messageLogLevel <= maxLogLevel) then
        print(LOG_LEVELS[messageLogLevel].text..": "..tag.." - "..text)
    end
end
--Optionally, pass the desired log level.  This lets you store that locally and change it in your mod.
--It might seem silly to pass values you know will fail, but that's the point, so you can enable debug easily when you want to change things,
--and turn it off when you want to ship.

---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function lwl.logError(tag, text, optionalLogLevel)
    logInternal(tag, text, 1, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function lwl.logWarn(tag, text, optionalLogLevel)
    logInternal(tag, text, 2, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function lwl.logDebug(tag, text, optionalLogLevel)
    logInternal(tag, text, 3, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function lwl.logInfo(tag, text, optionalLogLevel)
    logInternal(tag, text, 4, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function lwl.logVerbose(tag, text, optionalLogLevel)
    logInternal(tag, text, 5, optionalLogLevel)
end

--[[  CREW UTILS  ]]--
---@param crewmem Hyperspace.CrewMember
---@param name string
function lwl.setCrewName(crewmem, name)
    local nameTextString = Hyperspace.TextString()
    nameTextString.data = name
    crewmem:SetName(nameTextString, true)
end

--Then we give some filter functions that might be broadly useful

---Returns true for all crew.
---@param crewmem Hyperspace.CrewMember
---@return boolean
function lwl.noFilter(crewmem)
    return true
end

---Currently living crew.
---@param crewmem Hyperspace.CrewMember
---@return boolean
function lwl.filterLivingCrew(crewmem)
    return (not (crewmem:OutOfGame() or crewmem.bDead))
end

---@param crewmem Hyperspace.CrewMember
---@return boolean
function lwl.filterTrueCrewNoDrones(crewmem)
    return crewmem:CountForVictory()  --Crew is not a drone AND (Crew is not dead or dying) OR crew is preparing to clone --sillysandvich
end

---@param crewmem Hyperspace.CrewMember
---@return boolean
function lwl.filterOwnshipTrueCrew(crewmem)
    return crewmem:CountForVictory() and crewmem.iShipId == 0
end

---@param filterFunction function
---@return table
function lwl.getAllMemberCrewFromFactory(filterFunction)
    local memberCrew = {}
    for crewmem in vter(mCrewMemberFactory.crewMembers) do
        if filterFunction(crewmem) then
            table.insert(memberCrew, crewmem)
        end
    end
    return memberCrew
end

---@param shipManager Hyperspace.ShipManager
---@param tracking TrackingType|nil
---@param includeNoWarn boolean|nil
---@return table
function lwl.getAllMemberCrew(shipManager, tracking, includeNoWarn)
    tracking = lwl.setIfNil(tracking, "all")
    includeNoWarn = lwl.setIfNil(includeNoWarn, true)
    local function selectionFilter(crewmem)
        local shouldTrack = ((tracking == "all") or (tracking == "crew" and not crewmem:IsDrone()) or (tracking == "drones" and crewmem:IsDrone()))
        local warningless = (not ((not includeNoWarn) and crewmem.extend:GetDefinition().noWarning))
        return shouldTrack and warningless and lwl.filterLivingCrew(crewmem) and crewmem.iShipId == shipManager.iShipId
    end
    return lwl.getAllMemberCrewFromFactory(selectionFilter)
end

---Searches all crew, both ships.  This is unique, so it can just return whatever it finds.
---@param selfId number
---@return nil|Hyperspace.CrewMember
function lwl.getCrewById(selfId)
    local function selectionFilter(crewmem)
        return crewmem.extend.selfId == selfId
    end
    local crewArray = lwl.getAllMemberCrewFromFactory(selectionFilter)
    if #crewArray == 0 then return nil end
    return crewArray[1]
    --print("ERROR: lwl could not get crew ", selfId) --This is actually kind of normal
end

---returns all crew on ship that belong to crewShip.
---@param targetShipManager Hyperspace.ShipManager
---@param crewShipManager Hyperspace.ShipManager
---@return table
function lwl.getCrewOnSameShip(targetShipManager, crewShipManager)
    local function selectionFilter(crewmem)
        return crewmem.iShipId == crewShipManager.iShipId and crewmem.currentShipId == targetShipManager.iShipId
    end
    return lwl.getAllMemberCrewFromFactory(selectionFilter)
end

--todo call into factory with filter function.
function lwl.getSelectedCrew(selectionState)
    local function selectionFilter(crewmem)
        return crewmem.selectionState == selectionState
    end
    return lwl.getAllMemberCrewFromFactory(selectionFilter)
end

---Returns a table of all crew on shipManager ship's belonging to crewShipManager's crew on the room tile at the given point.
---booleans getDrones and getNonDrones are optional, but you have to include both if you include one or it calls wrong.
---default is returning all crew if not specified.
---maxCount is optional, but you must specify both getDrones and getNonDrones if you use it.
---@param shipManager Hyperspace.ShipManager
---@param crewShipManager Hyperspace.ShipManager
---@param x number
---@param y number
---@param getDrones boolean|nil
---@param getNonDrones boolean|nil
---@param maxCount integer|nil
---@return table
function lwl.get_ship_crew_point(shipManager, crewShipManager, x, y, getDrones, getNonDrones, maxCount)
    local res = {}
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

---@param allegiance number 0 if you are looking for foes of the player, and 1 if looking for foes of the enemy.
---@param currentShip number the id of the ship to check the space relative to.
---@param location Hyperspace.Point
---@return table
function lwl.getFoesAtSpace(allegiance, currentShip, location)
    local enemyList = {}
    local currentShipManager = Hyperspace.ships(currentShip)
    local foeShipManager = Hyperspace.ships(1 - allegiance)
    if (currentShipManager and foeShipManager) then
        enemyList = lwl.get_ship_crew_point(currentShipManager, foeShipManager, location.x, location.y)
    end
    return enemyList
end

---@param crewmem Hyperspace.CrewMember
---@return table
function lwl.getFoesAtSelf(crewmem)
    return lwl.getFoesAtSpace(crewmem.iShipId, crewmem.currentShipId, crewmem:GetPosition())
end

--- -1 in the unlikely event no room is found
---@param crewmem Hyperspace.CrewMember
---@return integer
function lwl.getRoomAtCrewmember(crewmem)
    local shipManager = Hyperspace.ships(crewmem.currentShipId)
    --need to call this with the shipManager of the ship you want to look at.
    local room = get_room_at_location(shipManager, crewmem:GetPosition(), true)
    --print(crewmem:GetLongName(), ", Room: ", room, " at ", crewmem:GetPosition().x, crewmem:GetPosition().y)
    return room
end

---If two rooms have multiple doors, returns all of them.
---@param shipId ShipId
---@param roomIdFirst number
---@param roomIdSecond number
---@return table
function lwl.getSharedDoors(shipId, roomIdFirst, roomIdSecond)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local doorList = shipGraph:GetDoors(roomIdFirst)
    local doorList2 = shipGraph:GetDoors(roomIdSecond)
    local sharedDoors = lwl.setIntersectionVter(doorList, doorList2)
    return sharedDoors 
end

--returns true if it did anything and false otherwise
---@param allegiance number 0 if you are looking for foes of the player, and 1 if looking for foes of the enemy.
---@param currentShip number the id of the ship to check the space relative to.
---@param location Hyperspace.Point
---@param damage number
---@param stunTime number
---@param directDamage number
---@return boolean
function lwl.damageFoesAtSpace(allegiance, currentShip, location, damage, stunTime, directDamage)
    local foes_at_point = lwl.getFoesAtSpace(allegiance, currentShip, location)
    for j = 1, #foes_at_point do
        local foe = foes_at_point[j]
        foe.fStunTime = foe.fStunTime + stunTime
        foe:ModifyHealth(-damage)
        foe:DirectModifyHealth(-directDamage)
    end
    return #foes_at_point > 0
end

--returns true if it did anything and false otherwise
---comment
---@param crewmem Hyperspace.CrewMember
---@param damage number
---@param stunTime number
---@param directDamage number
---@return boolean
function lwl.damageFoesInSameSpace(crewmem, damage, stunTime, directDamage)
    return lwl.damageFoesAtSpace(crewmem.iShipId, crewmem.currentShipId, crewmem:GetPosition(), damage, stunTime, directDamage)
end

---Ok this function doesn't make very much sense.  TODO rework this.
---@param activeCrew Hyperspace.CrewMember
---@param amount number
---@param stunTime number
---@param currentRoom number
---@param bystander Hyperspace.CrewMember
function lwl.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
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


---comment
---@param roomId integer
---@param shipId integer 0 or 1
---@param filterFunction function (Hyperspace.CrewMember) optional additional conditions for which crew to get.
---@return table
function lwl.getRoomCrew(roomId, shipId, filterFunction)
    filterFunction = lwl.setIfNil(filterFunction, function (_)
        return true
    end)
    local function roomFilter(crewmem)
        --print("Checking", crewmem:GetName(), "at", crewmem.currentShipId, crewmem.iRoomId, "against", shipId, roomId)
        return crewmem.currentShipId == shipId and crewmem.iRoomId == roomId and filterFunction(crewmem)
    end
    return lwl.getAllMemberCrewFromFactory(roomFilter)
end

---comment
---@param crewmem Hyperspace.CrewMember crew to get crew in the room of.
---@param filterFunction function (Hyperspace.CrewMember) optional additional conditions for which crew to get.
---@return table
function lwl.getSameRoomCrew(crewmem, filterFunction)
    filterFunction = lwl.setIfNil(filterFunction, function (_)
        return true
    end)
    return lwl.getRoomCrew(crewmem.iRoomId, crewmem.currentShipId, filterFunction)
end


--Does direct damage to all foes in the room. optional stun time
---comment
---@param activeCrew Hyperspace.CrewMember
---@param amount any
---@param stunTime any
function lwl.damageEnemyCrewInSameRoom(activeCrew, amount, stunTime)
    local currentRoom = lwl.getRoomAtCrewmember(activeCrew)
        -- Modified from brightlord's modification of Arc's get_ship_crew_room().
    if (Hyperspace.ships.enemy) then
      for bystander in vter(Hyperspace.ships.enemy.vCrewList) do
            --print(bystander:GetLongName(), " was in the same room!")
          lwl.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
      end
    end
    --do the same for friendly ship
    for bystander in vter(Hyperspace.ships.player.vCrewList) do
        lwl.damageEnemyHelper(activeCrew, amount, stunTime, currentRoom, bystander)
    end
end

local mTeleportConditions = {}

--nil if none exists.
function mods.lightweight_lua.getRoomAtLocation(position)
    --Ships in mv don't overlap, so check both ships --poinf?
    local retRoom = get_room_at_location(Hyperspace.ships(OWNSHIP), lwl.convertMousePositionToPlayerShipPosition(position), true)
    if retRoom then return retRoom end
    return get_room_at_location(Hyperspace.ships(ENEMY_SHIP), lwl.convertMousePositionToEnemyShipPosition(position), true)
end

--[[  GEOMETRY UTILS  ]]--
---
---@param pointf Hyperspace.Pointf
---@return Hyperspace.Point
function lwl.pointfToPoint(pointf)
    return Hyperspace.Point(math.floor(pointf.x), math.floor(pointf.y))
end

---
---@param point Hyperspace.Point
---@return Hyperspace.Pointf
function lwl.pointToPointf(point)
    return Hyperspace.Pointf(point.x, point.y)
end

---Use with points or pointfs, but don't mix them.
---@param point1 Hyperspace.Point|Hyperspace.Pointf
---@param point2 Hyperspace.Point|Hyperspace.Pointf
---@return boolean True if these points have the same values.
function mods.lightweight_lua.pointEquals(point1, point2)
    return point1.x == point2.x and point1.y == point2.y
end

function lwl.floatCompare(a, b, epsilon)
    epsilon = epsilon or 1e-6
    return a == b or math.abs(a - b) < epsilon
end

--- Generate a random point radius away from a point
---modified from vertexUtils random_point_radius
---@param origin Hyperspace.Point
---@param radius number
---@return Hyperspace.Pointf
function lwl.random_point_circle(origin, radius)
    local r = radius
    local theta = TAU*(math.random())
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

--- Generate a random point radius away from a point
---copied from vertexUtils random_point_radius
---@param origin Hyperspace.Point
---@param radius number
---@return Hyperspace.Pointf
function lwl.random_point_radius(origin, radius)
    local r = radius*(math.random())
    local theta = TAU*(math.random())
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

---Generate a random point within the radius of a given point
---@param origin Hyperspace.Point
---@return Hyperspace.Pointf
function lwl.random_point_adjacent(origin)
    local r = TILE_SIZE
    local theta = math.pi*(math.floor(math.random(0, 4))) / 2
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

---random_point_adjacent in a while loop until it lands on a floor space.
---This is dumb and poorly written.
---@param origin any
---@param shipManager any
---@return Hyperspace.Point|nil
function lwl.random_valid_space_point_adjacent(origin, shipManager)
    local r = TILE_SIZE
    local theta = math.pi*(math.floor(math.random(0, 4))) / 2
    for i = 0,3 do
        local new_angle = theta + (i * math.pi / 2)
        local point = Hyperspace.Point(origin.x + r*math.cos(new_angle), origin.y + r*math.sin(new_angle))
        if (not ((get_room_at_location(shipManager, point, true) == -1))) then
            return point
        end
    end
    return nil
end

---returns the closest available slot, or a slot with id and room -1 if none is found.
---isIntruder seems to be iff you want to check slots ignoring ones invading crew occupy, else ignoring ones defending crew occupy.
---@param point Hyperspace.Point
---@param shipId ShipId
---@param isIntruder boolean
---@return Hyperspace.Slot
function lwl.closestOpenSlot(point, shipId, isIntruder)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    return shipGraph:GetClosestSlot(point, shipId, isIntruder)
end

---@param crewmem Hyperspace.CrewMember
---@return Hyperspace.Slot
function lwl.closestOpenSlotToCrew(crewmem)
    return lwl.closestOpenSlot(crewmem:GetPosition(), crewmem.currentShipId, crewmem.currentShipId ~= crewmem.iShipId)
end

---Doesn't matter who's in it, returns -1 if no room is found. For use with things like MoveToRoom
---@param point Hyperspace.Point
---@param shipManager Hyperspace.ShipManager
---@return integer
function lwl.slotIdAtPoint(point, shipManager)
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
    local indexY = math.floor(deltaY / TILE_SIZE)
    return indexX + (indexY * width)
end

--Returns a random slot id in the given room.
---@param roomNumber number
---@param shipId ShipId
---@return integer
function lwl.randomSlotRoom(roomNumber, shipId)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local shape = shipGraph:GetRoomShape(roomNumber)
    local width = shape.w / TILE_SIZE
    local height = shape.h / TILE_SIZE
    local count_of_tiles_in_room = width * height
    return math.floor(math.random() * count_of_tiles_in_room) --zero indexed
end

function lwl.getRandomSystem(shipManager)
    return shipManager.vSystemList[math.random(1, shipManager.vSystemList:size())]
end
---Note: Filter functions must not maintain a reference to CrewMember objects as they can go out of scope if you quit to menu and continue.
---TODO: I might need to use memory safe crew for all filter functions that need to access dynamic crew fields.
---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function lwl.generateCrewFilterFunction(crewmem)
    local crewId = crewmem.extend.selfId
    return function (crew)
        return crew.extend.selfId == crewId
    end
end

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function lwl.generateSameRoomAlliesFilterFunction(crewmem)
    local allegiance = crewmem.iShipId
    return function ()
        return lwl.getSameRoomCrew(crewmem, function (crew)
            return crew.iShipId == allegiance
        end)
    end
end

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function lwl.generateSameRoomFoesFilterFunction(crewmem)
    local allegiance = crewmem.iShipId
    return function ()
        return lwl.getSameRoomCrew(crewmem, function (crew)
            return crew.iShipId ~= allegiance
        end)
    end
end

--Generates a filter, not one itself.
function lwl.generateOpposingCrewFilter(crewmem)
    local allegiance = crewmem.iShipId
    return function (crew)
        return crew.iShipId ~= allegiance
    end
end


--[[  EVENT INTERACTION UTILS  ]]--
--toggle with INSert key, because this can be quite verbose
--storage checks, sylvan, and the starting beacon are all very long.
--Call the internal version instead if you ALWAYS want to print
function lwl.printChoiceInternal(choice, level) end
function lwl.printEventInternal(locationEvent, level) end
lwl.PRINT_EVENTS = false

lwl.safe_script.on_internal_event("lwl_event_logging_keystroke", Defines.InternalEvents.ON_KEY_DOWN, function(key)
-- script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
        if (key == Defines.SDL.KEY_INSERT) then
            lwl.PRINT_EVENTS = (not lwl.PRINT_EVENTS)
            print("Set event logging ", lwl.PRINT_EVENTS)
        end
    end)

local function indentPrint(text, indentLevel)
    local prefix = ""
    for i = 0,indentLevel do
        prefix = prefix.."\t"
    end
    print(prefix..text)
end

function lwl.printEvent(locationEvent)
    if lwl.PRINT_EVENTS then
        lwl.printEventInternal(locationEvent, 0)
    end
end

function lwl.printChoice(choice)
    if lwl.PRINT_EVENTS then
        lwl.printChoiceInternal(choice, 0)
    end
end

function lwl.prependEventText(event, text)
    local eventText = event.text:GetText()
    eventText = text..eventText
    event.text.data = eventText
    event.text.isLiteral = true
end

local function appendEventText(event, text)
    local eventText = event.text:GetText()
    eventText = eventText..text
    event.text.data = eventText
    event.text.isLiteral = true
end

--somehow this doesn't cause issues with recursive checks.
lwl.printChoiceInternal = function(choice, level)
    indentPrint("Choice Text: "..choice.text.data.." Requirement: "..choice.requirement.object.." min "..choice.requirement.min_level.." max "..choice.requirement.max_level.." max choice num "..choice.requirement.max_group, level)
    local choiceEvent = choice.event
    if (choiceEvent ~= nil) then
        lwl.printEventInternal(choiceEvent, level + 1)
    end
end

lwl.printEventInternal = function(locationEvent, level)
    --recursive print through all event trees, using level to indent with tabs and newlines.
    indentPrint("Event Name: "..locationEvent.eventName, level)
    indentPrint("Event Text: "..locationEvent.text.data, level)
    local choices = locationEvent:GetChoices()
    for choice in vter(choices) do
        lwl.printChoiceInternal(choice, level + 1)
    end
end

-- written by arc
function lwl.convertMousePositionToPlayerShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

-- written by kokoro
 function lwl.convertMousePositionToEnemyShipPosition(mousePosition)
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
function lwl.getRoomAtLocation(position)
    --Ships in mv don't overlap, so check both ships --poinf?
    local retRoom = get_room_at_location(Hyperspace.ships(OWNSHIP), lwl.convertMousePositionToPlayerShipPosition(mousePos), true)
    if retRoom then return retRoom end
    return get_room_at_location(Hyperspace.ships(ENEMY_SHIP), lwl.convertMousePositionToEnemyShipPosition(mousePos), true)
end

-----------------------------CONTROL FLOW------------------------------
---Returns a Function that returns true once every trueEvery calls.
---@param trueEvery function
---@return function
function lwl.createIncrementalConditonal(trueEvery)
    local counter = 1
    local maxValue = trueEvery
    return function()
        if counter < maxValue then
            counter = counter + 1
        else
            counter = 1
        end
        return counter == 1
    end
end



function lwl.floatEquals(f1, f2, epsilon)
    epsilon = lwl.nilSet(epsilon, .0001)
    return math.abs(f1-f2) < epsilon
end

function lwl.isMoving(crewmem)
    return crewmem.speed_x + crewmem.speed_y > 0
end

------------------POINT UTILS---------------------
---Returns true if two points are near each other
---@param p1 Hyperspace.Point|Hyperspace.Pointf
---@param p2 Hyperspace.Point|Hyperspace.Pointf
---@param epsilon number How far apart they can be, in pixels.
---@return boolean true if they are at least within epsilon pixels of each other.
function lwl.pointFuzzyEquals(p1, p2, epsilon) --todo this should actually check the straight distance. As is it's a square.
    if not epsilon then
        epsilon = 1
    end
    --print("compare xx,yy", p1.x, p2.x, p1.y, p2.y)
    return lwl.floatEquals(p1.x, p2.x, epsilon) and lwl.floatEquals(p1.y, p2.y, epsilon)
end

---Returns if a goalPoint actually exists, or is a value that indicates that it doesn't, but they didn't want to put nil.
---@param goalPoint Hyperspace.Pointf a goal from a CrewMember object
---@return boolean true if the goal exists, and false if the goal is the dummy, fake one.
function lwl.goalExists(goalPoint)
    return not (lwl.floatEquals(goalPoint.x, -1) and lwl.floatEquals(goalPoint.y, -1))
end

---Returns the angle in degrees, 0 being straight up.
---@param point1 Hyperspace.Point|Hyperspace.Pointf
---@param point2 Hyperspace.Point|Hyperspace.Pointf
---@return number
function lwl.distanceBetweenPoints(point1, point2)
    return math.sqrt((point1.x - point2.x)^2 + (point1.y - point2.y)^2)
end

---Returns a new point given an existing point, an angle, and a distance.
---@param origin Hyperspace.Point|Hyperspace.Pointf Point to calculate from.
---@param angle number Angle in radians, 0 is straight right.
---@param distance number in pixels
---@return Hyperspace.Pointf the new point relative to the origin
function lwl.getPoint(origin, angle, distance)
    return Hyperspace.Pointf(origin.x - (distance * math.cos(angle)), origin.y - (distance * math.sin(angle)))
end

function lwl.getDistance(origin, target)
    return math.abs(math.sqrt((origin.x - target.x)^2 + (origin.y - target.y)^2))
end

---comment
---@param origin Hyperspace.Point|Hyperspace.Pointf
---@param target Hyperspace.Point|Hyperspace.Pointf
---@return number FTL Angle in the direction of target from origin.
function lwl.getAngle(origin, target)
    local deltaX = origin.x - target.x
    local deltaY = origin.y - target.y
    local innerAngle = math.atan(deltaY, deltaX)
    --print("Angle is ", innerAngle)
    return innerAngle
end
------------------END POINT UTILS---------------------
function lwl.crewSpeedToScreenSpeed(crewSpeed)
    --1.333 ~= .4, it's probably linear.  And 0=0
    return crewSpeed --* .4 / 1.334
end
------------------ANGLE UTILS---------------------
---Converts an FTL style angle to a Brightness Particles style one.
---That is, it rotates it by 90 degrees and converts it to degrees.
---@param angle number FTL Angle (Radians, 0 is right)
---@return number Brightness Angle (Degrees, 0 is up)
function lwl.angleFtlToBrightness(angle)
    return ((angle * 180 / math.pi) + 270) % 360
end

---Converts an Brightness Particles style angle to an FTL style one.
---That is, it rotates it by -90 degrees and converts it to radians.
---@param angle number Brightness Angle (Degrees, 0 is up)
---@return number FTL Angle (Radians, 0 is right)
function lwl.angleBrightnessToFtl(angle)
    return (((angle + 90) % 360) * math.pi / 180)
end

---Returns the distance in degrees clockwise from heading to target.
---@param heading number origin angle
---@param target number angle to measure towards.
---@return number the clockwise distance between the two angles
function lwl.clockwiseDistanceDegrees(heading, target)
      return ((target - heading) + 360) % 360
end

---Returns the distance in degrees counterclockwise from heading to target.
---@param heading number origin angle
---@param target number angle to measure towards.
---@return number the counterclockwise distance between the two angles
function lwl.counterclockwiseDistanceDegrees(heading, target)
      return ((heading - target) + 360) % 360
end

---
---@param heading number angle in degrees
---@param target number angle in degrees
---@return number the shortest angular distance between the heading and the target directions.
function lwl.angleDistanceDegrees(heading, target)
    return math.min(lwl.clockwiseDistanceDegrees(heading, target), lwl.counterclockwiseDistanceDegrees(heading, target))
end

---comment
---@param heading number the current facing angle in degrees
---@param target number angle in degrees to rotate towards
---@param step number how much to rotate towards the target
---@return number the new adjusted heading, now closer to target.
function lwl.rotateTowardsDegrees(heading, target, step) --todo how was this not jittering before?
    local clockwise = lwl.clockwiseDistanceDegrees(heading, target)
    local counterclockwise = lwl.counterclockwiseDistanceDegrees(heading, target)
    if clockwise <= 1 or counterclockwise <= 1 then
        --Close enough
        return heading
    end
    if clockwise > counterclockwise then
        return heading - step
    else
        return heading + step
    end
end

---Returns the angle the crew is travelling in degrees, 0 being straight right.
---@param crewmem Hyperspace.CrewMember
---@return number the angle the crew is travelling in degrees, 0 being straight right.
function lwl.getMovementDirection(crewmem)
    return lwl.getAngle(crewmem:GetPosition(), crewmem:GetNextGoal())
end

---comment
---@param direction number from CrewAnimation
---@return number FTL angle in radians
function lwl.animationDirectionToFtlAngle(direction)
    return ((3 - direction) % 4) * math.pi / 2
end

---TODO! IT'S VERY IMPORTANT NOT TO MIX BRIGHTNESS ANGLES WITH NON-BRIGHTNESS ANGLES!
------------------END ANGLE UTILS---------------------

-------------------------------Stuff for Nauter----------------------------------
--crewFilterFunction(crewmember): which crew this should apply to, conditionFunction(crewmember): when it should apply to them
---Allow types of crew to use wither-style personal teleporters under certain circumstances.
---@param conditionFunction function
---@param crewFilterFunction function
function lwl.registerConditionalTeleport(conditionFunction, crewFilterFunction)
    table.insert(mTeleportConditions, {conditionFunction, crewFilterFunction})
end

--Rooms on both ends must contain fire
--Current ship is the one the crew is on, target ship is the one that has been clicked.
local function fireTeleportCondition(crewmem) --needs work
    local mousePos = Hyperspace.Mouse.position
    local targetRoom = lwl.getRoomAtLocation(mousePos)
    if not targetRoom then return false end
    local sourceRoom = lwl.getRoomAtCrewmember(crewmem)
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


--[[ Neat idea, but it needs to many layers of encapsulation to be a good idiom.
local function waitForInitialization(blockedFunction, localVar, varGetter)
    if localVar == nil then
        localVar = varGetter()
    else
        blockedFunction
    end
end
--]]






----Black Magic
--[[
When a thing fails, it should say how it failed, and then inform its calling process that it failed.
Usually with how things are written these days, this bubbles all the way up to the main runtime.


Can't you have dynamic loading of code at runtime if you paste in the new lua code?
As long as you have top-level things like script blocks abstracted into functions, it's not an issue?
Hm, actually, you need it to have some stuff it skips if it's 

You want to write your script in such a way that if it is run any number of times, it still ends up in a good state.
So you may have some logic that handles anything a previous run may have set up and you need to handle differently if it is.

You need a block like this:
if (alreadyset == nil) then
    --do stuff that should only be done once, and would break if run multiple times
    --This is stuff like all your script blocks, and anything that calls script.whatever.
end

You also need to ensure that your calls in the alreadyset block refer to references that can be changed at global scope.
This means you will need global variables like myModName_onTick() that you pass in to these.

Actually, that is what we are trying to construct here.



]]
local function resolveToTypeInternal(value, desiredType, previousValue, depth)
    depth = depth or 0
    if depth > 100 then
        error("Exceeded maximum resolution depth")
        return nil
    end
    if value == previousValue then
        error("Value has not changed after evaluation")
        return nil
    end

    if type(value) == desiredType then
        return value
    elseif type(value) == "function" then
        return resolveToTypeInternal(value(), desiredType, value, depth + 1)
    elseif type(value) == "string" then
        local chunk, err = load("return " .. value)
        if chunk then
            return resolveToTypeInternal(chunk(), desiredType, value, depth + 1)
        else
            error("String could not be evaluated to a number: " .. err)
        end
    else
        error("Unsupported type: " .. type(value))
        return nil
    end
end

---Attempts to evaluate value until it returns a number.
---@param value any but should be a number or a function that returns a ... function that returns a number.
---@return number|nil Nil if this value cannot be resolved to a number.
function lwl.resolveToNumber(value)
    return resolveToTypeInternal(value, "number", nil, 0)
end

---Attempts to evaluate value until it returns a boolean.
---@param value any but should be a boolean or a function that returns a ... function that returns a boolean.
---@return boolean|nil Nil if this value cannot be resolved to a boolean.
function lwl.resolveToBoolean(value)
    return resolveToTypeInternal(value, "boolean", nil, 0)
end

---Attempts to evaluate value until it returns a string.
---@param value any but should be a string or a function that returns a ... function that returns a string.
---@return String|nil Nil if this value cannot be resolved to a string.
function lwl.resolveToString(value)
    return resolveToTypeInternal(value, "string", nil, 0)
end









