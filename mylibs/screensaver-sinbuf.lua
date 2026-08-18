local cmp_reader = require("cmp_reader")
--
local heart = cmp_reader.get_table("heart.cmp")
local colorTable = {[0]=-1,[1]=colors.yellow,[2]=colors.red}
--
local drawRate = 1.0/100.0
local calcRate = drawRate
local monitor = peripheral.find("monitor")
if not monitor then error("No monitors found!",0) return end
local monitorSize = {x=1,y=1} monitorSize.x,monitorSize.y = monitor.getSize()
local monitorPixels = monitorSize.x*monitorSize.y
local colorList = {0xFFFFFF,0xFFAA00,0xFF00FF,0x00FFFF,0xFFDF00,0x55FF00,0xFFB5B5,0x4C4C4C,0x999999,0x00FFFF,0xAA00FF,0x0000FF,0x7F664C,0x99FF99,0xFF0000,0x000000}
local sinTable = {}
local bufferCurrent = {}
local bufferNext = {}
--
local size = {x=26,y=24}
local pos = {x=math.random(1,monitorSize.x-size.x),y=math.random(1,monitorSize.y-size.y)}
local vel = {x=1,y=1}
--

local function clearBuffers()
    for i=1,monitorPixels do
        bufferCurrent[i]=-1
        bufferNext[i]=-1
    end
end

local function sim()
	local newX,newY = pos.x+vel.x,pos.y+vel.y
	if ((newX+size.x) > monitorSize.x) or (newX < 0) then vel.x = -vel.x end
	if ((newY+size.y) > monitorSize.y) or (newY < 0) then vel.y = -vel.y end
	pos.x = pos.x + vel.x
	pos.y = pos.y + vel.y
end

local function getWave(x,offset)
    local speed = 1000.0
    local offset = x+math.floor(os.time()*speed)
    local offsetb = offset*3 + math.floor(os.time()*speed*4.15)
    return (sinTable[((offset)%#sinTable)+1] + sinTable[((offsetb)%#sinTable)+1])*0.5
end

-- Defaults: 5.0,100,0.05,0.25
local function genSinTable(seconds,width,freq,amp)
    for i=1,math.floor(width*seconds) do
        sinTable[#sinTable+1] = math.sin(((i)+1)*freq)*amp + 0.5
    end
end

-- Returns string ID
local function getPixelColor(size,x,y)
    local wave = size.y*getWave(x)
    local wavea = size.y*getWave(x+20)
    local abs = math.abs(y-wave)
    local absa = math.abs(y-wavea)
    if (abs < 1) or (absa < 1) then return colors.red
    elseif (abs < 2) or (absa < 2) then return colors.orange
    elseif (abs < 3) or (absa < 3) then return colors.yellow
    else return -1 end
end

local function drawWaveRegion(x,y,w,h)
end

local function setColors(monitor,colorList)
    local bshift = bit32.lshift
    for c=1,#colorList do
        monitor.setPaletteColor(bshift(1,c-1),colorList[c])
    end
end

local function swap()
    local temp = bufferCurrent
    bufferCurrent = bufferNext
    bufferNext = temp
end


local function calculate()
    while true do
        -- Draw the wave
        for i=1,monitorPixels do
            local x,y = ((i-1)%monitorSize.x),math.floor(i/monitorSize.x)
            local color = getPixelColor(monitorSize,x,y)
            bufferNext[i]=color
        end
        -- Draw the heart
        cmp_reader.draw_buffer(heart,bufferNext,monitorSize.x,pos.x,pos.y,colorTable)
        sim()
        swap()
        sleep(calcRate)
    end
end

local function draw()
    term.redirect(monitor)
    while true do
        monitor.clear()
        paintutils.drawImage(cmp_reader.buffer_to_img(bufferCurrent,monitorSize.x,monitorSize.y),1,1)
        monitor.setBackgroundColor(colors.black)
        sleep(drawRate)
    end
end

genSinTable(5.0,monitorSize.x,0.05,0.25)
-- genSinTable(5.0,monitorSize.x,0.05,0.25)
clearBuffers()
monitor.setTextScale(0.5)
setColors(monitor,colorList)

parallel.waitForAll(
    draw,
    calculate
)
-- draw()
