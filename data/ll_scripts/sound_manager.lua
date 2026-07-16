local lwl = mods.lightweight_lua
local SoundManager = mods.lightweight_lua.sound_manager
local Deque = mods.lightweight_lua.deque
local time_increment = mods.multiverse.time_increment
--[[
channel object
    id
        playbackChannel
        queue --deque object
        currentSoundRemainingTime

sound object
    name
        length=length
]]
SoundManager.__index = SoundManager

local function alwaysTick()
    return true
end

local function emptyQueue(channelQueue)
    --Delete all pending items
    channelQueue.queue = Deque.new()
end

local function playSoundInternal(self, soundObject, channelQueue)
    -- print("playSoundInternal \n    channelQueue", channelQueue.playbackChannel,  channelQueue.currentSoundRemainingTime, channelQueue.id,
    --         "\n    soundObject", soundObject.name, soundObject.volume, soundObject.loop, soundObject.duration)
    --stopChannel(channelQueue)
    if soundObject.loop then
        self:queueSound(channelQueue.id, soundObject.name, soundObject.volume, soundObject.loop, soundObject.duration)
    end
    channelQueue.currentSoundRemainingTime = soundObject.duration
    if channelQueue.currentSoundRemainingTime == nil then
        print("Error! No legnth found for sound", soundObject.name, "!")
    end
    return Hyperspace.Sounds:PlaySoundMix(soundObject.name, soundObject.volume, false)
end


--#region -----------API---------------------

---Create a new SoundManager object for your use.
---@return table the SoundManager.
function SoundManager.new()
    local self = setmetatable({}, SoundManager)
    self._nextChannelId = 1
    self._channelQueues = {}
    
    script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
        for channelId,channelQueue in pairs(self._channelQueues) do
            -- print("Ticking channel", channelId, "timer", channelQueue.currentSoundRemainingTime)
            if channelQueue.shouldTick() and (channelQueue.currentSoundRemainingTime == nil or channelQueue.currentSoundRemainingTime <= 0) then
                local soundObject = channelQueue.queue:pop_left()
                if not soundObject then
                    self._channelQueues[channelId] = nil
                else
                    self._channelQueues[channelId].playbackChannel = playSoundInternal(self, soundObject, channelQueue)
                end
            else
                channelQueue.currentSoundRemainingTime = channelQueue.currentSoundRemainingTime - time_increment()
            end
        end
    end)

    return self
end

---Add a sound to a channel's queue.
---@param channelId number Optional param for channel to use, if missing will create a new channel.
---@param soundName string previously registered with soundManager.registerSound()
---@param volume number passed to Hyperspace.Sounds:PlaySoundMix
---@param looping boolean if true, sound will loop until channel is cleared.
---@param duration number how long to wait until this channel can play another sound
---@return number channel of the sound.  Not the one hyperspace uses.
function SoundManager:queueSound(channelId, soundName, volume, looping, duration)
    -- print("queueSound", soundName, volume, looping, channelId, duration)
    if not channelId then
        while self._channelQueues[self._nextChannelId] do
            self._nextChannelId = self._nextChannelId + 1
        end
        channelId = self._nextChannelId
    end
    if self._channelQueues[channelId] == nil then
        self._channelQueues[channelId] = {playbackChannel=nil, queue=Deque.new(), currentSoundRemainingTime=nil, id=channelId, shouldTick=alwaysTick}
    end

    self._channelQueues[channelId].queue:push_right({name=soundName, volume=volume, loop=looping, duration=duration})
    return channelId
end

---Add a sound to a channel's queue.
---@param channelId number Optional param for channel to use, if missing will create a new channel.
---@param soundName string previously registered with soundManager.registerSound()
---@param volume number passed to Hyperspace.Sounds:PlaySoundMix
---@param looping boolean if true, sound will loop until channel is cleared.
---@param duration number how long to wait until this channel can play another sound
---@return number channel of the sound.  Not the one hyperspace uses.
function SoundManager:playSound(channelId, soundName, volume, looping, duration)
    self:emptyQueue(channelId)
    return self:queueSound(channelId, soundName, volume, looping, duration)
end

---Emptys the queue of a given channel.  Does not stop currently playing audio.
---@param channelNumber number the channel ID returned by queueSound or playSound
function SoundManager:emptyQueue(channelNumber)
    local channelQueue = self._channelQueues[channelNumber]
    if channelQueue then
        emptyQueue(channelQueue)
    end
end

---Stops the current sound on a channel and goes to the next one.
---@param channelNumber number the channel ID returned by queueSound or playSound
function SoundManager:skipSound(channelNumber)
    local channelQueue = self._channelQueues[channelNumber]
    local hsChannel = channelQueue.playbackChannel
    if hsChannel then
        Hyperspace.Sounds:StopChannel(hsChannel, 0)
    end
    channelQueue.currentSoundRemainingTime = 0
end

---Lets you pass a function to a channel that determines when it is allowed to tick down.
---This does not affect sounds already playing.
---@param shouldTick function takes zero arguments, returns true if the channel should advance its timers and false if not.
function SoundManager:setChannelActiveLogic(shouldTick)
    self._channelQueues[channelNumber].shouldTick = shouldTick
end

--#endregion

-- local soundManager = SoundManager.new()

-- local mSecondSound
-- --When game loads:
-- script.on_init(function(newGame)
--     mSecondSound = true
-- end)
-- --We only need this for second sound, both still have the volume issue.
-- script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
--     if mSecondSound then
--         mSecondSound = false
--         print(lwl.dumpObject(soundManager))
--         soundManager:queueSound(1, "detectiveShoot3", 9, false, 1)
--         soundManager:queueSound(1, "detectiveShoot3", 9, false, 1)
--         soundManager:queueSound(1, "detectiveShoot3", 9, false, 1)
--         soundManager:queueSound(1, "detectiveShoot3", 9, false, 1)
--         soundManager:queueSound(1, "detectiveShoot3", 9, false, 1)
--     end
-- end)