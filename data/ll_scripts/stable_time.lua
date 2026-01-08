mods.lightweight_stable_time = {}
local lwst = mods.lightweight_stable_time

local lwl = mods.lightweight_lua

local IGNORE_PAUSE = 1
local PAUSE = 2
local NO_SCALING_IGNORE_PAUSE = 3
local NO_SCALING_PAUSE = 4

local mSetupRequested = false
local mScaledLocalTime = {0, 0, 0, 0}
local mOnTickList = {{}, {}, {}, {}}

--[[
LWST is a library that handles framerate differences for you, giving you consistent tick frequency regardless of the current framerate.

Usage:
    local lwst = mods.lightweight_stable_time
    lwst.registerOnTick("your thing name", function() [do stuff] end, false)
]]

---Register a method to be called a consistent amount of times regardless of framerate while the game is not paused.
---@param identifier string
---@param onTick function
---@param tickWhilePaused boolean
lwst.registerOnTick = function(identifier, onTick, tickWhilePaused)
    mSetupRequested = true
    if tickWhilePaused then
        mOnTickList[IGNORE_PAUSE][identifier] = onTick
    else
        mOnTickList[PAUSE][identifier] =  onTick
    end
end

---Register a method to be called _every_ tick, even if the game is paused.
---@param identifier string
---@param onTick function
---@param tickWhilePaused boolean
lwst.registerTrueOnTick = function(identifier, onTick, tickWhilePaused)
    mSetupRequested = true
    if tickWhilePaused then
        mOnTickList[NO_SCALING_IGNORE_PAUSE][identifier] = onTick
    else
        mOnTickList[NO_SCALING_PAUSE][identifier] = onTick
    end
end

local function doTicks(pauseBehavior) --For things that should render, or compute regardless of timescale.
    for identifier,onTick in pairs(mOnTickList[pauseBehavior]) do
        local success, error = pcall(onTick)
        if not success then
            print("Error true ticking function", identifier, "!  Call failed, see error.", error)
        end
    end
end

local function advanceTicks(pauseBehavior)
    mScaledLocalTime[pauseBehavior] = mScaledLocalTime[pauseBehavior] + (Hyperspace.FPS.SpeedFactor * 16 / 10)
    if (mScaledLocalTime[pauseBehavior] > 1) then
        for identifier,onTick in pairs(mOnTickList[pauseBehavior]) do
            local success, error = pcall(onTick)
            if not success then
                print("Error ticking function", identifier, "!  Call failed, see error.", error)
            end
        end
        mScaledLocalTime[pauseBehavior] = 0
    end
end


lwl.safe_script.on_internal_event("lwst_main_tick", Defines.InternalEvents.ON_TICK, function()
-- script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mSetupRequested then return end
    if not lwl.isPaused() then
        --[[ formula to turn ticks into 1/32 second
        16 / speedFactor = ticks per second
        tps * functor = 32
        --]]
        doTicks(NO_SCALING_PAUSE)
        advanceTicks(PAUSE)
    end
    doTicks(NO_SCALING_IGNORE_PAUSE)
    advanceTicks(IGNORE_PAUSE)
end)