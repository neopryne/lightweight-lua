mods.lightweight_stable_time = {}
local lwst = mods.lightweight_stable_time

local lwl = mods.lightweight_lua

local IGNORE_PAUSE = 1
local PAUSE = 2
local NO_SCALING_IGNORE_PAUSE = 3
local NO_SCALING_PAUSE = 4

local mSetupRequested = false
local mScaledLocalTime = {0, 0}
local mOnTickList = {{}, {}, {}, {}}

--[[
LWST is a library that handles framerate differences for you, giving you consistent tick frequency regardless of the current framerate.

Usage:
    local lwst = mods.lightweight_stable_time
    lwst.reg
]]

lwst.registerOnTick = function(onTick, tickWhilePaused)
    mSetupRequested = true
    if tickWhilePaused then
        table.insert(mOnTickList[IGNORE_PAUSE], onTick)
    else
        table.insert(mOnTickList[PAUSE], onTick)
    end
end

lwst.registerTrueOnTick = function(onTick, tickWhilePaused)
    mSetupRequested = true
    if tickWhilePaused then
        table.insert(mOnTickList[NO_SCALING_IGNORE_PAUSE], onTick)
    else
        table.insert(mOnTickList[NO_SCALING_PAUSE], onTick)
    end
end

local function doTicks(pauseBehavior)
    for _,onTick in ipairs(mOnTickList[pauseBehavior]) do
        onTick()
    end
end

local function advanceTicks(pauseBehavior)
    mScaledLocalTime[pauseBehavior] = mScaledLocalTime[pauseBehavior] + (Hyperspace.FPS.SpeedFactor * 16 / 10)
    if (mScaledLocalTime[pauseBehavior] > 1) then
        for _,onTick in ipairs(mOnTickList[pauseBehavior]) do
            onTick()
        end
        mScaledLocalTime[pauseBehavior] = 0
    end
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
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