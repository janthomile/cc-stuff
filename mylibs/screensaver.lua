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
local colorList = {0xFFFFFF,0xFFAA00,0xFF00FF,0x00FFFF,0xFFFB00,0x55FF00,0xFFB5B5,0x4C4C4C,0x999999,0x00FFFF,0xAA00FF,0x0000FF,0x7F664C,0x99FF99,0xFF0000,0x000000}
local bufferCurrent = {}
local bufferNext = {}
local updateFinished = false
--
local size = {x=26,y=24}
local pos = {x=math.random(1,monitorSize.x-size.x),y=math.random(1,monitorSize.y-size.y)}
local vel = {x=1,y=1}
--

for i=1,monitorPixels do
    bufferCurrent[i]=-1
    bufferNext[i]=-1
end

local function sim()
	local newX,newY = pos.x+vel.x,pos.y+vel.y
	if ((newX+size.x) > monitorSize.x) or (newX < 0) then vel.x = -vel.x end
	if ((newY+size.y) > monitorSize.y) or (newY < 0) then vel.y = -vel.y end
	pos.x = pos.x + vel.x
	pos.y = pos.y + vel.y
end

local function getWave(x)
    local sin = math.sin
    local offset = os.time()*100.0
    local freq = 0.05
    local amp = 0.25
    local y_offset = 0.5
    local count = 2
    local sinw = ((sin(x*freq+offset)+sin((x*freq+offset*2)*2))/count)*amp + y_offset
    return sinw
end

-- Returns string ID
local function getPixelColor(size,x,y)
    local wave = size.y*getWave(x)
    local abs = math.abs(y-wave)
    if abs < 2 then return colors.red
    elseif abs < 4 then return colors.yellow
    else return -1 end
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
            bufferNext[i]=getPixelColor(monitorSize,x,y)
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

monitor.setTextScale(0.5)
setColors(monitor,colorList)

parallel.waitForAll(
    draw,
    calculate
)
-- draw()
