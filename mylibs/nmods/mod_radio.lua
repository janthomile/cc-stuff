local MODULE = {
    name = "Radio", -- Required
    enabled = false, -- Required
    doScan = false, -- Recommended
    doSense = false -- Recommended
}

-- Working Vars
local modem
local speakers
local active = false
local focused = false
local tick = 1
local discoverUpdateTicks=40
local targetChannel = 0
local discoveryBuffer = {}
local discoveryBufferNext = {}
local stationsFormat = "[%s]:%s"
-- UI
local uiKeys = {
    focus = keys.grave,
    navUp = keys.up,
    navDown = keys.down,
    navSelect = keys.right
}
local focused = false
local focusIdx = 1
local selectIdx = -1
local anchorIdx = 1
local focusColor = 0x00000000
local selectColor = 0x00000000
local oobSelect
--
local separation = 1
local charSize = {x=6,y=12}
local listingCount = 5
local isFocusedText = string.format("Press '%s' to focus UI.",string.upper(keys.getName(uiKeys.focus)))
-- Canvas Objects
local listingGroup
local listingBG
local focusRect
local focusOutline
local selectedRect
local listingText
local isFocusedTextObject

local function clamp(v,min,max)
    return math.min(math.max(v,min),max)
end

local function centerText(textObject,xsize,ysize)
    xsize = xsize or 1.5
    ysize = ysize or 12
    local scale = textObject.getScale()
    local txt = textObject.getText()
    local offset = {x=-(#txt*xsize*scale),y=-(ysize*scale)}
    -- local offset = getTextCenterOffset(textObject.getText(),xsize,ysize,textObject.getScale())
    local x,y = textObject.getPosition()
    textObject.setPosition(x+offset.x,y+offset.y)
    return textObject
end

function hsvaToHex(h, s, v, a)
    local r, g, b

    if s == 0 then
        r, g, b = v, v, v
    else
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - s * f)
        local t = v * (1 - s * (1 - f))

        i = i % 6

        if i == 0 then
            r, g, b = v, t, p
        elseif i == 1 then
            r, g, b = q, v, p
        elseif i == 2 then
            r, g, b = p, v, t
        elseif i == 3 then
            r, g, b = p, q, v
        elseif i == 4 then
            r, g, b = t, p, v
        else
            r, g, b = v, p, q
        end
    end

    local R = math.floor(r * 255 + 0.5)
    local G = math.floor(g * 255 + 0.5)
    local B = math.floor(b * 255 + 0.5)
    local A = math.floor(a * 255 + 0.5)

    return R * 0x1000000 + G * 0x10000 + B * 0x100 + A
end

--[[ Discovery Format:
{
    type = "discovery_response",protocol = "PASC", channel = 0000, station = "Station Name",
    metadata = {artist = "Artist Name",owner="Owner Name", protocol = "PASC", song = "Song Name"}
}
]]

-- RADIO LOGIC
local function discover(event)
    repeat
        modem.open(759)
    until modem.isOpen(759) and self.enabled

    modem.transmit(759,759,{protocol="PASC",type="discovery"})
    if tick%discoverUpdateTicks == 0 then
        discoveryBuffer = discoveryBufferNext
        discoveryBufferNext = {}
    end
    if event[1]=="modem_message" and event[3]==759 and event[4]==759 and event[5].type=="discovery_response" then table.insert(discoveryBufferNext,formatDiscovery(event[5])) end
end

local function changeChannel()
    modem.open(targetChannel)
end

local function playAudio(event)
    if not active then return end
    if event[1]=="modem_message" then
        if event[3]==chan and event[4]==759 then
            local payload=event[5]
            speaker_left.playAudio(payload.buffer[1]) speaker_right.playAudio(payload.buffer[2])
        end
    end
end

-- UI LOGIC

local function updateSelectRect()
    local target = selectIdx-anchorIdx
    oobSelect = target < 0 or target >= listingCount -- or selectIdx == focusIdx
    selectedRect.setPosition(0,charSize.y*(target) + separation*target)
    selectedRect.setColor(oobSelect and 0x00000000 or selectColor)
end

local function updateListing()
    for i=1,listingCount do
        local idx = anchorIdx+i-1
        if i > #discoveryBuffer then break end
        local entry = discoveryBuffer[i]
        listingText[i].setText(string.format(formatDiscovery,entry.channel,entry.station))
    end
    updateSelectRect()
end


local function assignOutlineGroup(group,size,color,thickness)
    group.addRectangle(0,0,size.x,thickness,color)
    group.addRectangle(0,size.y-thickness,size.x,thickness,color)
    group.addRectangle(0,thickness,thickness,size.y-thickness*2,color)
    group.addRectangle(size.x-thickness,thickness,thickness,size.y-thickness*2,color)
    return group
end

local function printTable(t)
    local l = {}
    for key,value in pairs(focusOutline) do
        table.insert(l,key) end
    print(table.concat(l,","))
end

local function setupUI(data)
    listingText = {}
    local canvas = data.canvas
    local size = data.canvasSize
    local half = {x=size.x/2,y=size.y/2}

    local listingSize = {x=64,y=(listingCount*charSize.y + listingCount*separation - separation)}
    local groupMargin = {x=4,y=4}
    local indent = 4
    local textSize = 0.5
    local outlineMargin = 1.5
    --
    listingGroup = canvas.addGroup({size.x-listingSize.x-groupMargin.x,groupMargin.y+charSize.y})
    local radiotext = listingGroup.addText({16,-8},"Radio Listings",0xFFFFFFFF,0.5)
    -- centerText(radiotext,2.25,-8)
    listingBG = listingGroup.addRectangle(0,0,listingSize.x,listingSize.y,0x0B0B45AA)
    focusOutline = listingGroup.addGroup({0,0})
    focusRect = focusOutline.addRectangle(0,0,listingSize.x,charSize.y,0x444444AA)
    assignOutlineGroup(focusOutline,{x=listingSize.x,y=charSize.y},0xFFFFFFAA,1.5)
    -- focusRect = listingGroup.addRectangle(0,0,listingSize.x,charSize.y,0x444444AA)
    selectedRect = listingGroup.addRectangle(0,0,listingSize.x,charSize.y,0xFFFFFF22)
    isFocusedTextObject = listingGroup.addText({0,listingSize.y+outlineMargin+1},isFocusedText,0xFFFFFFAA,0.33)
    assignOutlineGroup(listingGroup.addGroup({-outlineMargin,-outlineMargin}),{x=listingSize.x+outlineMargin*2,y=listingSize.y+outlineMargin*2},0xFFD700AA,1.5)
    for i=1,listingCount do
        local idx = i-1
        table.insert(listingText,listingGroup.addText({indent,idx*charSize.y+idx*separation+4},"",0xFFFFFFFF,0.5))
        -- table.insert(listingText,listingGroup.addText({indent,idx*charSize.y+idx*separation+4},string.format("Radio Station %s",i),0xFFFFFFFF,0.5))
    end
    updateListing()
end

local function incrementChannel(increment)
    focusIdx = (((focusIdx-1)+#discoveryBuffer+increment) % #discoveryBuffer) + 1
    anchorIdx = clamp(focusIdx-2,1,#discoveryBuffer-listingCount+1)
    updateListing()
    -- local target = focusIdx-anchorIdx
    -- focusOutline.setPosition(0,charSize.y*(target) + separation*target)
end

local function stopAudio()
    speakers.left.stop()
    speakers.right.stop()
end

local function selectChannel()
    local playing = false
    if focusIdx == selectIdx then selectIdx = -1 active = false
    else selectIdx = focusIdx active = true end
    stopAudio()
    updateSelectRect()
    print("Selected channel " .. selectIdx)
end

--

function MODULE:draw()
    if not self.enabled then return end -- You should put this line right before using canvas objects. Usually once is fine.
    tick = tick + 1
    selectColor = hsvaToHex((tick%100)/100,0.5,0.7,0.5)
    local target = focusIdx-anchorIdx
    if focused then focusOutline.setPosition(0,charSize.y*(target) + separation*target) else focusOutline.setPosition(-100,-100) end
    focusColor = focused and hsvaToHex(0,0.0,0.5+math.sin(tick*0.1)*0.25,0.5) or 0x00000000
    focusRect.setColor(focusColor)
    selectedRect.setColor(oobSelect and 0x00000000 or selectColor)
end

function MODULE:input(event)
    playAudio(event)
    if event[1] == "key" then
        if event[2] == uiKeys.focus and (not event[3]) then
            focused = not focused
            if focused then isFocusedTextObject.setText("") else isFocusedTextObject.setText(isFocusedText) end
        elseif not focused then return
        elseif event[2] == uiKeys.navUp then
            incrementChannel(-1)
        elseif event[2] == uiKeys.navDown then
            incrementChannel(1)
        elseif event[2] == uiKeys.navSelect then
            selectChannel()
        end
    end
    return false -- Returns whether the input was consumed
end

function MODULE:enable(data)
    if data.speakers then speakers = data.speakers else print("Radio Module Error: Invalid Speakers") return false end
    if data.modem then modem = data.modem else print("Radio Module Error: Invalid Modem") return false end
    setupUI(data)
    -- discover()
end

function MODULE:disable(data)
    listingGroup.remove()
end

return MODULE