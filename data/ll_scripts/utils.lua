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
mods.lightweight_lua = {}
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

local SKILL_PILOT = 0
local SKILL_ENGINES = 1
local SKILL_SHIELDS = 2
local SKILL_WEAPONS = 3
local SKILL_REPAIR = 4
local SKILL_COMBAT = 5

---@return integer
function mods.lightweight_lua.SKILL_PILOT() return SKILL_PILOT end
---@return integer
function mods.lightweight_lua.SKILL_ENGINES() return SKILL_ENGINES end
---@return integer
function mods.lightweight_lua.SKILL_SHIELDS() return SKILL_SHIELDS end
---@return integer
function mods.lightweight_lua.SKILL_WEAPONS() return SKILL_WEAPONS end
---@return integer
function mods.lightweight_lua.SKILL_REPAIR() return SKILL_REPAIR end
---@return integer
function mods.lightweight_lua.SKILL_COMBAT() return SKILL_COMBAT end

---@return integer
function mods.lightweight_lua.SYS_SHIELDS() return SYS_SHIELDS end
---@return integer
function mods.lightweight_lua.SYS_ENGINES() return SYS_ENGINES end
---@return integer
function mods.lightweight_lua.SYS_OXYGEN() return SYS_OXYGEN end
---@return integer
function mods.lightweight_lua.SYS_WEAPONS() return SYS_WEAPONS end
---@return integer
function mods.lightweight_lua.SYS_DRONES() return SYS_DRONES end
---@return integer
function mods.lightweight_lua.SYS_MEDBAY() return SYS_MEDBAY end
---@return integer
function mods.lightweight_lua.SYS_PILOT() return SYS_PILOT end
---@return integer
function mods.lightweight_lua.SYS_SENSORS() return SYS_SENSORS end
---@return integer
function mods.lightweight_lua.SYS_DOORS() return SYS_DOORS end
---@return integer
function mods.lightweight_lua.SYS_TELEPORTER() return SYS_TELEPORTER end
---@return integer
function mods.lightweight_lua.SYS_CLOAKING() return SYS_CLOAKING end
---@return integer
function mods.lightweight_lua.SYS_ARTILLERY() return SYS_ARTILLERY end
---@return integer
function mods.lightweight_lua.SYS_BATTERY() return SYS_BATTERY end
---@return integer
function mods.lightweight_lua.SYS_CLONEBAY() return SYS_CLONEBAY end
---@return integer
function mods.lightweight_lua.SYS_MIND() return SYS_MIND end
---@return integer
function mods.lightweight_lua.SYS_HACKING() return SYS_HACKING end
---@return integer
function mods.lightweight_lua.SYS_TEMPORAL() return SYS_TEMPORAL end

--This might be overkill, but it works
function mods.lightweight_lua.isPaused()
    local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
    return commandGui.bPaused or commandGui.bAutoPaused or commandGui.event_pause or commandGui.menu_pause
end

---usage: object = nilSet(object, value)
---@param object any
---@param value any
---@return any
function mods.lightweight_lua.nilSet(object, value)
    if (object == nil) then
        object = value
    end
    return object
end

---usage: object = nilSet(object, value)
---@param object any
---@param value any
---@return any
function mods.lightweight_lua.setIfNil(object, value)
    return lwl.nilSet(object, value)
end

--[[  TABLE UTILS  ]]--
---for use in printing all of a table
---@param o table
---@return string
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

--one level deep copy of t1 and t2 to t3 deep, it's not recursive.  For full deep copy, use deepTableMerge
---@param t1 table
---@param t2 table
---@return table
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

---note: does not copy objects in the table.
---@param t table
---@return table
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
---The filter function is which ones to keep, onRemove is called on elements removed.
---@param table table
---@param filterFunction function
---@param onRemove function
---@return table
function mods.lightweight_lua.arrayRemove(table, filterFunction, onRemove)
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
            onRemove(table[i])
            table[i] = nil;
        end
    end
    return table;
end

---returns nil if table is empty
---@param table table
---@return any|nil
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

---Returns the set of elements in newSet that are not in initialSet.  Arguments should not have duplicate entries.
---@param newSet table
---@param initialSet table
---@return table
function mods.lightweight_lua.getNewElements(newSet, initialSet)
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

---Arguments should not have duplicate entries.  Returns the set union of both sets.
---@param set1 table
---@param set2 table
---@return table
function mods.lightweight_lua.setMerge(set1, set2)
    elements = lwl.deepCopyTable(set2)
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
function mods.lightweight_lua.setXor(set1, set2)
   return lwl.setMerge(lwl.getNewElements(set1, set2), lwl.getNewElements(set2, set1))
end

---Returns the set intersection of two tables.
---@param set1 any
---@param set2 any
---@return table
function mods.lightweight_lua.setIntersectionTable(set1, set2)
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

---Returns the number of keys in the table
---@param table table
---@return integer
function mods.lightweight_lua.countKeys(table)
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
function mods.lightweight_lua.setMetavar(name, value)
    if (value ~= nil) then
        Hyperspace.metaVariables[name] = value
    end
    return (value ~= nil)
end

---returns a merged deep copy of both tables.  Non-table objects will not be deep-copied.
---@param t1 table
---@param t2 table
---@return table
function mods.lightweight_lua.deepTableMerge(t1, t2)
    local t1Copy = mods.lightweight_lua.deepCopyTable(t1)
    local t2Copy = mods.lightweight_lua.deepCopyTable(t2)
    return mods.lightweight_lua.tableMerge(t1Copy, t2Copy)
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
        maxLogLevel = mods.lightweight_lua.LOG_LEVEL
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
function mods.lightweight_lua.logError(tag, text, optionalLogLevel)
    logInternal(tag, text, 1, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function mods.lightweight_lua.logWarn(tag, text, optionalLogLevel)
    logInternal(tag, text, 2, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function mods.lightweight_lua.logDebug(tag, text, optionalLogLevel)
    logInternal(tag, text, 3, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function mods.lightweight_lua.logInfo(tag, text, optionalLogLevel)
    logInternal(tag, text, 4, optionalLogLevel)
end
---@param tag string Denote the source of the log
---@param text string
---@param optionalLogLevel integer|nil
function mods.lightweight_lua.logVerbose(tag, text, optionalLogLevel)
    logInternal(tag, text, 5, optionalLogLevel)
end

--[[  CREW UTILS  ]]--
---@param crewmem Hyperspace.CrewMember
---@param name string
function mods.lightweight_lua.setCrewName(crewmem, name)
    local nameTextString = Hyperspace.TextString()
    nameTextString.data = name
    crewmem:SetName(nameTextString, true)
end

---@param crewmem Hyperspace.CrewMember
---@return boolean
function mods.lightweight_lua.filterLivingCrew(crewmem)
    return (not (crewmem:OutOfGame() or (crewmem.bDead and not (crewmem.clone_ready or crewmem.bCloned))))
end

---@param crewmem Hyperspace.CrewMember
---@return boolean
function mods.lightweight_lua.filterTrueCrewNoDrones(crewmem)
    return crewmem:CountForVictory()  --Crew is not a drone AND (Crew is not dead or dying) OR crew is preparing to clone --sillysandvich
end

---@param crewmem Hyperspace.CrewMember
---@return boolean
function mods.lightweight_lua.filterOwnshipTrueCrew(crewmem)
    return crewmem:CountForVictory() and crewmem.iShipId == 0
end

---@param filterFunction function
---@return table
function mods.lightweight_lua.getAllMemberCrewFromFactory(filterFunction)
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
function mods.lightweight_lua.getAllMemberCrew(shipManager, tracking, includeNoWarn)
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
function mods.lightweight_lua.getCrewById(selfId)
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
function mods.lightweight_lua.getCrewOnSameShip(targetShipManager, crewShipManager)
    local function selectionFilter(crewmem)
        return crewmem.iShipId == crewShipManager.iShipId and crewmem.currentShipId == targetShipManager.iShipId
    end
    return lwl.getAllMemberCrewFromFactory(selectionFilter)
end

--todo call into factory with filter function.
function mods.lightweight_lua.getSelectedCrew(selectionState)
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
function mods.lightweight_lua.get_ship_crew_point(shipManager, crewShipManager, x, y, getDrones, getNonDrones, maxCount)
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

---@param crewmem Hyperspace.CrewMember
---@param location Hyperspace.Point
---@return table
function mods.lightweight_lua.getFoesAtSpace(crewmem, location)
    local enemyList = {}
    local currentShipManager = Hyperspace.ships(crewmem.currentShipId)
    local foeShipManager = Hyperspace.ships(1 - crewmem.iShipId)
    if (currentShipManager and foeShipManager) then
        enemyList = mods.lightweight_lua.get_ship_crew_point(currentShipManager, foeShipManager, location.x, location.y)
    end
    return enemyList
end

---@param crewmem Hyperspace.CrewMember
---@return table
function mods.lightweight_lua.getFoesAtSelf(crewmem)
    return lwl.getFoesAtSpace(crewmem, crewmem:GetPosition())
end

--- -1 in the unlikely event no room is found
---@param crewmem Hyperspace.CrewMember
---@return integer
function mods.lightweight_lua.getRoomAtCrewmember(crewmem)
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
function mods.lightweight_lua.getSharedDoors(shipId, roomIdFirst, roomIdSecond)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local doorList = shipGraph:GetDoors(roomIdFirst)
    local doorList2 = shipGraph:GetDoors(roomIdSecond)
    local sharedDoors = mods.lightweight_lua.setIntersectionVter(doorList, doorList2)
    return sharedDoors 
end

--returns true if it did anything and false otherwise
---@param crewmem Hyperspace.CrewMember
---@param location Hyperspace.Point
---@param damage number
---@param stunTime number
---@param directDamage number
---@return boolean
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
---comment
---@param crewmem Hyperspace.CrewMember
---@param damage number
---@param stunTime number
---@param directDamage number
---@return boolean
function mods.lightweight_lua.damageFoesInSameSpace(crewmem, damage, stunTime, directDamage)
    return mods.lightweight_lua.damageFoesAtSpace(crewmem, crewmem:GetPosition(), damage, stunTime, directDamage)
end

---Ok this function doesn't make very much sense.  TODO rework this.
---@param activeCrew Hyperspace.CrewMember
---@param amount number
---@param stunTime number
---@param currentRoom number
---@param bystander Hyperspace.CrewMember
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


---comment
---@param roomId integer
---@param shipId integer 0 or 1
---@param filterFunction function (Hyperspace.CrewMember) optional additional conditions for which crew to get.
---@return table
function mods.lightweight_lua.getRoomCrew(roomId, shipId, filterFunction)
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
function mods.lightweight_lua.getSameRoomCrew(crewmem, filterFunction)
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


--[[  GEOMETRY UTILS  ]]--
function mods.lightweight_lua.pointfToPoint(pointf)
    return Hyperspace.Point(math.floor(pointf.x), math.floor(pointf.y))
end

function mods.lightweight_lua.pointToPointf(point)
    return Hyperspace.Pointf(point.x, point.y)
end

--- Generate a random point radius away from a point
---modified from vertexUtils random_point_radius
---@param origin Hyperspace.Point
---@param radius number
---@return Hyperspace.Pointf
function mods.lightweight_lua.random_point_circle(origin, radius)
    local r = radius
    local theta = TAU*(math.random())
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

--- Generate a random point radius away from a point
---copied from vertexUtils random_point_radius
---@param origin Hyperspace.Point
---@param radius number
---@return Hyperspace.Pointf
function mods.lightweight_lua.random_point_radius(origin, radius)
    local r = radius*(math.random())
    local theta = TAU*(math.random())
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

---Generate a random point within the radius of a given point
---@param origin Hyperspace.Point
---@return Hyperspace.Pointf
function mods.lightweight_lua.random_point_adjacent(origin)
    local r = TILE_SIZE
    local theta = math.pi*(math.floor(math.random(0, 4))) / 2
    return Hyperspace.Pointf(origin.x + r*math.cos(theta), origin.y + r*math.sin(theta))
end

---random_point_adjacent in a while loop until it lands on a floor space.
---This is dumb and poorly written.
---@param origin any
---@param shipManager any
---@return Hyperspace.Point|nil
function mods.lightweight_lua.random_valid_space_point_adjacent(origin, shipManager)
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
function mods.lightweight_lua.closestOpenSlot(point, shipId, isIntruder)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    return shipGraph:GetClosestSlot(point, shipId, isIntruder)
end

---@param crewmem Hyperspace.CrewMember
---@return Hyperspace.Slot
function mods.lightweight_lua.closestOpenSlotToCrew(crewmem)
    return lwl.closestOpenSlot(crewmem:GetPosition(), crewmem.currentShipId, crewmem.currentShipId ~= crewmem.iShipId)
end

---Doesn't matter who's in it, returns -1 if no room is found. For use with things like MoveToRoom
---@param point Hyperspace.Point
---@param shipManager Hyperspace.ShipManager
---@return integer
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
    local indexY = math.floor(deltaY / TILE_SIZE)
    return indexX + (indexY * width)
end

--Returns a random slot id in the given room.
---@param roomNumber number
---@param shipId ShipId
---@return integer
function mods.lightweight_lua.randomSlotRoom(roomNumber, shipId)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local shape = shipGraph:GetRoomShape(roomNumber)
    local width = shape.w / TILE_SIZE
    local height = shape.h / TILE_SIZE
    local count_of_tiles_in_room = width * height
    return math.floor(math.random() * count_of_tiles_in_room) --zero indexed
end


--Then we give some filter functions that might be broadly useful
function mods.lightweight_lua.noFilter(crewmem)
    return true
end

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function mods.lightweight_lua.generateCrewFilterFunction(crewmem)
    return function (crew)
        return crew.extend.selfId == crewmem.extend.selfId
    end
end

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function mods.lightweight_lua.generateSameRoomAlliesFilterFunction(crewmem)
    return function ()
        return lwl.getSameRoomCrew(crewmem, function (crew)
            return crew.iShipId == crewmem.iShipId
        end)
    end
end

---@param crewmem Hyperspace.CrewMember
---@return function Returns true if this crewmember is an exact match.
function mods.lightweight_lua.generateSameRoomFoesFilterFunction(crewmem)
    return function ()
        return lwl.getSameRoomCrew(crewmem, function (crew)
            return crew.iShipId ~= crewmem.iShipId
        end)
    end
end

--Generates a filter, not one itself.
function mods.lightweight_lua.generateOpposingCrewFilter(crewmem)
    return function (crew)
        return crew.iShipId ~= crewmem.iShipId
    end
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

-- written by arc
function mods.lightweight_lua.convertMousePositionToPlayerShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

-- written by kokoro
 function mods.lightweight_lua.convertMousePositionToEnemyShipPosition(mousePosition)
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
function mods.lightweight_lua.getRoomAtLocation(position)
    --Ships in mv don't overlap, so check both ships --poinf?
    local retRoom = get_room_at_location(Hyperspace.ships(OWNSHIP), lwl.convertMousePositionToPlayerShipPosition(mousePos), true)
    if retRoom then return retRoom end
    return get_room_at_location(Hyperspace.ships(ENEMY_SHIP), lwl.convertMousePositionToEnemyShipPosition(mousePos), true)
end

-----------------------------CONTROL FLOW------------------------------
---Returns a Function that returns true once every trueEvery calls.
---@param trueEvery function
---@return function
function mods.lightweight_lua.createIncrementalConditonal(trueEvery)
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

-------------------------------Stuff for Nauter----------------------------------
--crewFilterFunction(crewmember): which crew this should apply to, conditionFunction(crewmember): when it should apply to them
---Allow types of crew to use wither-style personal teleporters under certain circumstances.
---@param conditionFunction function
---@param crewFilterFunction function
function mods.lightweight_lua.registerConditionalTeleport(conditionFunction, crewFilterFunction)
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

function mods.lightweight_lua.resolveToNumber(value)
    return resolveToTypeInternal(value, "number", nil, 0)
end

function mods.lightweight_lua.resolveToBoolean(value)
    return resolveToTypeInternal(value, "boolean", nil, 0)
end

function mods.lightweight_lua.resolveToString(value)
    return resolveToTypeInternal(value, "string", nil, 0)
end









