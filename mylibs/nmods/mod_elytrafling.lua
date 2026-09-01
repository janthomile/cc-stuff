local MODULE = {
    name = "ElytraFling", -- Required
    enabled = false, -- Required
    doScan = false, -- Recommended
    doSense = false -- Recommended
}

local neural
local owner
local speaker
-- local flingKey = keys.leftAlt
local active = false
local activeText
local dataText
local ticks = 0
local speedUpdateTick = 20
local power = 1.0
local powerLimits = {0.1,4.0}
local powerIncrement = 0.1
local speed = 0.0
local dataFormat = "BoostPower: %.1f"
-- local dataFormat = "BoostPower: %.1f\n\nSpeed: %.2f m/s"

local function clamp(v,min,max)
    return math.min(math.max(v,min),max)
end

local function changePower(value)
    local oldValue = power
    power = clamp(power + value,powerLimits[1],powerLimits[2])
    local playSound = (value ~= 0.0) and (power ~= oldValue)
    if speaker and (playSound) then speaker.playSound("minecraft:block.note_block.guitar",0.15,0.5+(power/powerLimits[2])) end
    dataText.setText(string.format(dataFormat,power)) 
end

function MODULE:sim(data)
    owner = data.owner
    if (owner == nil) then return end
    active = owner.isSneaking and owner.isElytraFlying
    ticks = ticks + 1
    if not active then return end
    neural.launch(owner.yaw,owner.pitch,power)
end

function MODULE:input(event)
    if not owner then return end
    if event[1] == "key" then
        if not owner.isSneaking then
            if event[2] == keys.up then
                changePower(powerIncrement)
            elseif event[2] == keys.down then
                changePower(-powerIncrement)
            end
        elseif event[2] == keys.space and (not owner.isAirborne) then
            neural.launch(0,-90,2.0)
        end
    end
end

function MODULE:enable(data)
    local canvasSize = data.canvasSize
    local speakers = data.speakers
    if speakers ~= nil then speaker = (speakers.left or speakers.right) end
    neural = data.neural
    activeText = data.canvas.addText({canvasSize.x/2-6,canvasSize.y/2-8},"Fling",0xFFFFFF66,0.5)
    dataText = data.canvas.addText({canvasSize.x/2+8,canvasSize.y/2-2},"data",0xFFFFFF66,0.33)
    changePower(0)
end

function MODULE:disable(data)
    activeText.remove()
    dataText.remove()
end

return MODULE