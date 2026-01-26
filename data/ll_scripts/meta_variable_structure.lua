local lwl = mods.lightweight_lua

--[[
Ok, this library is all about letting you define player variables for things that are kind of clunky.

You can have numbers or number-indexed tables.  You can't store strings here.

The hard thing this helps with is being able to return you a list of all the uuids for a given interface.
Then you can kind of refer to the registered things as objects, with properties you can get through this interface.

There is no way to remove items from the list as it stands.
]]

local GLOBAL_NAME = "lwl_player_vars"
local GLOBAL_NUMBER_KEY = "NUM_ENTRIES"
local GLOBAL_UUID_KEY = "_uuidindex_"


--Then we have a number of fields of the form thing-UUID-fieldname = number
--These numbers don't mean anything by themselves, you will need to parse them, or build a layer.
--Maybe having people define an enum is enough.  Yeah, just build a table of the things you want this to return, and it will do that.
--tables are implicitly indexed by number.  You should define them yourself, and the translations from number to other thing.
local typeTable = {"basic", "advanced", "custom"}

local mRegisteredNames = {}


local function buildInterfaceKey(name)
    return GLOBAL_NAME..name..GLOBAL_NUMBER_KEY
end

local function buildObjectKey(name)
    return GLOBAL_NAME..name..GLOBAL_UUID_KEY
end

local function buildVariableKey(uuid, key, name)
    return GLOBAL_NAME..name..uuid..key
end


function lwl.CreateMetaVariableInterface(name)
    if (mRegisteredNames[name] ~= nil) then
        error(name.." is already registered, aborting.")
        return
    end
    mRegisteredNames[name] = true
    local interface = {}
    interface.name = name
    interface.uuidToObjectTable = {}
    local buildUuidToObjectTable

    local function printInterface(interface)
        -- print("total number", Hyperspace.metaVariables[buildInterfaceKey(name)])
        -- print("uuidtable", lwl.dumpObject(buildUuidToIndexTable()))
    end

    interface.getVariable = function(uuid, key)
        return Hyperspace.metaVariables[buildVariableKey(uuid, key, name)]
    end

    interface.getCount = function()
        -- print("getting", buildInterfaceKey(name), "is", Hyperspace.metaVariables[buildInterfaceKey(name)])
        return Hyperspace.metaVariables[buildInterfaceKey(name)]
    end

    ---@return table of uuids
    interface.getUuids = function()
        local uuids = {}
        for i=1,interface.getCount() do
            table.insert(uuids, Hyperspace.metaVariables[buildInterfaceKey(name)..i])
        end
        return uuids
    end

    buildUuidToObjectTable = function()
        local uuids = {}
        for i=1,interface.getCount() do
            local interfaceKey = buildInterfaceKey(name)
            uuids[Hyperspace.metaVariables[interfaceKey..i]] = {}
            local object = uuids[Hyperspace.metaVariables[interfaceKey..i]]
            object.index = i
        end
        return uuids
    end


    ---Sets a variable of an object, creating the object if it does not already exist.
    ---@param uuid number uniquely identifies the object
    ---@param key string name of the variable to set
    ---@param value number value of the variable
    interface.setVariable = function(uuid, key, value)
        if value == nil then
            lwl.logError(GLOBAL_NAME, "Value must not be nil!")
        end
        local object = interface.uuidToObjectTable[uuid]
        ---If object is not present, create it, else find its index.
        if not object then
            --insert new variable into all places that track it.
            local newIndex = 1 + #interface.uuidToObjectTable
            interface.uuidToObjectTable[uuid] = {}
            interface.uuidToObjectTable[uuid].index = newIndex
            Hyperspace.metaVariables[buildObjectKey(name)..newIndex] = uuid
            Hyperspace.metaVariables[buildInterfaceKey(name)] = lwl.setIfNil(interface.getCount(), 0) + 1
        end

        Hyperspace.metaVariables[buildVariableKey(uuid, key, name)] = value
        -- print("set variable", buildKey(uuid, key), Hyperspace.playerVariables[buildKey(uuid, key)])
        printInterface(interface)
    end

    interface.removeInternal = function(uuid)
        local object = interface.uuidToObjectTable[uuid]
        for key,_ in pairs(object) do
            Hyperspace.metaVariables[buildVariableKey(uuid, key, name)] = 0
        end
    end

    interface.removeObject = function(uuid)
        local uuidIndex = interface.uuidToObjectTable[uuid].index
        if not uuidIndex then
            error("No such object found", uuid)
            return
        end
        
        interface.removeInternal(uuid)

        for i=uuidIndex, interface.getCount() - 1 do
            Hyperspace.metaVariables[buildObjectKey(name)..i] = Hyperspace.metaVariables[buildObjectKey(name)..i + 1]
        end
        --todo remove all the things in it.
        interface.uuidToObjectTable[uuid] = nil
        Hyperspace.metaVariables[buildInterfaceKey(name)] = lwl.setIfNil(interface.getCount(), 0) - 1
    end

    interface.clearAll = function()
        for uuid,_ in pairs(interface.uuidToObjectTable) do
            interface.removeInternal(uuid)
        end
        Hyperspace.metaVariables[buildInterfaceKey(name)] = 0
        interface.uuidToObjectTable = buildUuidToObjectTable()
    end

    --if the interface has any local structure, populate it from stored vars.
    interface.uuidToObjectTable = buildUuidToObjectTable()
    return interface
end

--lwl.CreateMetaVariableInterface("testInterface")

