if not mods.multiverse then
    error("Multiverse was not patched, or was patched after Lightweight Lua.  All library functions will be broken.")
end

--This is the minimal code you need for an init file of this style, which accounts for multiple contributers to a table.
local function initIfNil(modTable)
    if not modTable then
        modTable = {}
    end
    if not modTable.owners then
        modTable.owners = {}
    else
        print("Lightweight Lua loading, previously modified by: ")
        for owner in modTable.owners do
            print(owner)
        end
    end
    table.insert(modTable.owners, "lightweight_lua")
    return modTable
end

mods.lightweight_lua = initIfNil(mods.lightweight_lua)
mods.lightweight_lua.sound_manager = initIfNil(mods.lightweight_lua.sound_manager)
mods.lightweight_lua.safe_script = initIfNil(mods.lightweight_lua.safe_script)
mods.lightweight_lua.safe_script.eventFunctionWrappers = initIfNil(mods.lightweight_lua.safe_script.eventFunctionWrappers)
mods.lightweight_keybinds = initIfNil(mods.lightweight_keybinds)
mods.lightweight_doublylinkedlist = initIfNil(mods.lightweight_doublylinkedlist)
mods.lightweight_user_interface = initIfNil(mods.lightweight_user_interface)
mods.lightweight_lua.primitiveList = initIfNil(mods.lightweight_lua.primitiveList)
mods.lightweight_crew_effects = initIfNil(mods.lightweight_crew_effects)