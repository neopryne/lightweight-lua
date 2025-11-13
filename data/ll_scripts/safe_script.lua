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
lwl.safe_script.on_internal_event = function(identifier, definesEvent, eventFunction)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = eventFunction

    if firstCreation then
        local function eventFunctionWrapper(arg1, arg2, arg3, arg4, arg5)
            lwl.safe_script.eventFunctionWrappers[identifier](arg1, arg2, arg3, arg4, arg5)
        end
        script.on_internal_event(definesEvent, eventFunctionWrapper)
    end
end
---todo ok, I might have to make a function that unpacks the arguments 

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
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = {beforeFunction=beforeFunction, afterFunction=afterFunction}

    if firstCreation then
        local function beforeFunctionWrapper(...) --todo idk how to pass a list of all arguments
            lwl.safe_script.eventFunctionWrappers[identifier].beforeFunction(table.unpack(arg))
        end
        local function afterFunctionWrapper(...)
            lwl.safe_script.eventFunctionWrappers[identifier].afterFunction(table.unpack(arg))
        end
        script.on_render_event(definesEvent, beforeFunctionWrapper, afterFunctionWrapper)
    end
end

lwl.safe_script.on_game_event = function(identifier, eventName, onLoadOnly, callback)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function gameFunctionWrapper(...) --todo idk how to pass a list of all arguments
            lwl.safe_script.eventFunctionWrappers[identifier](table.unpack(arg))
        end
        script.on_render_event(eventName, onLoadOnly, gameFunctionWrapper) --todo only halfway done, todo finish
    end
end

lwl.safe_script.on_load = function(identifier, eventName, onLoadOnly, callback)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function gameFunctionWrapper(arg1, arg2, arg3, arg4, arg5) --todo idk how to pass a list of all arguments
            lwl.safe_script.eventFunctionWrappers[identifier].beforeFunction(arg1, arg2, arg3, arg4, arg5)
        end
        script.on_render_event(eventName, onLoadOnly, gameFunctionWrapper) --todo only halfway done, todo finish
    end
end

lwl.safe_script.on_init = function(identifier, eventName, onLoadOnly, callback)
    local firstCreation = lwl.safe_script.eventFunctionWrappers[identifier] == nil

    lwl.safe_script.eventFunctionWrappers[identifier] = callback

    if firstCreation then
        local function gameFunctionWrapper(arg1, arg2, arg3, arg4, arg5) --todo idk how to pass a list of all arguments
            lwl.safe_script.eventFunctionWrappers[identifier].beforeFunction(arg1, arg2, arg3, arg4, arg5)
        end
        script.on_render_event(eventName, onLoadOnly, gameFunctionWrapper) --todo only halfway done, todo finish
    end
end

--upgrades, crew, equipment
--todo I realize that lwst needs to add this, and every place I use script, I should be using this instead.  TODO how to handle newlines in functions required to type proper lua code?

--This is actually a stupid thing you can't do right now, but I will add it by adding a text box you can write stuff into, using my own listeners for keypress events.
--ok, the easy way to do this is to customize the ahk script to turn all the newlines into spaces.  That seems to work.  But it's hackier than the good solution.
---Which is I give you a textbox you can type in.  However, that only works if I can listen to key events from ahk.
--You also need to strip out single line comments if you want to collapse everything to one line.  multi line is fine., it works.

lwl.safe_script.on_render_event("example_oi;juewrnkljewr;lj", Defines.RenderEvents.TABBED_WINDOW, lwl.NOOP, function(tabName)
    print("2Current tab is", tabName)
end)

-- lua mods.lightweight_lua.safe_script.on_render_event("example_oi;juewrnkljewr;lj", Defines.RenderEvents.TABBED_WINDOW, mods.lightweight_lua.NOOP, function(tabName) print("wow that worked", tabName) end)
