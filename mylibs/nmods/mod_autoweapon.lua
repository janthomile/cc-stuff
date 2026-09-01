local MODULE = {
    name = "Autoweapon", -- Required
    enabled = false, -- Required
}
local ownerName
local meta
local rangedTime = 0
local rangedTimeIncrement = 5
local rangedTimeLimits = {0,40}
local swingTicks = 12
--
local neural
local speaker
local active = true
local activeText
local dataText
local tick = 1
--
local dataFormat = "RangedTicks: %s\n\nMeleeTicks: %s"
local melee = {"minecraft:diamond_sword"}
local ranged = {"plethora:module_laser"}

local function clamp(v,min,max)
    return math.min(math.max(v,min),max)
end

local function setupWeapons()
    local mtable = {}
    for i=1,#melee do
        mtable[melee[i]] = true
    end
    local rtable = {}
    for i=1,#ranged do
        rtable[ranged[i]] = true
    end
    melee = mtable
    ranged = rtable
end

setupWeapons()

local function changeRangedTime(value)
    local oldValue = rangedTime
    rangedTime = clamp(rangedTime + value,rangedTimeLimits[1],rangedTimeLimits[2])
    local playSound = (value ~= 0.0) and (rangedTime ~= oldValue)
    if speaker and (playSound) then speaker.playSound("minecraft:block.note_block.bass",0.15,0.5+(rangedTime/rangedTimeLimits[2]))
    dataText.setText(string.format(dataFormat,rangedTime,swingTicks)) 
    end
end

local function setActive(_active,sound)
    active = _active
    tick = 0
    if speaker and sound then speaker.playNote("didgeridoo",0.1,active and 16 or 12) end
    if active then activeText.setText("Auto") dataText.setText(string.format(dataFormat,rangedTime,swingTicks)) 
    else activeText.setText("") dataText.setText("") 
    end
end

-- Optional
function MODULE:sim(data)
    meta = data.owner
    if active and meta then
        if meta.heldItem == nil then return end
        local itemName = meta.heldItem.getMetadata().name
        if ((tick % swingTicks) == 0) and melee[itemName] then
            local result,type = neural.swing()
            if type ~= "entity" then tick = swingTicks end
        elseif ranged[itemName] then
            neural.use(rangedTime)
        end
    end
    tick = tick + 1
end

-- Optional
function MODULE:input(event)
    if not meta then return end
    if event[1] == "key" and active and (not meta.isSneaking) then
        if event[2] == keys.up then
            changeRangedTime(rangedTimeIncrement)
        elseif event[2] == keys.down then
            changeRangedTime(-rangedTimeIncrement)
        end
    elseif event[1] == "key_up" then
        if meta.isSneaking and event[2] == keys.enter then
            setActive(not active,true)
        end
    end
end

-- Required
function MODULE:enable(data)
    ownerName = data.ownerName
    neural = data.neural
    local speakers = data.speakers
    local canvasSize = data.canvasSize
    if speakers ~= nil then speaker = (speakers.left or speakers.right) end
    activeText = data.canvas.addText({canvasSize.x/2-5,canvasSize.y/2+4},"Auto",0xFFFFFF66,0.5)
    dataText = data.canvas.addText({canvasSize.x/2+8,canvasSize.y/2-5},"data",0xFFFFFF66,0.33)
    changeRangedTime(0)
    setActive(true)
end

-- Required
function MODULE:disable(data)
    activeText.remove()
    dataText.remove()
end

return MODULE