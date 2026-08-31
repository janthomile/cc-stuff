local MODULE = {
    name = "Ore Scanner", -- Required
    enabled = false, -- Required
    doScan = true,
    doSense = false
}
--
local neural
local pingCount = 64 -- Maximum pings to be displayed
--
local function clamp(v,min,max)
    return math.min(math.max(v,min),max)
end
local function getHex(r,g,b,a)
    return (r*0x1000000)+(g*0x10000)+(b*0x100)+a
end
-- Radar variables
local canvasSize
local compassPos
local radarZoom = 2.0
local radarZoomLimits = {0.5,10.0}
local zoomIncrement = 0.5
local compassResolution = 32
local compassRadius = 48
local compass = {}
local crosshairWidth = 0.5
local crosshairSize = 3.0
local crosshairColor = getHex(255,255,255,128)
local pings = {}
local blocks = {}
local pingScale = 0.5
local format = "%+.1f"
--
local ores = {
    "minecraft:diamond_ore","minecraft:iron_ore","minecraft:lapis_ore",
    "minecraft:gold_ore","minecraft:copper_ore","minecraft:redstone_ore",
    "minecraft:deepslate_diamond_ore","minecraft:deepslate_iron_ore","minecraft:deepslate_lapis_ore",
    "minecraft:emerald_ore","minecraft:deepslate_emerald_ore",
    "minecraft:ancient_debris"
}
--

local function rotateVector(x,y,angle)
    local cosA,sinA = math.cos(angle),math.sin(angle)
    local rotatedX,rotatedY = (x*cosA-y*sinA),(x*sinA+y*cosA)
    return {x=rotatedX,y=rotatedY}
end

local function getTextCenterOffset(txt,xsize,ysize,scale)
    return {x=-(#txt*xsize*scale),y=-(ysize*scale)}
end

local function centerText(textObject,xsize,ysize)
    xsize = xsize or 1.5
    ysize = ysize or 12
    local offset = getTextCenterOffset(textObject.getText(),xsize,ysize,textObject.getScale())
    local x,y = textObject.getPosition()
    textObject.setPosition(x+offset.x,y+offset.y)
    return textObject
end

local function getCircle(resolution,offset,radius,color)
    local points = {}
    local basePoint = {0,radius}
    local increment = (math.pi*2)/resolution
    for i=1,(resolution) do
        local vec = rotateVector(basePoint[1],basePoint[2],(i-1)*increment)
        points[#points+1] = {offset.x+vec.x,offset.y+vec.y}
    end
    points[#points+1]=color
    return points
end

local function drawCompass(canvas)
    compass = {}
    table.insert(compass,canvas.addPolygon(table.unpack(getCircle(compassResolution,compassPos,compassRadius,0xFFFFFF22))))
    table.insert(compass,canvas.addPolygon(table.unpack(getCircle(compassResolution,compassPos,compassRadius-4,0x11111122))))
    table.insert(compass,canvas.addLine({compassPos.x,compassPos.y-crosshairSize},{compassPos.x,compassPos.y+crosshairSize},crosshairColor,crosshairWidth))
    table.insert(compass,canvas.addLine({compassPos.x-crosshairSize,compassPos.y},{compassPos.x+crosshairSize,compassPos.y},crosshairColor,crosshairWidth))
end

-- Get the position on the compass for the block and rotate it based on owner yaw
local function getCompassRelative(pos, yaw)
    local rotated = rotateVector(pos.x*radarZoom,pos.y*radarZoom,math.rad(360+180-yaw))
    local offset = {-1.1,6}
    local mult = 0.5
    local screenX,screenY = (compassPos.x+rotated.x)*mult+offset[1],(compassPos.y+rotated.y)*mult+offset[2]
    return {x=screenX,y=screenY}
end

local function setupOres()
    local oreCheck = {}
    for i=1,#ores do
        oreCheck[ores[i]] = true
    end
    ores = oreCheck
end

setupOres()

-- Optional
function MODULE:draw(canvas)
    if not enabled then return end
    local me = neural.getMetaByName(ownerName)
    local pingIdx = 1
    local list = {}
    --
    local northOffset = rotateVector(0,compassRadius,math.rad(-me.yaw))
    local westOffset = rotateVector(0,compassRadius,math.rad(-me.yaw+90))
    local shift = {x=-3,y=-3}
    --
    for i=1,#blocks do
        local block = blocks[i]
        if (ores[block.name]) and pingIdx <= pingCount then
            local pingItem = pings[pingIdx][1]
            local pingText = pings[pingIdx][2]
            -- print(block.name)
            local screenPos = getCompassRelative({x=block.x,y=block.z},me.yaw)
            if screenPos == nil then ping.setText("")
            else
                local yoffset = block.y
                pingItem.setScale(pingScale)
                pingItem.setPosition(screenPos.x,screenPos.y)
                pingItem.setItem(block.name,1)
                pingText.setPosition(screenPos.x*1.9,screenPos.y*1.9)
                pingText.setText(string.format(format,yoffset))
            end
            pingIdx = pingIdx + 1
        else
        end
    end
    for i=1,(pingCount-pingIdx) do
        pings[pingIdx+i-1][1].setScale(0.001)
        pings[pingIdx+i-1][2].setText("")
    end 
end

-- Optional
function MODULE:input(event,key,held)
    if event == "key" then
        if key == keys.minus then
            radarZoom = clamp(radarZoom - zoomIncrement,radarZoomLimits[1],radarZoomLimits[2])
        elseif key == keys.equals then
            radarZoom = clamp(radarZoom + zoomIncrement,radarZoomLimits[1],radarZoomLimits[2])
        end
    end
end

-- Optional
function MODULE:sim(data)
    blocks = data.blocks or {}
end

-- Required
function MODULE:enable(data)
    neural = data.neural
    pings = {}
    --
    local canvas = data.canvas
    canvasSize = {x,y} canvasSize.x,canvasSize.y = canvas.getSize()
    compassPos = {x=(compassRadius+8),y=canvasSize.y-(compassRadius+8)}
    for i=1,pingCount do
        local color = getHex(math.random(128,255),math.random(128,255),math.random(128,255),192)
        pings[i] = {canvas.addItem({1,1},"minecraft:dirt",0,0),canvas.addText({1,1},"",0xFFFFFFFF,pingScale)}
    end
    drawCompass(canvas)
end

-- Required
function MODULE:disable(data)
    for i=1,#pings do
        pings[i][1].remove()
    end
    for i=1,#compass do
        compass[i].remove()
    end
end

return MODULE