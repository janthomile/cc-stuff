local MODULE = {
    name = "Mob Radar", -- Required
    enabled = false, -- Required
    doSense = true
}
--
local neural
local ownerName = "Spommicus" -- Owner for skipping
local pingCount = 64 -- Maximum pings to be displayed
local nameRemap = {
    ["glass_item_frame"]="gif",
    ["item_frame"]="if"
}
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
local radarZoomLimits = {0.5,5.0}
local zoomIncrement = 0.5
local compassResolution = 32
local compassRadius = 48
local n,s,e,w = nil
local crosshairWidth = 0.5
local crosshairSize = 3.0
local crosshairColor = getHex(255,255,255,128)
local pings = {}
local mobs = {}
local prevMobCount = 0
local nameColor = 0xFFFFFFBB
local pingScale = 0.33
local format = "%s\n%+.1f"
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
    -- Two circles for compassiness
    local outer = canvas.addPolygon(table.unpack(getCircle(compassResolution,compassPos,compassRadius,0xFFFFFF22)))
    local inner = canvas.addPolygon(table.unpack(getCircle(compassResolution,compassPos,compassRadius-4,0x11111122)))
    -- You gotta have it
    n = centerText(canvas.addText({compassPos.x,compassPos.y-compassRadius},"N",0xFFFFFFFF,1.0),4,3)
    s = centerText(canvas.addText({compassPos.x,compassPos.y-compassRadius},"S",0xFFFFFFFF,1.0),4,3)
    e = centerText(canvas.addText({compassPos.x,compassPos.y-compassRadius},"E",0xFFFFFFFF,1.0),4,3)
    w = centerText(canvas.addText({compassPos.x,compassPos.y-compassRadius},"W",0xFFFFFFFF,1.0),4,3)
    -- Crosshair
    local crosshairVert = canvas.addLine({compassPos.x,compassPos.y-crosshairSize},{compassPos.x,compassPos.y+crosshairSize},crosshairColor,crosshairWidth)
    local crosshairHorz = canvas.addLine({compassPos.x-crosshairSize,compassPos.y},{compassPos.x+crosshairSize,compassPos.y},crosshairColor,crosshairWidth)
end

-- Get the position on the compass for the mob and rotate it based on owner yaw
local function getCompassRelative(pos, yaw)
    local rotated = rotateVector(pos.x*radarZoom,pos.y*radarZoom,math.rad(360+180-yaw))
    local screenX,screenY = compassPos.x+rotated.x,compassPos.y+rotated.y
    return {x=screenX,y=screenY}
end

-- Optional
function MODULE:canvas_setup(canvas)
    canvasSize = {x,y} canvasSize.x,canvasSize.y = canvas.getSize()
    compassPos = {x=(compassRadius+8),y=canvasSize.y-(compassRadius+8)}
    for i=1,pingCount do
        local color = getHex(math.random(128,255),math.random(128,255),math.random(128,255),192)
        pings[i] = canvas.addText({1,1},"",color,pingScale)
    end
    drawCompass(canvas)
end

-- Optional
function MODULE:draw(canvas)
    local me = neural.getMetaByName(ownerName)
    local pingIdx = 1
    local list = {}
    --
    local northOffset = rotateVector(0,compassRadius,math.rad(-me.yaw))
    local westOffset = rotateVector(0,compassRadius,math.rad(-me.yaw+90))
    local shift = {x=-3,y=-3}
    n.setPosition(compassPos.x+northOffset.x+shift.x,compassPos.y+northOffset.y+shift.y)
    s.setPosition(compassPos.x-northOffset.x+shift.x,compassPos.y-northOffset.y+shift.y)
    w.setPosition(compassPos.x-westOffset.x+shift.x,compassPos.y-westOffset.y+shift.y)
    e.setPosition(compassPos.x+westOffset.x+shift.x,compassPos.y+westOffset.y+shift.y)
    --
    for i=1,pingCount do
        local ping = pings[i]
        if i <= (#mobs) then
            local mob = mobs[i]
            if not (mob.name == ownerName) then
                local screenPos = getCompassRelative({x=mob.x,y=mob.z},me.yaw)
                if screenPos == nil then ping.setText("")
                else
                    local yoffset = me.eyeOffset.y-mob.eyeOffset.y + mob.y
                    ping.setPosition(screenPos.x,screenPos.y)
                    local name = mob.key:gsub("^.+:","")
                    name = nameRemap[name] or ((name == player) and mob.name or name)
                    ping.setText(string.format(format,name,yoffset))
                    centerText(ping,1.5,10)
                end
            else ping.setText("") 
            end 
        else ping.setText("")
        end
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
    mobs = data.mobs or {}
end

-- Required
function MODULE:enable(interface)
    neural = interface
    print("Mob Radar Enabled")
end

-- Required
function MODULE:disable(interface)
    print("Mob Radar Disabled")
end

return MODULE