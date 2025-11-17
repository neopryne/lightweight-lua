--[[

Usage:
-- lwl.safe_script.on_render_event("example_oi;juewrnkljewr;lj", Defines.RenderEvents.TABBED_WINDOW, lwl.NOOP, function(tabName)
--     print("2Current tab is", tabName)
-- end)


--kanban would be perfect if boards could be cards.
]]

if not mods.lightweight_lua then
    mods.lightweight_lua = {}
    mods.lightweight_lua.safe_script = {}
    mods.lightweight_lua.safe_script.eventFunctionWrappers = {}
end --todo lwl.setIfNil is what you should use for this once lwl is loaded.
local lwl = mods.lightweight_lua

local MAX_EXPECTED_ARGUMENTS = 15

--Dear got we need varargs, this entire method is a huge kludge to work around this HS quirk.
local function safe_varargs_standin_register_event(definesEvent, identifier)

    local function makeWrapper(n)
        if n == 0 then
            return function()
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler() end
            end
        elseif n == 1 then
            return function(a1)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler(a1) end
            end
        elseif n == 2 then
            return function(a1, a2)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler(a1, a2) end
            end
        elseif n == 3 then
            return function(a1, a2, a3)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler(a1, a2, a3) end
            end
        elseif n == 4 then
            return function(a1, a2, a3, a4)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler(a1, a2, a3, a4) end
            end
        else
            return function(a1, a2, a3, a4, a5)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier]
                if handler then return handler(a1, a2, a3, a4, a5) end
            end
        end
    end

    for n = 5, 0, -1 do
        local eventFunctionWrapper = makeWrapper(n)
        local success, err = pcall(function()
            script.on_internal_event(definesEvent, eventFunctionWrapper)
        end)

        if success then
            print("✅ Successfully registered wrapper with", n, "args for ", definesEvent)
            return eventFunctionWrapper, n
        else
            print("❌ Failed to register wrapper with", n, "args:", err)
        end
    end

    return nil, "No valid wrapper signature found"
end

--Render version to handle dumbness.
local function safe_varargs_standin_register_render_event(definesEvent, identifier)

    local function makeWrapper(n, type)
        if n == 0 then
            return function()
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler() end
            end
        elseif n == 1 then
            return function(a1)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler(a1) end
            end
        elseif n == 2 then
            return function(a1, a2)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler(a1, a2) end
            end
        elseif n == 3 then
            return function(a1, a2, a3)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler(a1, a2, a3) end
            end
        elseif n == 4 then
            return function(a1, a2, a3, a4)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler(a1, a2, a3, a4) end
            end
        else
            return function(a1, a2, a3, a4, a5)
                local handler = lwl.safe_script.eventFunctionWrappers[identifier][type]
                if handler then return handler(a1, a2, a3, a4, a5) end
            end
        end
    end --todo it seems like this isn't doing anything.  It's not crashing, but it's not calling properly.

    for n = 5, 0, -1 do
        local eventFunctionWrapper = makeWrapper(n)
        local success, err = pcall(function()
            local beforeFunctionWrapper = makeWrapper(n, "before")
            local afterFunctionWrapper = makeWrapper(n, "after")
            script.on_render_event(definesEvent, beforeFunctionWrapper, afterFunctionWrapper)
        end)

        if success then
            print("✅ Successfully registered render wrapper with", n, "args for ", definesEvent)
            return eventFunctionWrapper, n
        else
            print("❌ Failed to register wrapper with", n, "args:", err)
        end
    end

    return nil, "No valid wrapper signature found"
end


---------------------------------------------API---------------------------------------------------
---A script register function that is safe to call multiple times.
---Additional calls with the same identifier will replace existing behavior, allowing you to remove or override script events you have added.
---
---The main benefit of this is getting to update your code without restarting the game by using [the hotswap method] (HM).
---
---The first parameter is a unique identifier.
---The rest of the parameters are what you would normally pass to script.on_internal_event.
---@param identifier string Unique to the call, you must ensure that nothing else uses the same name or this will fail to register your event.
---@param definesEvent integer event name from Hyperspace.Defines
---@param eventFunction function Called before the event
lwl.safe_script.on_internal_event = function(identifier, definesEvent, eventFunction) --TODO MAKE THESE VARARGS WHEN HYPERSPACE SUPPORTS IT.
    print("Registering internal event", identifier)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = eventFunction

    if firstCreation then
        safe_varargs_standin_register_event(definesEvent, identifier)
    end
end
---todo ok, I might have to make a function that unpacks the arguments.

---A script register function that is safe to call multiple times.
---Additional calls with the same identifier will replace existing behavior, allowing you to remove or override script events you have added.
---
---The main benefit of this is getting to update your code without restarting the game by using [the hotswap method] (HM).
---
---The first parameter is a unique identifier.
---The rest of the parameters are what you would normally pass to script.on_internal_event.
---@param identifier string Unique to the call, you must ensure that nothing else uses the same name or this will fail to register your event.
---@param definesEvent integer event name from Hyperspace.Defines
---@param beforeFunction function Called before the event
---@param afterFunction function Called after the event
lwl.safe_script.on_render_event = function(identifier, definesEvent, beforeFunction, afterFunction)
    print("Registering render event", identifier)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = {beforeFunction=beforeFunction, afterFunction=afterFunction}

    if firstCreation then
        safe_varargs_standin_register_render_event(definesEvent, identifier)
    end
end

---Multicall-safe wrapper for script.on_game_event.
---@param identifier string Unique to the call, you must ensure that nothing else uses the same name or this will fail to register your event.
---@param eventName string The name of the event, as you would pass to script.on_game_event()
---@param onLoadOnly boolean true if this should be called when the event loads, false if it should be called when the event happens.
---@param callback function takes no arguments
lwl.safe_script.on_game_event = function(identifier, eventName, onLoadOnly, callback)
    print("Registering game event", identifier)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function gameFunctionWrapper() --todo idk how to pass a list of all arguments
            return lwl.safe_script.eventFunctionWrappers[identifier]()
        end
        script.on_game_event(eventName, onLoadOnly, gameFunctionWrapper)
    end
end

---Multicall-safe wrapper for script.on_load.
---@param identifier string Unique to the call, you must ensure that nothing else uses the same name or this will fail to register your event.
---@param callback function takes one argument, boolean newGame.  True if this is a new game and false otherwise.
lwl.safe_script.on_load = function(identifier, callback)
    print("Registering load event", identifier)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function loadFunctionWrapper(newGame)
            return lwl.safe_script.eventFunctionWrappers[identifier](newGame)
        end
        script.on_load(loadFunctionWrapper)
    end
end

---Multicall-safe wrapper for script.on_init.
---@param identifier string Unique to the call, you must ensure that nothing else uses the same name or this will fail to register your event.
---@param callback function takes one argument, boolean newGame.  True if this is a new game and false otherwise.
lwl.safe_script.on_init = function(identifier, callback)
    print("Registering init event", identifier)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function initFunctionWrapper(newGame)
            return lwl.safe_script.eventFunctionWrappers[identifier](newGame)
        end
        script.on_init(initFunctionWrapper)
    end
end
-------------------------------------------END API---------------------------------------------------

--upgrades, crew, equipment
--todo I realize that lwst needs to add this, and every place I use script, I should be using this instead.  TODO how to handle newlines in functions required to type proper lua code?

--This is actually a stupid thing you can't do right now, but I will add it by adding a text box you can write stuff into, using my own listeners for keypress events.
--ok, the easy way to do this is to customize the ahk script to turn all the newlines into spaces.  That seems to work.  But it's hackier than the good solution.
---Which is I give you a textbox you can type in.  However, that only works if I can listen to key events from ahk.
--You also need to strip out single line comments if you want to collapse everything to one line.  multi line is fine., it works.

-- lwl.safe_script.on_render_event("example_oi;juewrnkljewr;lj", Defines.RenderEvents.TABBED_WINDOW, lwl.NOOP, function(tabName)
--     print("2Current tab is", tabName)
-- end)


-- lwl.safe_script.on_internal_event("example_2", Defines.InternalEvents.ON_TICK, function()
--     print("tick worked")
-- end)
-- lua mods.lightweight_lua.safe_script.on_render_event("example_oi;juewrnkljewr;lj", Defines.RenderEvents.TABBED_WINDOW, mods.lightweight_lua.NOOP, function(tabName) print("wow that worked", tabName) end)
