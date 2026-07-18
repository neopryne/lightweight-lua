local lwl = mods.lightweight_lua
local lweb = mods.lightweight_event_broadcaster

--[[
You must only access this from within a run or it will give you tons of bugs.

Usage:
local myPlayerVariableInterface = lwl.CreatePlayerVariableInterface("SOMETHING")
script.on_init(function(newGame)
    if newGame then
        myPlayerVariableInterface.clearAll()
    else
        --load stuff from interface
    end
end)

Ok, this library is all about letting you define player variables for things that are kind of clunky.

You can have numbers or strings.

The hard thing this helps with is being able to return you a list of all the uuids for a given interface.
Then you can kind of refer to the registered things as objects, with properties you can get through this interface.

--TODO add this so it properly removes variable stuff.
Internally, an object is a {index=uuid, "var1"={}, "var2"={}} 
]]

local GLOBAL_NAME = "lwl_player_vars"
local GLOBAL_NUMBER_KEY = "NUM_ENTRIES"
local GLOBAL_UUID_KEY = "_uuidindex_"


--Then we have a number of fields of the form thing-UUID-fieldname = number
--These numbers don't mean anything by themselves, you will need to parse them, or build a layer.
--Maybe having people define an enum is enough.  Yeah, just build a table of the things you want this to return, and it will do that.
--tables are implicitly indexed by number.  You should define them yourself, and the translations from number to other thing.

local mRegisteredNames = {}

local function buildInterfaceKey(name)
    return GLOBAL_NAME..name..GLOBAL_NUMBER_KEY
end

local function buildObjectKey(name)
    return GLOBAL_NAME..name..GLOBAL_UUID_KEY
end

local buildVariableKey = function(uuid, key, name)
    return GLOBAL_NAME..name..uuid..key
end

--todo it's because they're player variables, and I'm loading them in the main screen.
--ok, this one, you have to make sure you only create once you're in a run.  Otherwise it doesn't work.
function lwl.CreatePlayerVariableInterface(name)
    if (mRegisteredNames[name] ~= nil) then
        error(name.." is already registered, aborting.")
        return
    end
    mRegisteredNames[name] = true
    local mInitialized = false
    local interface = {}
    interface.name = name
    interface.uuidToObjectTable = {}
    local buildUuidToObjectTable

    local function printInterface(interface)
        -- print("total number", Hyperspace.playerVariables[GLOBAL_NAME..name..GLOBAL_NUMBER_KEY])
        -- print("uuidtable", lwl.dumpObject(interface.uuidToObjectTable))
        -- for uuid,object in pairs(interface.uuidToObjectTable) do
        --     print("uuid", uuid)
        --     print("object", interface.getVariableString(uuid, ))
        -- end
    end

    local function buildUuidKey(i)
        return buildObjectKey(name)..i
    end

    ---Print the current value of this interface.
    ---@param keys table of the form {strings={}, numbers={}}, where strings is all keys used to save string values,
    ---and numbers is all keys used to save number values.
    interface.printSelf = function(keys)
        for _,uuid in ipairs(interface.getUuids()) do
            print("print object uuid", uuid, interface.getCount())
            for _,key in ipairs(keys.strings) do
                print("\t", key, interface.getVariableString(uuid, key))
            end
            for _,key in ipairs(keys.numbers) do
                print("\t", key, interface.getVariable(uuid, key))
            end
        end
    end

    interface.getCount = function()
        return Hyperspace.playerVariables[buildInterfaceKey(name)]
    end

    ---@return table of uuids
    interface.getUuids = function()
        local uuids = {}
        for i=1,interface.getCount() do
            table.insert(uuids, Hyperspace.playerVariables[buildUuidKey(i)])
        end
        return uuids
    end

    buildUuidToObjectTable = function()
        local uuids = {}
        for i=1,interface.getCount() do
            local interfaceKey = buildInterfaceKey(name)
            uuids[Hyperspace.playerVariables[interfaceKey..i]] = {}
            local object = uuids[Hyperspace.playerVariables[interfaceKey..i]]
            object.index = i
            -- print("uuid", Hyperspace.playerVariables[buildObjectKey(name)..i], "index", i, "key", buildObjectKey(name)..i)
        end
        -- print("uuidtable:", lwl.dumpObject(uuids))
        return uuids
    end

    ---Sets a variable of an object, creating the object if it does not already exist.
    ---@param uuid number uniquely identifies the object, non-zero.
    interface.createObject = function(uuid)
            if uuid == 0 then print("Error in createObject: uuid cannot be zero") return end
            print("Creating object with uuid", uuid)
            --insert new variable into all places that track it.
            local newIndex = 1 + #interface.uuidToObjectTable
            -- print("uuidToObjectTable", lwl.dumpObject(interface.uuidToObjectTable))
            interface.uuidToObjectTable[uuid] = {} --why is this complaining about being nil?
            interface.uuidToObjectTable[uuid].index = newIndex
            Hyperspace.playerVariables[buildUuidKey(newIndex)] = uuid
            Hyperspace.playerVariables[buildInterfaceKey(name)] = interface.getCount() + 1
    end

    --I am now realizing that this should keep track of all keys (variables) the user sets so it can nil them out.
    --but also this is player vars so who gives a crap.
    --eh I need it for metavars, so might as well add it here also.

    ---Sets an integer variable of an object, creating the object if it does not already exist.
    ---@param uuid number uniquely identifies the object
    ---@param key string name of the variable to set
    ---@param value number value of the variable
    interface.setVariable = function(uuid, key, value)
        if uuid == 0 then print("Error in setVariable: uuid cannot be zero") return end
        if value == nil then
            lwl.logError(GLOBAL_NAME, "Value must not be nil!")
        end
        local object = interface.uuidToObjectTable[uuid]
        ---If object is not present, create it, else find its index.
        if not object then
            interface.createObject(uuid)
            object = interface.uuidToObjectTable[uuid]
        end

        --I could merge these two and track what's a string internally but im not even sure that's better.
        Hyperspace.playerVariables[buildVariableKey(uuid, key, name)] = value
        -- print("set variable", buildKey(uuid, key), Hyperspace.playerVariables[buildKey(uuid, key)])
        printInterface(interface)
    end

    interface.getVariable = function(uuid, key)
        printInterface(interface)
        return Hyperspace.playerVariables[buildVariableKey(uuid, key, name)]
    end

    ---Sets a String variable of an object, creating the object if it does not already exist.
    ---@param uuid number uniquely identifies the object
    ---@param key string name of the variable to set
    ---@param value string value of the variable
    interface.setVariableString = function(uuid, key, value)
        if uuid == 0 then print("Error in setVariableString: uuid cannot be zero") return end
        if value == nil then
            lwl.logError(GLOBAL_NAME, "Value must not be nil!")
        end
        local object = interface.uuidToObjectTable[uuid]
        ---If object is not present, create it, else find its index.
        if not object then
            interface.createObject(uuid)
            object = interface.uuidToObjectTable[uuid]
        end

        lwl.persistStringPlayerVariable(buildVariableKey(uuid, key, name), value)
        -- print("set variable", buildKey(uuid, key), Hyperspace.playerVariables[buildKey(uuid, key)])
        printInterface(interface)
    end

    interface.getVariableString = function(uuid, key)
        printInterface(interface)
        return lwl.loadStringPlayerVariable(buildVariableKey(uuid, key, name))
    end

    --Zero out all saved values, because you can't set these to nil.
    interface.removeInternal = function(uuid)
        local object = interface.uuidToObjectTable[uuid]
        for key,_ in pairs(object) do
            Hyperspace.playerVariables[buildVariableKey(uuid, key, name)] = 0
        end
    end

    interface.removeObject = function(uuid)
        local uuidIndex = interface.uuidToObjectTable[uuid].index
        if not uuidIndex then
            error("No such object found", uuid)
            return
        end
        
        --remove all the things in it.
        interface.removeInternal(uuid)

        for i=uuidIndex, interface.getCount() - 1 do
            Hyperspace.playerVariables[buildObjectKey(name)..i] = Hyperspace.playerVariables[buildObjectKey(name)..i + 1]
        end
        interface.uuidToObjectTable[uuid] = nil
        Hyperspace.playerVariables[buildInterfaceKey(name)] = lwl.setIfNil(interface.getCount(), 0) - 1
    end

    interface.clearAll = function()
        for uuid,object in pairs(interface.uuidToObjectTable) do
            interface.removeInternal(uuid)
        end
        Hyperspace.playerVariables[buildInterfaceKey(name)] = 0
        interface.uuidToObjectTable = buildUuidToObjectTable()
    end
    
    --if the interface has any local structure, populate it from stored vars.
    --You have to do this inside of a run.
    --If you create one after this triggers, it will never get initialized. todo fix
    local function setupSave(newGame)
        -- print("Loadedpvs, is new game?", newGame)
        if newGame then
            --noop
        else
            if not mInitialized then
                interface.uuidToObjectTable = buildUuidToObjectTable()
                mInitialized = true
            end
        end
    end
    lweb.registerPlayerVariableInitializationListener(setupSave)
    
    return interface
end
--lwl.CreatePlayerVariableInterface("testInterface")



-- local PERSIST_KEY = "universal_modularity"
-- local KEY_WEAPON_NAME = "WEAPON_NAME"
-- local mAttachmentPersistanceInterface = lwl.CreatePlayerVariableInterface(PERSIST_KEY)

-- mAttachmentPersistanceInterface.setVariableString(43, KEY_WEAPON_NAME, "SOME GUN OK")
-- print("\n\n\nWeapon name loaded as:", mAttachmentPersistanceInterface.getVariableString(43, KEY_WEAPON_NAME))
-- mAttachmentPersistanceInterface.setVariableString(43, KEY_WEAPON_NAME, "special chars !@#$%^&*()")
-- print("\n\n\nWeapon name loaded as:", mAttachmentPersistanceInterface.getVariableString(43, KEY_WEAPON_NAME))
-- mAttachmentPersistanceInterface.setVariable(43, "arf", 92)
-- print("\n\n\nArf name loaded as:", mAttachmentPersistanceInterface.getVariable(43, "arf"))
-- mAttachmentPersistanceInterface.setVariable(43, "arsdfasdfasdfasdfsadfsadfasdfasdfasdfasdfsadfasdfasf", 111111)
-- print("\n\n\nArf name loaded as:", mAttachmentPersistanceInterface.getVariable(43, "arsdfasdfasdfasdfsadfsadfasdfasdfasdfasdfsadfasdfasf"))