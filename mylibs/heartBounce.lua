local cmp_reader = require("cmp_reader")

local t = cmp_reader.get_table("heart.cmp")
print("read table")
local colorTable = {[0]=-1,[1]=colors.yellow,[2]=colors.red}
print("set colors")
local monitor = peripheral.find("monitor")

local monitorSize = {x=1,y=1} monitorSize.x,monitorSize.y = monitor.getSize()
local oldTerm = term.redirect(monitor)
local size = {x=26,y=24}
local pos = {x=math.random(1,monitorSize.x-size.x),y=math.random(1,monitorSize.y-size.y)}
local vel = {x=1,y=1}

local function sim()
	local newX,newY = pos.x+vel.x,pos.y+vel.y
	if ((newX+size.x) > monitorSize.x) or (newX < 0) then vel.x = -vel.x end
	if ((newY+size.y) > monitorSize.y) or (newY < 0) then vel.y = -vel.y end
	pos.x = pos.x + vel.x
	pos.y = pos.y + vel.y
end

while true do
	monitor.clear()
	cmp_reader.draw_htable(t,pos.x,pos.y,colorTable)
	monitor.setBackgroundColor(colors.black)
	sim()
	sleep(0.01)
end
term.redirect(oldTerm)
